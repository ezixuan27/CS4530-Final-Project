import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/auth_service.dart';
import '../../../data/trip_repository.dart';
import '../../../models/activity_poll.dart';
import '../data/poll_repository.dart';
import '../view_models/poll_view_model.dart';

/// Story 7 · Choose an activity (Ella).
/// Lists the trip's polls; members vote on a card, the organizer creates polls.
/// Gets the trip id as the route argument.
class VoteActivityScreen extends StatelessWidget {
  const VoteActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tripId = ModalRoute.of(context)?.settings.arguments as String?;
    if (tripId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vote for an Activity')),
        body: const Center(child: Text('No trip selected.')),
      );
    }
    return ChangeNotifierProvider(
      create: (context) => PollViewModel(
        polls: context.read<PollRepository>(),
        trips: context.read<TripRepository>(),
        auth: context.read<AuthService>(),
        tripId: tripId,
      ),
      child: const _PollsView(),
    );
  }
}

class _PollsView extends StatelessWidget {
  const _PollsView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PollViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Vote for an Activity')),
      floatingActionButton: vm.isOrganizer
          ? FloatingActionButton(
              tooltip: 'New poll',
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => ChangeNotifierProvider.value(
                  value: vm,
                  child: const _NewPollDialog(),
                ),
              ),
              child: const Icon(Icons.add),
            )
          : null,
      body: _buildBody(vm),
    );
  }

  Widget _buildBody(PollViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.polls.isEmpty) {
      return const Center(child: Text('No polls yet.'));
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 88), // room for the button
      children: [for (final poll in vm.polls) _PollCard(poll: poll)],
    );
  }
}

class _PollCard extends StatelessWidget {
  const _PollCard({required this.poll});

  final ActivityPoll poll;

  Future<void> _vote(BuildContext context, String option) async {
    final error = await context.read<PollViewModel>().vote(poll, option);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<PollViewModel>();
    final myVote = poll.voteOf(vm.currentUserId);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(poll.question, style: theme.textTheme.titleMedium),
            ),
            for (final option in poll.options)
              ListTile(
                leading: Icon(
                  option == myVote
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: option == myVote ? theme.colorScheme.primary : null,
                ),
                title: Text(option),
                trailing: Text(
                  '${poll.countFor(option)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                selected: option == myVote,
                onTap: () => _vote(context, option),
              ),
          ],
        ),
      ),
    );
  }
}

class _NewPollDialog extends StatefulWidget {
  const _NewPollDialog();

  @override
  State<_NewPollDialog> createState() => _NewPollDialogState();
}

class _NewPollDialogState extends State<_NewPollDialog> {
  final _question = TextEditingController();
  final _options = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _question.dispose();
    _options.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _saving = true);
    final error = await context.read<PollViewModel>().createPoll(
      question: _question.text,
      options: _options.text,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
    } else {
      setState(() {
        _error = error;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New poll'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _question,
            decoration: const InputDecoration(labelText: 'Question'),
            textCapitalization: TextCapitalization.sentences,
          ),
          TextField(
            controller: _options,
            decoration: const InputDecoration(
              labelText: 'Options (one per line)',
            ),
            keyboardType: TextInputType.multiline,
            minLines: 3,
            maxLines: 6,
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
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _create,
          child: const Text('Create'),
        ),
      ],
    );
  }
}
