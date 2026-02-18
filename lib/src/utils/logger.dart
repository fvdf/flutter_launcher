import 'dart:io';

class Logger {
  static bool verbose = false;

  static void info(String message) {
    print('\x1B[32m[INFO]\x1B[0m $message');
  }

  static void warn(String message) {
    print('\x1B[33m[WARN]\x1B[0m $message');
  }

  static void error(String message) {
    stderr.writeln('\x1B[31m[ERROR]\x1B[0m $message');
  }

  static void section(String message) {
    print('\n\x1B[1m\x1B[36m=== $message ===\x1B[0m');
  }

  static void step(String message) {
    print('\x1B[34m[➤]\x1B[0m $message...');
  }

  static void success(String message) {
    print('\x1B[32m[✓]\x1B[0m $message');
  }

  static void debug(String message) {
    if (verbose) {
      print('\x1B[90m[DEBUG] $message\x1B[0m');
    }
  }

  static void pipe(String message) {
    if (verbose) {
      stdout.write(message);
    }
  }
}
