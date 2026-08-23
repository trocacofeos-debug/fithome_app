import 'package:cloud_firestore/cloud_firestore.dart';

/// Uma conversa entre um instrutor e um aluno específico. O ID do
/// documento é sempre "{instrutorId}_{alunoId}" — assim nunca existe mais
/// de uma conversa entre a mesma dupla, e dá pra achar/criar o chat sem
/// precisar de uma consulta extra.
class ChatModel {
  final String id;
  final String instrutorId;
  final String instrutorNome;
  final String alunoId;
  final String alunoNome;
  final String? ultimaMensagem;
  final DateTime? ultimaMensagemEm;
  final String? ultimaMensagemAutorId;
  final int naoLidasInstrutor;
  final int naoLidasAluno;

  ChatModel({
    required this.id,
    required this.instrutorId,
    required this.instrutorNome,
    required this.alunoId,
    required this.alunoNome,
    this.ultimaMensagem,
    this.ultimaMensagemEm,
    this.ultimaMensagemAutorId,
    this.naoLidasInstrutor = 0,
    this.naoLidasAluno = 0,
  });

  factory ChatModel.fromMap(String id, Map<String, dynamic> map) {
    return ChatModel(
      id: id,
      instrutorId: map['instrutorId'] ?? '',
      instrutorNome: map['instrutorNome'] ?? '',
      alunoId: map['alunoId'] ?? '',
      alunoNome: map['alunoNome'] ?? '',
      ultimaMensagem: map['ultimaMensagem'],
      ultimaMensagemEm: (map['ultimaMensagemEm'] as Timestamp?)?.toDate(),
      ultimaMensagemAutorId: map['ultimaMensagemAutorId'],
      naoLidasInstrutor: map['naoLidasInstrutor'] ?? 0,
      naoLidasAluno: map['naoLidasAluno'] ?? 0,
    );
  }
}

class ChatMessageModel {
  final String id;
  final String autorId;
  final String autorNome;
  final String texto;
  final DateTime criadoEm;

  ChatMessageModel({
    required this.id,
    required this.autorId,
    required this.autorNome,
    required this.texto,
    required this.criadoEm,
  });

  factory ChatMessageModel.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessageModel(
      id: id,
      autorId: map['autorId'] ?? '',
      autorNome: map['autorNome'] ?? '',
      texto: map['texto'] ?? '',
      criadoEm: (map['criadoEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}