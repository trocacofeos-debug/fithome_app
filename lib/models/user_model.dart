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

  /// CPF (só números). Exigido pelo Asaas para criar o cliente e emitir
  /// cobranças — sem isso, o checkout de assinatura não funciona.
  final String? cpf;

  /// uid do instrutor que indicou este usuário no cadastro (sistema de
  /// indicação/comissão). Nulo se não veio de nenhuma indicação. É
  /// definido só na criação da conta e travado pelas regras do Firestore
  /// depois disso — não faz parte do `copyWith`.
  final String? indicadoPor;

  UserModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.role,
    this.fotoUrl,
    this.telefone,
    required this.createdAt,
    this.ativo = true,
    this.cpf,
    this.indicadoPor,
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
      cpf: map['cpf'],
      indicadoPor: map['indicadoPor'],
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
      'cpf': cpf,
      'indicadoPor': indicadoPor,
    };
  }

  UserModel copyWith({
    String? nome,
    String? fotoUrl,
    String? telefone,
    bool? ativo,
    String? cpf,
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
      cpf: cpf ?? this.cpf,
    );
  }
}