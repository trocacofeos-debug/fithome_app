import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/app_shell.dart';
import 'tabs/student_home_tab.dart';
import 'tabs/student_workouts_tab.dart';
import 'tabs/student_progress_tab.dart';
import 'tabs/student_subscription_tab.dart';

class StudentPanel extends StatefulWidget {
  const StudentPanel({super.key});

  @override
  State<StudentPanel> createState() => _StudentPanelState();
}

class _StudentPanelState extends State<StudentPanel> {
  String _tab = 'home';

  static const _tabs = [
    AppTab(key: 'home', label: 'Início', icon: Icons.local_fire_department_outlined),
    AppTab(key: 'treinos', label: 'Treinos', icon: Icons.fitness_center_outlined),
    AppTab(key: 'progresso', label: 'Progresso', icon: Icons.bar_chart_outlined),
    AppTab(key: 'assinatura', label: 'Plano', icon: Icons.credit_card_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return AppShell(
      role: UserRole.aluno,
      tabs: _tabs,
      activeTab: _tab,
      onTab: (t) => setState(() => _tab = t),
      body: switch (_tab) {
        'treinos' => const StudentWorkoutsTab(),
        'progresso' => const StudentProgressTab(),
        'assinatura' => const StudentSubscriptionTab(),
        _ => const StudentHomeTab(),
      },
    );
  }
}
