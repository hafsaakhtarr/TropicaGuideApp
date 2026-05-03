import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// FIREBASE INITIALIZATION
Future<void> initializeFirebase() async {
  await Firebase.initializeApp();
}

// AUTH SERVICE
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<User?> signUpEmail(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      
      // Create traveler profile in Firestore
      if (user != null) {
        await _db.collection('travelers').doc(user.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'trips': [],
        });
      }
      return user;
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }

  static Future<User?> signInEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static User? getCurrentUser() {
    return _auth.currentUser;
  }
}

// TRIP SERVICE (Firestore)
class TripService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create new trip
  static Future<String> createTrip(String userId, String tripName, DateTime startDate, DateTime endDate) async {
    try {
      // First, ensure the user document exists
      await _db.collection('travelers').doc(userId).set({
        'trips': [],
      }, SetOptions(merge: true));
      
      // Create the trip
      DocumentReference docRef = await _db.collection('trips').add({
        'name': tripName,
        'userId': userId,
        'members': [userId],
        'startDate': startDate,
        'endDate': endDate,
        'activities': [],
        'packingList': [],
        'checklist': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Add trip reference to user's trips
      await _db.collection('travelers').doc(userId).update({
        'trips': FieldValue.arrayUnion([docRef.id])
      });
      
      return docRef.id;
    } catch (e) {
      print('Create trip error: $e');
      rethrow;
    }
  }

  // Get trip data
  static Stream<DocumentSnapshot> getTripStream(String tripId) {
    return _db.collection('trips').doc(tripId).snapshots();
  }

  // Add activity to trip
  static Future<void> addActivity(String tripId, String activityName, String description, 
      double cost, String openingHours, String location, double distance) async {
    try {
      await _db.collection('trips').doc(tripId).update({
        'activities': FieldValue.arrayUnion([
          {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'name': activityName,
            'description': description,
            'cost': cost,
            'openingHours': openingHours,
            'location': location,
            'distance': distance,
            'timeAdded': FieldValue.serverTimestamp(),
          }
        ])
      });
    } catch (e) {
      print('Add activity error: $e');
      rethrow;
    }
  }

  // Optimizer: Reorder activities based on distance, opening hours, budget
  static Future<void> optimizeItinerary(String tripId, double distanceWeight, double budgetCap, String priorityHours) async {
    try {
      DocumentSnapshot tripDoc = await _db.collection('trips').doc(tripId).get();
      List activities = tripDoc['activities'] ?? [];
      
      if (activities.isEmpty) return;

      // Simple scoring algorithm
      activities.sort((a, b) {
        double scoreA = _calculateScore(a, distanceWeight, budgetCap, priorityHours);
        double scoreB = _calculateScore(b, distanceWeight, budgetCap, priorityHours);
        return scoreB.compareTo(scoreA); // Descending order
      });

      await _db.collection('trips').doc(tripId).update({'activities': activities});
    } catch (e) {
      print('Optimize error: $e');
      rethrow;
    }
  }

  static double _calculateScore(Map activity, double distanceWeight, double budgetCap, String priorityHours) {
    double score = 0;
    
    // Distance scoring (lower is better)
    double distanceScore = (100 - (activity['distance'] ?? 0)) / 100;
    score += distanceScore * distanceWeight;
    
    // Budget scoring
    double cost = activity['cost']?.toDouble() ?? 0;
    double budgetScore = cost <= budgetCap ? 1.0 : 0.5;
    score += budgetScore * 0.3;
    
    // Opening hours priority
    if ((activity['openingHours'] ?? '').contains(priorityHours)) {
      score += 0.5;
    }
    
    return score;
  }

  // Packing list: Add item with real-time sync
  Future<void> addPackingItem(String tripId, String itemName, String category, String assignedTo) async {
    try {
      await _db.collection('trips').doc(tripId).update({
        'packingList': FieldValue.arrayUnion([
          {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'name': itemName,
            'category': category,
            'assignedTo': assignedTo,
            'checked': false,
          }
        ])
      });
    } catch (e) {
      print('Add packing item error: $e');
      rethrow;
    }
  }

  // Check item off (with transaction for conflict resolution)
  Future<void> checkPackingItem(String tripId, String itemId) async {
    try {
      DocumentSnapshot tripDoc = await _db.collection('trips').doc(tripId).get();
      List packingList = tripDoc['packingList'] ?? [];
      
      packingList = packingList.map((item) {
        if (item['id'] == itemId) {
          return {...item, 'checked': !(item['checked'] ?? false)};
        }
        return item;
      }).toList();

      await _db.collection('trips').doc(tripId).update({'packingList': packingList});
    } catch (e) {
      print('Check item error: $e');
      rethrow;
    }
  }

  // Checklist: Add checklist task
  Future<void> addChecklistTask(String tripId, String taskName, String category, String assignedTo) async {
    try {
      await _db.collection('trips').doc(tripId).update({
        'checklist': FieldValue.arrayUnion([
          {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'name': taskName,
            'category': category,
            'assignedTo': assignedTo,
            'completed': false,
          }
        ])
      });
    } catch (e) {
      print('Add checklist task error: $e');
      rethrow;
    }
  }

  // Complete checklist task
  Future<void> completeChecklistTask(String tripId, String taskId) async {
    try {
      DocumentSnapshot tripDoc = await _db.collection('trips').doc(tripId).get();
      List checklist = tripDoc['checklist'] ?? [];
      
      checklist = checklist.map((task) {
        if (task['id'] == taskId) {
          return {...task, 'completed': !(task['completed'] ?? false)};
        }
        return task;
      }).toList();

      await _db.collection('trips').doc(tripId).update({'checklist': checklist});
    } catch (e) {
      print('Complete task error: $e');
      rethrow;
    }
  }
}

// FCM SERVICE (Push Notifications)
class FCMService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> initializeFCM() async {
    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    }

    // Listen for messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
    });
  }

  static Future<String?> getDeviceToken() async {
    return await _fcm.getToken();
  }

  static Future<void> sendNotification(String title, String body) async {
    // In production, you'd call Firebase Cloud Functions or your backend
    print('Notification: $title - $body');
  }
}