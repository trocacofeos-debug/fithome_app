// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/chat_model.dart';
import '../services/firestore_service.dart';
import '../widgets/shared_widgets.dart';

/// Tela de conversa entre um instrutor e um aluno. Funciona igual dos dois
/// lados — só muda quem é "eu" e quem é "a outra pessoa".
class ChatScreen extends StatefulWidget {
  final String instrutorId;
  final String instrutorNome;
  final String alunoId;
  final String alunoNome;
  final String meuId;
  final String meuNome;
  final bool souInstrutor;

  const ChatScreen({
    super.key,
    required this.instrutorId,
    required this.instrutorNome,
    required this.alunoId,
    required this.alunoNome,
    required this.meuId,
    required this.meuNome,
    required this.souInstrutor,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _fsService = FirestoreService();
  final _textoCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _enviando = false;
  bool _pronto = false;
  String? _erroInicializacao;

  String get _chatId => _fsService.idDoChat(widget.instrutorId, widget.alunoId);
  String get _nomeOutraPessoa => widget.souInstrutor ? widget.alunoNome : widget.instrutorNome;
  Color get _corDestaque => widget.souInstrutor ? AppColors.instrutorColor : AppColors.primary;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  /// Garante que o documento do chat existe ANTES de tentar ouvir as
  /// mensagens — numa conversa nova, a regra de segurança da subcoleção
  /// de mensagens confere o dono checando esse documento pai, e se ele
  /// não existir ainda, a leitura seria negada.
  Future<void> _inicializar() async {
    try {
      await _fsService.garantirChatExiste(
        instrutorId: widget.instrutorId,
        instrutorNome: widget.instrutorNome,
        alunoId: widget.alunoId,
        alunoNome: widget.alunoNome,
      );
      await _fsService.marcarChatComoLido(_chatId, souInstrutor: widget.souInstrutor);
      if (mounted) setState(() => _pronto = true);
    } catch (e) {
      if (mounted) setState(() => _erroInicializacao = '$e');
    }
  }

  @override
  void dispose() {
    _textoCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _textoCtrl.text.trim();
    if (texto.isEmpty || _enviando) return;

    setState(() => _enviando = true);
    _textoCtrl.clear();
    try {
      await _fsService.enviarMensagem(
        instrutorId: widget.instrutorId,
        instrutorNome: widget.instrutorNome,
        alunoId: widget.alunoId,
        alunoNome: widget.alunoNome,
        autorId: widget.meuId,
        autorNome: widget.meuNome,
        texto: texto,
      );
      if (_scrollCtrl.hasClients) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: $e'), backgroundColor: AppColors.destructive),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            InitialsAvatar(
              initials: _nomeOutraPessoa.isNotEmpty ? _nomeOutraPessoa.substring(0, 1).toUpperCase() : '?',
              size: 32,
              color: _corDestaque,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(_nomeOutraPessoa, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: !_pronto
          ? Center(
              child: _erroInicializacao != null
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: StreamErrorMessage(erro: _erroInicializacao),
                    )
                  : const CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _fsService.streamMensagens(_chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(padding: const EdgeInsets.all(20), child: StreamErrorMessage(erro: snapshot.error));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                final mensagens = snapshot.data!;
                if (mensagens.isEmpty) {
                  return Center(
                    child: Text('Envie a primeira mensagem para ${_nomeOutraPessoa.split(' ').first}.',
                        style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: mensagens.length,
                  itemBuilder: (context, i) {
                    final msg = mensagens[i];
                    final minha = msg.autorId == widget.meuId;
                    return _BolhaMensagem(mensagem: msg, minha: minha, corDestaque: _corDestaque);
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _textoCtrl,
                        style: const TextStyle(color: AppColors.foreground, fontSize: 14),
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _enviar(),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          hintText: 'Escreva uma mensagem...',
                          hintStyle: TextStyle(color: AppColors.mutedForeground),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(color: _corDestaque, shape: BoxShape.circle),
                    child: IconButton(
                      onPressed: _enviando ? null : _enviar,
                      icon: _enviando
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryForeground))
                          : const Icon(Icons.arrow_upward, color: AppColors.primaryForeground, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BolhaMensagem extends StatelessWidget {
  final ChatMessageModel mensagem;
  final bool minha;
  final Color corDestaque;

  const _BolhaMensagem({required this.mensagem, required this.minha, required this.corDestaque});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: minha ? corDestaque : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(minha ? 16 : 4),
            bottomRight: Radius.circular(minha ? 4 : 16),
          ),
          border: minha ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              mensagem.texto,
              style: TextStyle(color: minha ? AppColors.primaryForeground : AppColors.foreground, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(mensagem.criadoEm),
              style: TextStyle(
                fontSize: 10,
                color: minha ? AppColors.primaryForeground.withOpacity(0.7) : AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}