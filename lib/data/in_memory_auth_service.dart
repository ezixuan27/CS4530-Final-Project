import '../models/user.dart';
import 'auth_service.dart';

/// Fake AuthService for tests. Starts signed in as testUser, or use
/// `.signedOut()` to test the sign in / register screens.
class InMemoryAuthService extends AuthService {
  InMemoryAuthService() : _user = AuthService.testUser;

  InMemoryAuthService.signedOut() : _user = null;

  /// testUser's password
  static const testPassword = 'password123';

  AppUser? _user;
  int _nextId = 2;

  final Map<String, ({AppUser user, String password})> _accounts = {
    AuthService.testUser.email: (
      user: AuthService.testUser,
      password: testPassword,
    ),
  };

  @override
  AppUser? get signedInUser => _user;

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final key = _normalize(email);
    if (!key.contains('@')) throw AuthException.invalidEmail;
    if (password.length < 6) throw AuthException.weakPassword;
    if (_accounts.containsKey(key)) throw AuthException.emailInUse;

    final user = AppUser(id: 'u${_nextId++}', name: name.trim(), email: key);
    _accounts[key] = (user: user, password: password);
    _setUser(user);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    final account = _accounts[_normalize(email)];
    if (account == null || account.password != password) {
      throw AuthException.wrongCredentials;
    }
    _setUser(account.user);
  }

  @override
  Future<void> signOut() async => _setUser(null);

  // emails aren't case sensitive in Firebase either
  static String _normalize(String email) => email.trim().toLowerCase();

  void _setUser(AppUser? user) {
    _user = user;
    notifyListeners();
  }
}
