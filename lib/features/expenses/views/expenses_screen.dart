import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/auth_service.dart';
import '../data/expense_repository.dart';
import '../view_models/expense_view_model.dart';

/// Story 8 · Track expenses (Ella).
/// Lists who paid for what in this trip and lets members add an expense.
/// Gets the trip id as the route argument.
class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tripId = ModalRoute.of(context)?.settings.arguments as String?;
    if (tripId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expenses')),
        body: const Center(child: Text('No trip selected.')),
      );
    }
    return ChangeNotifierProvider(
      create: (context) => ExpenseViewModel(
        repository: context.read<ExpenseRepository>(),
        auth: context.read<AuthService>(),
        tripId: tripId,
      ),
      child: const _ExpensesView(),
    );
  }
}

class _ExpensesView extends StatelessWidget {
  const _ExpensesView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExpenseViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => ChangeNotifierProvider.value(
            value: vm,
            child: const _AddExpenseDialog(),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
      body: _buildBody(vm),
    );
  }

  Widget _buildBody(ExpenseViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.expenses.isEmpty) {
      return const Center(child: Text('No expenses yet.'));
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 88), // room for the button
      children: [
        for (final expense in vm.expenses)
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: Text(expense.description),
            subtitle: Text('Paid by ${expense.paidByName}'),
            trailing: Text(
              ExpenseViewModel.formatCents(expense.amountInCents),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

class _AddExpenseDialog extends StatefulWidget {
  const _AddExpenseDialog();

  @override
  State<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<_AddExpenseDialog> {
  final _description = TextEditingController();
  final _amount = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final vm = context.read<ExpenseViewModel>();
    final error = await vm.addExpense(
      description: _description.text,
      amount: _amount.text,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<ExpenseViewModel>().isSaving;
    return AlertDialog(
      title: const Text('Add expense'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'What was it for?'),
            textCapitalization: TextCapitalization.sentences,
          ),
          TextField(
            controller: _amount,
            decoration: const InputDecoration(labelText: 'Amount (€)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: saving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
