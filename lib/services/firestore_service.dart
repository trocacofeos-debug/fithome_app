import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/workout_model.dart';
import '../models/subscription_model.dart';
import '../models/workout_progress_model.dart';
import '../models/appointment_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- USUÁRIOS ----------

  Stream<List<UserModel>> streamUsuarios({UserRole? role}) {
    Query<Map<String, dynamic>> query = _db.collection(FirestoreCollections.users);
    if (role != null) {
      query = query.where('role', isEqualTo: role.value);
    }
    return query.snapshots().map(
          (snap) => snap.docs.map((d) => UserModel.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> atualizarRole(String uid, UserRole novaRole) {
    return _db.collection(FirestoreCollections.users).doc(uid).update({
      'role': novaRole.value,
    });
  }

  Future<void> ativarDesativarUsuario(String uid, bool ativo) {
    return _db.collection(FirestoreCollections.users).doc(uid).update({'ativo': ativo});
  }

  // ---------- TREINOS ----------

  Future<String> criarTreino(WorkoutModel treino) async {
    final doc = await _db.collection(FirestoreCollections.workouts).add(treino.toMap());
    return doc.id;
  }

  Future<void> atualizarTreino(String id, Map<String, dynamic> dados) {
    return _db.collection(FirestoreCollections.workouts).doc(id).update(dados);
  }

  Future<void> excluirTreino(String id) {
    return _db.collection(FirestoreCollections.workouts).doc(id).delete();
  }

  Stream<List<WorkoutModel>> streamTreinos({
    String? instrutorId,
    bool apenasPublicados = false,
    String? paraAlunoId,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(FirestoreCollections.workouts);
    if (instrutorId != null) {
      query = query.where('instrutorId', isEqualTo: instrutorId);
    }
    if (apenasPublicados) {
      query = query.where('publicado', isEqualTo: true);
    }
    return query.orderBy('createdAt', descending: true).snapshots().map((snap) {
      var treinos = snap.docs.map((d) => WorkoutModel.fromMap(d.id, d.data())).toList();
      // Do lado do aluno (paraAlunoId informado): mostra os treinos gerais
      // (sem alunoId) + os treinos individuais criados especificamente
      // para ele. Do lado do instrutor/admin (paraAlunoId nulo), mostra tudo.
      if (paraAlunoId != null) {
        treinos = treinos.where((t) => t.alunoId == null || t.alunoId == paraAlunoId).toList();
      }
      return treinos;
    });
  }

  Future<WorkoutModel> getTreino(String id) async {
    final doc = await _db.collection(FirestoreCollections.workouts).doc(id).get();
    return WorkoutModel.fromMap(doc.id, doc.data()!);
  }

  // ---------- PLANOS ----------

  Future<String> criarPlano(PlanModel plano) async {
    final doc = await _db.collection(FirestoreCollections.plans).add(plano.toMap());
    return doc.id;
  }

  Future<void> excluirPlano(String id) {
    return _db.collection(FirestoreCollections.plans).doc(id).delete();
  }

  Stream<List<PlanModel>> streamPlanos() {
    return _db.collection(FirestoreCollections.plans).snapshots().map(
          (snap) => snap.docs.map((d) => PlanModel.fromMap(d.id, d.data())).toList(),
        );
  }

  // ---------- PROGRESSO DE TREINO ----------

  /// Registra que um aluno concluiu um treino. Chamado pelo botão
  /// "Concluir treino" na tela de detalhe.
  Future<void> registrarConclusaoTreino({
    required String alunoId,
    required String alunoNome,
    required WorkoutModel treino,
  }) async {
    final progresso = WorkoutProgressModel(
      id: '',
      alunoId: alunoId,
      alunoNome: alunoNome,
      workoutId: treino.id,
      workoutTitulo: treino.titulo,
      instrutorId: treino.instrutorId,
      duracaoMinutos: treino.duracaoMinutos,
      concluidoEm: DateTime.now(),
    );
    await _db.collection(FirestoreCollections.workoutProgress).add(progresso.toMap());
  }

  /// Todo o histórico de treinos concluídos por um aluno (mais recentes primeiro).
  Stream<List<WorkoutProgressModel>> streamProgressoDoAluno(String alunoId) {
    return _db
        .collection(FirestoreCollections.workoutProgress)
        .where('alunoId', isEqualTo: alunoId)
        .orderBy('concluidoEm', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => WorkoutProgressModel.fromMap(d.id, d.data())).toList());
  }

  /// Todas as conclusões de treinos criados por um instrutor específico —
  /// usado para calcular métricas reais no dashboard dele (ex: sessões no mês).
  Stream<List<WorkoutProgressModel>> streamProgressoDoInstrutor(String instrutorId) {
    return _db
        .collection(FirestoreCollections.workoutProgress)
        .where('instrutorId', isEqualTo: instrutorId)
        .orderBy('concluidoEm', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => WorkoutProgressModel.fromMap(d.id, d.data())).toList());
  }

  // ---------- AGENDA (AGENDAMENTOS DO INSTRUTOR) ----------

  Future<String> criarAgendamento(AppointmentModel agendamento) async {
    final doc = await _db.collection(FirestoreCollections.appointments).add(agendamento.toMap());
    return doc.id;
  }

  Future<void> atualizarStatusAgendamento(String id, AppointmentStatus status) {
    return _db.collection(FirestoreCollections.appointments).doc(id).update({'status': status.value});
  }

  Future<void> excluirAgendamento(String id) {
    return _db.collection(FirestoreCollections.appointments).doc(id).delete();
  }

  /// Todos os agendamentos de um instrutor num dia específico, ordenados
  /// por horário. Usado na aba "Agenda".
  Stream<List<AppointmentModel>> streamAgendaDoDia({
    required String instrutorId,
    required DateTime dia,
  }) {
    final inicio = DateTime(dia.year, dia.month, dia.day);
    final fim = inicio.add(const Duration(days: 1));
    return _db
        .collection(FirestoreCollections.appointments)
        .where('instrutorId', isEqualTo: instrutorId)
        .where('dataHora', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('dataHora', isLessThan: Timestamp.fromDate(fim))
        .orderBy('dataHora')
        .snapshots()
        .map((snap) => snap.docs.map((d) => AppointmentModel.fromMap(d.id, d.data())).toList());
  }

  /// Todos os agendamentos futuros de um aluno com um instrutor específico
  /// (não usado ainda na UI do aluno, mas pronto para uma futura tela de
  /// "meus agendamentos").
  Stream<List<AppointmentModel>> streamAgendaDoAluno(String alunoId) {
    return _db
        .collection(FirestoreCollections.appointments)
        .where('alunoId', isEqualTo: alunoId)
        .orderBy('dataHora')
        .snapshots()
        .map((snap) => snap.docs.map((d) => AppointmentModel.fromMap(d.id, d.data())).toList());
  }
}