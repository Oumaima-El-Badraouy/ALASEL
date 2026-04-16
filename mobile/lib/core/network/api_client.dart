import 'package:dio/dio.dart';

import '../config/api_config.dart';

class ApiClient {
  ApiClient({String? demoUid}) {
    final uid = demoUid ?? ApiConfig.demoUid;
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['X-Demo-Uid'] = uid;
          handler.next(options);
        },
      ),
    );
  }

  late final Dio _dio;

  Dio get dio => _dio;
}
