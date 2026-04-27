import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> setDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) =>
      _db.collection(collection).doc(docId).set(data);

  static Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) =>
      _db.collection(collection).doc(docId).update(data);

  static Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    String collection,
    String docId,
  ) =>
      _db.collection(collection).doc(docId).get();

  static Future<QuerySnapshot<Map<String, dynamic>>> queryWhere(
    String collection,
    String field,
    dynamic value,
  ) =>
      _db.collection(collection).where(field, isEqualTo: value).get();

  static Future<DocumentReference<Map<String, dynamic>>> addDocument(
    String collection,
    Map<String, dynamic> data,
  ) =>
      _db.collection(collection).add(data);

  static FieldValue get serverTimestamp => FieldValue.serverTimestamp();
}
