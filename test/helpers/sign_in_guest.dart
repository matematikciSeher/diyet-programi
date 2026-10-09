import 'package:diyet_programi/features/authentication/presentation/pages/sign_in_page.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> tapContinueAsGuest(WidgetTester tester) async {
  final guest = find.byKey(SignInPage.guestButtonKey);
  await tester.ensureVisible(guest);
  await tester.tap(guest);
  await tester.pumpAndSettle();
}
