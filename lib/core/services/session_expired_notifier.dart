import 'package:flutter/foundation.dart';

/// Fires when a token refresh fails because the refresh token itself was rejected - the
/// session cannot be recovered automatically. The Dio layer has no BuildContext/Provider
/// access, so this is how it tells the app to clear auth state and return to sign-in.
class SessionExpiredNotifier extends ChangeNotifier {
  void notifySessionExpired() => notifyListeners();
}

final sessionExpiredNotifier = SessionExpiredNotifier();
