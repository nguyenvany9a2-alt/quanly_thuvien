import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class Api extends ChangeNotifier {
  final String baseUrl;
  final http.Client client;
  final FlutterSecureStorage storage;
  String? token;
  Map<String, dynamic>? user;
  Api({String? url, http.Client? client, FlutterSecureStorage? storage})
    : baseUrl =
          url ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://10.0.2.2:8000',
          ),
      client = client ?? http.Client(),
      storage = storage ?? const FlutterSecureStorage();
  bool get isStaff => user?['role'] != 'reader';
  bool get isManager => user?['role'] == 'manager';
  Future<dynamic> call(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? data,
  }) async {
    try {
      final req = http.Request(method, Uri.parse('$baseUrl$path'));
      req.headers.addAll({
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (data != null) req.body = jsonEncode(data);
      final res = await http.Response.fromStream(
        await client.send(req).timeout(const Duration(seconds: 15)),
      ).timeout(const Duration(seconds: 15));
      final value = res.body.isEmpty
          ? null
          : jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode >= 400) {
        if (res.statusCode == 401 && path != '/auth/login') {
          token = null;
          user = null;
          await storage.delete(key: 'mot_token');
          notifyListeners();
        }
        final detail = value is Map ? value['detail'] : null;
        throw ApiError(
          detail is String
              ? detail
              : 'Dữ liệu chưa hợp lệ. Hãy kiểm tra các trường bắt buộc.',
        );
      }
      return value;
    } on ApiError {
      rethrow;
    } on TimeoutException {
      throw ApiError(
        'Kết nối chậm. Thử tải lại; kiểm tra danh sách trước khi gửi lại thao tác.',
      );
    } catch (_) {
      throw ApiError(
        'Chưa kết nối được máy chủ MỌT. Hãy kiểm tra kết nối và máy chủ.',
      );
    }
  }

  Future<void> restore() async {
    token = await storage.read(key: 'mot_token');
    if (token != null) {
      try {
        user = Map<String, dynamic>.from(await call('/me'));
      } catch (_) {
        token = null;
      }
    }
  }

  Future<void> login(String email, String password, bool remember) async {
    final r = await call(
      '/auth/login',
      method: 'POST',
      data: {'email': email, 'password': password, 'remember': remember},
    );
    token = r['token'];
    user = Map<String, dynamic>.from(r['user']);
    try {
      if (remember) {
        await storage.write(key: 'mot_token', value: token);
      } else {
        await storage.delete(key: 'mot_token');
      }
    } catch (_) {
      notifyListeners();
      throw ApiError('Đã đăng nhập nhưng không lưu được phiên trên thiết bị.');
    }
    notifyListeners();
  }

  Future<void> refreshUser() async {
    user = Map<String, dynamic>.from(await call('/me'));
    notifyListeners();
  }

  Future<void> logout() async {
    await call('/auth/logout', method: 'POST');
    token = null;
    user = null;
    await storage.delete(key: 'mot_token');
    notifyListeners();
  }

  @override
  void dispose() {
    client.close();
    super.dispose();
  }
}

class ApiError implements Exception {
  final String message;
  ApiError(this.message);
  @override
  String toString() => message;
}
