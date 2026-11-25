import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/auth_service.dart';
import '../../../models/expense.dart';
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
            child: const _ExpenseDialog(),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
      body: _buildBody(context, vm),
    );
  }

  Widget _buildBody(BuildContext context, ExpenseViewModel vm) {
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
            // Only the payer can edit; other rows aren't tappable.
            onTap: vm.canEdit(expense)
                ? () => showDialog<void>(
                    context: context,
                    builder: (_) => ChangeNotifierProvider.value(
                      value: vm,
                      child: _ExpenseDialog(editing: expense),
                    ),
                  )
                : null,
          ),
      ],
    );
  }
}

/// Adds an expense, or edits [editing] when given.
class _ExpenseDialog extends StatefulWidget {
  const _ExpenseDialog({this.editing});

  final Expense? editing;

  @override
  State<_ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<_ExpenseDialog> {
  late final _description = TextEditingController(
    text: widget.editing?.description,
  );
  // "48.50" for 4850: the formatted amount without the euro sign.
  late final _amount = TextEditingController(
    text: switch (widget.editing) {
      final e? => ExpenseViewModel.formatCents(e.amountInCents).substring(1),
      null => null,
    },
  );
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final vm = context.read<ExpenseViewModel>();
    final editing = widget.editing;
    final error = editing == null
        ? await vm.addExpense(
            description: _description.text,
            amount: _amount.text,
          )
        : await vm.editExpense(
            editing,
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
      title: Text(widget.editing == null ? 'Add expense' : 'Edit expense'),
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
