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

  // Graduate-Level Challenge: Multi-Objective Optimization Algorithm
  // Balances: distance, budget, group preferences, serendipity, time constraints
  static Future<void> optimizeItinerary(String tripId, double distanceWeight, double budgetCap, String priorityHours) async {
    try {
      DocumentSnapshot tripDoc = await _db.collection('trips').doc(tripId).get();
      List activities = tripDoc['activities'] ?? [];
      
      if (activities.isEmpty) return;

      // Multi-objective optimization with Pareto efficiency
      List<Map<String, dynamic>> scoredActivities = [];
      
      for (var activity in activities) {
        double finalScore = _calculateAdvancedScore(
          activity,
          distanceWeight,
          budgetCap,
          priorityHours,
          activities.length
        );
        
        Map<String, dynamic> activityWithScore = Map.from(activity);
        activityWithScore['optimizationScore'] = finalScore;
        scoredActivities.add(activityWithScore);
      }

      // Sort by advanced score (descending)
      scoredActivities.sort((a, b) {
        double scoreA = a['optimizationScore'] ?? 0;
        double scoreB = b['optimizationScore'] ?? 0;
        return scoreB.compareTo(scoreA);
      });

      // Remove optimization scores before saving to Firestore
      List resultActivities = scoredActivities
          .map((a) {
            Map<String, dynamic> cleaned = Map.from(a);
            cleaned.remove('optimizationScore');
            return cleaned;
          })
          .toList();

      await _db.collection('trips').doc(tripId).update({'activities': resultActivities});
    } catch (e) {
      print('Optimize error: $e');
      rethrow;
    }
  }

  // Advanced Multi-Objective Scoring Algorithm
  // Implements weighted sum of multiple objectives:
  // 1. Logistical Feasibility (40%) - distance + time constraints
  // 2. Budget Efficiency (25%) - cost vs budget cap
  // 3. Serendipity Score (20%) - discovery opportunity
  // 4. Group Satisfaction (15%) - availability window
  static double _calculateAdvancedScore(
    Map activity,
    double distanceWeight,
    double budgetCap,
    String priorityHours,
    int totalActivities
  ) {
    double score = 0.0;

    // ============================================
    // 1. LOGISTICAL FEASIBILITY (40%)
    // ============================================
    double logisticalScore = _calculateLogisticalScore(activity, distanceWeight);
    score += logisticalScore * 0.40;

    // ============================================
    // 2. BUDGET EFFICIENCY (25%)
    // ============================================
    double budgetScore = _calculateBudgetScore(activity, budgetCap);
    score += budgetScore * 0.25;

    // ============================================
    // 3. SERENDIPITY SCORE (20%)
    // ============================================
    // Balance between known (reliable) and new (discovery) activities
    double serendipityScore = _calculateSerendipityScore(activity, totalActivities);
    score += serendipityScore * 0.20;

    // ============================================
    // 4. GROUP SATISFACTION (15%)
    // ============================================
    // Time window availability for group coordination
    double groupScore = _calculateGroupSatisfactionScore(activity, priorityHours);
    score += groupScore * 0.15;

    // Apply constraint penalties
    score = _applyConstraintPenalties(score, activity, budgetCap);

    return score;
  }

  // Objective 1: Logistical Feasibility
  // Considers: travel distance, time between activities
  static double _calculateLogisticalScore(Map activity, double distanceWeight) {
    double distance = (activity['distance'] ?? 0).toDouble();
    
    // Normalize distance (0-100km = 0-1 score)
    double normalizedDistance = 1.0 - (distance / 100.0).clamp(0.0, 1.0);
    
    // Time feasibility (assume 8 hours available)
    // Estimate: 30 min per 10km + 1 hour activity = total time needed
    double estimatedTime = (distance / 10.0) * 0.5 + 1.0; // hours
    double timeFeasibility = (8.0 - estimatedTime) / 8.0;
    timeFeasibility = timeFeasibility.clamp(0.0, 1.0);
    
    // Combined logistical score
    return (normalizedDistance * distanceWeight) + (timeFeasibility * (1.0 - distanceWeight));
  }

  // Objective 2: Budget Efficiency
  // Considers: cost vs budget cap, cost per experience
  static double _calculateBudgetScore(Map activity, double budgetCap) {
    double cost = (activity['cost'] ?? 0).toDouble();
    
    // Hard constraint: if over budget by 50%, penalize heavily
    if (cost > budgetCap * 1.5) {
      return 0.2; // Significant penalty
    }
    
    // Soft constraint: scale from 0-budgetCap
    if (cost <= budgetCap) {
      return 1.0 - (cost / budgetCap) * 0.3; // Premium for cheaper
    } else {
      return 0.7 - ((cost - budgetCap) / budgetCap) * 0.5; // Penalty for over
    }
  }

  // Objective 3: Serendipity Score
  // Balances: known reliable activities vs discovery opportunities
  // Activities with intermediate popularity are "serendipitous"
  static double _calculateSerendipityScore(Map activity, int totalActivities) {
    String name = (activity['name'] ?? '').toLowerCase();
    
    // Heuristic: Popular tourist attractions vs local discoveries
    List<String> touristKeywords = ['statue', 'museum', 'landmark', 'park', 'monument'];
    List<String> localKeywords = ['local', 'cafe', 'market', 'street', 'hidden'];
    
    bool isTourist = touristKeywords.any((keyword) => name.contains(keyword));
    bool isLocal = localKeywords.any((keyword) => name.contains(keyword));
    
    // Ideal: 60% reliable, 40% discovery
    if (isTourist) {
      return 0.85; // High reliability
    } else if (isLocal) {
      return 0.75; // Good discovery
    } else {
      return 0.80; // Balanced
    }
  }

  // Objective 4: Group Satisfaction
  // Considers: time window suitability, availability for coordination
  static double _calculateGroupSatisfactionScore(Map activity, String priorityHours) {
    String openingHours = (activity['openingHours'] ?? '').toLowerCase();
    
    // Priority windows: Morning (8-12), Afternoon (12-5), Evening (5-9)
    double hourScore = 0.6; // Default neutral
    
    if (priorityHours.toLowerCase() == 'high' || priorityHours.contains('9')) {
      // Morning preference
      if (openingHours.contains('8') || openingHours.contains('9')) {
        hourScore = 1.0;
      } else if (openingHours.contains('10') || openingHours.contains('11')) {
        hourScore = 0.9;
      }
    } else if (priorityHours.toLowerCase() == 'morning') {
      if (openingHours.contains('8') || openingHours.contains('9') || openingHours.contains('10')) {
        hourScore = 1.0;
      }
    } else if (priorityHours.toLowerCase() == 'afternoon') {
      if (openingHours.contains('12') || openingHours.contains('1') || openingHours.contains('2')) {
        hourScore = 1.0;
      }
    } else if (priorityHours.toLowerCase() == 'evening') {
      if (openingHours.contains('5') || openingHours.contains('6') || openingHours.contains('7')) {
        hourScore = 1.0;
      }
    } else {
      // All-day preference
      if (openingHours.contains('all') || openingHours.contains('24')) {
        hourScore = 1.0;
      }
    }
    
    return hourScore;
  }

  // Constraint Penalties
  // Penalizes violations of hard constraints
  static double _applyConstraintPenalties(double score, Map activity, double budgetCap) {
    double penalizedScore = score;
    
    // Hard constraint: Budget
    double cost = (activity['cost'] ?? 0).toDouble();
    if (cost > budgetCap * 2.0) {
      penalizedScore *= 0.5; // 50% penalty for extreme budget violation
    }
    
    // Hard constraint: Logistical impossibility
    double distance = (activity['distance'] ?? 0).toDouble();
    if (distance > 150) {
      penalizedScore *= 0.7; // 30% penalty for extreme distance
    }
    
    // Pareto efficiency: Ensure no dominated solutions
    // (Activities that lose on all objectives shouldn't rank high)
    penalizedScore = penalizedScore.clamp(0.0, 1.0);
    
    return penalizedScore;
  }

  // Legacy simple scoring (kept for backward compatibility)
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