import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/auth_service.dart';
import '../../../data/trip_repository.dart';
import '../../../routes.dart';
import '../view_models/join_trip_view_model.dart';

/// Story 3 · Join a trip.
/// Type the invite code, then land in that trip.
class JoinTripScreen extends StatelessWidget {
  const JoinTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => JoinTripViewModel(
        repository: context.read<TripRepository>(),
        auth: context.read<AuthService>(),
      ),
      child: const _JoinTripView(),
    );
  }
}

class _JoinTripView extends StatefulWidget {
  const _JoinTripView();

  @override
  State<_JoinTripView> createState() => _JoinTripViewState();
}

class _JoinTripViewState extends State<_JoinTripView> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final trip = await context.read<JoinTripViewModel>().join(_code.text);
    if (trip == null || !mounted) return;
    // replace so back goes to My Trips, not this form
    Navigator.pushReplacementNamed(
      context,
      Routes.itinerary,
      arguments: trip.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<JoinTripViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Join Trip')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Enter the code a friend shared with you.'),
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              decoration: InputDecoration(
                labelText: 'Invite code',
                hintText: 'e.g. RME27A',
                errorText: vm.error,
              ),
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
              ],
              textInputAction: TextInputAction.go,
              onChanged: (_) => vm.clearError(),
              onSubmitted: (_) => _join(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: vm.isJoining ? null : _join,
              child: vm.isJoining
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Join'),
            ),
          ],
        ),
      ),
    );
  }
}
