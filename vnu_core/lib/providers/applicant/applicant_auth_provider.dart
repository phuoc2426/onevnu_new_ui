import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:vnu_core/services/applicant/applicant_api_service.dart';
import 'package:vnu_core/models/applicant/applicant_account.dart';
import 'package:vnu_core/models/applicant/applicant_profile.dart';

class ApplicantAuthProvider extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final ApplicantApiService apiService;

  ApplicantAccount? _account;
  ApplicantProfile? _profile;

  ApplicantAuthProvider({required this.apiService});

  ApplicantAccount? get account => _account;
  ApplicantProfile? get profile => _profile;

  bool get isSignedIn => _account != null;

  Future<void> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return; // cancelled
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final email = googleUser.email;
    final fullName = googleUser.displayName ?? '';
    final avatarUrl = googleUser.photoUrl ?? '';
    await apiService.googleLogin(idToken!, email, fullName, avatarUrl);
    // Fetch account info
    _account = await apiService.getMe();
    // Optionally fetch profile separately if needed
    // For simplicity, assume profile is part of account response
    notifyListeners();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    // Use the service's signOut method to clear stored token
    await apiService.signOut();
    _account = null;
    _profile = null;
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    try {
      _account = await apiService.getMe();
      // TODO: fetch profile if separate endpoint exists
    } catch (e) {
      // ignore, not signed in
    }
    notifyListeners();
  }

  Future<void> updateProfile(ApplicantProfile profile) async {
    _profile = await apiService.updateProfile(profile);
    notifyListeners();
  }
}
