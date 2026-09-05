/// Login screen — entry point for new users.
///
/// Reached after splash when no real (Apple/Google/Email) account is on
/// file. Surfaces the social + email sign-in options; "Continue as
/// guest" is a tertiary path.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/tokens.dart';
import '../services/auth_state.dart';
import '../widgets/social_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Kanji watermark — 春 (haru, spring)
          Positioned(
            top: -60,
            right: -80,
            child: Text(
              '春',
              style: SakuraType.display(
                color: SakuraColors.sakuraSoft.withOpacity(0.6),
                size: 380,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: SakuraSpace.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: SakuraSpace.xxl),
                  // Eyebrow — Japanese tagline
                  Text(
                    '日本語を話す',
                    style: SakuraType.japanese(
                        color: SakuraColors.sakura, size: 16),
                  ),
                  const SizedBox(height: SakuraSpace.m),
                  // Display
                  Text(
                    'Sakura',
                    style: SakuraType.display(size: 48),
                  ),
                  const SizedBox(height: SakuraSpace.s),
                  Text(
                    'Your AI pronunciation tutor.\nLearn to speak Japanese with confidence.',
                    style: SakuraType.body(
                        color: SakuraColors.mist, size: 16),
                  ),
                  const SizedBox(height: SakuraSpace.xl),
                  // Sign-in options
                  const _LoginOptions(),
                  const SizedBox(height: SakuraSpace.l),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginOptions extends StatefulWidget {
  const _LoginOptions();

  @override
  State<_LoginOptions> createState() => _LoginOptionsState();
}

class _LoginOptionsState extends State<_LoginOptions> {
  bool _showEmailForm = false;
  bool _isSignUp = false;
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _nameCtl = TextEditingController();

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    _nameCtl.dispose();
    super.dispose();
  }

  Future<void> _onApple() async {
    final auth = context.read<AuthState>();
    final ok = await auth.signInWithApple();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (auth.lastError != null) {
      _toast(context, auth.lastError!);
    }
  }

  Future<void> _onGoogle() async {
    final auth = context.read<AuthState>();
    final ok = await auth.signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (auth.lastError != null) {
      _toast(context, auth.lastError!);
    }
  }

  Future<void> _onEmailSubmit() async {
    final auth = context.read<AuthState>();
    final email = _emailCtl.text.trim();
    final pass = _passCtl.text;
    if (email.isEmpty || pass.isEmpty) {
      _toast(context, 'Email and password required');
      return;
    }
    if (pass.length < 8) {
      _toast(context, 'Password must be at least 8 characters');
      return;
    }
    final ok = _isSignUp
        ? await auth.signUpWithEmail(
            email: email,
            password: pass,
            displayName:
                _nameCtl.text.trim().isEmpty ? null : _nameCtl.text.trim(),
          )
        : await auth.signInWithEmail(email: email, password: pass);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (auth.lastError != null) {
      _toast(context, auth.lastError!);
    }
  }

  void _toast(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SocialButton(
          label: 'Continue with Apple',
          icon: Icons.apple_rounded,
          background: Colors.black,
          foreground: Colors.white,
          busy: auth.isBusy,
          onTap: _onApple,
        ),
        const SizedBox(height: SakuraSpace.m),
        SocialButton(
          label: 'Continue with Google',
          icon: Icons.g_mobiledata_rounded,
          background: SakuraColors.white,
          foreground: SakuraColors.sumi,
          border: SakuraColors.bamboo,
          busy: auth.isBusy,
          onTap: _onGoogle,
        ),
        const SizedBox(height: SakuraSpace.l),
        if (!_showEmailForm) ...[
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: SakuraSpace.m),
                child: Text('or',
                    style: SakuraType.caption(
                        color: SakuraColors.stone)),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: SakuraSpace.l),
          OutlinedButton(
            onPressed: () => setState(() => _showEmailForm = true),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: SakuraColors.bamboo),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(SakuraRadius.m),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              'Continue with Email',
              style: SakuraType.label(
                  color: SakuraColors.sumi, size: 15),
            ),
          ),
        ] else ...[
          TextField(
            controller: _emailCtl,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'you@example.com',
            ),
          ),
          const SizedBox(height: SakuraSpace.m),
          if (_isSignUp) ...[
            TextField(
              controller: _nameCtl,
              decoration: const InputDecoration(
                labelText: 'Display name (optional)',
              ),
            ),
            const SizedBox(height: SakuraSpace.m),
          ],
          TextField(
            controller: _passCtl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: 'At least 8 characters',
            ),
          ),
          const SizedBox(height: SakuraSpace.l),
          ElevatedButton(
            onPressed: auth.isBusy ? null : _onEmailSubmit,
            child: Text(
              _isSignUp ? 'Create account' : 'Sign in',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: SakuraSpace.s),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _isSignUp = !_isSignUp),
              child: Text(
                _isSignUp
                    ? 'Already have an account? Sign in'
                    : 'New here? Create an account',
                style: SakuraType.caption(
                    color: SakuraColors.sakura, size: 13),
              ),
            ),
          ),
          const SizedBox(height: SakuraSpace.s),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _showEmailForm = false;
                _isSignUp = false;
              }),
              child: Text(
                '← Back to other options',
                style: SakuraType.caption(
                    color: SakuraColors.mist, size: 12),
              ),
            ),
          ),
        ],
        const SizedBox(height: SakuraSpace.l),
        // Tertiary path: continue without an account.
        Center(
          child: TextButton(
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed('/home'),
            child: Text(
              'Continue without an account',
              style: SakuraType.caption(
                  color: SakuraColors.mist, size: 13),
            ),
          ),
        ),
      ],
    );
  }
}
