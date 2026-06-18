import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNotifier extends Notifier<User?> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  User? build() {
    final sub = _auth.authStateChanges().listen((user) {
      state = user;
    });
    ref.onDispose(() => sub.cancel());
    return _auth.currentUser;
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUpWithEmailPassword(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

final authProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);
