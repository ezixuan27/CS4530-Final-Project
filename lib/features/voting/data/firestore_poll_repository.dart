import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/activity_poll.dart';
import 'poll_repository.dart';

/// Stores polls in Firestore at `trips/{tripId}/polls/{pollId}`.
/// Votes are a map field `votes: {userId: option}`.
class FirestorePollRepository implements PollRepository {
  final FirebaseFirestore _db;

  FirestorePollRepository(this._db);

  CollectionReference<Map<String, dynamic>> _collection(String tripId) =>
      _db.collection('trips').doc(tripId).collection('polls');

  @override
  Stream<List<ActivityPoll>> watchPolls(String tripId) => _collection(tripId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs) _fromDoc(tripId, doc.id, doc.data()),
        ],
      );

  @override
  Future<void> createPoll({
    required String tripId,
    required String question,
    required List<String> options,
    required String createdBy,
  }) async {
    await _collection(tripId).add({
      'question': question,
      'options': options,
      'votes': <String, String>{},
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> vote({
    required String tripId,
    required String pollId,
    required String userId,
    required String option,
  }) async {
    // Update only this user's entry, so two members voting at the same time
    // don't overwrite each other.
    await _collection(tripId).doc(pollId).update({'votes.$userId': option});
  }

  ActivityPoll _fromDoc(String tripId, String id, Map<String, dynamic> data) {
    // createdAt is null locally until the server sets the timestamp.
    final createdAt = data['createdAt'] as Timestamp?;
    return ActivityPoll(
      id: id,
      tripId: tripId,
      question: data['question'] as String,
      options: List<String>.from(data['options'] as List),
      votes: Map<String, String>.from(data['votes'] as Map? ?? const {}),
      createdBy: data['createdBy'] as String,
      createdAt: createdAt?.toDate() ?? DateTime.now(),
    );
  }
}
