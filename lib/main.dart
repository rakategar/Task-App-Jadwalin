import 'dart:io';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:time_machine/time_machine.dart';
import 'package:todark/app/modules/home.dart';
import 'package:todark/app/modules/onboarding.dart';
import 'package:todark/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:isar/isar.dart';
import 'package:todark/theme/theme_controller.dart';
import 'app/data/schema.dart';
import 'package:path_provider/path_provider.dart';
import 'translation/translation.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:todark/constants.dart';
import 'package:todark/firebase_options.dart';
import 'package:todark/ui/auth/authentication_bloc.dart';
import 'package:todark/ui/auth/launcherScreen/launcher_screen.dart';
import 'package:todark/ui/loading_cubit.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

late Isar isar;
late Settings settings;

bool amoledTheme = false;
bool materialColor = false;
Locale locale = const Locale('en', 'US');

final List appLanguages = [
  {'name': 'English', 'locale': const Locale('en', 'US')},
  {'name': 'Русский', 'locale': const Locale('ru', 'RU')},
  {'name': '中文', 'locale': const Locale('zh', 'CN')},
  {'name': '中国传统台湾', 'locale': const Locale('zh', 'TW')},
  {'name': 'فارسی', 'locale': const Locale('fa', 'IR')},
];

void main() async {
  final String timeZoneName;
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(systemNavigationBarColor: Colors.black));
  if (Platform.isAndroid) {
    await setOptimalDisplayMode();
  }
  if (Platform.isAndroid || Platform.isIOS) {
    timeZoneName = await FlutterTimezone.getLocalTimezone();
  } else {
    timeZoneName = '${DateTimeZone.local}';
  }
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const LinuxInitializationSettings initializationSettingsLinux =
      LinuxInitializationSettings(defaultActionName: 'Jadwal in');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    linux: initializationSettingsLinux,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  await isarInit();
  if (kIsWeb || defaultTargetPlatform == TargetPlatform.macOS) {
    await FacebookAuth.i.webAndDesktopInitialize(
      appId: facebookAppID,
      cookie: true,
      xfbml: true,
      version: "v15.0",
    );
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MultiRepositoryProvider(
    providers: [
      RepositoryProvider(create: (_) => AuthenticationBloc()),
      RepositoryProvider(create: (_) => LoadingCubit()),
    ],
    child: const MyApp(),
  ));
}

Future<void> setOptimalDisplayMode() async {
  final List<DisplayMode> supported = await FlutterDisplayMode.supported;
  final DisplayMode active = await FlutterDisplayMode.active;
  final List<DisplayMode> sameResolution = supported
      .where((DisplayMode m) =>
          m.width == active.width && m.height == active.height)
      .toList()
    ..sort((DisplayMode a, DisplayMode b) =>
        b.refreshRate.compareTo(a.refreshRate));
  final DisplayMode mostOptimalMode =
      sameResolution.isNotEmpty ? sameResolution.first : active;
  await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
}

Future<void> isarInit() async {
  isar = await Isar.open(
    [
      TasksSchema,
      TodosSchema,
      SettingsSchema,
    ],
    directory: (await getApplicationSupportDirectory()).path,
  );
  settings = isar.settings.where().findFirstSync() ?? Settings();
  if (settings.language == null) {
    settings.language = '${Get.deviceLocale}';
    isar.writeTxnSync(() => isar.settings.putSync(settings));
  }

  if (settings.theme == null) {
    settings.theme = 'system';
    isar.writeTxnSync(() => isar.settings.putSync(settings));
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  static Future<void> updateAppState(
    BuildContext context, {
    bool? newAmoledTheme,
    bool? newMaterialColor,
    Locale? newLocale,
  }) async {
    final state = context.findAncestorStateOfType<MyAppState>()!;

    if (newAmoledTheme != null) {
      state.changeAmoledTheme(newAmoledTheme);
    }
    if (newMaterialColor != null) {
      state.changeMarerialTheme(newMaterialColor);
    }
    if (newLocale != null) {
      state.changeLocale(newLocale);
    }
  }

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final themeController = Get.put(ThemeController());
  // Set default `_initialized` and `_error` state to false

  void changeAmoledTheme(bool newAmoledTheme) {
    setState(() {
      amoledTheme = newAmoledTheme;
    });
  }

  void changeMarerialTheme(bool newMaterialColor) {
    setState(() {
      materialColor = newMaterialColor;
    });
  }

  void changeLocale(Locale newLocale) {
    setState(() {
      locale = newLocale;
    });
  }

  @override
  void initState() {
    amoledTheme = settings.amoledTheme;
    materialColor = settings.materialColor;
    locale = Locale(
        settings.language!.substring(0, 2), settings.language!.substring(3));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: DynamicColorBuilder(
        builder: (lightColorScheme, darkColorScheme) {
          final lightMaterialTheme =
              lightTheme(lightColorScheme?.surface, lightColorScheme);
          final darkMaterialTheme =
              darkTheme(darkColorScheme?.surface, darkColorScheme);
          final darkMaterialThemeOled = darkTheme(oledColor, darkColorScheme);

          return GetMaterialApp(
            theme: materialColor
                ? lightColorScheme != null
                    ? lightMaterialTheme
                    : lightTheme(lightColor, colorSchemeLight)
                : lightTheme(lightColor, colorSchemeLight),
            darkTheme: amoledTheme
                ? materialColor
                    ? darkColorScheme != null
                        ? darkMaterialThemeOled
                        : darkTheme(oledColor, colorSchemeDark)
                    : darkTheme(oledColor, colorSchemeDark)
                : materialColor
                    ? darkColorScheme != null
                        ? darkMaterialTheme
                        : darkTheme(darkColor, colorSchemeDark)
                    : darkTheme(darkColor, colorSchemeDark),
            themeMode: themeController.theme,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            translations: Translation(),
            locale: locale,
            fallbackLocale: const Locale('en', 'US'),
            supportedLocales:
                appLanguages.map((e) => e['locale'] as Locale).toList(),
            debugShowCheckedModeBanner: false,
            home: const LauncherScreen(),
            builder: EasyLoading.init(),
          );
        },
      ),
    );
  }
}
