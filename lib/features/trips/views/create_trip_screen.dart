import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/auth_service.dart';
import '../../../data/trip_repository.dart';
import '../../../models/trip.dart';
import '../view_models/create_trip_view_model.dart';

/// Story 2 · Create and invite.
/// Form for a new trip, then shows the invite code to share.
class CreateTripScreen extends StatelessWidget {
  const CreateTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CreateTripViewModel(
        repository: context.read<TripRepository>(),
        auth: context.read<AuthService>(),
      ),
      child: Builder(
        builder: (context) {
          final trip = context.select<CreateTripViewModel, Trip?>(
            (vm) => vm.createdTrip,
          );
          return trip == null ? const _CreateTripForm() : _InviteCodeView(trip);
        },
      ),
    );
  }
}

class _CreateTripForm extends StatefulWidget {
  const _CreateTripForm();

  @override
  State<_CreateTripForm> createState() => _CreateTripFormState();
}

class _CreateTripFormState extends State<_CreateTripForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _destination = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _destination.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final vm = context.read<CreateTripViewModel>();
    final today = DateUtils.dateOnly(DateTime.now());
    // end date can't go before the start
    final first = isStart ? today : (vm.startDate ?? today);
    final current = isStart ? vm.startDate : vm.endDate;
    final picked = await showDatePicker(
      context: context,
      firstDate: first,
      lastDate: DateTime(today.year + 5, 12, 31),
      initialDate: current != null && !current.isBefore(first)
          ? current
          : first,
      helpText: isStart ? 'Start date' : 'End date',
    );
    if (picked == null) return;
    isStart ? vm.setStartDate(picked) : vm.setEndDate(picked);
  }

  Future<void> _submit() async {
    final vm = context.read<CreateTripViewModel>();
    // field errors show under the fields, the vm only has to catch dates
    if (!_formKey.currentState!.validate()) return;
    await vm.create(name: _name.text, destination: _destination.text);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CreateTripViewModel>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Create Trip')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Trip name'),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onChanged: (_) => vm.clearError(),
                validator: (v) => CreateTripViewModel.validateName(v ?? ''),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _destination,
                decoration: const InputDecoration(labelText: 'Destination'),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onChanged: (_) => vm.clearError(),
                validator: (v) =>
                    CreateTripViewModel.validateDestination(v ?? ''),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: 'Start date',
                      date: vm.startDate,
                      onPressed: () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateButton(
                      label: 'End date',
                      date: vm.endDate,
                      onPressed: () => _pickDate(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    vm.error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              FilledButton(
                onPressed: vm.isSaving ? null : _submit,
                child: vm.isSaving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create trip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.onPressed,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(date == null ? 'Pick' : CreateTripViewModel.formatDate(date!)),
        ],
      ),
    );
  }
}

class _InviteCodeView extends StatelessWidget {
  const _InviteCodeView(this.trip);

  final Trip trip;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: trip.inviteCode));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Code copied')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Trip created')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(trip.name, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                '${trip.destination} · '
                '${CreateTripViewModel.formatDate(trip.startDate)} – '
                '${CreateTripViewModel.formatDate(trip.endDate)}',
              ),
              const SizedBox(height: 32),
              const Text('Share this code so friends can join:'),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          trip.inviteCode,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontFamily: 'Courier',
                            letterSpacing: 4,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy code',
                        icon: const Icon(Icons.copy),
                        onPressed: () => _copy(context),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
