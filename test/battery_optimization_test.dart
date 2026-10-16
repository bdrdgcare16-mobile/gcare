import 'package:flutter_test/flutter_test.dart';
import 'package:serv_app/utils/battery_optimization.dart';

void main() {
  group('shouldPromptBatteryExemption', () {
    test('prompts on Android when not exempt and never prompted', () {
      expect(
        shouldPromptBatteryExemption(
          isAndroid: true, alreadyExempt: false, promptedBefore: false,
        ),
        isTrue,
      );
    });

    test('never prompts when already exempt', () {
      expect(
        shouldPromptBatteryExemption(
          isAndroid: true, alreadyExempt: true, promptedBefore: false,
        ),
        isFalse,
      );
    });

    test('never prompts twice (dismissal is final)', () {
      expect(
        shouldPromptBatteryExemption(
          isAndroid: true, alreadyExempt: false, promptedBefore: true,
        ),
        isFalse,
      );
    });

    test('never prompts off-Android', () {
      expect(
        shouldPromptBatteryExemption(
          isAndroid: false, alreadyExempt: false, promptedBefore: false,
        ),
        isFalse,
      );
    });
  });
}
