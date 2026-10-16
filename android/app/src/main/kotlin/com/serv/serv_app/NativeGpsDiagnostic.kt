package com.serv.serv_app

import android.annotation.SuppressLint
import android.content.Context
import android.location.GnssStatus
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import androidx.annotation.NonNull
import com.google.android.gms.location.CurrentLocationRequest
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * TEMPORARY DIAGNOSTIC ONLY - not part of the production attendance/tracking
 * pipeline. Disabled entirely in release builds (BuildConfig.DEBUG guard on
 * every entry point) and never invoked from check-in/check-out. Does not
 * touch geofencing, the 50m threshold, or background tracking, and never
 * registers a second concurrent production GPS subscription - all state
 * here is private to this plugin and torn down on every capture boundary.
 *
 * Two independent diagnostics:
 *  - fusedLocationOnce: Fused Location Provider at PRIORITY_HIGH_ACCURACY
 *    (the same priority geolocator_android requests for
 *    LocationAccuracy.bestForNavigation), for comparison against Flutter's
 *    result on the same device under the same conditions.
 *  - rawGpsProviderCapture: bypasses FLP entirely and talks to
 *    LocationManager.GPS_PROVIDER + GnssStatus directly, to distinguish "no
 *    satellite fix" from "GNSS fix with poor accuracy" from "network-only
 *    location" - none of which FLP's blended `fused` result can tell apart,
 *    and none of which geolocator surfaces to Dart at all.
 */
class NativeGpsDiagnostic(private val context: Context) : FlutterPlugin, MethodCallHandler {

    private var channel: MethodChannel? = null

    // ---- fusedLocationOnce state ----
    // Guards against overlapping native captures (e.g. a duplicate method
    // call arriving before the previous one finished): the prior in-flight
    // request is cancelled so only one GPS sampling request is active at a
    // time, and its result is dropped rather than returned twice.
    private var activeCancellationSource: CancellationTokenSource? = null

