import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/id_request.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- User Methods ---

  Future<void> createRequest(IDRequest request) async {
    await _firestore.collection('id_requests').add(request.toJson());
  }

  Future<List<IDRequest>> getUserRequests(String userId) async {
    final snapshot = await _firestore
        .collection('id_requests')
        .where('user_id', isEqualTo: userId)
        .get();
    
    final requests = snapshot.docs.map((doc) => IDRequest.fromJson({
      ...doc.data(),
      'id': doc.id,
    })).toList();

    // Sort client-side to avoid needing a composite index in Firestore
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return requests;
  }

  Stream<List<IDRequest>> streamUserRequests(String userId) {
    return _firestore
        .collection('id_requests')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs.map((doc) => IDRequest.fromJson({
        ...doc.data(),
        'id': doc.id,
      })).toList();
      // Sort client-side to avoid needing a composite index in Firestore
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  Future<IDRequest?> getLatestApprovedCard(String userId) async {
    final snapshot = await _firestore
        .collection('id_requests')
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'approved')
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    
    final requests = snapshot.docs.map((doc) => IDRequest.fromJson({
      ...doc.data(),
      'id': doc.id,
    })).toList();

    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return requests.first;
  }

  // --- Admin Methods ---

  Future<List<IDRequest>> getAllRequests() async {
    final snapshot = await _firestore
        .collection('id_requests')
        .orderBy('created_at', descending: true)
        .get();
    
    return snapshot.docs.map((doc) => IDRequest.fromJson({
      ...doc.data(),
      'id': doc.id,
    })).toList();
  }

  Stream<List<IDRequest>> streamAllRequests() {
    return _firestore
        .collection('id_requests')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => IDRequest.fromJson({
          ...doc.data(),
          'id': doc.id,
        })).toList());
  }

  Future<void> updateRequestStatus(String requestId, String status, {String? cardNumber, DateTime? expiryDate, String? adminNotes}) async {
    final data = <String, dynamic>{
      'status': status,
      if (adminNotes != null) 'admin_notes': adminNotes,
    };

    if (status == 'approved') {
      // If approved and no card number provided, generate one
      if (cardNumber == null || cardNumber.isEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
        final random = (1000 + (9999 - 1000) * (DateTime.now().microsecond / 1000000)).toInt();
        data['card_number'] = 'CTEA-$timestamp-$random';
      } else {
        data['card_number'] = cardNumber;
      }

      // If approved and no expiry provided, set to 365 days
      if (expiryDate == null) {
        data['expiry_date'] = DateTime.now().add(const Duration(days: 365)).toIso8601String();
      } else {
        data['expiry_date'] = expiryDate.toIso8601String();
      }
    }

    await _firestore.collection('id_requests').doc(requestId).update(data);
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snapshot = await _firestore.collection('profiles').orderBy('full_name').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
