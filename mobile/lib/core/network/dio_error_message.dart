import 'package:dio/dio.dart';

import '../l10n/strings.dart';

/// Message lisible pour SnackBar (connexion / inscription).
String friendlyDioError(Object e) {
  if (e is DioException) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return S.errApiTimeout;
      case DioExceptionType.connectionError:
        return S.errApiUnreachable;
      default:
        break;
    }
    final msg = e.message ?? '';
    if (msg.contains('timed out') || msg.contains('Timeout')) {
      return S.errApiTimeout;
    }
  }
  final s = e.toString();
  if (s.contains('Connection refused') ||
      s.contains('SocketException') ||
      s.contains('connection error') ||
      s.contains('Failed host lookup') ||
      s.contains('Network is unreachable')) {
    return S.errApiUnreachable;
  }
  return s;
}
