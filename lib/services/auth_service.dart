import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile.dart';

class AuthService extends ChangeNotifier {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Profile? _currentProfile;
  
  Profile? get currentProfile => _currentProfile;
  fb.User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<void> initialize() async {
    try {
      if (isAuthenticated) {
        await fetchProfile();
      }
    } catch (e) {
      debugPrint("❌ AuthService: Erro na inicialização: $e");
    }
  }

  Future<void> fetchProfile() async {
    try {
      final user = currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('profiles').doc(user.uid).get();
      
      if (doc.exists) {
        _currentProfile = Profile.fromJson(doc.data()!);
      } else {
        _currentProfile = Profile(
          id: user.uid,
          email: user.email ?? '',
          fullName: 'Usuário',
          role: UserRole.common,
        );
        await _firestore.collection('profiles').doc(user.uid).set(_currentProfile!.toJson());
      }
      notifyListeners();
    } catch (e) {
      debugPrint("❌ AuthService: Erro ao buscar perfil: $e");
      rethrow;
    }
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    await fetchProfile();
  }

  Future<void> signUp(String email, String password, String fullName, String phone) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (credential.user != null) {
      final profile = Profile(
        id: credential.user!.uid,
        email: email,
        fullName: fullName,
        role: UserRole.common,
        phone: phone,
      );
      await _firestore.collection('profiles').doc(credential.user!.uid).set(profile.toJson());
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentProfile = null;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
