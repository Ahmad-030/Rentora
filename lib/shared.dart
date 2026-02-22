// shared.dart — Models, Firebase Service, Auth, Theme

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

// ─────────────────────────────────────────────
// THEME
// ─────────────────────────────────────────────

class RentoraTheme {
  static const Color primary = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF1565C0);
  static const Color accent = Color(0xFF2979FF);
  static const Color bg = Color(0xFFF5F7FF);
  static const Color card = Colors.white;
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFC62828);
  static const Color warning = Color(0xFFE65100);

  static ThemeData get theme => ThemeData(
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: accent,
    ),
    scaffoldBackgroundColor: bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFBBCCEE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFBBCCEE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 2,
      shadowColor: Colors.black12,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    fontFamily: 'Roboto',
    useMaterial3: true,
  );
}

// Status chip colors
Color statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'available':
      return RentoraTheme.success;
    case 'rented':
      return RentoraTheme.error;
    case 'maintenance':
      return RentoraTheme.warning;
    default:
      return Colors.grey;
  }
}

// ─────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role; // 'admin' | 'agent'
  final String companyId;
  final bool disabled;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.companyId,
    this.disabled = false,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
    uid: uid,
    name: m['name'] ?? '',
    email: m['email'] ?? '',
    role: m['role'] ?? 'agent',
    companyId: m['companyId'] ?? '',
    disabled: m['disabled'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'role': role,
    'companyId': companyId,
    'disabled': disabled,
  };
}

class Vehicle {
  final String id;
  final String name;
  final String model;
  final String plate;
  final double pricePerDay;
  final String imageUrl;
  final String status; // available | rented | maintenance
  final String companyId;

  Vehicle({
    required this.id,
    required this.name,
    required this.model,
    required this.plate,
    required this.pricePerDay,
    required this.imageUrl,
    required this.status,
    required this.companyId,
  });

  factory Vehicle.fromMap(String id, Map<String, dynamic> m) => Vehicle(
    id: id,
    name: m['name'] ?? '',
    model: m['model'] ?? '',
    plate: m['plate'] ?? '',
    pricePerDay: (m['pricePerDay'] ?? 0).toDouble(),
    imageUrl: m['imageUrl'] ?? '',
    status: m['status'] ?? 'available',
    companyId: m['companyId'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'model': model,
    'plate': plate,
    'pricePerDay': pricePerDay,
    'imageUrl': imageUrl,
    'status': status,
    'companyId': companyId,
  };
}

class Booking {
  final String id;
  final String customerName;
  final String contact;
  final String cnic;
  final String vehicleId;
  final String vehicleName;
  final DateTime startDate;
  final DateTime endDate;
  final double totalAmount;
  final double advancePaid;
  final double remaining;
  final String status; // active | completed
  final String companyId;
  final String createdBy;
  final String? damageNotes;
  final double? extraCharges;

  Booking({
    required this.id,
    required this.customerName,
    required this.contact,
    required this.cnic,
    required this.vehicleId,
    required this.vehicleName,
    required this.startDate,
    required this.endDate,
    required this.totalAmount,
    required this.advancePaid,
    required this.remaining,
    required this.status,
    required this.companyId,
    required this.createdBy,
    this.damageNotes,
    this.extraCharges,
  });

  factory Booking.fromMap(String id, Map<String, dynamic> m) => Booking(
    id: id,
    customerName: m['customerName'] ?? '',
    contact: m['contact'] ?? '',
    cnic: m['cnic'] ?? '',
    vehicleId: m['vehicleId'] ?? '',
    vehicleName: m['vehicleName'] ?? '',
    startDate: (m['startDate'] as Timestamp).toDate(),
    endDate: (m['endDate'] as Timestamp).toDate(),
    totalAmount: (m['totalAmount'] ?? 0).toDouble(),
    advancePaid: (m['advancePaid'] ?? 0).toDouble(),
    remaining: (m['remaining'] ?? 0).toDouble(),
    status: m['status'] ?? 'active',
    companyId: m['companyId'] ?? '',
    createdBy: m['createdBy'] ?? '',
    damageNotes: m['damageNotes'],
    extraCharges: m['extraCharges']?.toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'customerName': customerName,
    'contact': contact,
    'cnic': cnic,
    'vehicleId': vehicleId,
    'vehicleName': vehicleName,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'totalAmount': totalAmount,
    'advancePaid': advancePaid,
    'remaining': remaining,
    'status': status,
    'companyId': companyId,
    'createdBy': createdBy,
    'damageNotes': damageNotes,
    'extraCharges': extraCharges,
  };
}

// ─────────────────────────────────────────────
// CLOUDINARY SERVICE
// ─────────────────────────────────────────────

class CloudinaryService {
  static const String cloudName = 'dyl2toyfl';
  static const String uploadPreset = 'Rentora';

  static Future<String> uploadImage(File file,
      {String folder = 'rentora/vehicles'}) async {
    final uri =
    Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['secure_url'] as String;
    } else {
      throw Exception('Cloudinary upload failed: ${response.body}');
    }
  }
}

// ─────────────────────────────────────────────
// FIREBASE SERVICE
// ─────────────────────────────────────────────

