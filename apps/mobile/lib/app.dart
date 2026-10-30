import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/network/network_providers.dart';
import 'core/realtime/realtime_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/generated/app_localizations.dart';

/// Disables Riverpod's automatic retry: failed loads surface an error state
/// with an explicit "Tekrar dene" button instead of silently looping.
Duration? noRetry(int retryCount, Object error) => null;

class LedCareApp extends ConsumerStatefulWidget {
  const LedCareApp({super.key});

  @override
  ConsumerState<LedCareApp> createState() => _LedCareAppState();
}

class _LedCareAppState extends ConsumerState<LedCareApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      // Events missed while in background are not replayed: re-fetch.
      onResume: () => ref.read(realtimeControllerProvider.notifier).onAppResumed(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the realtime controller alive for the whole app lifetime without
    // rebuilding the app on every status change.
    ref.listen(realtimeControllerProvider, (_, _) {});
    final router = ref.watch(routerProvider);
    final config = ref.watch(appConfigProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: Locale(config.localeCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      routerConfig: router,
    );
  }
}
