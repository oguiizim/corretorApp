import '../services/api_client.dart';

ApiException parseApiException(int statusCode, dynamic data) {
  if (data is Map<String, dynamic>) {
    final fields = data['fields'];
    if (fields is Map) {
      final joined = fields.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(' | ');
      if (joined.isNotEmpty) {
        return ApiException(statusCode: statusCode, readableMessage: joined);
      }
    }

    final errorText = data['error']?.toString();
    if (errorText != null && errorText.isNotEmpty) {
      return ApiException(statusCode: statusCode, readableMessage: errorText);
    }
  }

  return ApiException(
    statusCode: statusCode,
    readableMessage: 'Erro HTTP $statusCode',
  );
}
