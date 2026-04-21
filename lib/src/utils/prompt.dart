import 'dart:io';

class Prompt {
  /// Ask a free-text question. Re-prompts if the answer is empty.
  static String ask(String question, {String? defaultValue}) {
    final hint = defaultValue != null ? ' [$defaultValue]' : '';
    stdout.write('\n  $question$hint: ');
    final input = stdin.readLineSync()?.trim() ?? '';
    if (input.isEmpty && defaultValue != null) return defaultValue;
    if (input.isEmpty) return ask(question, defaultValue: defaultValue);
    return input;
  }

  /// Ask a yes/no question. Returns true for y/yes.
  static bool confirm(String question, {bool defaultValue = false}) {
    final hint = defaultValue ? '[Y/n]' : '[y/N]';
    stdout.write('\n  $question $hint: ');
    final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';
    if (input.isEmpty) return defaultValue;
    return input == 'y' || input == 'yes';
  }

  /// Present a numbered list and return the chosen item.
  static String select(String question, List<String> options) {
    print('\n  $question');
    for (var i = 0; i < options.length; i++) {
      print('    ${i + 1}. ${options[i]}');
    }
    stdout.write('\n  Enter number [1]: ');
    final input = stdin.readLineSync()?.trim() ?? '';
    final index = int.tryParse(input);
    if (index == null || index < 1 || index > options.length) {
      return options[0];
    }
    return options[index - 1];
  }

  /// Present a numbered list and return all chosen items.
  /// User can enter "1 3 4" or "1,3,4" or "all".
  static List<String> multiSelect(String question, List<String> options) {
    print('\n  $question');
    for (var i = 0; i < options.length; i++) {
      print('    ${i + 1}. ${options[i]}');
    }
    print('    a. All');
    stdout.write('\n  Enter numbers separated by space [a]: ');

    final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';

    if (input.isEmpty || input == 'a' || input == 'all') return [...options];

    final parts = input.split(RegExp(r'[\s,]+'));
    final selected = <String>[];

    for (final part in parts) {
      final index = int.tryParse(part);
      if (index != null && index >= 1 && index <= options.length) {
        selected.add(options[index - 1]);
      }
    }

    return selected.isEmpty ? [...options] : selected;
  }

  /// Print a section header to visually separate prompt groups.
  static void section(String title) {
    print('\n  ── $title ──');
  }
}