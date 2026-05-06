import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/id_request.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- User Methods ---

  Future<void> createRequest(IDRequest request) async {
    await _firestore.collection('id_requests').add(request.toJson());
  }

  Future<void> updateRequest(IDRequest request) async {
    await _firestore.collection('id_requests').doc(request.id).update(request.toJson());
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
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs.map((doc) => IDRequest.fromJson({
        ...doc.data(),
        'id': doc.id,
      })).toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  Future<void> updateRequestStatus(String requestId, String status, {String? cardNumber, DateTime? expiryDate, String? adminNotes, String? driveLink}) async {
    final data = <String, dynamic>{
      'status': status,
      if (adminNotes != null) 'admin_notes': adminNotes,
      if (driveLink != null) 'drive_link': driveLink,
    };

    if (status == 'approved') {
      if (cardNumber == null || cardNumber.isEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
        final random = (1000 + (9999 - 1000) * (DateTime.now().microsecond / 1000000)).toInt();
        data['card_number'] = 'CTEA-$timestamp-$random';
      } else {
        data['card_number'] = cardNumber;
      }

      if (expiryDate == null) {
        data['expiry_date'] = DateTime.now().add(const Duration(days: 365)).toIso8601String();
      } else {
        data['expiry_date'] = expiryDate.toIso8601String();
      }
    }

    await _firestore.collection('id_requests').doc(requestId).update(data);
  }

  Future<void> updateRequestData(String requestId, Map<String, dynamic> data) async {
    await _firestore.collection('id_requests').doc(requestId).update(data);
  }

  Future<void> suspendRequest(String requestId) async {
    await _firestore.collection('id_requests').doc(requestId).update({
      'status': 'suspended',
      'admin_notes': 'Carteirinha suspensa pela administração.',
    });
  }

  Future<void> requestRenewal(String requestId) async {
    await _firestore.collection('id_requests').doc(requestId).update({
      'status': 'renewal_requested',
    });
  }

  Future<void> checkAndProcessExpirations(String userId) async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection('id_requests')
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'approved')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final expiryStr = data['expiry_date'];
      if (expiryStr != null) {
        final expiryDate = DateTime.parse(expiryStr);
        if (expiryDate.isBefore(now)) {
          await doc.reference.update({
            'status': 'renewal_requested',
            'admin_notes': 'Vencimento automático (365 dias). Renovação solicitada automaticamente pelo sistema.'
          });
        }
      }
    }
  }

  Future<void> checkAllExpirations() async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection('id_requests')
        .where('status', isEqualTo: 'approved')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final expiryStr = data['expiry_date'];
      if (expiryStr != null) {
        final expiryDate = DateTime.parse(expiryStr);
        if (expiryDate.isBefore(now)) {
          await doc.reference.update({
            'status': 'renewal_requested',
            'admin_notes': 'Vencimento automático (365 dias). Renovação solicitada automaticamente pelo sistema.'
          });
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snapshot = await _firestore.collection('profiles').get();
    final users = snapshot.docs.map((doc) => doc.data()).toList();
    users.sort((a, b) => (a['full_name'] ?? '').compareTo(b['full_name'] ?? ''));
    return users;
  }
}

