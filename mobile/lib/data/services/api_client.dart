import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/property.dart';
import '../models/user.dart';
import '../parsers/api_error_parser.dart';
import '../parsers/property_parser.dart';
import '../parsers/user_parser.dart';
import 'session_store.dart';

class ApiClient {
  static const Duration _requestTimeout = Duration(seconds: 8);

  ApiClient(this._sessionStore, {http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final SessionStore _sessionStore;
  final http.Client _http;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _post('/usuarios', {'nome': name, 'email': email, 'senha': password});
  }

  Future<void> login({required String email, required String password}) async {
    final data =
        await _post('/usuarios/login', {'email': email, 'senha': password})
            as Map<String, dynamic>;

    final token = data['token']?.toString();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 500,
        readableMessage: 'A API nao retornou token de acesso.',
      );
    }

    await _sessionStore.saveToken(token);
  }

  Future<User> getCurrentUser() async {
    final data = await _get('/usuarios/me', auth: true) as Map<String, dynamic>;
    return parseUser(data);
  }

  Future<User> updateUser({
    required int id,
    required String name,
    required String email,
    required String password,
  }) async {
    final data =
        await _put('/usuarios/$id', {
              'nome': name,
              'email': email,
              'senha': password,
            }, auth: true)
            as Map<String, dynamic>;

    return parseUser(data);
  }

  Future<List<Property>> listPublicProperties() async {
    return _readPropertyList(await _get('/imoveis/publicos'));
  }

  Future<List<Property>> searchPublicProperties({
    String? title,
    double? priceMax,
  }) async {
    final query = _buildPropertyQuery(title: title, priceMax: priceMax);
    final data =
        await _getUri(
              _buildUri(
                '/imoveis/publicos/buscar',
              ).replace(queryParameters: query.isEmpty ? null : query),
            )
            as List<dynamic>;
    return _readPropertyList(data);
  }

  Future<List<Property>> listMyProperties() async {
    return _readPropertyList(await _get('/imoveis/meus', auth: true));
  }

  Future<List<Property>> searchMyProperties({
    String? title,
    double? priceMax,
  }) async {
    final query = _buildPropertyQuery(title: title, priceMax: priceMax);
    final data =
        await _getUri(
              _buildUri(
                '/imoveis/buscar',
              ).replace(queryParameters: query.isEmpty ? null : query),
              auth: true,
            )
            as List<dynamic>;
    return _readPropertyList(data);
  }

  Future<Property> createProperty({
    required String title,
    required String address,
    required double price,
  }) async {
    final data =
        await _post('/imoveis', {
              'titulo': title,
              'endereco': address,
              'preco': price,
            }, auth: true)
            as Map<String, dynamic>;

    return parseProperty(data);
  }

  Future<Property> updateProperty({
    required int id,
    required String title,
    required String address,
    required double price,
  }) async {
    final data =
        await _put('/imoveis/$id', {
              'titulo': title,
              'endereco': address,
              'preco': price,
            }, auth: true)
            as Map<String, dynamic>;

    return parseProperty(data);
  }

  Future<void> deleteProperty(int id) async {
    await _delete('/imoveis/$id', auth: true);
  }

  Future<dynamic> _get(String path, {bool auth = false}) async {
    return _getUri(_buildUri(path), auth: auth);
  }

  Future<dynamic> _getUri(Uri uri, {bool auth = false}) async {
    final response = await _sendRequest(
      () async => _http.get(uri, headers: await _headers(auth: auth)),
    );
    return _handleResponse(response);
  }

  Future<dynamic> _post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final response = await _sendRequest(
      () async => _http.post(
        _buildUri(path),
        headers: await _headers(auth: auth),
        body: jsonEncode(body),
      ),
    );
    return _handleResponse(response);
  }

  Future<dynamic> _put(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final response = await _sendRequest(
      () async => _http.put(
        _buildUri(path),
        headers: await _headers(auth: auth),
        body: jsonEncode(body),
      ),
    );
    return _handleResponse(response);
  }

  Future<dynamic> _delete(String path, {bool auth = false}) async {
    final response = await _sendRequest(
      () async => _http.delete(
        _buildUri(path),
        headers: await _headers(auth: auth),
      ),
    );
    return _handleResponse(response);
  }

  Future<http.Response> _sendRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(_requestTimeout);
    } on TimeoutException {
      throw const ApiException(
        statusCode: 0,
        readableMessage:
            'Nao foi possivel conectar ao servidor. Tente novamente em instantes.',
      );
    } on http.ClientException {
      throw const ApiException(
        statusCode: 0,
        readableMessage:
            'Nao foi possivel conectar ao servidor. Tente novamente em instantes.',
      );
    }
  }

  Uri _buildUri(String path) {
    final base = _sessionStore.baseUrl;
    final normalizedBase = base.endsWith('/') ? base : '$base/';
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  Future<Map<String, String>> _headers({required bool auth}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (auth) {
      final token = _sessionStore.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  List<Property> _readPropertyList(dynamic data) {
    return (data as List<dynamic>)
        .map((item) => parseProperty(Map<String, dynamic>.from(item)))
        .toList();
  }

  Map<String, String> _buildPropertyQuery({String? title, double? priceMax}) {
    final query = <String, String>{};
    if (title != null && title.isNotEmpty) {
      query['titulo'] = title;
    } else if (priceMax != null) {
      query['precoMax'] = priceMax.toString();
    }
    return query;
  }

  dynamic _handleResponse(http.Response response) {
    final bodyText = response.body.trim();
    final data = bodyText.isEmpty ? null : jsonDecode(bodyText);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw parseApiException(response.statusCode, data);
  }
}

class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.readableMessage});

  final int statusCode;
  final String readableMessage;

  @override
  String toString() => readableMessage;
}
