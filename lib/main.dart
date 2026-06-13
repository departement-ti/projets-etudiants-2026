import 'package:alarm/alarm.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mymeds_app/l10n/app_localizations.dart';
import 'package:mymeds_app/auth/main_page.dart';
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/services/notification_service.dart';
import 'package:mymeds_app/services/session_timeout_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await dotenv.load();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Alarm.init(showDebugLogs: true);
  await NotificationService().initialize();
  // AwesomeNotifications().initialize(
  //     // set the icon to null if you want to use the default app icon
  //     'resource://drawable/ic_stat_icon_small',
  //     [
  //       NotificationChannel(
  //           channelGroupKey: 'basic_channel_group',
  //           channelKey: 'basic_channel',
  //           channelName: 'Basic notifications',
  //           channelDescription: 'Notification channel for basic tests',
  //           defaultColor: const Color.fromRGBO(7, 82, 96, 1),
  //           channelShowBadge: true,
  //           importance: NotificationImportance.Max,
  //           ledColor: Colors.white)
  //     ],
  //     // Channel groups are only visual and are not required
  //     channelGroups: [
  //       NotificationChannelGroup(
  //           channelGroupKey: 'basic_channel_group',
  //           channelGroupName: 'Basic group')
  //     ],
  //     debug: true);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  Locale? _locale;
  bool _isInitialized = false;

  setLocale(Locale locale) {
    if (mounted) {
      setState(() {
        _locale = locale;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initLocale();
  }

  Future<void> _initLocale() async {
    final locale = await getLocale();
    if (mounted) {
      setLocale(locale);
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // AppLocalizations.load(Locale('si', ''));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: Color.fromRGBO(7, 82, 96, 1),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MainPage(),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color.fromRGBO(241, 250, 251, 1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 241, 250, 251),
        ),
        colorSchemeSeed: const Color.fromRGBO(7, 82, 96, 1),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
    );
  }
}
