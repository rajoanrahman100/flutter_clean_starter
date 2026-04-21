
//These ANSI codes give us colored terminal output — green for success, blue for info, red for errors, yellow for steps.

class Console {
  static void success(String message) =>
      print('\x1B[32m✓ $message\x1B[0m');

  static void info(String message) =>
      print('\x1B[34m→ $message\x1B[0m');

  static void error(String message) =>
      print('\x1B[31m✗ $message\x1B[0m');

  static void step(String message) =>
      print('\x1B[33m• $message\x1B[0m');

  static void blank() => print('');
}