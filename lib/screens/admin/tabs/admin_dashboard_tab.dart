import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/subscription_model.dart';
import '../../../services/subscription_service.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/shared_widgets.dart';

class AdminDashboardTab extends StatelessWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final subService = SubscriptionService();
    final fsService = FirestoreService();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        const Text('ADMINISTRAÇÃO',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.mutedForeground)),
        const SizedBox(height: 2),
        Text('DASHBOARD', style: condensed(fontSize: 30)),
        const SizedBox(height: 18),

        StreamBuilder(
          stream: subService.streamTodas(),
          builder: (context, subSnapshot) {
            if (subSnapshot.hasError) return StreamErrorMessage(erro: subSnapshot.error);
            final assinaturas = subSnapshot.data ?? [];
            final ativas = assinaturas.where((a) => a.status == SubscriptionStatus.ativa).length;
            final receita = assinaturas
                .where((a) => a.status == SubscriptionStatus.ativa)
                .fold<double>(0, (sum, a) => sum + a.valor);
            final cancelados = assinaturas.where((a) => a.status == SubscriptionStatus.cancelada).length;

            return StreamBuilder(
              stream: fsService.streamUsuarios(role: UserRole.instrutor),
              builder: (context, instSnapshot) {
                if (instSnapshot.hasError) return StreamErrorMessage(erro: instSnapshot.error);
                final instrutores = instSnapshot.data ?? [];
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.5,
                  children: [
                    StatCard(label: 'Assinantes', value: '$ativas', icon: Icons.people_outline, accent: true, accentColor: AppColors.adminColor),
                    StatCard(label: 'Receita mensal', value: 'R\$${(receita / 1000).toStringAsFixed(1)}k', icon: Icons.attach_money),
                    StatCard(label: 'Instrutores', value: '${instrutores.length}', icon: Icons.menu_book_outlined),
                    StatCard(label: 'Cancelamentos', value: '$cancelados', icon: Icons.cancel_outlined),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 18),

        StreamBuilder(
          stream: subService.streamTodas(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return StreamErrorMessage(erro: snapshot.error);
            final assinaturas = snapshot.data ?? [];
            final receitaPorMes = _receitaPorMes(assinaturas);
            final variacao = _variacaoPercentual(receitaPorMes);

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('RECEITA RECORRENTE MENSAL (MRR)',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.mutedForeground)),
                      if (variacao != null)
                        Row(
                          children: [
                            Icon(variacao >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                size: 12, color: variacao >= 0 ? AppColors.emerald : AppColors.destructive),
                            const SizedBox(width: 2),
                            Text('${variacao >= 0 ? '+' : ''}${variacao.toStringAsFixed(0)}%',
                                style: TextStyle(
                                    color: variacao >= 0 ? AppColors.emerald : AppColors.destructive,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (assinaturas.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('Sem assinaturas registradas ainda.', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                      ),
                    )
                  else
                    SizedBox(
                      height: 150,
                      child: BarChart(
                        BarChartData(
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, meta) {
                                  final i = v.toInt();
                                  if (i < 0 || i >= _ultimosMeses.length) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(_ultimosMeses[i], style: const TextStyle(color: AppColors.mutedForeground, fontSize: 11)),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: [
                            for (int i = 0; i < receitaPorMes.length; i++)
                              BarChartGroupData(x: i, barRods: [
                                BarChartRodData(
                                  toY: receitaPorMes[i],
                                  color: i == receitaPorMes.length - 1 ? AppColors.adminColor : AppColors.secondary,
                                  width: 18,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ]),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Rótulos dos últimos 6 meses (incluindo o atual), calculados a partir
  /// de hoje — usado tanto para os valores quanto para o eixo do gráfico.
  List<String> get _ultimosMeses {
    final agora = DateTime.now();
    final fmt = DateFormat('MMM', 'pt_BR');
    return List.generate(6, (i) {
      final mes = DateTime(agora.year, agora.month - (5 - i), 1);
      final rotulo = fmt.format(mes);
      return rotulo[0].toUpperCase() + rotulo.substring(1).replaceAll('.', '');
    });
  }

  /// MRR (receita recorrente mensal) real de cada um dos últimos 6 meses:
  /// soma o valor de toda assinatura que já tinha começado até o fim
  /// daquele mês e que não estava cancelada antes do início dele.
  List<double> _receitaPorMes(List<SubscriptionModel> assinaturas) {
    final agora = DateTime.now();
    return List.generate(6, (i) {
      final inicioMes = DateTime(agora.year, agora.month - (5 - i), 1);
      final fimMes = DateTime(inicioMes.year, inicioMes.month + 1, 1);

      double total = 0;
      for (final a in assinaturas) {
        final jaComecou = a.inicio.isBefore(fimMes);
        final aindaValidaNoMes = a.status != SubscriptionStatus.cancelada ||
            (a.canceladaEm != null && a.canceladaEm!.isAfter(inicioMes));
        if (jaComecou && aindaValidaNoMes) {
          total += a.valor;
        }
      }
      return total;
    });
  }

  /// Variação percentual entre o penúltimo e o último mês da série.
  /// Retorna null se não houver base de comparação (ex: mês anterior zerado).
  double? _variacaoPercentual(List<double> serie) {
    if (serie.length < 2) return null;
    final anterior = serie[serie.length - 2];
    final ultimo = serie.last;
    if (anterior == 0) return ultimo > 0 ? 100 : null;
    return ((ultimo - anterior) / anterior) * 100;
  }
}