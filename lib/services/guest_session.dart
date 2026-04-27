class GuestSession {
  GuestSession._();

  static bool _isGuest = false;

  static bool get isGuest => _isGuest;

  static void start() => _isGuest = true;

  static void end() => _isGuest = false;
}
