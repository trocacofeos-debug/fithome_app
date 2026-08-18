import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/shared_widgets.dart';

class StudentScheduleScreen extends StatelessWidget {
  const StudentScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fsService = FirestoreService();
    final alunoId = context.read<AuthProvider>().usuario!.id;

    return Scaffold(
      appBar: AppBar(title: Text('MINHA AGENDA', style: condensed(fontSize: 18))),
      body: StreamBuilder<List<AppointmentModel>>(
        stream: fsService.streamAgendaDoAluno(alunoId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(padding: const EdgeInsets.all(20), child: StreamErrorMessage(erro: snapshot.error));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final agora = DateTime.now();
          final todos = snapshot.data!;
          final proximos = todos.where((a) => a.dataHora.isAfter(agora) && a.status == AppointmentStatus.agendado).toList()
            ..sort((a, b) => a.dataHora.compareTo(b.dataHora));
          final anteriores = todos.where((a) => !proximos.contains(a)).toList()
            ..sort((a, b) => b.dataHora.compareTo(a.dataHora));

          if (todos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_available_outlined, size: 48, color: AppColors.mutedForeground),
                    SizedBox(height: 12),
                    Text('Nenhum compromisso agendado ainda.', style: TextStyle(color: AppColors.mutedForeground)),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (proximos.isNotEmpty) ...[
                const SectionTitle('Próximos'),
                const SizedBox(height: 10),
                ...proximos.map((a) => _AppointmentCard(agendamento: a)),
                const SizedBox(height: 20),
              ],
              if (anteriores.isNotEmpty) ...[
                const SectionTitle('Histórico'),
                const SizedBox(height: 10),
                ...anteriores.map((a) => _AppointmentCard(agendamento: a)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel agendamento;

  const _AppointmentCard({required this.agendamento});

  @override
  Widget build(BuildContext context) {
    final cancelado = agendamento.status == AppointmentStatus.cancelado;
    final concluido = agendamento.status == AppointmentStatus.concluido;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Opacity(
        opacity: cancelado ? 0.5 : 1,
        child: Row(
          children: [
            Column(
              children: [
                Text(DateFormat('dd').format(agendamento.dataHora), style: condensed(fontSize: 22, color: AppColors.primary)),
                Text(DateFormat('MMM', 'pt_BR').format(agendamento.dataHora).toUpperCase(),
                    style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(width: 14),
            Container(width: 1, height: 36, color: AppColors.border),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(agendamento.tipo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('${DateFormat('HH:mm').format(agendamento.dataHora)} · ${agendamento.duracaoMinutos} min',
                      style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                ],
              ),
            ),
            if (concluido)
              const StatusBadge(label: 'Concluído', color: AppColors.emerald)
            else if (cancelado)
              const StatusBadge(label: 'Cancelado', color: AppColors.destructive)
            else
              const StatusBadge(label: 'Agendado', color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}