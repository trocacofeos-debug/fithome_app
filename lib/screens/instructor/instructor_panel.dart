import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/app_shell.dart';
import 'tabs/instructor_home_tab.dart';
import 'tabs/instructor_students_tab.dart';
import 'tabs/instructor_workouts_tab.dart';
import 'tabs/instructor_schedule_tab.dart';

class InstructorPanel extends StatefulWidget {
  const InstructorPanel({super.key});

  @override
  State<InstructorPanel> createState() => _InstructorPanelState();
}

class _InstructorPanelState extends State<InstructorPanel> {
  String _tab = 'home';

  static const _tabs = [
    AppTab(key: 'home', label: 'Visão Geral', icon: Icons.bar_chart_outlined),
    AppTab(key: 'alunos', label: 'Alunos', icon: Icons.people_outline),
    AppTab(key: 'treinos', label: 'Treinos', icon: Icons.fitness_center_outlined),
    AppTab(key: 'agenda', label: 'Agenda', icon: Icons.calendar_today_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return AppShell(
      role: UserRole.instrutor,
      tabs: _tabs,
      activeTab: _tab,
      onTab: (t) => setState(() => _tab = t),
      body: switch (_tab) {
        'alunos' => const InstructorStudentsTab(),
        'treinos' => const InstructorWorkoutsTab(),
        'agenda' => const InstructorScheduleTab(),
        _ => const InstructorHomeTab(),
      },
    );
  }
}
