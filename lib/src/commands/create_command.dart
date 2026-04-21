import 'package:args/command_runner.dart';
import '../generators/project_generator.dart';
import '../models/project_config.dart';
import '../utils/console.dart';
import '../utils/prompt.dart';

class CreateCommand extends Command<void> {
  @override
  final String name = 'create';

  @override
  final String description =
      'Create a new Flutter project with Clean Architecture.';

  @override
  Future<void> run() async {
    _printBanner();

    // ── Basic info ──────────────────────────────────────────────
    Prompt.section('Project basics');

    final projectName = Prompt.ask(
      'Project name',
      defaultValue: 'my_flutter_app',
    );

    final bundleId = Prompt.ask(
      'Bundle ID',
      defaultValue: 'com.example.$projectName',
    );

    // ── State management ────────────────────────────────────────
    Prompt.section('State management');

    final stateManagement = Prompt.select(
      'Which state management do you want?',
      ['BLoC', 'Cubit', 'Riverpod'],
    );

    // ── Features ────────────────────────────────────────────────
    Prompt.section('Feature modules');

    final features = Prompt.multiSelect(
      'Which feature modules should be scaffolded?',
      ['auth', 'home', 'profile', 'settings', 'onboarding'],
    );

    // ── Project options ─────────────────────────────────────────
    Prompt.section('Project options');

    final useFlavors = Prompt.confirm(
      'Set up Flutter Flavors (dev / staging / prod)?',
      defaultValue: false,
    );

    // ── Summary ─────────────────────────────────────────────────
    final config = ProjectConfig(
      projectName: projectName,
      bundleId: bundleId,
      stateManagement: stateManagement,
      features: features,
      useFlavors: useFlavors,
      organization: bundleId.split('.').take(2).join('.'),
    );

    _printSummary(config);

    final confirmed = Prompt.confirm(
      'Create project with these settings?',
      defaultValue: true,
    );

    if (!confirmed) {
      Console.blank();
      Console.info('Cancelled. Run again to start over.');
      Console.blank();
      return;
    }

    await ProjectGenerator(config: config).generate();
  }

  void _printBanner() {
    Console.blank();
    print('  ╔══════════════════════════════════════╗');
    print('  ║       Flutter Scaffold CLI  v0.1     ║');
    print('  ║   Clean Architecture · BLoC · Dio    ║');
    print('  ╚══════════════════════════════════════╝');
    Console.blank();
  }

  void _printSummary(ProjectConfig config) {
    Console.blank();
    print('  ┌─ Project summary ───────────────────────');
    print('  │  Name        : ${config.projectName}');
    print('  │  Bundle ID   : ${config.bundleId}');
    print('  │  State mgmt  : ${config.stateManagement}');
    print('  │  Features    : ${config.features.join(', ')}');
    print('  │  Flavors     : ${config.useFlavors}');
    print('  └─────────────────────────────────────────');
  }
}