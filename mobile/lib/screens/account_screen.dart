/// Account tab — Apple / Google / Email sign-in + signed-in profile.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/tokens.dart';
import '../services/auth_state.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: SafeArea(
        child: auth.isSignedIn
            ? _SignedInView(auth: auth)
            : _SignInView(auth: auth),
      ),
    );
  }
}

// ── Signed-out view ──

class _SignInView extends StatefulWidget {
  final AuthState auth;
  const _SignInView({required this.auth});

  @override
  State<_SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<_SignInView> {
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
    final ok = await widget.auth.signInWithApple();
    if (!mounted) return;
    if (!ok && widget.auth.lastError != null) {
      _toast(context, widget.auth.lastError!);
    }
  }

  Future<void> _onGoogle() async {
    final ok = await widget.auth.signInWithGoogle();
    if (!mounted) return;
    if (!ok && widget.auth.lastError != null) {
      _toast(context, widget.auth.lastError!);
    }
  }

  Future<void> _onEmailSubmit() async {
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
        ? await widget.auth.signUpWithEmail(
            email: email,
            password: pass,
            displayName: _nameCtl.text.trim().isEmpty
                ? null
                : _nameCtl.text.trim(),
          )
        : await widget.auth.signInWithEmail(email: email, password: pass);
    if (!mounted) return;
    if (!ok && widget.auth.lastError != null) {
      _toast(context, widget.auth.lastError!);
    }
  }

  void _toast(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: SakuraSpace.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SakuraSpace.l),
          Text(
            'Welcome',
            style: SakuraType.display(size: 32),
          ),
          const SizedBox(height: SakuraSpace.xs),
          Text(
            'Sign in to sync your progress and unlock Sakura Pro on all devices.',
            style: SakuraType.body(color: SakuraColors.mist, size: 15),
          ),
          const SizedBox(height: SakuraSpace.xl),
          if (!_showEmailForm) ...[
            // Apple
            _SocialButton(
              label: 'Continue with Apple',
              icon: Icons.apple_rounded,
              background: Colors.black,
              foreground: Colors.white,
              busy: auth.isBusy,
              onTap: _onApple,
            ),
            const SizedBox(height: SakuraSpace.m),
            // Google
            _SocialButton(
              label: 'Continue with Google',
              icon: Icons.g_mobiledata_rounded,
              background: SakuraColors.white,
              foreground: SakuraColors.sumi,
              border: SakuraColors.bamboo,
              busy: auth.isBusy,
              onTap: _onGoogle,
            ),
            const SizedBox(height: SakuraSpace.l),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: SakuraSpace.m),
                  child: Text('or',
                      style: SakuraType.caption(color: SakuraColors.stone)),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: SakuraSpace.l),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => setState(() => _showEmailForm = true),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: SakuraColors.bamboo),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(SakuraRadius.m),
                  ),
                ),
                child: Text(
                  'Continue with Email',
                  style: SakuraType.label(
                      color: SakuraColors.sumi, size: 15),
                ),
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
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: auth.isBusy ? null : _onEmailSubmit,
                child: Text(
                  _isSignUp ? 'Create account' : 'Sign in',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: SakuraSpace.s),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () =>
                      setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign in'
                        : 'New here? Create an account',
                    style: SakuraType.caption(
                        color: SakuraColors.sakura, size: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SakuraSpace.s),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
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
              ],
            ),
          ],
          const SizedBox(height: SakuraSpace.xxl),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color? border;
  final bool busy;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    this.border,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(SakuraRadius.m),
          side: border != null
              ? BorderSide(color: border!)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: const BorderRadius.all(SakuraRadius.m),
          onTap: busy ? null : onTap,
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: foreground, size: 22),
                      const SizedBox(width: SakuraSpace.s),
                      Text(
                        label,
                        style: SakuraType.label(
                            color: foreground, size: 15),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Signed-in view ──

class _SignedInView extends StatelessWidget {
  final AuthState auth;
  const _SignedInView({required this.auth});

  @override
  Widget build(BuildContext context) {
    final user = auth.user!;
    final email = user.email.isNotEmpty ? user.email : '(no email)';
    final providerLabel = switch (user.provider) {
      AuthProvider.apple => 'Apple',
      AuthProvider.google => 'Google',
      AuthProvider.email => 'Email',
      AuthProvider.anonymous => 'Guest',
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: SakuraSpace.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SakuraSpace.l),
          // Avatar circle
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: SakuraColors.sakuraSoft,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  email.isNotEmpty ? email[0].toUpperCase() : '?',
                  style: SakuraType.display(
                      color: SakuraColors.sakura, size: 32),
                ),
              ),
            ),
          ),
          const SizedBox(height: SakuraSpace.m),
          Center(
            child: Text(
              email,
              style: SakuraType.title(size: 18),
            ),
          ),
          const SizedBox(height: SakuraSpace.xs),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: SakuraSpace.s, vertical: 4),
              decoration: BoxDecoration(
                color: SakuraColors.washiDeep,
                borderRadius:
                    const BorderRadius.all(SakuraRadius.pill),
              ),
              child: Text(
                'Signed in with $providerLabel',
                style: SakuraType.caption(
                    color: SakuraColors.mist, size: 11),
              ),
            ),
          ),
          const SizedBox(height: SakuraSpace.xl),
          if (user.isNewUser) ...[
            Container(
              padding: const EdgeInsets.all(SakuraSpace.m),
              decoration: BoxDecoration(
                color: SakuraColors.sakuraSoft,
                borderRadius:
                    const BorderRadius.all(SakuraRadius.m),
              ),
              child: Row(
                children: [
                  const Icon(Icons.celebration_outlined,
                      color: SakuraColors.sakura),
                  const SizedBox(width: SakuraSpace.s),
                  Expanded(
                    child: Text(
                      'Welcome to Sakura! Your progress will be saved to this account from now on.',
                      style: SakuraType.body(size: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SakuraSpace.l),
          ],
          // Account details card
          Card(
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.alternate_email,
                  label: 'Email',
                  value: email,
                ),
                const Divider(height: 1),
                _DetailRow(
                  icon: Icons.verified_user_outlined,
                  label: 'Provider',
                  value: providerLabel,
                ),
                const Divider(height: 1),
                _DetailRow(
                  icon: Icons.fingerprint,
                  label: 'User ID',
                  value: user.userId,
                ),
              ],
            ),
          ),
          const SizedBox(height: SakuraSpace.l),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () async {
                await auth.signOut();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signed out')),
                );
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign out'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: SakuraColors.bamboo),
                foregroundColor: SakuraColors.sumi,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(SakuraRadius.m),
                ),
              ),
            ),
          ),
          const SizedBox(height: SakuraSpace.xxl),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: SakuraSpace.m, vertical: SakuraSpace.m),
      child: Row(
        children: [
          Icon(icon, color: SakuraColors.mist, size: 20),
          const SizedBox(width: SakuraSpace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: SakuraType.caption(size: 11)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: SakuraType.body(size: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
