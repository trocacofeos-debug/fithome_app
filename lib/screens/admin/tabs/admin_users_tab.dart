// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/user_model.dart';
import '../../../models/subscription_model.dart';
import '../../../services/firestore_service.dart';
import '../../../services/subscription_service.dart';
import '../../../services/payment_service.dart';
import '../../../widgets/shared_widgets.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _fsService = FirestoreService();
  final _subService = SubscriptionService();
  final _paymentService = PaymentService();
  String _busca = '';
  UserRole? _filtroRole;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        const SectionTitle('Usuários'),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            style: const TextStyle(color: AppColors.foreground, fontSize: 14),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Buscar usuário...',
              hintStyle: TextStyle(color: AppColors.mutedForeground),
              prefixIcon: Icon(Icons.search, size: 18, color: AppColors.mutedForeground),
            ),
            onChanged: (v) => setState(() => _busca = v.toLowerCase()),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _chipRole(null, 'Todos'),
              _chipRole(UserRole.aluno, 'Alunos'),
              _chipRole(UserRole.instrutor, 'Instrutores'),
              _chipRole(UserRole.admin, 'Admins'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        StreamBuilder(
          stream: _fsService.streamUsuarios(role: _filtroRole),
          builder: (context, snapshot) {
            if (snapshot.hasError) return StreamErrorMessage(erro: snapshot.error);
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator(color: AppColors.adminColor)),
              );
            }
            final usuarios = snapshot.data!.where((u) => u.nome.toLowerCase().contains(_busca)).toList();
            if (usuarios.isEmpty) {
              return const Text('Nenhum usuário encontrado.', style: TextStyle(color: AppColors.mutedForeground));
            }
            return Column(
              children: usuarios.map((u) => _UserRow(
                    usuario: u,
                    subService: _subService,
                    fsService: _fsService,
                    paymentService: _paymentService,
                  )).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _chipRole(UserRole? role, String label) {
    final selecionado = _filtroRole == role;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selecionado,
        onSelected: (_) => setState(() => _filtroRole = role),
        selectedColor: AppColors.adminColor.withOpacity(0.25),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final UserModel usuario;
  final SubscriptionService subService;
  final FirestoreService fsService;
  final PaymentService paymentService;

  const _UserRow({
    required this.usuario,
    required this.subService,
    required this.fsService,
    required this.paymentService,
  });

  @override
  Widget build(BuildContext context) {
    final bloqueado = !usuario.ativo;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bloqueado ? AppColors.destructive.withOpacity(0.4) : AppColors.border),
      ),
      child: Row(
        children: [
          InitialsAvatar(
            initials: usuario.nome.isNotEmpty ? usuario.nome.substring(0, 1).toUpperCase() : '?',
            size: 34,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(usuario.nome,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    if (bloqueado) ...[
                      const SizedBox(width: 6),
                      const StatusBadge(label: 'Bloqueado', color: AppColors.destructive),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (usuario.role == UserRole.aluno)
                      StreamBuilder(
                        stream: subService.streamDoAluno(usuario.id),
                        builder: (context, snap) {
                          if (snap.hasError) return const StatusBadge(label: 'Erro', color: AppColors.destructive);
                          final assinatura = snap.data;
                          if (assinatura == null) return const StatusBadge(label: 'Sem plano', color: AppColors.mutedForeground);
                          return StatusBadge.status(assinatura.status.label);
                        },
                      )
                    else
                      StatusBadge(label: usuario.role.label, color: AppColors.porRole(usuario.role)),
                    Text(usuario.email, style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _abrirDetalhes(context),
            icon: const Icon(Icons.settings_outlined, size: 18, color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }

  void _abrirDetalhes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _UserDetailSheet(
        usuario: usuario,
        subService: subService,
        fsService: fsService,
        paymentService: paymentService,
      ),
    );
  }
}

class _UserDetailSheet extends StatefulWidget {
  final UserModel usuario;
  final SubscriptionService subService;
  final FirestoreService fsService;
  final PaymentService paymentService;

  const _UserDetailSheet({
    required this.usuario,
    required this.subService,
    required this.fsService,
    required this.paymentService,
  });

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  late UserRole _role;
  late bool _ativo;

  @override
  void initState() {
    super.initState();
    _role = widget.usuario.role;
    _ativo = widget.usuario.ativo;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                InitialsAvatar(initials: widget.usuario.nome.substring(0, 1).toUpperCase(), size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.usuario.nome, style: condensed(fontSize: 20)),
                      Text(widget.usuario.email, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('PAPEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.mutedForeground)),
            const SizedBox(height: 6),
            DropdownButtonFormField<UserRole>(
              initialValue: _role,
              dropdownColor: AppColors.card,
              items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.label))).toList(),
              onChanged: (r) async {
                if (r == null) return;
                setState(() => _role = r);
                await widget.fsService.atualizarRole(widget.usuario.id, r);
              },
            ),
            const SizedBox(height: 20),

            // ---- Bloqueio de acesso: agora derruba a sessão de verdade ----
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _ativo ? AppColors.secondary : AppColors.destructive.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _ativo ? Colors.transparent : AppColors.destructive.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(_ativo ? Icons.lock_open_outlined : Icons.lock_outline,
                      size: 18, color: _ativo ? AppColors.mutedForeground : AppColors.destructive),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_ativo ? 'Acesso liberado' : 'Acesso bloqueado',
                            style: TextStyle(fontWeight: FontWeight.w700, color: _ativo ? AppColors.foreground : AppColors.destructive)),
                        Text(
                          _ativo
                              ? 'A pessoa consegue entrar normalmente.'
                              : 'A pessoa é desconectada agora e não consegue mais entrar.',
                          style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _ativo,
                    onChanged: (v) async {
                      setState(() => _ativo = v);
                      await widget.fsService.ativarDesativarUsuario(widget.usuario.id, v);
                    },
                  ),
                ],
              ),
            ),

            if (_role == UserRole.aluno) ...[
              const SizedBox(height: 20),
              const Text('ASSINATURA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.mutedForeground)),
              const SizedBox(height: 10),
              StreamBuilder(
                stream: widget.subService.streamDoAluno(widget.usuario.id),
                builder: (context, snap) {
                  if (snap.hasError) return StreamErrorMessage(erro: snap.error);
                  final assinatura = snap.data;
                  if (assinatura == null) {
                    return ElevatedButton.icon(
                      onPressed: () => _atribuirPlano(context),
                      icon: const Icon(Icons.add_card_outlined),
                      label: const Text('Ativar plano para esse aluno'),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(assinatura.planoNome, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('R\$ ${assinatura.valor.toStringAsFixed(2)}/mês',
                                      style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                                ],
                              ),
                            ),
                            StatusBadge.status(assinatura.status.label),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (assinatura.cobrancaAutomatica) ...[
                        const Text('Cobrança automática ativa — renovação é feita pelo Asaas.',
                            style: TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.destructive),
                            onPressed: () async {
                              try {
                                await widget.paymentService.cancelarAssinatura(assinatura.id);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$e'), backgroundColor: AppColors.destructive),
                                  );
                                }
                              }
                            },
                            child: const Text('Cancelar no Asaas'),
                          ),
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => widget.subService.renovar(assinatura.id, diasAdicionais: 30),
                                child: const Text('Renovar +30d'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.destructive),
                                onPressed: () => widget.subService.cancelar(assinatura.id),
                                child: const Text('Cancelar'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _atribuirPlano(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StreamBuilder(
        stream: widget.fsService.streamPlanos(),
        builder: (context, snap) {
          if (snap.hasError) {
            return SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: StreamErrorMessage(erro: snap.error)));
          }
          final planos = snap.data ?? [];
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('ESCOLHER PLANO', style: condensed(fontSize: 18)),
                  const SizedBox(height: 12),
                  if (planos.isEmpty) const Text('Cadastre um plano na aba Planos primeiro.'),
                  ...planos.map((p) => ListTile(
                        title: Text(p.nome),
                        subtitle: Text('R\$ ${p.valor.toStringAsFixed(2)} · ${p.duracaoDias} dias'),
                        onTap: () async {
                          final agora = DateTime.now();
                          await widget.subService.criarAssinatura(SubscriptionModel(
                            id: '',
                            alunoId: widget.usuario.id,
                            alunoNome: widget.usuario.nome,
                            planoId: p.id,
                            planoNome: p.nome,
                            valor: p.valor,
                            status: SubscriptionStatus.ativa,
                            inicio: agora,
                            proximoVencimento: agora.add(Duration(days: p.duracaoDias)),
                          ));
                          if (context.mounted) Navigator.pop(context);
                        },
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}