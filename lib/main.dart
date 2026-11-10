import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'core/api/api_client.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/language_cubit.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/create_post/cubit/create_post_cubit.dart';
import 'features/feed/cubit/feed_cubit.dart';
import 'features/media/cubit/media_detail_cubit.dart';
import 'features/profile/cubit/profile_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient().initToken();

  runApp(const CineTrackApp());
}

class CineTrackApp extends StatelessWidget {
  const CineTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
        BlocProvider<LanguageCubit>(create: (_) => LanguageCubit()),
        BlocProvider<AuthCubit>(create: (_) => AuthCubit()..checkAuthStatus()),
        BlocProvider<FeedCubit>(create: (_) => FeedCubit()),
        BlocProvider<ProfileCubit>(create: (_) => ProfileCubit()),
        BlocProvider<CreatePostCubit>(create: (_) => CreatePostCubit()),
        BlocProvider<MediaDetailCubit>(create: (_) => MediaDetailCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<LanguageCubit, Locale>(
            builder: (context, locale) {
              return ShadApp.router(
                title: 'CineTrack',
                debugShowCheckedModeBanner: false,
                theme: ShadThemeData(
                  brightness: Brightness.light,
                  colorScheme: const ShadZincColorScheme.light(
                    primary: AppTheme.primaryColor,
                  ),
                ),
                darkTheme: ShadThemeData(
                  brightness: Brightness.dark,
                  colorScheme: const ShadZincColorScheme.dark(
                    primary: AppTheme.primaryColor,
                  ),
                ),
                themeMode: themeMode,
                locale: locale,
                supportedLocales: const [
                  Locale('tr', 'TR'),
                  Locale('en', 'US'),
                ],
                localizationsDelegates: const [
                  AppLocalizationsDelegate(),
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                routerConfig: AppRouter.router,
              );
            },
          );
        },
      ),
    );
  }
}

