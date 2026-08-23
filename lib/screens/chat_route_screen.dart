import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../models/chat_model.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/shared_widgets.dart';
import 'chat_screen.dart';

/// Ponte entre uma rota simples (`/chat/:chatId`, usada por notificações)
/// e a `ChatScreen` de verdade, que precisa saber vários dados (quem é
/// instrutor, quem é aluno, quem sou "eu" na conversa). Busca o chat pelo
/// ID, descobre automaticamente qual lado da conversa é o usuário logado,
/// e já entrega a tela pronta.
class ChatRouteScreen extends StatelessWidget {
  final String chatId;

  const ChatRouteScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    final fsService = FirestoreService();
    final meuId = context.watch<AuthProvider>().usuario!.id;
    final meuNome = context.watch<AuthProvider>().usuario!.nome;

    return StreamBuilder<ChatModel?>(
      stream: fsService.streamChat(chatId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Conversa')),
            body: Padding(padding: const EdgeInsets.all(20), child: StreamErrorMessage(erro: snapshot.error)),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
        }
        final chat = snapshot.data;
        if (chat == null) {
          return const Scaffold(
            body: Center(child: Text('Conversa não encontrada.', style: TextStyle(color: AppColors.mutedForeground))),
          );
        }

        return ChatScreen(
          instrutorId: chat.instrutorId,
          instrutorNome: chat.instrutorNome,
          alunoId: chat.alunoId,
          alunoNome: chat.alunoNome,
          meuId: meuId,
          meuNome: meuNome,
          souInstrutor: meuId == chat.instrutorId,
        );
      },
    );
  }
}