    // ---- rawGpsProviderCapture state ----
    // All of this is torn down by cleanupRawGpsCapture() before a new
    // capture starts, when explicitly cancelled from Dart, and from
    // onDetachedFromEngine - a capture can never outlive the engine or
    // overlap with another one.
    private val mainHandler = Handler(Looper.getMainLooper())
    private var gpsLocationListener: LocationListener? = null
    private var gnssStatusCallback: GnssStatus.Callback? = null
    private var gpsCaptureTimeoutRunnable: Runnable? = null
    private var gpsCaptureResult: Result? = null
    private var gpsCaptureStartElapsedNanos: Long = 0L
    private var gpsCaptureSatelliteCount = 0
    private var gpsCaptureSatellitesUsedInFix = 0
    private var gpsCaptureTtffMillis: Int? = null
    private var gpsCaptureBestFix: Location? = null
    private var gpsCaptureFinished = true

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        activeCancellationSource?.cancel()
        activeCancellationSource = null
        // Lifecycle-safe teardown: the engine (and this Activity) may be
        // gone before a capture completes - never leave a LocationListener
        // or GnssStatus callback registered past this point.
        cleanupRawGpsCapture()
    }

    @SuppressLint("MissingPermission")
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "fusedLocationOnce" -> handleFusedLocationOnce(result)
            "rawGpsProviderCapture" -> handleRawGpsProviderCapture(result)
            "cancelRawGpsCapture" -> {
                cleanupRawGpsCapture()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    @SuppressLint("MissingPermission")
    private fun handleFusedLocationOnce(result: Result) {
        if (!BuildConfig.DEBUG) {
            result.error("RELEASE_BUILD", "GPS diagnostics are disabled in release builds", null)
            return
        }
        try {
            // Cancel any still-running capture before starting a new one -
            // never let two FLP requests sample concurrently.
            activeCancellationSource?.cancel()
            val cancellationSource = CancellationTokenSource()
            activeCancellationSource = cancellationSource

            val fused = LocationServices.getFusedLocationProviderClient(context)
            val request = CurrentLocationRequest.Builder()
                .setPriority(Priority.PRIORITY_HIGH_ACCURACY)
                .setDurationMillis(30_000L)
                .build()

            fused.getCurrentLocation(request, cancellationSource.token)
                .addOnSuccessListener { location ->
                    if (activeCancellationSource !== cancellationSource) return@addOnSuccessListener
                    result.success(toFusedMap(location, rawManagerFix()))
                }
                .addOnFailureListener { e ->
                    if (activeCancellationSource !== cancellationSource) return@addOnFailureListener
                    result.error("FUSED_LOCATION_ERROR", e.message, null)
                }
        } catch (e: Exception) {
            result.error("FUSED_LOCATION_EXCEPTION", e.message, null)
        }
    }

    /**
     * Fresh, FLP-bypassing GPS_PROVIDER capture via LocationManager +
     * GnssStatus. Time-bounded ([RAW_GPS_CAPTURE_DURATION_MS]), finishes
     * early on an accurate fix, and is fully cancellable/lifecycle-safe
     * via [cleanupRawGpsCapture]. Registers exactly one LocationListener
     * and one GnssStatus.Callback for the duration of the capture - never
     * a second or lingering subscription, and never anything touching the
     * production attendance/tracking GPS consumers.
     */
    @SuppressLint("MissingPermission")
    private fun handleRawGpsProviderCapture(result: Result) {
        if (!BuildConfig.DEBUG) {
            result.error("RELEASE_BUILD", "GPS diagnostics are disabled in release builds", null)
            return
        }

        // Never let a second capture start while one is already running -
        // tear down the previous one first (its pending result, if any, is
        // resolved with a CANCELLED error, never left hanging).
        cleanupRawGpsCapture()

        val lm = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
        if (lm == null) {
            result.error("NO_LOCATION_MANAGER", "LocationManager unavailable", null)
            return
        }

        val gpsProviderEnabled = try {
            lm.isProviderEnabled(LocationManager.GPS_PROVIDER)
        } catch (e: Exception) {
            false
        }

        gpsCaptureResult = result
        gpsCaptureFinished = false
        gpsCaptureSatelliteCount = 0
        gpsCaptureSatellitesUsedInFix = 0
        gpsCaptureTtffMillis = null
        gpsCaptureBestFix = null
        gpsCaptureStartElapsedNanos = SystemClock.elapsedRealtimeNanos()

        if (!gpsProviderEnabled) {
            // Nothing to listen for - report immediately rather than
            // waiting out the full time budget.
            finishRawGpsCapture(gpsProviderEnabled = false)
            return
        }

        val statusCallback = object : GnssStatus.Callback() {
            override fun onSatelliteStatusChanged(status: GnssStatus) {
                gpsCaptureSatelliteCount = status.satelliteCount
                var usedInFix = 0
                for (i in 0 until status.satelliteCount) {
                    if (status.usedInFix(i)) usedInFix++
                }
                gpsCaptureSatellitesUsedInFix = usedInFix
            }

            override fun onFirstFix(ttffMillis: Int) {
                gpsCaptureTtffMillis = ttffMillis
            }
        }
        gnssStatusCallback = statusCallback

        val listener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                val best = gpsCaptureBestFix
                if (best == null || location.accuracy < best.accuracy) {
                    gpsCaptureBestFix = location
                }
                // A genuinely accurate GPS fix - no need to burn the rest
                // of the time budget.
                if (location.accuracy <= 50f) {
                    finishRawGpsCapture(gpsProviderEnabled = true)
                }
            }

            @Deprecated("Deprecated in Java, still called on some OEM skins")
            override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}

            override fun onProviderEnabled(provider: String) {}

            override fun onProviderDisabled(provider: String) {
                // GPS turned off mid-capture - stop immediately with
                // whatever was observed rather than waiting out the timer.
                finishRawGpsCapture(gpsProviderEnabled = false)
            }
        }
        gpsLocationListener = listener

        try {
            lm.registerGnssStatusCallback(statusCallback, mainHandler)
            lm.requestLocationUpdates(
                LocationManager.GPS_PROVIDER,
                /* minTimeMs = */ 1000L,
                /* minDistanceM = */ 0f,
                listener,
                Looper.getMainLooper(),
            )
        } catch (e: Exception) {
            finishRawGpsCaptureWithError(e.message ?: "requestLocationUpdates failed")
            return
        }

        // Time-bounded regardless of outcome: never leaves the listener
        // running indefinitely waiting for a fix that may never arrive.
        val timeoutRunnable = Runnable { finishRawGpsCapture(gpsProviderEnabled = true) }
        gpsCaptureTimeoutRunnable = timeoutRunnable
        mainHandler.postDelayed(timeoutRunnable, RAW_GPS_CAPTURE_DURATION_MS)
    }

    private fun finishRawGpsCapture(gpsProviderEnabled: Boolean) {
        if (gpsCaptureFinished) return
        gpsCaptureFinished = true

        val elapsedMs = (SystemClock.elapsedRealtimeNanos() - gpsCaptureStartElapsedNanos) / 1_000_000
        val bestFix = gpsCaptureBestFix

        // Distinguishes: no satellites detected at all, satellites visible
        // but none used in a fix, satellites used but no Location emitted
        // yet, a GNSS fix that doesn't meet the 50m check-in threshold, and
        // a genuinely accurate GNSS fix. This is strictly more granular
        // than FLP's blended `fused` result, which cannot tell "network
        // fallback" apart from "poor GPS fix".
        val fixState = when {
            !gpsProviderEnabled -> "gps_provider_disabled"
            bestFix != null && bestFix.accuracy <= 50f -> "gps_fix_accurate"
            bestFix != null -> "gps_fix_poor_accuracy"
            gpsCaptureSatellitesUsedInFix > 0 -> "satellites_used_but_no_location_yet"
            gpsCaptureSatelliteCount > 0 -> "satellites_visible_no_fix"
            else -> "no_satellites_detected"
        }

        val payload = mapOf(
            "gpsProviderEnabled" to gpsProviderEnabled,
            "satelliteCount" to gpsCaptureSatelliteCount,
            "satellitesUsedInFix" to gpsCaptureSatellitesUsedInFix,
            "timeToFirstFixMs" to gpsCaptureTtffMillis,
            "captureDurationMs" to elapsedMs,
            "fixState" to fixState,
            "fix" to describeLocation(bestFix),
        )

        val pendingResult = gpsCaptureResult
        gpsCaptureResult = null
        cleanupRawGpsCapture()
        pendingResult?.success(payload)
    }

    private fun finishRawGpsCaptureWithError(message: String) {
        if (gpsCaptureFinished) return
        gpsCaptureFinished = true
        val pendingResult = gpsCaptureResult
        gpsCaptureResult = null
        cleanupRawGpsCapture()
        pendingResult?.error("RAW_GPS_CAPTURE_ERROR", message, null)
    }

    /**
     * Lifecycle-safe teardown: called before starting a new capture, on
     * explicit cancellation from Dart, and from onDetachedFromEngine.
     * Idempotent, and never leaves a LocationListener or GnssStatus
     * callback registered after it returns. If a capture was in flight
     * and did not finish through [finishRawGpsCapture]/
     * [finishRawGpsCaptureWithError] first, its pending Dart result is
     * resolved with a CANCELLED error rather than left hanging forever.
     */
    @SuppressLint("MissingPermission")
    private fun cleanupRawGpsCapture() {
        gpsCaptureTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
        gpsCaptureTimeoutRunnable = null

        try {
            val lm = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
            gpsLocationListener?.let { lm?.removeUpdates(it) }
            gnssStatusCallback?.let { lm?.unregisterGnssStatusCallback(it) }
        } catch (e: Exception) {
            // Best-effort cleanup only - never throw out of a teardown path.
        }
        gpsLocationListener = null
        gnssStatusCallback = null

        val wasFinished = gpsCaptureFinished
        gpsCaptureFinished = true
        val pendingResult = gpsCaptureResult
        gpsCaptureResult = null
        if (!wasFinished) {
            pendingResult?.error("CANCELLED", "Raw GPS capture cancelled", null)
        }
    }

    /** Last known fix read straight from LocationManager's GPS provider, bypassing FLP,
     * purely to surface `provider` and cross-check against the fused result. */
    @SuppressLint("MissingPermission")
    private fun rawManagerFix(): Location? {
        return try {
            val lm = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
            lm?.getLastKnownLocation(LocationManager.GPS_PROVIDER)
        } catch (e: Exception) {
            null
        }
    }

    private fun describeLocation(loc: Location?): Map<String, Any?>? {
        if (loc == null) return null
        val iso = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }
        val isMock = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            loc.isMock
        } else {
            @Suppress("DEPRECATION")
            loc.isFromMockProvider
        }
        return mapOf(
            "latitude" to loc.latitude,
            "longitude" to loc.longitude,
            "accuracy" to loc.accuracy,
            "altitude" to if (loc.hasAltitude()) loc.altitude else null,
            "speed" to if (loc.hasSpeed()) loc.speed else null,
            "provider" to loc.provider,
            "timestampMs" to loc.time,
            "timestampIso" to iso.format(Date(loc.time)),
            "isMocked" to isMock,
        )
    }

    private fun toFusedMap(location: Location?, gpsManagerFix: Location?): Map<String, Any?> {
        return mapOf(
            "fused" to describeLocation(location),
            "gpsProviderLastKnown" to describeLocation(gpsManagerFix),
            "capturedAtMs" to System.currentTimeMillis(),
        )
    }

    companion object {
        const val CHANNEL = "serv_app/native_gps_diagnostic"
        const val RAW_GPS_CAPTURE_DURATION_MS = 25_000L
    }
}
