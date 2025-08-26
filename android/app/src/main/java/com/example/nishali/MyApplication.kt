package com.example.nishali

import android.app.Application
import android.util.Log
import com.google.firebase.FirebaseApp

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        try {
            FirebaseApp.initializeApp(this)
        } catch (e: Exception) {
            Log.e("MyApplication", "Failed to initialize Firebase", e)
            // Continue without Firebase
        }
    }
}
