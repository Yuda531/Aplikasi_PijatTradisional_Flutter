// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:susanti_refleksi/core/constants/app_strings.dart';

void main() {
  testWidgets('App name is correct', (WidgetTester tester) async {
    // Simple test to verify app strings
    expect(AppStrings.appName, 'Susanti Refleksi');
    expect(AppStrings.appTagline, 'Pijat & Refleksi Khusus Wanita');
  });
}
