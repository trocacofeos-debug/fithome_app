import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/user_model.dart';
import '../../../models/subscription_model.dart';
import '../../../services/firestore_service.dart';
import '../../../services/subscription_service.dart';
import '../../../widgets/shared_widgets.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _fsService = FirestoreService();
  final _subService = SubscriptionService();
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
        selectedColor: AppColors.adminColor.withValues(alpha: 0.25),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final UserModel usuario;
  final SubscriptionService subService;
  final FirestoreService fsService;

  const _UserRow({required this.usuario, required this.subService, required this.fsService});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          InitialsAvatar(initials: usuario.nome.isNotEmpty ? usuario.nome.substring(0, 1).toUpperCase() : '?', size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(usuario.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
          Row(
            children: [
              IconButton(
                onPressed: () => _abrirDetalhes(context),
                icon: const Icon(Icons.settings_outlined, size: 18, color: AppColors.mutedForeground),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _abrirDetalhes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _UserDetailSheet(usuario: usuario, subService: subService, fsService: fsService),
    );
  }
}

class _UserDetailSheet extends StatefulWidget {
  final UserModel usuario;
  final SubscriptionService subService;
  final FirestoreService fsService;

  const _UserDetailSheet({required this.usuario, required this.subService, required this.fsService});

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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Expanded(child: Text('Conta ativa', style: TextStyle(fontWeight: FontWeight.w600))),
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
                final assinatura = snap.data;
                if (assinatura == null) {
                  return ElevatedButton(
                    onPressed: () => _atribuirPlano(context),
                    child: const Text('Atribuir plano'),
                  );
                }
                return Row(
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
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _atribuirPlano(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StreamBuilder(
        stream: widget.fsService.streamPlanos(),
        builder: (context, snap) {
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
