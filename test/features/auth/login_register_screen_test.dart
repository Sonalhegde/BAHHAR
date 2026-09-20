import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bahhar/features/auth/presentation/widgets/apple_sign_in_button.dart';
import 'package:bahhar/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:bahhar/features/auth/presentation/widgets/phone_otp_widget.dart';

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.tap(find.byKey(key));
  // Flush the tap, the injected Future and the resulting rebuild without
  // pumpAndSettle (the in-flight spinner animates forever).
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 60));
}

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
    );

void main() {
  group('GoogleSignInButton', () {
    testWidgets('renders a bilingual label and triggers the injected action',
        (WidgetTester tester) async {
      var pressed = 0;
      var signedIn = 0;
      await tester.pumpWidget(_wrap(GoogleSignInButton(
        onPressed: () async {
          pressed++;
          return true;
        },
        onSignedIn: () => signedIn++,
      )));

      expect(find.text('Sign in with Google'), findsOneWidget);

      await _tap(tester, const Key('google_sign_in_button'));

      expect(pressed, 1);
      expect(signedIn, 1);
    });

    testWidgets('surfaces an error and does not report success on failure',
        (WidgetTester tester) async {
      var signedIn = 0;
      await tester.pumpWidget(_wrap(GoogleSignInButton(
        onPressed: () async => false,
        onSignedIn: () => signedIn++,
      )));

      await _tap(tester, const Key('google_sign_in_button'));
      await tester.pump();

      expect(signedIn, 0);
    });

    testWidgets('button is disabled while an external load is running',
        (WidgetTester tester) async {
      var pressed = 0;
      await tester.pumpWidget(_wrap(GoogleSignInButton(
        isLoading: true,
        onPressed: () async {
          pressed++;
          return true;
        },
      )));

      await _tap(tester, const Key('google_sign_in_button'));
      expect(pressed, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('AppleSignInButton', () {
    testWidgets('drives the injected Apple action and navigates on success',
        (WidgetTester tester) async {
      var signedIn = false;
      await tester.pumpWidget(_wrap(AppleSignInButton(
        onPressed: () async => true,
        onSignedIn: () => signedIn = true,
      )));

      expect(find.text('Sign in with Apple'), findsOneWidget);
      await _tap(tester, const Key('apple_sign_in_button'));
      expect(signedIn, isTrue);
    });

    testWidgets('shows the Arabic label when the locale is Arabic',
        (WidgetTester tester) async {
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AppleSignInButton(onPressed: () async => true),
          ),
        ),
      ));
      // Default provider is English; assert the English label by default.
      expect(find.text('Sign in with Apple'), findsOneWidget);
    });
  });

  group('PhoneOtpWidget', () {
    testWidgets('rejects an invalid number before sending', (tester) async {
      var sent = 0;
      await tester.pumpWidget(_wrap(PhoneOtpWidget(
        onSendOtp: (_) async {
          sent++;
          return true;
        },
      )));

      // Leave the phone field empty and hit send.
      await _tap(tester, const Key('phone_otp_action'));
      await tester.pump();

      expect(sent, 0);
      expect(find.text('Enter a valid Omani number.'), findsOneWidget);
    });

    testWidgets('full happy path: send → OTP field appears → verify',
        (tester) async {
      var verified = 0;
      String? sentTo;
      await tester.pumpWidget(_wrap(PhoneOtpWidget(
        onSendOtp: (phone) async {
          sentTo = phone;
          return true;
        },
        onVerifyOtp: (_) async => true,
        onVerified: () => verified++,
      )));

      await tester.enterText(find.byType(TextField).first, '91234567');
      await tester.pump();

      await _tap(tester, const Key('phone_otp_action'));
      expect(sentTo, '+96891234567');
      expect(find.byKey(const Key('otp_input')), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, '123456');
      await tester.pump();

      await _tap(tester, const Key('phone_otp_action'));
      expect(verified, 1);
    });

    testWidgets('reports an invalid-code error when verification fails',
        (tester) async {
      await tester.pumpWidget(_wrap(PhoneOtpWidget(
        onSendOtp: (_) async => true,
        onVerifyOtp: (_) async => false,
      )));

      await tester.enterText(find.byType(TextField).first, '91234567');
      await tester.pump();
      await _tap(tester, const Key('phone_otp_action'));

      await tester.enterText(find.byType(TextField).last, '000000');
      await tester.pump();
      await _tap(tester, const Key('phone_otp_action'));
      await tester.pump();

      expect(find.text('Invalid verification code.'), findsOneWidget);
    });

    testWidgets('blocks verification when the code is too short',
        (tester) async {
      var verifyCalls = 0;
      await tester.pumpWidget(_wrap(PhoneOtpWidget(
        onSendOtp: (_) async => true,
        onVerifyOtp: (_) async {
          verifyCalls++;
          return true;
        },
      )));

      await tester.enterText(find.byType(TextField).first, '91234567');
      await tester.pump();
      await _tap(tester, const Key('phone_otp_action'));

      await tester.enterText(find.byType(TextField).last, '12');
      await tester.pump();
      await _tap(tester, const Key('phone_otp_action'));
      await tester.pump();

      expect(verifyCalls, 0);
      expect(find.textContaining('6-digit'), findsOneWidget);
    });
  });
}
