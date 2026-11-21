import '../models/user.dart';

/// The one place screens get the signed-in user from:
/// `context.read<AuthService>().currentUser`.
///
/// Stub: always returns [testUser] until real sign-in exists (Story 1,
/// Member A). Don't hardcode user ids in screens; read them from here.
class AuthService {
  static const testUser = AppUser(
    id: 'u1',
    name: 'Test User',
    email: 'test@tripsync.app',
  );

  AppUser get currentUser => testUser;
}
