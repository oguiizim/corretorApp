import '../models/property.dart';

Property parseProperty(Map<String, dynamic> json) {
  return Property(
    id: json['id'] as int,
    title: json['titulo']?.toString() ?? '',
    address: json['endereco']?.toString() ?? '',
    price: (json['preco'] as num?)?.toDouble() ?? 0,
  );
}
