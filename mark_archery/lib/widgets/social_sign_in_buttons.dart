import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../screens/home_shell.dart';
import 'google_logo.dart';

const _googleServerClientId =
    '779518587521-hbneugdgrdut7ielejhqhqm4ti2ipco2.apps.googleusercontent.com';

/// A random string sent to the provider (hashed) and to Supabase (raw), so
/// Supabase can confirm the ID token it receives was minted for this exact
/// sign-in attempt and not replayed from another one.
String _generateNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(
    length,
    (_) => charset[random.nextInt(charset.length)],
  ).join();
}

String _sha256OfString(String input) =>
    sha256.convert(utf8.encode(input)).toString();

/// "Continue with Google" and "Continue with Apple" buttons, handling the
/// full sign-in flow (including navigating to [HomeShell] on success)
/// internally. The host screen only needs to display [onError] messages —
/// used identically on the Login and Sign Up screens.
class SocialSignInButtons extends StatefulWidget {
  final ValueChanged<String> onError;

  const SocialSignInButtons({super.key, required this.onError});

  @override
  State<SocialSignInButtons> createState() => _SocialSignInButtonsState();
}

class _SocialSignInButtonsState extends State<SocialSignInButtons> {
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  bool get _isBusy => _isGoogleLoading || _isAppleLoading;

  Future<void> _completeSignIn(
    String idToken,
    OAuthProvider provider,
    String rawNonce,
  ) async {
    await supabase.auth.signInWithIdToken(
      provider: provider,
      idToken: idToken,
      nonce: rawNonce,
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeShell()),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    try {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256OfString(rawNonce);

      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        serverClientId: _googleServerClientId,
        nonce: hashedNonce,
      );
      final googleUser = await googleSignIn.authenticate();

      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw Exception('No ID token received from Google');
      }

      await _completeSignIn(idToken, OAuthProvider.google, rawNonce);
    } catch (e) {
      widget.onError('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isAppleLoading = true);

    try {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256OfString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception('No ID token received from Apple');
      }

      await _completeSignIn(idToken, OAuthProvider.apple, rawNonce);
    } catch (e) {
      widget.onError('Apple sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: _isBusy ? null : _handleGoogleSignIn,
          icon: _isGoogleLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const GoogleLogo(),
          label: const Text('Continue with Google'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isBusy ? null : _handleAppleSignIn,
          icon: _isAppleLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.apple, size: 22),
          label: const Text('Continue with Apple'),
        ),
      ],
    );
  }
}
