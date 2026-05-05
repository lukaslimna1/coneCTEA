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
        .orderBy('created_at', descending: true)
        .get();
    
    return snapshot.docs.map((doc) => IDRequest.fromJson({
      ...doc.data(),
      'id': doc.id, // Ensure ID is passed if not in JSON
    })).toList();
  }

  Future<IDRequest?> getLatestApprovedCard(String userId) async {
    final snapshot = await _firestore
        .collection('id_requests')
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'approved')
        .orderBy('created_at', descending: true)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return IDRequest.fromJson({
      ...doc.data(),
      'id': doc.id,
    });
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

  Future<void> updateRequestStatus(String requestId, String status, {String? cardNumber, DateTime? expiryDate, String? adminNotes}) async {
    final data = {
      'status': status,
      if (cardNumber != null) 'card_number': cardNumber,
      if (expiryDate != null) 'expiry_date': expiryDate.toIso8601String(),
      if (adminNotes != null) 'admin_notes': adminNotes,
    };
    await _firestore.collection('id_requests').doc(requestId).update(data);
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snapshot = await _firestore.collection('profiles').orderBy('full_name').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
