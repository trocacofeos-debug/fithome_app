import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class UserModel {
  final String id;
  final String nome;
  final String email;
  final UserRole role;
  final String? fotoUrl;
  final String? telefone;
  final DateTime createdAt;
  final bool ativo;

  UserModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.role,
    this.fotoUrl,
    this.telefone,
    required this.createdAt,
    this.ativo = true,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      role: UserRoleX.fromString(map['role'] ?? 'aluno'),
      fotoUrl: map['fotoUrl'],
      telefone: map['telefone'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ativo: map['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'role': role.value,
      'fotoUrl': fotoUrl,
      'telefone': telefone,
      'createdAt': Timestamp.fromDate(createdAt),
      'ativo': ativo,
    };
  }

  UserModel copyWith({
    String? nome,
    String? fotoUrl,
    String? telefone,
    bool? ativo,
  }) {
    return UserModel(
      id: id,
      nome: nome ?? this.nome,
      email: email,
      role: role,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      telefone: telefone ?? this.telefone,
      createdAt: createdAt,
      ativo: ativo ?? this.ativo,
    );
  }
}
