import 'dart:io';

abstract class AppConstants {
  AppConstants._();
  static final String secretKey =
      Platform.environment["SERCRET_KEY"] ?? 'SERCRET_KEY';

  static const String accessToken = 'accessToken';
  static const String refreshToken = 'refreshToken';
}
