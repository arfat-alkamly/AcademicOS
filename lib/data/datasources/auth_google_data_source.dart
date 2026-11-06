import 'package:google_sign_in/google_sign_in.dart';

abstract class AuthGoogleDataSource {
  Future<GoogleSignInAccount?> signIn();
  Future<GoogleSignInAccount?> signInSilently();
  Future<void> signOut();
}

class AuthGoogleDataSourceImpl implements AuthGoogleDataSource {
  final GoogleSignIn _googleSignIn;

  AuthGoogleDataSourceImpl({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Future<GoogleSignInAccount?> signIn() async {
    return await _googleSignIn.signIn();
  }

  @override
  Future<GoogleSignInAccount?> signInSilently() async {
    return await _googleSignIn.signInSilently();
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
