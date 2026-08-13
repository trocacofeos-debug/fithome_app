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
}

class AppConstants {
  static const appName = 'FitHome Pro';
}