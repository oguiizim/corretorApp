import '../models/user.dart';

User parseUser(Map<String, dynamic> json) {
  return User(
    id: json['id'] as int,
    name: json['nome']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
  );
}
