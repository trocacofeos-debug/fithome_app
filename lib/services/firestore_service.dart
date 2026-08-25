import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/workout_model.dart';
import '../models/subscription_model.dart';
import '../models/workout_progress_model.dart';
import '../models/appointment_model.dart';
import '../models/notification_model.dart';
import '../models/chat_model.dart';

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

  Future<void> atualizarRole(String uid, UserRole novaRole) async {
    await _db.collection(FirestoreCollections.users).doc(uid).update({
      'role': novaRole.value,
    });
    await criarNotificacao(
      userId: uid,
      titulo: 'Seu perfil foi atualizado',
      mensagem: 'Agora você é ${novaRole.label} no FitHome Pro.',
      tipo: 'role_alterado',
    );
  }

  Future<void> ativarDesativarUsuario(String uid, bool ativo) {
    return _db.collection(FirestoreCollections.users).doc(uid).update({'ativo': ativo});
  }

  /// Alunos cujo cadastro foi feito com o código de indicação deste
  /// instrutor (campo `indicadoPor`, gravado uma única vez na criação da
  /// conta) — usado na tela de Indicações/Comissões do instrutor.
  Stream<List<UserModel>> streamIndicadosPeloInstrutor(String instrutorId) {
    return _db
        .collection(FirestoreCollections.users)
        .where('indicadoPor', isEqualTo: instrutorId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserModel.fromMap(d.id, d.data())).toList());
  }

  /// Atualiza o próprio perfil (usado pela tela "Meu Perfil" — qualquer
  /// usuário pode editar os próprios dados básicos, mas nunca o "role").
  Future<void> atualizarPerfilProprio(
    String uid, {
    String? nome,
    String? telefone,
    String? cpf,
    String? fotoUrl,
  }) {
    final dados = <String, dynamic>{};
    if (nome != null) dados['nome'] = nome;
    if (telefone != null) dados['telefone'] = telefone;
    if (cpf != null) dados['cpf'] = cpf;
    if (fotoUrl != null) dados['fotoUrl'] = fotoUrl;
    if (dados.isEmpty) return Future.value();
    return _db.collection(FirestoreCollections.users).doc(uid).update(dados);
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

  /// Cria uma cópia de um treino existente como rascunho (não publicado),
  /// sempre como treino geral (o instrutor escolhe conscientemente se quer
  /// tornar individual de novo, evitando duplicar sem querer um treino
  /// pessoal de um aluno para outro contexto).
  Future<String> duplicarTreino(WorkoutModel original) async {
    final copia = WorkoutModel(
      id: '',
      titulo: '${original.titulo} (cópia)',
      descricao: original.descricao,
      instrutorId: original.instrutorId,
      instrutorNome: original.instrutorNome,
      nivel: original.nivel,
      categoria: original.categoria,
      capaUrl: original.capaUrl,
      exercicios: original.exercicios,
      duracaoMinutos: original.duracaoMinutos,
      createdAt: DateTime.now(),
      publicado: false,
    );
    return criarTreino(copia);
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
  /// "Concluir treino" na tela de execução guiada.
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

  /// Todo o histórico de treinos concluídos no app inteiro, sem filtro —
  /// usado só no dashboard do admin, pra métricas gerais da plataforma.
  Stream<List<WorkoutProgressModel>> streamTodoProgresso() {
    return _db
        .collection(FirestoreCollections.workoutProgress)
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

  /// Todos os agendamentos de um aluno com qualquer instrutor.
  Stream<List<AppointmentModel>> streamAgendaDoAluno(String alunoId) {
    return _db
        .collection(FirestoreCollections.appointments)
        .where('alunoId', isEqualTo: alunoId)
        .orderBy('dataHora')
        .snapshots()
        .map((snap) => snap.docs.map((d) => AppointmentModel.fromMap(d.id, d.data())).toList());
  }

  // ---------- NOTIFICAÇÕES ----------

  Future<void> criarNotificacao({
    required String userId,
    required String titulo,
    required String mensagem,
    String tipo = 'geral',
    String? rota,
  }) async {
    final notificacao = NotificationModel(
      id: '',
      userId: userId,
      titulo: titulo,
      mensagem: mensagem,
      tipo: tipo,
      createdAt: DateTime.now(),
      rota: rota,
    );
    await _db.collection(FirestoreCollections.notifications).add(notificacao.toMap());
  }

  Stream<List<NotificationModel>> streamNotificacoes(String userId) {
    return _db
        .collection(FirestoreCollections.notifications)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => NotificationModel.fromMap(d.id, d.data())).toList());
  }

  Future<void> marcarNotificacaoComoLida(String id) {
    return _db.collection(FirestoreCollections.notifications).doc(id).update({'lida': true});
  }

  Future<void> marcarTodasNotificacoesComoLidas(String userId) async {
    final naoLidas = await _db
        .collection(FirestoreCollections.notifications)
        .where('userId', isEqualTo: userId)
        .where('lida', isEqualTo: false)
        .get();
    if (naoLidas.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in naoLidas.docs) {
      batch.update(doc.reference, {'lida': true});
    }
    await batch.commit();
  }

  // ---------- CHAT ----------

  /// ID determinístico do chat entre uma dupla instrutor+aluno — nunca
  /// existe mais de uma conversa entre as mesmas duas pessoas.
  String idDoChat(String instrutorId, String alunoId) => '${instrutorId}_$alunoId';

  /// Garante que o documento do chat existe, com os campos de identidade
  /// preenchidos (instrutorId/alunoId/nomes) — sem "última mensagem"
  /// ainda, se for a primeira vez. Precisa ser chamado ANTES de tentar
  /// ouvir as mensagens de uma conversa: a regra de segurança da
  /// subcoleção "mensagens" confere o dono checando esse documento pai, e
  /// se ele não existir, a leitura é negada.
  Future<void> garantirChatExiste({
    required String instrutorId,
    required String instrutorNome,
    required String alunoId,
    required String alunoNome,
  }) async {
    final chatId = idDoChat(instrutorId, alunoId);
    await _db.collection(FirestoreCollections.chats).doc(chatId).set({
      'instrutorId': instrutorId,
      'instrutorNome': instrutorNome,
      'alunoId': alunoId,
      'alunoNome': alunoNome,
    }, SetOptions(merge: true));
  }

  /// Envia uma mensagem e atualiza os metadados do chat (última mensagem,
  /// contador de não lidas de quem NÃO mandou).
  ///
  /// Importante: NÃO usa transação/`.get()` prévio no documento do chat —
  /// numa conversa nova, esse documento ainda não existe, e uma regra de
  /// segurança que tenta ler `resource.data` de um documento inexistente
  /// trava com "permission denied" antes mesmo de criar o documento. Em
  /// vez disso, usamos `set(merge: true)` (cria se não existir, atualiza
  /// se já existir) e `FieldValue.increment` (não precisa saber o valor
  /// atual do contador).
  Future<void> enviarMensagem({
    required String instrutorId,
    required String instrutorNome,
    required String alunoId,
    required String alunoNome,
    required String autorId,
    required String autorNome,
    required String texto,
  }) async {
    final chatId = idDoChat(instrutorId, alunoId);
    final chatRef = _db.collection(FirestoreCollections.chats).doc(chatId);
    final souInstrutor = autorId == instrutorId;
    final agora = Timestamp.now();

    // 1) Cria ou atualiza os metadados do chat.
    await chatRef.set({
      'instrutorId': instrutorId,
      'instrutorNome': instrutorNome,
      'alunoId': alunoId,
      'alunoNome': alunoNome,
      'ultimaMensagem': texto,
      'ultimaMensagemEm': agora,
      'ultimaMensagemAutorId': autorId,
      if (souInstrutor) 'naoLidasAluno': FieldValue.increment(1) else 'naoLidasInstrutor': FieldValue.increment(1),
    }, SetOptions(merge: true));

    // 2) Só depois cria a mensagem em si — nessa hora o documento do chat
    // já existe de verdade, então a regra de segurança da subcoleção
    // "mensagens" (que confere o dono do chat) encontra ele normalmente.
    await chatRef.collection(FirestoreCollections.mensagens).add({
      'autorId': autorId,
      'autorNome': autorNome,
      'texto': texto,
      'criadoEm': agora,
    });

    // 3) Notifica quem RECEBEU a mensagem (nunca quem mandou) — aparece no
    // sino, tanto do lado do instrutor quanto do aluno. Já com a rota
    // pronta pra abrir direto na conversa ao tocar na notificação.
    final destinatarioId = souInstrutor ? alunoId : instrutorId;
    final preview = texto.length > 60 ? '${texto.substring(0, 60)}...' : texto;
    await criarNotificacao(
      userId: destinatarioId,
      titulo: 'Nova mensagem de $autorNome',
      mensagem: preview,
      tipo: 'mensagem',
      rota: '/chat/$chatId',
    );
  }

  Stream<List<ChatMessageModel>> streamMensagens(String chatId) {
    return _db
        .collection(FirestoreCollections.chats)
        .doc(chatId)
        .collection(FirestoreCollections.mensagens)
        .orderBy('criadoEm')
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatMessageModel.fromMap(d.id, d.data())).toList());
  }

  Stream<ChatModel?> streamChat(String chatId) {
    return _db.collection(FirestoreCollections.chats).doc(chatId).snapshots().map(
          (doc) => doc.exists ? ChatModel.fromMap(doc.id, doc.data()!) : null,
        );
  }

  /// Todas as conversas de um instrutor, mais recentes primeiro.
  Stream<List<ChatModel>> streamChatsDoInstrutor(String instrutorId) {
    return _db
        .collection(FirestoreCollections.chats)
        .where('instrutorId', isEqualTo: instrutorId)
        .orderBy('ultimaMensagemEm', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatModel.fromMap(d.id, d.data())).toList());
  }

  /// Tenta marcar como lido; se o chat ainda não existir (conversa sem
  /// nenhuma mensagem ainda), o `update()` falha e a gente ignora — não
  /// tem nada pra marcar como lido mesmo. Evitamos de propósito checar a
  /// existência com um `.get()` antes: isso bateria na mesma regra de
  /// segurança que só libera leitura pra quem já é dono do chat, e um chat
  /// que ainda não existe não tem "dono" nenhum pra regra reconhecer.
  Future<void> marcarChatComoLido(String chatId, {required bool souInstrutor}) async {
    try {
      await _db.collection(FirestoreCollections.chats).doc(chatId).update({
        souInstrutor ? 'naoLidasInstrutor' : 'naoLidasAluno': 0,
      });
    } catch (_) {
      // Chat ainda não existe — nada a fazer.
    }
  }
}