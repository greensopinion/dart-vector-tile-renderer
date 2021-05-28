typedef MessageFunction = String Function();

abstract class Logger {
  const factory Logger.noop() = _NoOpLogger;
  const factory Logger.console() = _ConsoleLogger;
  const Logger._();

  void log(MessageFunction message);
}

class _NoOpLogger extends Logger {
  const _NoOpLogger() : super._();

  @override
  void log(MessageFunction message) {}
}

class _ConsoleLogger extends Logger {
  const _ConsoleLogger() : super._();

  @override
  void log(MessageFunction message) {
    print(message());
  }
}
