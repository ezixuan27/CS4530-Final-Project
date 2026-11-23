import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/auth_service.dart';
import '../../../routes.dart';
import '../view_models/auth_view_model.dart';
import 'auth_form.dart';

/// Story 1 · Account access.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthViewModel(auth: context.read<AuthService>()),
      child: const _SignInView(),
    );
  }
}

class _SignInView extends StatefulWidget {
  const _SignInView();

  @override
  State<_SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<_SignInView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<AuthViewModel>().signIn(
      email: _email.text,
      password: _password.text,
    );
    if (ok && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, Routes.myTrips, (_) => false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return AuthForm(
      title: 'Sign In',
      formKey: _formKey,
      fields: [
        EmailField(controller: _email, onChanged: vm.clearError),
        PasswordField(
          controller: _password,
          onChanged: vm.clearError,
          onSubmitted: _submit,
          // only check it's filled in, old accounts might not meet new rules
          validator: (value) =>
              (value ?? '').isEmpty ? 'Enter your password.' : null,
        ),
      ],
      error: vm.error,
      isLoading: vm.isLoading,
      submitLabel: 'Sign In',
      onSubmit: _submit,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('No account yet?'),
          TextButton(
            onPressed: vm.isLoading
                ? null
                : () => Navigator.pushNamed(context, Routes.register),
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }
}
