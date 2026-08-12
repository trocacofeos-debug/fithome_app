// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../models/workout_progress_model.dart';
import '../../../widgets/shared_widgets.dart';

class StudentProgressTab extends StatelessWidget {
  const StudentProgressTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fsService = FirestoreService();
    final alunoId = auth.usuario!.id;

    return StreamBuilder<List<WorkoutProgressModel>>(
      stream: fsService.streamProgressoDoAluno(alunoId),
      builder: (context, snapshot) {
        final historico = snapshot.data ?? [];
        final agora = DateTime.now();
        final esteMs = historico.where((p) => p.concluidoEm.year == agora.year && p.concluidoEm.month == agora.month).length;
        final minutosPorSemana = _agruparPorSemana(historico);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            const SectionTitle('Meu Progresso'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: StatCard(label: 'Treinos concluídos', value: '${historico.length}', icon: Icons.check_circle_outline)),
                const SizedBox(width: 10),
                Expanded(child: StatCard(label: 'Este mês', value: '$esteMs', icon: Icons.local_fire_department, accent: true)),
              ],
            ),
            const SizedBox(height: 16),
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
                  const Text('MINUTOS DE TREINO (ÚLTIMAS 6 SEMANAS)',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.mutedForeground)),
                  const SizedBox(height: 12),
                  if (historico.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Text('Conclua um treino para começar a ver seu progresso aqui.',
                            textAlign: TextAlign.center, style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                      ),
                    )
                  else
                    SizedBox(
                      height: 150,
                      child: LineChart(
                        LineChartData(
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
                                  if (i < 0 || i >= minutosPorSemana.length) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text('S${i + 1}', style: const TextStyle(color: AppColors.mutedForeground, fontSize: 11)),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [for (int i = 0; i < minutosPorSemana.length; i++) FlSpot(i.toDouble(), minutosPorSemana[i])],
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 2.5,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.08)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionTitle('Conquistas'),
            const SizedBox(height: 12),
            ..._conquistas(historico.length).map((a) {
              final feito = a['feito'] as bool;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: feito ? AppColors.primary.withOpacity(0.1) : AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: feito ? AppColors.primary.withOpacity(0.2) : AppColors.border),
                ),
                child: Opacity(
                  opacity: feito ? 1 : 0.5,
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, size: 18, color: feito ? AppColors.primary : AppColors.mutedForeground),
                      const SizedBox(width: 10),
                      Expanded(child: Text(a['nome'] as String, style: const TextStyle(fontWeight: FontWeight.w600))),
                      if (feito) const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  /// Soma os minutos de treino concluídos em cada uma das últimas 6 semanas
  /// (a partir de hoje), com base no histórico real do Firestore.
  List<double> _agruparPorSemana(List<WorkoutProgressModel> historico) {
    final agora = DateTime.now();
    final inicioSemana0 = agora.subtract(Duration(days: agora.weekday - 1)); // segunda-feira desta semana
    final somas = List<double>.filled(6, 0);

    for (final p in historico) {
      final diffDias = inicioSemana0.difference(p.concluidoEm).inDays;
      final indiceSemana = 5 - (diffDias / 7).floor();
      if (indiceSemana >= 0 && indiceSemana < 6) {
        somas[indiceSemana] += p.duracaoMinutos;
      }
    }
    return somas;
  }

  List<Map<String, Object>> _conquistas(int totalConcluido) {
    return [
      {'nome': 'Primeiro Treino', 'feito': totalConcluido >= 1},
      {'nome': '10 Treinos Concluídos', 'feito': totalConcluido >= 10},
      {'nome': '30 Treinos Concluídos', 'feito': totalConcluido >= 30},
      {'nome': '100 Treinos Concluídos', 'feito': totalConcluido >= 100},
    ];
  }
}