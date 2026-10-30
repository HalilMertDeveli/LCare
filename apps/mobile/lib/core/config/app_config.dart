/// Compile-time configuration supplied with `--dart-define`.
///
/// * `API_BASE_URL` — API origin. Defaults to the host loopback as seen from
///   the Android emulator. Release builds must pass an `https://` URL.
/// * `APP_LOCALE` — `tr` (default) or `en`.
class AppConfig {
  const AppConfig({required this.apiBaseUrl, this.localeCode = 'tr'});

  factory AppConfig.fromEnvironment() => AppConfig(
        apiBaseUrl: _trimSlash(const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://10.0.2.2:5080',
        )),
        localeCode: const String.fromEnvironment('APP_LOCALE', defaultValue: 'tr'),
      );

  final String apiBaseUrl;
  final String localeCode;

  String get notificationsHubUrl => '$apiBaseUrl/hubs/notifications';

  static String _trimSlash(String value) =>
      value.endsWith('/') ? value.substring(0, value.length - 1) : value;
}
