import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/auth_service.dart';
import '../../../routes.dart';
import '../view_models/auth_view_model.dart';
import 'auth_form.dart';

/// Story 1 · Account access.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthViewModel(auth: context.read<AuthService>()),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<AuthViewModel>().register(
      name: _name.text,
      email: _email.text,
      password: _password.text,
    );
    if (ok && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, Routes.myTrips, (_) => false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return AuthForm(
      title: 'Register',
      formKey: _formKey,
      fields: [
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Name'),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          onChanged: (_) => vm.clearError(),
          validator: (value) => AuthViewModel.validateName(value ?? ''),
        ),
        EmailField(controller: _email, onChanged: vm.clearError),
        PasswordField(
          controller: _password,
          onChanged: vm.clearError,
          onSubmitted: _submit,
          isNew: true,
          validator: (value) => AuthViewModel.validatePassword(value ?? ''),
        ),
      ],
      error: vm.error,
      isLoading: vm.isLoading,
      submitLabel: 'Create account',
      onSubmit: _submit,
    );
  }
}
