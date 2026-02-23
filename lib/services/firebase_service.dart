import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/models.dart';

/// Service for Firebase operations including Auth and Firestore.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _checkInsCollection =>
      _firestore.collection('checkIns');

  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _firestore.collection('events');

  // ============ AUTHENTICATION ============

  /// Current Firebase user
  fb.User? get currentFirebaseUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<fb.User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Get or create user document
        return await _getOrCreateUserDocument(credential.user!);
      }
      return null;
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  /// Register with email and password
  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        return await _createUserDocument(credential.user!, name);
      }
      return null;
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get or create user document in Firestore
  Future<User> _getOrCreateUserDocument(fb.User firebaseUser) async {
    final doc = await _usersCollection.doc(firebaseUser.uid).get();

    if (doc.exists) {
      return User.fromJson({...doc.data()!, 'id': doc.id});
    } else {
      return await _createUserDocument(
        firebaseUser,
        firebaseUser.displayName ?? _extractNameFromEmail(firebaseUser.email!),
      );
    }
  }

  /// Create user document in Firestore
  Future<User> _createUserDocument(fb.User firebaseUser, String name) async {
    final role = _determineUserRole(firebaseUser.email!);

    final userData = {
      'email': firebaseUser.email,
      'name': name,
      'studentNumber': _extractStudentNumber(firebaseUser.email!),
      'role': role.name,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _usersCollection.doc(firebaseUser.uid).set(userData);

    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email!,
      name: name,
      studentNumber: userData['studentNumber'] as String,
      role: role,
    );
  }

  /// Determine user role based on email prefix
  UserRole _determineUserRole(String email) {
    final lowerEmail = email.toLowerCase();
    if (lowerEmail.startsWith('prof.') ||
        lowerEmail.startsWith('professor.') ||
        lowerEmail.startsWith('docente.')) {
      return UserRole.professor;
    }
    return UserRole.aluno;
  }

  String _extractNameFromEmail(String email) {
    final localPart = email.split('@').first;
    return localPart
        .replaceAll(RegExp(r'prof\.|professor\.|docente\.'), '')
        .replaceAll('.', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _extractStudentNumber(String email) {
    final localPart = email.split('@').first;
    final numbers = RegExp(r'\d+').firstMatch(localPart);
    return numbers?.group(0) ?? 'N/A';
  }

  String _mapFirebaseAuthException(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Utilizador não encontrado';
      case 'wrong-password':
        return 'Password incorreta';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Conta desativada';
      case 'email-already-in-use':
        return 'Email já está em uso';
      case 'weak-password':
        return 'Password demasiado fraca';
      case 'invalid-credential':
        return 'Credenciais inválidas';
      default:
        return e.message ?? 'Erro de autenticação';
    }
  }

  // ============ CHECK-INS ============

  /// Save a check-in to Firestore
  Future<void> saveCheckIn(CheckIn checkIn, String userId) async {
    await _checkInsCollection.doc(checkIn.id).set({
      ...checkIn.toJson(),
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get check-ins for a specific user
  /// Note: Sorting done on client to avoid composite index requirement
  Stream<List<CheckIn>> getUserCheckIns(String userId) {
    return _checkInsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final checkIns = snapshot.docs
              .map((doc) => CheckIn.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
          // Sort on client side to avoid needing composite index
          checkIns.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
          return checkIns;
        });
  }

  /// Get all check-ins for a specific event (for professors)
  /// Note: Sorting done on client to avoid composite index requirement
  Stream<List<Map<String, dynamic>>> getEventCheckIns(String eventId) {
    return _checkInsCollection
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .asyncMap((snapshot) async {
          final checkIns = <Map<String, dynamic>>[];

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final userId = data['userId'] as String?;

            // Get user info
            String userName = 'Desconhecido';
            String userNumber = 'N/A';

            if (userId != null) {
              final userDoc = await _usersCollection.doc(userId).get();
              if (userDoc.exists) {
                userName = userDoc.data()?['name'] ?? 'Desconhecido';
                userNumber = userDoc.data()?['studentNumber'] ?? 'N/A';
              }
            }

            checkIns.add({
              'checkIn': CheckIn.fromJson({...data, 'id': doc.id}),
              'userName': userName,
              'userNumber': userNumber,
            });
          }

          // Sort on client side to avoid needing composite index
          checkIns.sort((a, b) {
            final checkInA = a['checkIn'] as CheckIn;
            final checkInB = b['checkIn'] as CheckIn;
            return checkInB.checkInTime.compareTo(checkInA.checkInTime);
          });

          return checkIns;
        });
  }

  /// Get check-in count for an event
  Future<int> getEventCheckInCount(String eventId) async {
    final snapshot = await _checkInsCollection
        .where('eventId', isEqualTo: eventId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // ============ EVENTS ============

  /// Save an event to Firestore (created by professor)
  Future<void> saveEvent(Event event, String professorId) async {
    await _eventsCollection.doc(event.id).set({
      ...event.toJson(),
      'professorId': professorId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get events created by a professor
  /// Note: Sorting done on client to avoid composite index requirement
  Stream<List<Event>> getProfessorEvents(String professorId) {
    return _eventsCollection
        .where('professorId', isEqualTo: professorId)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) => Event.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
          // Sort on client side to avoid needing composite index
          events.sort((a, b) => b.startTime.compareTo(a.startTime));
          return events;
        });
  }

  /// Get active events (for professors dashboard)
  Future<int> getActiveEventsCount(String professorId) async {
    final now = DateTime.now();
    final snapshot = await _eventsCollection
        .where('professorId', isEqualTo: professorId)
        .where('endTime', isGreaterThan: now.toIso8601String())
        .get();
    return snapshot.docs.length;
  }

  /// Get total check-ins for all professor's events
  Future<int> getProfessorTotalCheckIns(String professorId) async {
    final events = await _eventsCollection
        .where('professorId', isEqualTo: professorId)
        .get();

    int total = 0;
    for (final event in events.docs) {
      final checkIns = await _checkInsCollection
          .where('eventId', isEqualTo: event.id)
          .count()
          .get();
      total += checkIns.count ?? 0;
    }
    return total;
  }
}
