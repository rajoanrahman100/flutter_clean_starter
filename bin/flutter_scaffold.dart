import 'package:args/command_runner.dart';
import 'package:flutter_scaffold/flutter_scaffold.dart';

Future<void> main(List<String> arguments) async {
  final runner = CommandRunner<void>(
    'flutter_scaffold',
    'Scaffold Flutter projects with Clean Architecture, BLoC, and Dio.',
  )..addCommand(CreateCommand());

  try {
    await runner.run(arguments);
  } on UsageException catch (e) {
    print(e.message);
    print('');
    print(e.usage);
  }
}