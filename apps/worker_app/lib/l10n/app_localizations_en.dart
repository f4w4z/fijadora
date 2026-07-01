// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Phoebe Worker';

  @override
  String get appTagline => 'Work On Your Terms';

  @override
  String get signIn => 'Sign In';

  @override
  String get signOut => 'Sign Out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get myJobs => 'My Jobs';

  @override
  String get schedule => 'Schedule';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get noInternet => 'No internet connection';

  @override
  String get offlineBanner =>
      'You are offline. Some features may be unavailable.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get errorOccurred => 'Oops! Something went wrong.';
}
