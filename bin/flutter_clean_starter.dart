import 'package:args/command_runner.dart';
import 'package:flutter_clean_starter/flutter_clean_starter.dart';

Future<void> main(List<String> arguments) async {
  final runner = CommandRunner<void>(
    'flutter_clean_starter',
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
