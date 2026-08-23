/// Papéis (roles) de usuário dentro do app.
enum UserRole { aluno, instrutor, admin }

extension UserRoleX on UserRole {
  String get value {
    switch (this) {
      case UserRole.aluno:
        return 'aluno';
      case UserRole.instrutor:
        return 'instrutor';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'instrutor':
        return UserRole.instrutor;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.aluno;
    }
  }

  String get label {
    switch (this) {
      case UserRole.aluno:
        return 'Aluno';
      case UserRole.instrutor:
        return 'Instrutor';
      case UserRole.admin:
        return 'Administrador';
    }
  }
}

/// Status possíveis de uma assinatura.
enum SubscriptionStatus { ativa, pendente, atrasada, cancelada, expirada }

extension SubscriptionStatusX on SubscriptionStatus {
  String get value => toString().split('.').last;

  static SubscriptionStatus fromString(String value) {
    return SubscriptionStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SubscriptionStatus.pendente,
    );
  }

  String get label {
    switch (this) {
      case SubscriptionStatus.ativa:
        return 'Ativa';
      case SubscriptionStatus.pendente:
        return 'Pendente';
      case SubscriptionStatus.atrasada:
        return 'Atrasada';
      case SubscriptionStatus.cancelada:
        return 'Cancelada';
      case SubscriptionStatus.expirada:
        return 'Expirada';
    }
  }
}

/// Nomes das coleções do Firestore, centralizados para evitar strings soltas.
class FirestoreCollections {
  static const users = 'users';
  static const workouts = 'workouts';
  static const exercises = 'exercises';
  static const subscriptions = 'subscriptions';
  static const plans = 'plans';
  static const workoutProgress = 'workout_progress';
  static const appointments = 'appointments';
  static const notifications = 'notifications';
  static const chats = 'chats';
  static const mensagens = 'mensagens'; // subcoleção de chats/{id}/mensagens
}

class AppConstants {
  static const appName = 'FitHome Pro';
}

/// Lê um campo booleano do Firestore de forma tolerante: aceita `bool` de
/// verdade, mas também `"true"`/`"false"` como texto (pode acontecer se o
/// campo foi criado/editado manualmente no Firestore Console como string
/// em vez de boolean, o que quebraria o app com um TypeError em runtime).
bool lerBoolFirestore(dynamic valor, {required bool padrao}) {
  if (valor == null) return padrao;
  if (valor is bool) return valor;
  if (valor is String) return valor.toLowerCase() == 'true';
  return padrao;
}