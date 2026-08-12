import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
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
            final assinaturas = subSnapshot.data ?? [];
            final ativas = assinaturas.where((a) => a.status == SubscriptionStatus.ativa).length;
            final receita = assinaturas
                .where((a) => a.status == SubscriptionStatus.ativa)
                .fold<double>(0, (sum, a) => sum + a.valor);
            final cancelados = assinaturas.where((a) => a.status == SubscriptionStatus.cancelada).length;

            return StreamBuilder(
              stream: fsService.streamUsuarios(role: UserRole.instrutor),
              builder: (context, instSnapshot) {
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

        // Receita mensal (dados de exemplo até existir agregação histórica real)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('RECEITA MENSAL',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.mutedForeground)),
                  Row(
                    children: [
                      Icon(Icons.arrow_upward, size: 12, color: AppColors.emerald),
                      SizedBox(width: 2),
                      Text('+12%', style: TextStyle(color: AppColors.emerald, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
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
                            const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun'];
                            final i = v.toInt();
                            if (i < 0 || i >= meses.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(meses[i], style: const TextStyle(color: AppColors.mutedForeground, fontSize: 11)),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (int i = 0; i < 6; i++)
                        BarChartGroupData(x: i, barRods: [
                          BarChartRodData(
                            toY: [18.4, 21.2, 19.8, 24.5, 27.1, 31.2][i],
                            color: i == 5 ? AppColors.adminColor : AppColors.secondary,
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
        ),
      ],
    );
  }
}
