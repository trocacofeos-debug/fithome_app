// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/appointment_model.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/shared_widgets.dart';

const _tiposAgendamento = ['Avaliação física', 'Treino presencial', 'Consultoria', 'Reavaliação'];

class InstructorScheduleTab extends StatefulWidget {
  const InstructorScheduleTab({super.key});

  @override
  State<InstructorScheduleTab> createState() => _InstructorScheduleTabState();
}

class _InstructorScheduleTabState extends State<InstructorScheduleTab> {
  final _fsService = FirestoreService();
  DateTime _diaSelecionado = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final instrutorId = auth.usuario!.id;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.instrutorColor,
        onPressed: () => _abrirNovoAgendamento(context, instrutorId),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionTitle('Agenda — ${_rotuloDia(_diaSelecionado)}'),
              IconButton(
                icon: const Icon(Icons.calendar_month_outlined, color: AppColors.instrutorColor),
                onPressed: () => _escolherData(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _seletorDiasRapidos(),
          const SizedBox(height: 16),
          StreamBuilder<List<AppointmentModel>>(
            stream: _fsService.streamAgendaDoDia(instrutorId: instrutorId, dia: _diaSelecionado),
            builder: (context, snapshot) {
              if (snapshot.hasError) return StreamErrorMessage(erro: snapshot.error);
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.instrutorColor)),
                );
              }
              final agendamentos = snapshot.data!;
              if (agendamentos.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 30),
                  child: Center(
                    child: Text('Nenhum compromisso neste dia.', style: TextStyle(color: AppColors.mutedForeground)),
                  ),
                );
              }
              return Column(
                children: agendamentos.map((ag) => _cardAgendamento(context, ag)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _seletorDiasRapidos() {
    final hoje = DateTime.now();
    final dias = List.generate(7, (i) => DateTime(hoje.year, hoje.month, hoje.day).add(Duration(days: i)));
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = dias[i];
          final selecionado = _mesmoDia(d, _diaSelecionado);
          return InkWell(
            onTap: () => setState(() => _diaSelecionado = d),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 52,
              decoration: BoxDecoration(
                color: selecionado ? AppColors.instrutorColor : AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selecionado ? AppColors.instrutorColor : AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('E', 'pt_BR').format(d).substring(0, 3).toUpperCase(),
                      style: TextStyle(fontSize: 10, color: selecionado ? Colors.white70 : AppColors.mutedForeground)),
                  Text('${d.day}',
                      style: condensed(fontSize: 18, color: selecionado ? Colors.white : AppColors.foreground)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _cardAgendamento(BuildContext context, AppointmentModel ag) {
    final cancelado = ag.status == AppointmentStatus.cancelado;
    final concluido = ag.status == AppointmentStatus.concluido;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Opacity(
        opacity: cancelado ? 0.5 : 1,
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(DateFormat('HH:mm').format(ag.dataHora), style: condensed(fontSize: 16, color: AppColors.instrutorColor)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ag.alunoNome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(ag.tipo, style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                ],
              ),
            ),
            if (concluido)
              const StatusBadge(label: 'Concluído', color: AppColors.emerald)
            else if (cancelado)
              const StatusBadge(label: 'Cancelado', color: AppColors.destructive)
            else
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'concluir') {
                    await _fsService.atualizarStatusAgendamento(ag.id, AppointmentStatus.concluido);
                  } else if (v == 'cancelar') {
                    await _fsService.atualizarStatusAgendamento(ag.id, AppointmentStatus.cancelado);
                  } else if (v == 'excluir') {
                    await _fsService.excluirAgendamento(ag.id);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'concluir', child: Text('Marcar como concluído')),
                  PopupMenuItem(value: 'cancelar', child: Text('Cancelar')),
                  PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.instrutorColor.withOpacity(0.1),
                    border: Border.all(color: AppColors.instrutorColor.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Ver', style: TextStyle(color: AppColors.instrutorColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _escolherData(BuildContext context) async {
    final novaData = await showDatePicker(
      context: context,
      initialDate: _diaSelecionado,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (novaData != null) setState(() => _diaSelecionado = novaData);
  }

  void _abrirNovoAgendamento(BuildContext context, String instrutorId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _NovoAgendamentoSheet(
        instrutorId: instrutorId,
        diaInicial: _diaSelecionado,
        fsService: _fsService,
      ),
    );
  }

  bool _mesmoDia(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String _rotuloDia(DateTime d) {
    final hoje = DateTime.now();
    if (_mesmoDia(d, hoje)) return 'Hoje';
    if (_mesmoDia(d, hoje.add(const Duration(days: 1)))) return 'Amanhã';
    return DateFormat('dd/MM').format(d);
  }
}

class _NovoAgendamentoSheet extends StatefulWidget {
  final String instrutorId;
  final DateTime diaInicial;
  final FirestoreService fsService;

  const _NovoAgendamentoSheet({required this.instrutorId, required this.diaInicial, required this.fsService});

  @override
  State<_NovoAgendamentoSheet> createState() => _NovoAgendamentoSheetState();
}

class _NovoAgendamentoSheetState extends State<_NovoAgendamentoSheet> {
  String? _alunoId;
  String? _alunoNome;
  String _tipo = _tiposAgendamento.first;
  late DateTime _data;
  TimeOfDay _hora = const TimeOfDay(hour: 9, minute: 0);
  int _duracao = 60;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _data = widget.diaInicial;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('NOVO COMPROMISSO', style: condensed(fontSize: 18)),
            const SizedBox(height: 16),
            StreamBuilder<List<UserModel>>(
              stream: widget.fsService.streamUsuarios(role: UserRole.aluno),
              builder: (context, snapshot) {
                if (snapshot.hasError) return StreamErrorMessage(erro: snapshot.error);
                final alunos = snapshot.data ?? [];
                return DropdownButtonFormField<String>(
                  initialValue: _alunoId,
                  decoration: const InputDecoration(labelText: 'Aluno'),
                  items: alunos.map((a) => DropdownMenuItem(value: a.id, child: Text(a.nome))).toList(),
                  onChanged: (v) {
                    final aluno = alunos.firstWhere((a) => a.id == v);
                    setState(() {
                      _alunoId = v;
                      _alunoNome = aluno.nome;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: _tiposAgendamento.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _tipo = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final novaData = await showDatePicker(
                        context: context,
                        initialDate: _data,
                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (novaData != null) setState(() => _data = novaData);
                    },
                    child: Text(DateFormat('dd/MM/yyyy').format(_data)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final novaHora = await showTimePicker(context: context, initialTime: _hora);
                      if (novaHora != null) setState(() => _hora = novaHora);
                    },
                    child: Text(_hora.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _duracao,
              decoration: const InputDecoration(labelText: 'Duração'),
              items: const [
                DropdownMenuItem(value: 30, child: Text('30 minutos')),
                DropdownMenuItem(value: 60, child: Text('1 hora')),
                DropdownMenuItem(value: 90, child: Text('1h30')),
              ],
              onChanged: (v) => setState(() => _duracao = v!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (_alunoId == null || _salvando) ? null : _salvar,
              child: _salvando
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryForeground))
                  : const Text('Agendar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    final dataHora = DateTime(_data.year, _data.month, _data.day, _hora.hour, _hora.minute);
    await widget.fsService.criarAgendamento(AppointmentModel(
      id: '',
      instrutorId: widget.instrutorId,
      alunoId: _alunoId!,
      alunoNome: _alunoNome!,
      tipo: _tipo,
      dataHora: dataHora,
      duracaoMinutos: _duracao,
    ));
    if (mounted) Navigator.pop(context);
  }
}