import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/message.dart';

// Enhancement 1, 2 & 3
// handles reading/writing users and chat messages in Cloud Firestore
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // get all users
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();

        user['uid'] ??= doc.id;

        return user;
      }).toList();
    });
  }

  // Enhancement 1
  // all registered users except the currently logged-in user
  Stream<List<Map<String, dynamic>>> getOtherUsersStream() {
    final currentUser = _firebaseAuth.currentUser;

    return getUsersStream().map((users) {
      return users.where((user) {
        final uid = (user['uid'] ?? '').toString();
        final email = (user['email'] ?? '').toString().toLowerCase();

        if (currentUser == null) return true;
        if (uid == currentUser.uid) return false;
        if (email.isNotEmpty &&
            email == (currentUser.email ?? '').toLowerCase()) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  // Enhancement 3
  // builds the same chat room ID for any 2 users (sorted to ensure uniqueness)
  String getChatRoomId(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    return ids.join("_");
  }

  // send message
  Future<void> sendMessage(String receiverId, message) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String? currentUserEmail = _firebaseAuth.currentUser!.email;
    final Timestamp timestamp = Timestamp.now();
    MessageModel newMessage = MessageModel(
      senderId: currentUserId,
      senderEmail: currentUserEmail ?? "",
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
    );

    // construct chat room ID for the two users (sorted to ensure uniqueness)
    String chatRoomID = getChatRoomId(currentUserId, receiverId);

    // add new message to database
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());
  }

  // get message
  Stream<QuerySnapshot> getMessage(String userID, otherUserID) {
    // construct chat room ID for the two users (sorted to ensure uniqueness)
    String chatRoomID = getChatRoomId(userID, otherUserID);

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy('timestamp', descending: true)
        // "sending" (hasPendingWrites = true) to "delivered" (saved on server)
        .snapshots(includeMetadataChanges: true);
  }

  Future<void> markMessagesAsRead(
    String userID,
    String otherUserID,
    List<String> messageIds,
  ) async {
    if (messageIds.isEmpty) return;

    final messages = _firestore
        .collection("chat_rooms")
        .doc(getChatRoomId(userID, otherUserID))
        .collection("messages");

    final batch = _firestore.batch();
    for (final id in messageIds) {
      batch.update(messages.doc(id), {'isRead': true});
    }
    await batch.commit();
  }

  Stream<QuerySnapshot> getUnreadMessages(String userID, String otherUserID) {
    return _firestore
        .collection("chat_rooms")
        .doc(getChatRoomId(userID, otherUserID))
        .collection("messages")
        .where('receiverId', isEqualTo: userID)
        .where('isRead', isEqualTo: false)
        .snapshots();
  }

  Future<String?> getUidByEmail(String email) async {
    final q = await _firestore
        .collection('Users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    // Ensure your Users doc actually stores the Firebase Auth UID in a field `uid`
    return (q.docs.first.data()['uid'] ?? '').toString();
  }
}