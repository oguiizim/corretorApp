import '../models/property.dart';
import 'api_client.dart';

class PropertyService {
  const PropertyService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Property>> listPublicProperties() {
    return _apiClient.listPublicProperties();
  }

  Future<List<Property>> searchPublicProperties({
    String? title,
    double? priceMax,
  }) {
    return _apiClient.searchPublicProperties(
      title: title,
      priceMax: priceMax,
    );
  }

  Future<List<Property>> listMyProperties() {
    return _apiClient.listMyProperties();
  }

  Future<List<Property>> searchMyProperties({
    String? title,
    double? priceMax,
  }) {
    return _apiClient.searchMyProperties(title: title, priceMax: priceMax);
  }

  Future<Property> createProperty({
    required String title,
    required String address,
    required double price,
  }) {
    return _apiClient.createProperty(
      title: title,
      address: address,
      price: price,
    );
  }

  Future<Property> updateProperty({
    required int id,
    required String title,
    required String address,
    required double price,
  }) {
    return _apiClient.updateProperty(
      id: id,
      title: title,
      address: address,
      price: price,
    );
  }

  Future<void> deleteProperty(int id) {
    return _apiClient.deleteProperty(id);
  }
}
