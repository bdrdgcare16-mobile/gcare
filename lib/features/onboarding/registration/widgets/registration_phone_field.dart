// lib/features/onboarding/registration/widgets/registration_phone_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

/// Splits a stored phone value into (countryIso, nationalNumber) for
/// restoring an [IntlPhoneField].
///
/// Stored values are normalized international numbers (`+919876543210`)
/// but older drafts may contain spaced variants (`+91 80 0000 0000`) or
/// bare national numbers (`9876543210` — assumed India).
({String isoCode, String nationalNumber}) splitStoredPhone(
  String stored, {
  String fallbackIso = 'IN',
}) {
  final raw = stored.trim();
  if (raw.isEmpty) return (isoCode: fallbackIso, nationalNumber: '');

  // Keep the leading '+', strip formatting from the rest.
  final compact = raw.startsWith('+')
      ? '+${raw.substring(1).replaceAll(RegExp(r'[^0-9]'), '')}'
      : raw.replaceAll(RegExp(r'[^0-9]'), '');

  if (compact.isEmpty) return (isoCode: fallbackIso, nationalNumber: '');

  if (!compact.startsWith('+')) {
    return (isoCode: fallbackIso, nationalNumber: compact);
  }

  try {
    final parsed =
        PhoneNumber.fromCompleteNumber(completeNumber: compact);
    if (parsed.countryISOCode.isEmpty) {
      return (isoCode: fallbackIso, nationalNumber: compact);
    }
    return (
      isoCode: parsed.countryISOCode,
      nationalNumber: parsed.number,
    );
  } catch (_) {
    return (
      isoCode: fallbackIso,
      nationalNumber: compact.replaceAll('+', ''),
    );
  }
}

/// Shared country-aware phone input for the registration wizard.
///
/// Renders [IntlPhoneField]'s country selector directly beside the
/// national-number input and validates against the SELECTED country's
/// metadata (min/max national length). India additionally enforces the
/// mobile format rules (10 digits, starts 6–9, no repeated digit).
///
/// Validation is driven by a wrapping [FormField] — not the field's own
/// internal validator — so the same rules run identically on Next,
/// Save Draft and Review in every screen that uses this widget.
class RegistrationPhoneField extends StatefulWidget {
  /// Field label shown in the input decoration ('Contact Number *').
  final String label;

  /// Message when the field is empty ('Contact number is required').
  final String requiredMessage;

  /// Base invalid message ('Enter a valid contact number').
  /// Rendered as "$invalidMessage for COUNTRY" for non-India countries.
  final String invalidMessage;

  /// ISO code used to restore the country selector ('IN').
  final String initialIsoCode;

  /// National number (no dial code) used to restore the input.
  final String initialNationalNumber;

  /// Fires on every change with the package's [PhoneNumber] —
  /// callers persist `phone.completeNumber` (`+919876543210`).
  final ValueChanged<PhoneNumber> onChanged;

  const RegistrationPhoneField({
    super.key,
    required this.label,
    required this.requiredMessage,
    required this.invalidMessage,
    required this.onChanged,
    this.initialIsoCode = 'IN',
    this.initialNationalNumber = '',
  });

  @override
  State<RegistrationPhoneField> createState() =>
      _RegistrationPhoneFieldState();
}

class _RegistrationPhoneFieldState extends State<RegistrationPhoneField> {
  static final RegExp _digitsOnly = RegExp(r'^[0-9]+$');
  static final RegExp _repeatedDigit = RegExp(r'^(\d)\1{9}$');

  /// Mobile-number rules for countries the product explicitly supports.
  /// `min`/`max` are national-number lengths; `start` is an optional
  /// leading-digit constraint. Countries not listed fall back to the
  /// bundled package metadata (min/max national length).
  static const Map<String, ({int min, int max, String? start})>
      _countryRules = {
    // India: 10 digits, starts 6-9, no single repeated digit.
    'IN': (min: 10, max: 10, start: r'^[6-9]'),
    // Malaysia: mobiles are 9-10 national digits starting with '1'.
    'MY': (min: 9, max: 10, start: r'^1'),
    // Singapore: 8 digits, mobiles start 8/9.
    'SG': (min: 8, max: 8, start: r'^[89]'),
    // UAE: 9 national digits, mobiles start with '5'.
    'AE': (min: 9, max: 9, start: r'^5'),
    // NANP (US/Canada): 10 digits, area code starts 2-9.
    'US': (min: 10, max: 10, start: r'^[2-9]'),
    'CA': (min: 10, max: 10, start: r'^[2-9]'),
  };

  late Country _country;
  late String _number;

  @override
  void initState() {
    super.initState();
    _country = countries.firstWhere(
      (c) => c.code == widget.initialIsoCode,
      orElse: () => countries.firstWhere((c) => c.code == 'IN'),
    );
    _number = widget.initialNationalNumber;
  }

  int get _maxNationalLength =>
      _countryRules[_country.code]?.max ?? _country.maxLength;

  /// Country-aware validation — same rules regardless of which screen
  /// hosts the field.
  String? _validate(String? value) {
    final number = (value ?? '').trim();
    if (number.isEmpty) return widget.requiredMessage;
    if (!_digitsOnly.hasMatch(number)) return widget.invalidMessage;

    final rule = _countryRules[_country.code];
    final min = rule?.min ?? _country.minLength;
    final max = rule?.max ?? _country.maxLength;
    var valid = number.length >= min && number.length <= max;
    if (valid && rule?.start != null) {
      valid = RegExp(rule!.start!).hasMatch(number);
    }
    if (valid && _country.code == 'IN') {
      valid = !_repeatedDigit.hasMatch(number);
    }
    return valid
        ? null
        : '${widget.invalidMessage} for ${_country.name}';
  }

  InputDecoration _decoration() {
    return InputDecoration(
      labelText: widget.label,
      filled: true,
      fillColor: const Color(0xFFF7F4FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF655193), width: 1.6),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.initialNationalNumber,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: _validate,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntlPhoneField(
              decoration: _decoration(),
              initialCountryCode: _country.code,
              initialValue: widget.initialNationalNumber,
              // The wrapping FormField owns validation — suppress the
              // package's built-in validator and its length enforcement
              // (we apply the selected country's maxLength ourselves).
              disableLengthCheck: true,
              validator: (_) => null,
              autovalidateMode: AutovalidateMode.disabled,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(_maxNationalLength),
              ],
              onChanged: (phone) {
                _number = phone.number;
                state.didChange(phone.number);
                widget.onChanged(phone);
              },
              onCountryChanged: (country) {
                setState(() => _country = country);
                state.didChange(_number);
                // IntlPhoneField does not re-emit onChanged when only the
                // country changes — forward a synthesized PhoneNumber so
                // the stored complete number picks up the new dial code.
                widget.onChanged(
                  PhoneNumber(
                    countryISOCode: country.code,
                    countryCode: '+${country.fullCountryCode}',
                    number: _number,
                  ),
                );
              },
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 14, top: 6),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
