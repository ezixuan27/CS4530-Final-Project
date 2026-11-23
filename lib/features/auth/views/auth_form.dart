import 'package:flutter/material.dart';

import '../view_models/auth_view_model.dart';

/// Shared layout for Sign In and Register.
class AuthForm extends StatelessWidget {
  const AuthForm({
    super.key,
    required this.title,
    required this.formKey,
    required this.fields,
    required this.error,
    required this.isLoading,
    required this.submitLabel,
    required this.onSubmit,
    this.footer,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> fields;
  final String? error;
  final bool isLoading;
  final String submitLabel;
  final VoidCallback onSubmit;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                for (final field in fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: field,
                  ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                FilledButton(
                  onPressed: isLoading ? null : onSubmit,
                  child: isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(submitLabel),
                ),
                if (footer != null) ...[const SizedBox(height: 8), footer!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmailField extends StatelessWidget {
  const EmailField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(labelText: 'Email'),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      autofillHints: const [AutofillHints.email],
      onChanged: (_) => onChanged(),
      validator: (value) => AuthViewModel.validateEmail(value ?? ''),
    );
  }
}

class PasswordField extends StatelessWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.validator,
    this.isNew = false,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onSubmitted;
  final FormFieldValidator<String> validator;

  /// true on Register, so iOS offers a strong password
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(labelText: 'Password'),
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.done,
      autofillHints: [
        isNew ? AutofillHints.newPassword : AutofillHints.password,
      ],
      onChanged: (_) => onChanged(),
      onFieldSubmitted: (_) => onSubmitted(),
      validator: validator,
    );
  }
}
