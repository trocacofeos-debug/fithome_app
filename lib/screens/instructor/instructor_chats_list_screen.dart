// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/chat_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/shared_widgets.dart';
import '../chat_screen.dart';

class InstructorChatsListScreen extends StatelessWidget {
  final String meuId;
  final String meuNome;

  const InstructorChatsListScreen({super.key, required this.meuId, required this.meuNome});

  @override
  Widget build(BuildContext context) {
    final fsService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: Text('MENSAGENS', style: condensed(fontSize: 18))),
      body: StreamBuilder<List<ChatModel>>(
        stream: fsService.streamChatsDoInstrutor(meuId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(padding: const EdgeInsets.all(20), child: StreamErrorMessage(erro: snapshot.error));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.instrutorColor));
          }
          final chats = snapshot.data!;
          if (chats.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.mutedForeground),
                    SizedBox(height: 12),
                    Text('Nenhuma conversa ainda.', style: TextStyle(color: AppColors.mutedForeground)),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final chat = chats[i];
              final naoLidas = chat.naoLidasInstrutor;
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      instrutorId: chat.instrutorId,
                      instrutorNome: chat.instrutorNome,
                      alunoId: chat.alunoId,
                      alunoNome: chat.alunoNome,
                      meuId: meuId,
                      meuNome: meuNome,
                      souInstrutor: true,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: naoLidas > 0 ? AppColors.instrutorColor.withOpacity(0.4) : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      InitialsAvatar(
                        initials: chat.alunoNome.isNotEmpty ? chat.alunoNome.substring(0, 1).toUpperCase() : '?',
                        color: AppColors.instrutorColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(chat.alunoNome,
                                style: TextStyle(fontWeight: naoLidas > 0 ? FontWeight.bold : FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                              chat.ultimaMensagem ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: naoLidas > 0 ? AppColors.foreground : AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (chat.ultimaMensagemEm != null)
                            Text(DateFormat('HH:mm').format(chat.ultimaMensagemEm!),
                                style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
                          if (naoLidas > 0) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: const BoxDecoration(color: AppColors.instrutorColor, shape: BoxShape.circle),
                              child: Text('$naoLidas', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}