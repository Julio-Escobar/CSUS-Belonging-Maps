import 'package:shared_preferences/shared_preferences.dart';

class LoginLockout {
  LoginLockout({DateTime Function()? now}) : _now = now ?? DateTime.now;

  static const int maxAttempts = 5;
  static const Duration lockDuration = Duration(seconds: 30);

  static const String _attemptsKey = 'login_failed_attempts';
  static const String _lockedUntilKey = 'login_locked_until_ms';

  final DateTime Function() _now;

  Future<Duration?> remainingLock() async {
    final prefs = await SharedPreferences.getInstance();
    final lockedUntilMs = prefs.getInt(_lockedUntilKey);
    if (lockedUntilMs == null) return null;

    final remaining = DateTime.fromMillisecondsSinceEpoch(
      lockedUntilMs,
    ).difference(_now());
    if (remaining > Duration.zero) return remaining;

    await reset();
    return null;
  }

  Future<Duration?> recordFailure() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = (prefs.getInt(_attemptsKey) ?? 0) + 1;

    if (attempts >= maxAttempts) {
      await prefs.setInt(_attemptsKey, 0);
      await prefs.setInt(
        _lockedUntilKey,
        _now().add(lockDuration).millisecondsSinceEpoch,
      );
      return lockDuration;
    }

    await prefs.setInt(_attemptsKey, attempts);
    return null;
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attemptsKey);
    await prefs.remove(_lockedUntilKey);
  }
}

String lockoutMessage(Duration remaining) {
  final seconds = (remaining.inMilliseconds / 1000).ceil();
  return 'Too many failed attempts. Try again in $seconds '
      'second${seconds == 1 ? '' : 's'}.';
}