class FirebaseService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  // AUTH
  static Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  static Future<void> signOut() => _auth.signOut();

  static User? get currentUser => _auth.currentUser;

  // REGISTER COMPANY (Admin)
  static Future<AppUser> registerCompany({
    required String companyName,
    required String ownerName,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final uid = cred.user!.uid;

    final companyRef = _db.collection('companies').doc();
    await companyRef.set({
      'name': companyName,
      'ownerName': ownerName,
      'phone': phone,
      'address': address,
      'adminUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final user = AppUser(
      uid: uid,
      name: ownerName,
      email: email,
      role: 'admin',
      companyId: companyRef.id,
    );
    await _db.collection('users').doc(uid).set(user.toMap());
    return user;
  }

  // GET USER INFO
  static Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromMap(uid, doc.data()!);
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 800));
      try {
        final doc = await _db.collection('users').doc(uid).get();
        if (!doc.exists) return null;
        return AppUser.fromMap(uid, doc.data()!);
      } catch (e2) {
        throw Exception('Failed to load profile: $e2');
      }
    }
  }

  // ─────────────────────────────────────────────
  // AGENTS
  // ─────────────────────────────────────────────

  static Future<void> createAgent({
    required String name,
    required String email,
    required String password,
    required String companyId,
  }) async {
    const secondaryAppName = 'agentCreator';

    FirebaseApp? secondaryApp;
    try {
      secondaryApp = Firebase.app(secondaryAppName);
    } catch (_) {
      secondaryApp = await Firebase.initializeApp(
        name: secondaryAppName,
        options: Firebase.app().options,
      );
    }

    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      await _db.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'role': 'agent',
        'companyId': companyId,
        'disabled': false,
      });

      await secondaryAuth.signOut();
    } finally {
      await secondaryApp.delete();
    }
  }

  static Stream<List<AppUser>> agentsStream(String companyId) => _db
      .collection('users')
      .where('companyId', isEqualTo: companyId)
      .where('role', isEqualTo: 'agent')
      .snapshots()
      .map((s) =>
      s.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList());

  static Future<void> updateAgentStatus(String uid, bool disabled) =>
      _db.collection('users').doc(uid).update({'disabled': disabled});

  /// Deletes agent's Firestore profile doc.
  /// Note: Firebase Auth account removal requires Admin SDK (server-side).
  /// The Firestore doc deletion prevents login lookup, effectively deactivating the agent.
  static Future<void> deleteAgent(String uid) =>
      _db.collection('users').doc(uid).delete();

  // VEHICLES
  static Stream<List<Vehicle>> vehiclesStream(String companyId) => _db
      .collection('vehicles')
      .where('companyId', isEqualTo: companyId)
      .snapshots()
      .map((s) =>
      s.docs.map((d) => Vehicle.fromMap(d.id, d.data())).toList());

  static Future<void> addVehicle(Vehicle v) =>
      _db.collection('vehicles').add(v.toMap());

  static Future<void> updateVehicle(String id, Map<String, dynamic> data) =>
      _db.collection('vehicles').doc(id).update(data);

  static Future<void> deleteVehicle(String id) =>
      _db.collection('vehicles').doc(id).delete();

  // BOOKINGS
  static Stream<List<Booking>> bookingsStream(String companyId) => _db
      .collection('bookings')
      .where('companyId', isEqualTo: companyId)
      .orderBy('startDate', descending: true)
      .snapshots()
      .map((s) =>
      s.docs.map((d) => Booking.fromMap(d.id, d.data())).toList());

  static Future<void> createBooking(Booking b) async {
    await _db.collection('bookings').add(b.toMap());
    await updateVehicle(b.vehicleId, {'status': 'rented'});
  }

  static Future<void> completeBooking(String bookingId, String vehicleId,
      String? damageNotes, double? extraCharges) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': 'completed',
      'damageNotes': damageNotes,
      'extraCharges': extraCharges,
    });
    await updateVehicle(vehicleId, {'status': 'available'});
  }

  /// Permanently deletes a booking record.
  static Future<void> deleteBooking(String bookingId) =>
      _db.collection('bookings').doc(bookingId).delete();

  // COMPANY
  static Future<Map<String, dynamic>?> getCompany(String companyId) async {
    final doc = await _db.collection('companies').doc(companyId).get();
    return doc.data();
  }

  static Future<void> updateCompany(
      String companyId, Map<String, dynamic> data) =>
      _db.collection('companies').doc(companyId).update(data);
}

// ─────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor(status).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor(status).withOpacity(0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: statusColor(status),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class DashCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const DashCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: RentoraTheme.primary)),
            const SizedBox(height: 2),
            Text(title,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
          ],
        ),
      ),
    );
  }
}

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback? onTap;
  final bool isAdmin;

  const VehicleCard(
      {super.key, required this.vehicle, this.onTap, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 100,
              width: double.infinity,
              child: vehicle.imageUrl.isNotEmpty
                  ? Image.network(vehicle.imageUrl, fit: BoxFit.cover)
                  : Container(
                color: RentoraTheme.primary.withOpacity(0.1),
                child: const Center(
                    child: Icon(Icons.directions_car,
                        size: 40, color: RentoraTheme.primary)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(vehicle.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        StatusBadge(vehicle.status),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(vehicle.model,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('🪪 ${vehicle.plate}',
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Text('Rs. ${vehicle.pricePerDay.toStringAsFixed(0)}/day',
                        style: const TextStyle(
                            color: RentoraTheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingTile extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;

  const BookingTile({super.key, required this.booking, this.onTap});

  @override
  Widget build(BuildContext context) {
    final days = booking.endDate.difference(booking.startDate).inDays;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: RentoraTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
          const Icon(Icons.directions_car, color: RentoraTheme.primary),
        ),
        title: Text(booking.customerName,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(booking.vehicleName,
                style: const TextStyle(
                    color: RentoraTheme.primary, fontSize: 13)),
            Text(
                '$days days • Rs. ${booking.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                    color: Colors.black54, fontSize: 12)),
          ],
        ),
        trailing: StatusBadge(booking.status),
      ),
    );
  }
}