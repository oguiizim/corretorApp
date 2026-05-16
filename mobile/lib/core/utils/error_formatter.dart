import '../../data/services/api_client.dart';

String readFutureError(Object? error) {
  if (error is ApiException) {
    return error.readableMessage;
  }
  return 'Falha ao carregar dados: $error';
}
