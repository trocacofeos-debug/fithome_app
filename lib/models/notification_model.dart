import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String titulo;
  final String mensagem;
  final String tipo; // 'treino_individual', 'role_alterado', 'agendamento', 'assinatura', 'geral'
  final bool lida;
  final DateTime createdAt;
  final String? rota; // rota do go_router pra abrir ao tocar (opcional)

  NotificationModel({
    required this.id,
    required this.userId,
    required this.titulo,
    required this.mensagem,
    this.tipo = 'geral',
    this.lida = false,
    required this.createdAt,
    this.rota,
  });

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      titulo: map['titulo'] ?? '',
      mensagem: map['mensagem'] ?? '',
      tipo: map['tipo'] ?? 'geral',
      lida: map['lida'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rota: map['rota'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'titulo': titulo,
      'mensagem': mensagem,
      'tipo': tipo,
      'lida': lida,
      'createdAt': Timestamp.fromDate(createdAt),
      'rota': rota,
    };
  }
}