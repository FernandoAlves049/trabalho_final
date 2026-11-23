import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_database.dart';
import '../state/session_provider.dart';
import 'style.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) => const _AuthForm(register: false);
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});
  @override
  Widget build(BuildContext context) => const _AuthForm(register: true);
}

class _AuthForm extends StatefulWidget {
  const _AuthForm({required this.register});
  final bool register;

  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(), email = TextEditingController();
  final password = TextEditingController(),
      confirmation = TextEditingController();
  bool busy = false, hide = true, hideConfirmation = true;
  String? error;

  @override
  void dispose() {
    for (final field in [name, email, password, confirmation]) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });
    final session = context.read<SessionProvider>();
    try {
      if (widget.register) {
        await session.auth.register(name.text, email.text, password.text);
        if (mounted) Navigator.of(context).pop(email.text.trim());
      } else {
        await session.login(email.text, password.text);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is AccountFailure
              ? e.message
              : 'Falha ao acessar o banco local. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> openRegister() async {
    final result = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const RegisterScreen()));
    if (result != null && mounted) {
      email.text = result;
      password.clear();
      setState(() => error = null);
      message(context, 'Conta criada. Entre com a sua senha.');
    }
  }

  Widget field(
    String label,
    TextEditingController controller,
    IconData icon, {
    required String? Function(String) validate,
    TextInputType? keyboard,
    bool secret = false,
    bool? hidden,
    VoidCallback? toggle,
    bool last = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: TextFormField(
      controller: controller,
      enabled: !busy,
      keyboardType: keyboard,
      obscureText: hidden ?? false,
      autocorrect: !secret && keyboard != TextInputType.emailAddress,
      enableSuggestions: !secret,
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: last ? (_) => submit() : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: secret
            ? IconButton(
                tooltip: hidden! ? 'Mostrar $label' : 'Ocultar $label',
                onPressed: toggle,
                icon: Icon(
                  hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
              )
            : null,
      ),
      validator: (value) => validate(value ?? ''),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final reg = widget.register;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                BrandBar(back: reg),
                ArcadeBanner(
                  title: reg ? 'Criar conta' : 'Promoções de jogos',
                  label: 'JOGOS PARA PC',
                  height: reg ? 110 : 158,
                ),
                const SizedBox(height: 24),
                Text(reg ? 'Seus dados' : 'Entrar', style: headline(33)),
                const SizedBox(height: 5),
                Text(
                  reg
                      ? 'A conta e os favoritos ficam neste dispositivo.'
                      : 'Acesse suas ofertas e seus favoritos.',
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 20),
                Form(
                  key: form,
                  child: Column(
                    children: [
                      if (reg)
                        field(
                          'Nome',
                          name,
                          Icons.person_outline,
                          validate: (s) =>
                              s.trim().isEmpty ? 'Informe seu nome.' : null,
                        ),
                      field(
                        'E-mail',
                        email,
                        Icons.mail_outline,
                        keyboard: TextInputType.emailAddress,
                        validate: (s) =>
                            RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(s.trim())
                            ? null
                            : 'Informe um e-mail válido.',
                      ),
                      field(
                        'Senha',
                        password,
                        Icons.lock_outline,
                        secret: true,
                        hidden: hide,
                        last: !reg,
                        toggle: () => setState(() => hide = !hide),
                        validate: (s) =>
                            s.isEmpty ? 'Informe sua senha.' : null,
                      ),
                      if (reg)
                        field(
                          'Confirmar senha',
                          confirmation,
                          Icons.lock_outline,
                          secret: true,
                          hidden: hideConfirmation,
                          last: true,
                          toggle: () => setState(
                            () => hideConfirmation = !hideConfirmation,
                          ),
                          validate: (s) => s.isEmpty || s != password.text
                              ? 'As senhas devem ser iguais.'
                              : null,
                        ),
                    ],
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                FilledButton(
                  onPressed: busy ? null : submit,
                  child: busy
                      ? const SizedBox.square(
                          dimension: 21,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(reg ? 'Cadastrar' : 'Entrar na conta'),
                ),
                if (!reg)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextButton(
                      onPressed: busy ? null : openRegister,
                      child: const Text('Criar uma conta'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
