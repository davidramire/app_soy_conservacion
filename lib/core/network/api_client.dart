import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../storage/secure_token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required this.config,
    required this.tokenStorage,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final AppConfig config;
  final SecureTokenStorage tokenStorage;
  final http.Client _client;

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final baseUri = config.apiBaseUri;
    return baseUri.resolve(normalizedPath).replace(queryParameters: queryParameters);
  }

  Future<Map<String, String>> _buildHeaders({
    Map<String, String>? extraHeaders,
    bool includeAuthorization = true,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...?extraHeaders,
    };

    if (includeAuthorization) {
      final accessToken = await tokenStorage.readAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    return headers;
  }

  Future<dynamic> getJson(
    String path, {
    Map<String, String>? queryParameters,
    bool includeAuthorization = true,
    Map<String, String>? headers,
  }) async {
    return _send(
      'GET',
      path,
      queryParameters: queryParameters,
      includeAuthorization: includeAuthorization,
      headers: headers,
    );
  }

  Future<dynamic> postJson(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    bool includeAuthorization = true,
    Map<String, String>? headers,
  }) async {
    return _send(
      'POST',
      path,
      queryParameters: queryParameters,
      includeAuthorization: includeAuthorization,
      headers: headers,
      body: body,
    );
  }

  Future<dynamic> putJson(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    bool includeAuthorization = true,
    Map<String, String>? headers,
  }) async {
    return _send(
      'PUT',
      path,
      queryParameters: queryParameters,
      includeAuthorization: includeAuthorization,
      headers: headers,
      body: body,
    );
  }

  Future<dynamic> deleteJson(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    bool includeAuthorization = true,
    Map<String, String>? headers,
  }) async {
    return _send(
      'DELETE',
      path,
      queryParameters: queryParameters,
      includeAuthorization: includeAuthorization,
      headers: headers,
      body: body,
    );
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    bool includeAuthorization = true,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final requestHeaders = await _buildHeaders(
      extraHeaders: headers,
      includeAuthorization: includeAuthorization,
    );

    try {
      final response = switch (method) {
        'GET' => await _client.get(uri, headers: requestHeaders).timeout(config.requestTimeout),
        'POST' => await _client.post(
            uri,
            headers: requestHeaders,
            body: body == null ? null : jsonEncode(body),
          ).timeout(config.requestTimeout),
        'PUT' => await _client.put(
            uri,
            headers: requestHeaders,
            body: body == null ? null : jsonEncode(body),
          ).timeout(config.requestTimeout),
        'DELETE' => await _client.delete(
            uri,
            headers: requestHeaders,
            body: body == null ? null : jsonEncode(body),
          ).timeout(config.requestTimeout),
        _ => throw ApiException.unexpected(uri: uri, details: 'HTTP method not supported: $method'),
      };

      final responseBody = utf8.decode(response.bodyBytes);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _throwForStatus(uri, response.statusCode, responseBody);
      }

      if (responseBody.trim().isEmpty) {
        return null;
      }

      try {
        return jsonDecode(responseBody);
      } on FormatException catch (error) {
        throw ApiException.invalidResponse(uri: uri, details: error);
      }
    } on SocketException catch (error) {
      throw ApiException.network(uri: uri, details: error);
    } on TimeoutException catch (error) {
      throw ApiException.timeout(uri: uri, details: error);
    }
  }

  Never _throwForStatus(Uri uri, int statusCode, String body) {
    if (statusCode == HttpStatus.unauthorized) {
      throw ApiException.unauthorized(uri: uri, details: body);
    }
    if (statusCode == HttpStatus.forbidden) {
      throw ApiException.forbidden(uri: uri, details: body);
    }
    if (statusCode == HttpStatus.notFound) {
      throw ApiException.notFound(uri: uri, details: body);
    }
    if (statusCode >= 500) {
      throw ApiException.server(statusCode: statusCode, uri: uri, details: body);
    }

    throw ApiException.unexpected(uri: uri, details: body);
  }
}