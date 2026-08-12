# FitHome Pro — App Flutter

App de treinos em casa com 3 painéis, seguindo o design gerado no Figma
(tema escuro, verde-limão como cor de destaque, tipografia Barlow/Barlow
Condensed):

- **Aluno**: Início, Treinos, Progresso e Plano (assinatura).
- **Instrutor**: Visão Geral, Alunos, Treinos e Agenda.
- **Administrador**: Dashboard, Planos, Usuários e Configurações.

## Arquitetura

```
lib/
  core/
    theme/app_theme.dart      # paleta + tipografia (Barlow Condensed via google_fonts)
    constants/app_constants.dart  # UserRole, SubscriptionStatus, nomes de coleções
  models/         # UserModel, WorkoutModel, ExerciseModel, SubscriptionModel, PlanModel
  services/       # AuthService, FirestoreService, SubscriptionService, R2StorageService
  providers/      # AuthProvider (estado global de sessão)
  routes/         # go_router com redirecionamento por role
  widgets/
    app_shell.dart       # casca comum: topo + navegação inferior por abas (por role)
    shared_widgets.dart  # StatCard, SectionTitle, InitialsAvatar, StatusBadge
  screens/
    auth/         # login, cadastro, recuperar senha
    admin/
      admin_panel.dart   # StatefulWidget com as 4 abas do admin
      tabs/               # admin_dashboard_tab, admin_plans_tab, admin_users_tab, admin_settings_tab
    instructor/
      instructor_panel.dart
      tabs/               # instructor_home_tab, instructor_students_tab, instructor_workouts_tab, instructor_schedule_tab
      create_workout_screen.dart  # tela empurrada (push) para criar/editar treino
    student/
      student_panel.dart
      tabs/               # student_home_tab, student_workouts_tab, student_progress_tab, student_subscription_tab
      workout_detail_screen.dart
```

Cada painel (`AdminPanel`, `InstructorPanel`, `StudentPanel`) é um
`StatefulWidget` que troca o conteúdo internamente ao tocar nas abas da
barra inferior — o `go_router` só navega entre `/admin`, `/instrutor` e
`/aluno` (mais as telas empurradas, como criar treino ou ver detalhe de
um treino).

Todo cadastro público entra automaticamente como **aluno**. Promoção a
instrutor/admin é feita manualmente pelo painel do Administrador
(aba "Usuários").

## 1. Pré-requisitos

- Flutter 3.22+ instalado (`flutter doctor`)
- Conta no [Firebase](https://console.firebase.google.com)
- Conta no [Cloudflare](https://dash.cloudflare.com) com R2 habilitado

## 2. Configurar o Firebase

1. Crie um projeto no [Firebase Console](https://console.firebase.google.com).
2. Ative **Authentication → E-mail/senha**.
3. Ative **Firestore Database** (modo produção).
4. Instale o FlutterFire CLI e gere o `firebase_options.dart` real
   (o arquivo atual é só um placeholder):

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

5. Publique as regras de segurança inclusas neste projeto:

   ```bash
   firebase deploy --only firestore:rules
   ```

   (arquivo `firestore.rules` na raiz do projeto)

6. **Crie o primeiro administrador manualmente**: cadastre-se normalmente
   pelo app (você entrará como "aluno"), depois no Firestore Console
   edite o documento `users/{seu_uid}` e mude o campo `role` para `"admin"`.
   A partir daí você já pode promover outros usuários pelo próprio app.

## 3. Configurar o Cloudflare R2

1. No dashboard da Cloudflare, crie um bucket R2 (ex: `treino-em-casa`).
2. Gere um **API Token** com permissão de leitura/escrita no R2
   (Account → R2 → Manage API Tokens).
3. Habilite acesso público ao bucket (domínio customizado ou `r2.dev`)
   para servir os vídeos/imagens.
4. Edite o arquivo `.env` na raiz do projeto (já incluso com valores de
   exemplo, para o `flutter pub get`/build não quebrar) com suas
   credenciais reais:

   ```
   R2_ENDPOINT=SEU_ACCOUNT_ID.r2.cloudflarestorage.com
   R2_ACCESS_KEY_ID=xxxxxxxx
   R2_SECRET_ACCESS_KEY=xxxxxxxx
   R2_BUCKET=treino-em-casa
   R2_PUBLIC_URL=https://pub-xxxxxxxx.r2.dev
   ```

   O `.env` já está no `.gitignore` — troque os valores localmente, mas
   não commite suas credenciais reais.

## 4. Rodar o projeto

```bash
flutter pub get
flutter run
```

## 5. Design

O tema em `lib/core/theme/app_theme.dart` replica os tokens do export do
Figma (`theme.css`): fundo `#0D0D0D`, cards `#181818`, verde-limão
`#C8FF3E` como cor primária, laranja para Instrutor e violeta para Admin.
Os títulos usam a fonte condensada via a função `condensed()` (ou
`AppTheme.heading()`), disponível em `lib/core/theme/app_theme.dart`.
Se você atualizar o design no Figma, ajuste as constantes em `AppColors`
e a paleta acompanha automaticamente em todas as telas.

## 6. Próximos passos sugeridos

- **Cobrança automática**: hoje o admin cria/renova assinaturas manualmente
  em `subscription_service.dart`. Para automatizar, integre Stripe,
  RevenueCat ou Google Play/App Store Billing e chame `renovar()` a partir
  do webhook de pagamento confirmado.
- **Notificações**: usar Firebase Cloud Messaging para avisar alunos sobre
  vencimento de assinatura.
- **Cloud Function agendada**: rodar `marcarAtrasadasAutomaticamente()`
  (já implementada no `SubscriptionService`) todo dia via Cloud Scheduler.
- **Player de vídeo**: o hook para reprodução já está em
  `workout_detail_screen.dart` — falta plugar o `VideoPlayerController`
  do pacote `video_player` (já incluso no `pubspec.yaml`).
- **Agenda do instrutor**: `instructor_schedule_tab.dart` está com dados
  de exemplo — crie uma coleção `appointments` no Firestore para deixá-la
  real.
- **Progresso do aluno**: a coleção `workout_progress` já está prevista
  nas regras do Firestore, pronta para registrar treinos concluídos (hoje
  o gráfico de minutos é ilustrativo em `student_progress_tab.dart`).

## Papéis e permissões (resumo)

| Ação                                | Aluno | Instrutor | Admin |
|--------------------------------------|:-----:|:---------:|:-----:|
| Ver treinos publicados               |  ✅   |    ✅     |  ✅   |
| Criar/editar/excluir treino          |  ❌   | ✅ (próprios) | ✅ |
| Ver a própria assinatura             |  ✅   |    ❌     |  ✅   |
| Criar/renovar/cancelar assinaturas   |  ❌   |    ❌     |  ✅   |
| Promover usuário (role)              |  ❌   |    ❌     |  ✅   |
| Ativar/desativar conta               |  ❌   |    ❌     |  ✅   |

