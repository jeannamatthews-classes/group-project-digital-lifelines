import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseHelper {
  FirebaseHelper._internal();
  static final FirebaseHelper instance = FirebaseHelper._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save entry value to Firebase
Future<void> saveValue(String firebaseDocId, int entryId, String fieldName, String value) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      await _db
          .collection('users')
          .doc(userId)
          .collection('timelines')
          .doc(firebaseDocId)
          .collection('entries')
          .doc(entryId.toString())
         .update({
  'values.$fieldName': value,
  'updated_at': DateTime.now().toIso8601String(),
});
      print('Value saved to Firebase: $fieldName = $value');
    } catch (e) {
      print('Firebase error: $e');
    }
  }

  // Save timeline to Firebase
 Future<String> saveTimeline(String name, int localId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final docId = '${DateTime.now().millisecondsSinceEpoch}_$localId';
      await _db
          .collection('users')
          .doc(userId)
          .collection('timelines')
          .doc(docId)
          .set({
        'name': name,
        'local_id': localId,
        'updated_at': DateTime.now().toIso8601String(),
      });
      print('Timeline saved to Firebase: $name');
      return docId;
    } catch (e) {
      print('Firebase error: $e');
      return localId.toString();
    }
  }

  // Save entry to Firebase
 Future<void> saveEntry(String firebaseDocId, int entryId, Map<String, String> values) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      await _db
          .collection('users')
          .doc(userId)
          .collection('timelines')
          .doc(firebaseDocId)
          .collection('entries')
          .doc(entryId.toString())
          .set({
        'values': values,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('Entry saved to Firebase!');
    } catch (e) {
      print('Firebase error: $e');
    }
  }

  // Get all timelines from Firebase
  Future<List<Map<String, dynamic>>> getTimelines() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('timelines')
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Firebase error: $e');
      return [];
    }
  }

  // Update timeline name in Firebase
 Future<void> updateTimelineName(String firebaseDocId, String newName) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      await _db
          .collection('users')
          .doc(userId)
          .collection('timelines')
          .doc(firebaseDocId)
          .update({
        'name': newName,
        'updated_at': DateTime.now().toIso8601String(),
      });
      print('Timeline name updated in Firebase: $newName');
    } catch (e) {
      print('Firebase error: $e');
    }
  }


// Save field/parameter to Firebase
Future<void> saveField(String firebaseDocId, String fieldName, String fieldType) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      await _db
          .collection('users')
          .doc(userId)
          .collection('timelines')
          .doc(firebaseDocId)
          .collection('fields')
          .add({
        'name': fieldName,
        'type': fieldType,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('Field saved to Firebase: $fieldName');
    } catch (e) {
      print('Firebase error: $e');
    }
  }

// Load all timelines from Firebase for current user
Future<List<Map<String, dynamic>>> getUserTimelines() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('timelines')
          .get();
      
      List<Map<String, dynamic>> timelines = [];
      
      for (var doc in snapshot.docs) {
        final timelineData = doc.data();
        
        // Get fields for this timeline
        final fieldsSnapshot = await _db
            .collection('users')
            .doc(userId)
            .collection('timelines')
            .doc(doc.id)
            .collection('fields')
            .get();
        
        // Get entries for this timeline
        final entriesSnapshot = await _db
            .collection('users')
            .doc(userId)
            .collection('timelines')
            .doc(doc.id)
            .collection('entries')
            .get();

        timelineData['firebase_doc_id'] = doc.id;
        timelineData['fields'] = fieldsSnapshot.docs
            .map((f) => f.data())
            .toList();
            
        timelineData['entries'] = entriesSnapshot.docs
            .map((e) => e.data())
            .toList();
            
        timelines.add(timelineData);
      }
      
      return timelines;
    } catch (e) {
      print('Firebase error: $e');
      return [];
    }
  }

// Delete timeline from Firebase
Future<void> deleteTimeline(String firebaseDocId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      
      // Delete all entries
      final entriesSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('timelines')
          .doc(firebaseDocId)
          .collection('entries')
          .get();
      for (var doc in entriesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all fields
      final fieldsSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('timelines')
          .doc(firebaseDocId)
          .collection('fields')
          .get();
      for (var doc in fieldsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete timeline document
      await _db
          .collection('users')
          .doc(userId)
          .collection('timelines')
          .doc(firebaseDocId)
          .delete();
          
      print('Timeline deleted from Firebase!');
    } catch (e) {
      print('Firebase delete error: $e');
    }
  }
}