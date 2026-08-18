// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/subscription_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/subscription_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/payment_service.dart';
import '../../../core/utils/cpf_validator.dart';
import '../../../widgets/shared_widgets.dart';

class StudentSubscriptionTab extends StatefulWidget {
  const StudentSubscriptionTab({super.key});

  @override
  State<StudentSubscriptionTab> createState() => _StudentSubscriptionTabState();
}

class _StudentSubscriptionTabState extends State<StudentSubscriptionTab> {
  final _subService = SubscriptionService();
  final _fsService = FirestoreService();
  final _paymentService = PaymentService();
  bool _processando = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dateFmt = DateFormat('dd/MM/yyyy');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        const SectionTitle('Minha Assinatura'),
        const SizedBox(height: 14),
        StreamBuilder(
          stream: _subService.streamDoAluno(auth.usuario!.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) return StreamErrorMessage(erro: snapshot.error);
            final assinatura = snapshot.data;
            final semAssinaturaAtiva = assinatura == null ||
                assinatura.status == SubscriptionStatus.cancelada ||
                assinatura.status == SubscriptionStatus.expirada;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (assinatura != null) _cardPlanoAtual(assinatura, dateFmt),
                if (assinatura != null && assinatura.cobrancaAutomatica && !semAssinaturaAtiva) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _processando ? null : () => _cancelar(context, assinatura),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.destructive),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Cancelar cobrança automática'),
                  ),
                ],
                if (semAssinaturaAtiva) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Escolha um plano abaixo para assinar. Você poderá pagar por PIX, boleto ou cartão de crédito.',
                    style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  _listaPlanosDisponiveis(context, auth),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        const SectionTitle('Benefícios'),
        const SizedBox(height: 12),
        ...['Treinos ilimitados', 'Acompanhamento do instrutor', 'Relatórios de progresso', 'Suporte prioritário']
            .map((p) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(p, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
      ],
    );
  }

  Widget _cardPlanoAtual(SubscriptionModel assinatura, DateFormat dateFmt) {
    final ativa = assinatura.status == SubscriptionStatus.ativa;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ativa ? AppColors.primary : AppColors.destructive.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: ativa ? null : Border.all(color: AppColors.destructive.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PLANO ATUAL',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2,
                      color: ativa ? AppColors.primaryForeground.withOpacity(0.7) : AppColors.foreground)),
              Icon(ativa ? Icons.check_circle : Icons.warning_amber_rounded,
                  size: 18, color: ativa ? AppColors.primaryForeground : AppColors.destructive),
            ],
          ),
          const SizedBox(height: 4),
          Text(assinatura.planoNome.toUpperCase(),
              style: condensed(fontSize: 32, color: ativa ? AppColors.primaryForeground : AppColors.foreground)),
          Text('R\$ ${assinatura.valor.toStringAsFixed(2)} / mês',
              style: condensed(
                  fontSize: 18,
                  color: ativa ? AppColors.primaryForeground.withOpacity(0.7) : AppColors.mutedForeground)),
          const SizedBox(height: 14),
          Container(height: 1, color: (ativa ? AppColors.primaryForeground : AppColors.foreground).withOpacity(0.15)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Vencimento: ${dateFmt.format(assinatura.proximoVencimento)}',
                  style: TextStyle(
                      fontSize: 11,
                      color: ativa ? AppColors.primaryForeground.withOpacity(0.7) : AppColors.mutedForeground)),
              StatusBadge.status(assinatura.status.label),
            ],
          ),
          if (assinatura.cobrancaAutomatica) ...[
            const SizedBox(height: 6),
            Text('Cobrança automática ativa (PIX/boleto/cartão)',
                style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: ativa ? AppColors.primaryForeground.withOpacity(0.6) : AppColors.mutedForeground)),
          ],
        ],
      ),
    );
  }

  Widget _listaPlanosDisponiveis(BuildContext context, AuthProvider auth) {
    return StreamBuilder(
      stream: _fsService.streamPlanos(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return StreamErrorMessage(erro: snapshot.error);
        final planos = snapshot.data ?? [];
        if (planos.isEmpty) {
          return const Text('Nenhum plano disponível no momento. Fale com a administração.',
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 12));
        }
        return Column(
          children: planos.map((plano) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plano.nome, style: condensed(fontSize: 18)),
                        Text('R\$ ${plano.valor.toStringAsFixed(2)} · ${plano.duracaoDias} dias',
                            style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                        if (plano.descricao != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(plano.descricao!,
                                style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                          ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _processando ? null : () => _assinar(context, auth, plano.id),
                    child: _processando
                        ? const SizedBox(
                            height: 16, width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryForeground))
                        : const Text('ASSINAR'),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _assinar(BuildContext context, AuthProvider auth, String planId) async {
    String? cpf = auth.usuario!.cpf;
    if (cpf == null || cpf.isEmpty) {
      cpf = await _pedirCpf(context);
      if (cpf == null) return; // cancelou o dialog
    }

    setState(() => _processando = true);
    try {
      final url = await _paymentService.criarCheckout(planId: planId, cpf: cpf);
      await _paymentService.abrirCheckout(url);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complete o pagamento na página que abriu. Sua assinatura ativa automaticamente após a confirmação.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.destructive),
        );
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _cancelar(BuildContext context, SubscriptionModel assinatura) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar assinatura?'),
        content: const Text('A cobrança automática será interrompida no Asaas. Você continua com acesso até o fim do período já pago.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.destructive),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar assinatura'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() => _processando = true);
    try {
      await _paymentService.cancelarAssinatura(assinatura.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assinatura cancelada.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.destructive),
        );
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<String?> _pedirCpf(BuildContext context) async {
    final ctrl = TextEditingController();
    String? erro;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Informe seu CPF'),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
              decoration: InputDecoration(hintText: 'Só números', errorText: erro),
              onChanged: (_) {
                if (erro != null) setDialogState(() => erro = null);
              },
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              FilledButton(
                onPressed: () {
                  final mensagemErro = CpfValidator.validar(ctrl.text);
                  if (mensagemErro != null) {
                    setDialogState(() => erro = mensagemErro);
                    return;
                  }
                  Navigator.pop(ctx, ctrl.text);
                },
                child: const Text('Continuar'),
              ),
            ],
          );
        },
      ),
    );
  }
}