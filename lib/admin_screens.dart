// admin_screens.dart — Admin Dashboard, Vehicles, Bookings, Agents, Settings

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';
import 'shared.dart';
import 'main.dart';

// ─────────────────────────────────────────────
// ADMIN DASHBOARD (root with bottom nav)
// ─────────────────────────────────────────────

class AdminDashboard extends StatefulWidget {
  final AppUser user;
  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _tab = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      AdminHomeTab(user: widget.user),
      VehiclesTab(user: widget.user, isAdmin: true),
      BookingsTab(user: widget.user, isAdmin: true),
      AgentsTab(user: widget.user),
      AdminSettingsScreen(user: widget.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        indicatorColor: RentoraTheme.primary.withOpacity(0.15),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.directions_car_outlined),
              selectedIcon: Icon(Icons.directions_car),
              label: 'Vehicles'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Bookings'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Agents'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HOME TAB
// ─────────────────────────────────────────────

class AdminHomeTab extends StatelessWidget {
  final AppUser user;
  const AdminHomeTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rentora'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Vehicle>>(
        stream: FirebaseService.vehiclesStream(user.companyId),
        builder: (context, vSnap) {
          return StreamBuilder<List<Booking>>(
            stream: FirebaseService.bookingsStream(user.companyId),
            builder: (context, bSnap) {
              final vehicles = vSnap.data ?? [];
              final bookings = bSnap.data ?? [];
              final available =
                  vehicles.where((v) => v.status == 'available').length;
              final rented =
                  vehicles.where((v) => v.status == 'rented').length;

              final totalRevenue = bookings
                  .where((b) => b.status == 'completed')
                  .fold(0.0, (sum, b) => sum + b.totalAmount);

              final pending = bookings
                  .where((b) => b.remaining > 0 && b.status == 'active')
                  .length;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome, ${user.name.split(' ').first} 👋',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text("Here's your fleet overview",
                        style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 20),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        DashCard(
                          title: 'Total Vehicles',
                          value: '${vehicles.length}',
                          icon: Icons.directions_car,
                          color: RentoraTheme.primary,
                        ),
                        DashCard(
                          title: 'Available',
                          value: '$available',
                          icon: Icons.check_circle,
                          color: RentoraTheme.success,
                        ),
                        DashCard(
                          title: 'Rented',
                          value: '$rented',
                          icon: Icons.key,
                          color: RentoraTheme.error,
                        ),
                        DashCard(
                          title: 'Total Revenue',
                          value: 'Rs. ${totalRevenue.toStringAsFixed(0)}',
                          icon: Icons.attach_money,
                          color: Colors.teal,
                        ),
                      ],
                    ),
                    if (pending > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: RentoraTheme.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: RentoraTheme.warning.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber,
                                color: RentoraTheme.warning, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              '$pending booking${pending > 1 ? 's' : ''} with pending payment',
                              style: const TextStyle(
                                  color: RentoraTheme.warning,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Text('Recent Bookings',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    if (bookings.isEmpty)
                      const Center(
                          child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('No bookings yet',
                                  style: TextStyle(color: Colors.black45))))
                    else
                      ...bookings
                          .take(5)
                          .map((b) => BookingTile(
                        booking: b,
                        showAgent: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingDetailScreen(
                                booking: b, user: user),
                          ),
                        ),
                      )),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// VEHICLES TAB
// ─────────────────────────────────────────────

class VehiclesTab extends StatelessWidget {
  final AppUser user;
  final bool isAdmin;
  const VehiclesTab({super.key, required this.user, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet'),
        actions: isAdmin
            ? [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        VehicleFormScreen(user: user, vehicle: null))),
          )
        ]
            : null,
      ),
      body: StreamBuilder<List<Vehicle>>(
        stream: FirebaseService.vehiclesStream(user.companyId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final vehicles = snap.data ?? [];
          if (vehicles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.directions_car,
                      size: 80, color: Colors.black12),
                  const SizedBox(height: 16),
                  const Text('No vehicles added yet',
                      style: TextStyle(color: Colors.black45)),
                  if (isAdmin) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Vehicle'),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => VehicleFormScreen(
                                  user: user, vehicle: null))),
                    ),
                  ]
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: vehicles.length,
            itemBuilder: (context, i) => VehicleCard(
              vehicle: vehicles[i],
              isAdmin: isAdmin,
              onTap: () => isAdmin
                  ? Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => VehicleDetailScreen(
                          vehicle: vehicles[i], user: user)))
                  : null,
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// VEHICLE FORM (Add / Edit)
// ─────────────────────────────────────────────

class VehicleFormScreen extends StatefulWidget {
  final AppUser user;
  final Vehicle? vehicle;
  const VehicleFormScreen(
      {super.key, required this.user, required this.vehicle});

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _model = TextEditingController();
  final _plate = TextEditingController();
  final _price = TextEditingController();
  String _status = 'available';
  File? _imageFile;
  String _existingImageUrl = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.vehicle != null) {
      _name.text = widget.vehicle!.name;
      _model.text = widget.vehicle!.model;
      _plate.text = widget.vehicle!.plate;
      _price.text = widget.vehicle!.pricePerDay.toString();
      _status = widget.vehicle!.status;
      _existingImageUrl = widget.vehicle!.imageUrl;
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked != null && mounted) {
        setState(() => _imageFile = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open gallery. Please try again.')),
        );
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.photo_library, color: RentoraTheme.primary),
            SizedBox(width: 10),
            Text('Permission Required'),
          ],
        ),
        content: const Text(
          'Gallery access was denied.\n\n'
              'Please enable it in your device Settings → App Permissions → Photos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.settings, size: 16),
            label: const Text('Open Settings'),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      String imageUrl = _existingImageUrl;
      if (_imageFile != null) {
        imageUrl = await CloudinaryService.uploadImage(
          _imageFile!,
          folder: 'rentora/vehicles/${widget.user.companyId}',
        );
      }
      final v = Vehicle(
        id: widget.vehicle?.id ?? '',
        name: _name.text.trim(),
        model: _model.text.trim(),
        plate: _plate.text.trim(),
        pricePerDay: double.parse(_price.text),
        imageUrl: imageUrl,
        status: _status,
        companyId: widget.user.companyId,
      );
      if (widget.vehicle == null) {
        await FirebaseService.addVehicle(v);
      } else {
        await FirebaseService.updateVehicle(widget.vehicle!.id, v.toMap());
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title:
          Text(widget.vehicle == null ? 'Add Vehicle' : 'Edit Vehicle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBBCCEE)),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(_imageFile!,
                          fit: BoxFit.cover, width: double.infinity))
                      : _existingImageUrl.isNotEmpty
                      ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(_existingImageUrl,
                          fit: BoxFit.cover, width: double.infinity))
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_a_photo,
                          size: 40, color: RentoraTheme.primary),
                      SizedBox(height: 8),
                      Text('Tap to upload image',
                          style:
                          TextStyle(color: Colors.black45)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _field(_name, 'Vehicle Name', Icons.drive_file_rename_outline),
              const SizedBox(height: 14),
              _field(_model, 'Model', Icons.model_training),
              const SizedBox(height: 14),
              _field(_plate, 'Number Plate', Icons.badge),
              const SizedBox(height: 14),
              _field(_price, 'Price per Day (Rs.)', Icons.attach_money,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.info_outline)),
                items: ['available', 'rented', 'maintenance']
                    .map((s) => DropdownMenuItem(
                    value: s, child: Text(s.toUpperCase())))
                    .toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : Text(widget.vehicle == null
                      ? 'Add Vehicle'
                      : 'Update Vehicle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {TextInputType? keyboardType}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }
}

// ─────────────────────────────────────────────
// VEHICLE DETAIL
// ─────────────────────────────────────────────

class VehicleDetailScreen extends StatelessWidget {
  final Vehicle vehicle;
  final AppUser user;
  const VehicleDetailScreen(
      {super.key, required this.vehicle, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(vehicle.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        VehicleFormScreen(user: user, vehicle: vehicle))),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Vehicle'),
                  content: const Text(
                      'Are you sure you want to delete this vehicle?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true) {
                await FirebaseService.deleteVehicle(vehicle.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vehicle.imageUrl.isNotEmpty)
              Image.network(vehicle.imageUrl,
                  width: double.infinity, height: 220, fit: BoxFit.cover)
            else
              Container(
                height: 220,
                color: RentoraTheme.primary.withOpacity(0.1),
                child: const Center(
                    child: Icon(Icons.directions_car,
                        size: 80, color: RentoraTheme.primary)),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text(vehicle.name,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800))),
                    StatusBadge(vehicle.status),
                  ]),
                  const SizedBox(height: 8),
                  Text(vehicle.model,
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 16)),
                  const SizedBox(height: 16),
                  _info('Number Plate', vehicle.plate, Icons.badge),
                  _info('Daily Rate',
                      'Rs. ${vehicle.pricePerDay.toStringAsFixed(0)}',
                      Icons.attach_money),
                  _info('Status', vehicle.status.toUpperCase(),
                      Icons.info_outline),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: RentoraTheme.primary),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(color: Colors.black54, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BOOKINGS TAB
// ─────────────────────────────────────────────

class BookingsTab extends StatefulWidget {
  final AppUser user;
  final bool isAdmin;
  const BookingsTab({super.key, required this.user, required this.isAdmin});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'Active'), Tab(text: 'Completed')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => BookingFormScreen(user: widget.user))),
          )
        ],
      ),
      body: StreamBuilder<List<Booking>>(
        stream: FirebaseService.bookingsStream(widget.user.companyId),
        builder: (context, snap) {
          final all = snap.data ?? [];
          final active = all.where((b) => b.status == 'active').toList();
          final completed =
          all.where((b) => b.status == 'completed').toList();
          return TabBarView(
            controller: _tabs,
            children: [
              _bookingList(context, active, canDelete: false),
              _bookingList(context, completed, canDelete: widget.isAdmin),
            ],
          );
        },
      ),
    );
  }

  Widget _bookingList(BuildContext context, List<Booking> bookings,
      {bool canDelete = false}) {
    if (bookings.isEmpty) {
      return const Center(
          child:
          Text('No bookings', style: TextStyle(color: Colors.black45)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: bookings.length,
      itemBuilder: (context, i) {
        final booking = bookings[i];
        return canDelete
            ? _DismissibleBookingTile(
          booking: booking,
          isAdmin: widget.isAdmin,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => BookingDetailScreen(
                      booking: booking, user: widget.user))),
        )
            : BookingTile(
          booking: booking,
          showAgent: widget.isAdmin,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => BookingDetailScreen(
                      booking: booking, user: widget.user))),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// DISMISSIBLE BOOKING TILE
// ─────────────────────────────────────────────

class _DismissibleBookingTile extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;
  final bool isAdmin;
  const _DismissibleBookingTile(
      {required this.booking, this.onTap, required this.isAdmin});

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 10),
            Text('Delete Booking'),
          ],
        ),
        content: Text(
            'Delete booking for ${booking.customerName}? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(booking.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) async {
        await FirebaseService.deleteBooking(booking.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking for ${booking.customerName} deleted'),
              backgroundColor: RentoraTheme.error,
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Delete',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: BookingTile(booking: booking, onTap: onTap, showAgent: isAdmin),
    );
  }
}

// ─────────────────────────────────────────────
// BOOKING FORM
// ─────────────────────────────────────────────

class BookingFormScreen extends StatefulWidget {
  final AppUser user;
  const BookingFormScreen({super.key, required this.user});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _form = GlobalKey<FormState>();
  final _customer = TextEditingController();
  final _contact = TextEditingController();
  final _cnic = TextEditingController();
  final _advance = TextEditingController();

  DateTime? _start;
  DateTime? _end;
  Vehicle? _selectedVehicle;
  List<Vehicle> _vehicles = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    FirebaseService.vehiclesStream(widget.user.companyId).listen((v) {
      setState(
              () => _vehicles = v.where((x) => x.status == 'available').toList());
    });
  }

  double get _total {
    if (_start == null || _end == null || _selectedVehicle == null) return 0;
    final days = _end!.difference(_start!).inDays;
    return days * _selectedVehicle!.pricePerDay;
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? now : (_start ?? now),
      firstDate: isStart ? now : (_start ?? now),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date != null) setState(() => isStart ? _start = date : _end = date);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select rental dates')));
      return;
    }
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a vehicle')));
      return;
    }
    setState(() => _loading = true);
    try {
      final advance = double.tryParse(_advance.text) ?? 0;
      final booking = Booking(
        id: '',
        customerName: _customer.text.trim(),
        contact: _contact.text.trim(),
        cnic: _cnic.text.trim(),
        vehicleId: _selectedVehicle!.id,
        vehicleName: _selectedVehicle!.name,
        startDate: _start!,
        endDate: _end!,
        totalAmount: _total,
        advancePaid: advance,
        remaining: _total - advance,
        status: 'active',
        companyId: widget.user.companyId,
        createdBy: widget.user.uid,
      );
      await FirebaseService.createBooking(booking);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('New Booking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Customer Info',
                  style:
                  TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customer,
                decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    prefixIcon: Icon(Icons.person)),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contact,
                decoration: const InputDecoration(
                    labelText: 'Contact Number',
                    prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cnic,
                decoration: const InputDecoration(
                    labelText: 'CNIC', prefixIcon: Icon(Icons.badge)),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              const Text('Vehicle & Dates',
                  style:
                  TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              DropdownButtonFormField<Vehicle>(
                value: _selectedVehicle,
                decoration: const InputDecoration(
                    labelText: 'Select Vehicle',
                    prefixIcon: Icon(Icons.directions_car)),
                items: _vehicles
                    .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text('${v.name} - ${v.plate}')))
                    .toList(),
                onChanged: (v) => setState(() => _selectedVehicle = v),
                validator: (v) => v == null ? 'Select a vehicle' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _dateTile(
                        _start != null ? fmt.format(_start!) : 'Start Date',
                        Icons.calendar_today,
                            () => _pickDate(true)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dateTile(
                        _end != null ? fmt.format(_end!) : 'End Date',
                        Icons.calendar_month,
                            () => _pickDate(false)),
                  ),
                ],
              ),
              if (_total > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: RentoraTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('Rs. ${_total.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: RentoraTheme.primary,
                              fontSize: 16)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _advance,
                decoration: const InputDecoration(
                    labelText: 'Advance Payment (Rs.)',
                    prefixIcon: Icon(Icons.payments)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : const Text('Create Booking'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateTile(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBBCCEE)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: RentoraTheme.primary),
            const SizedBox(width: 8),
            Expanded(
                child: Text(text,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BOOKING DETAIL
// ─────────────────────────────────────────────

class BookingDetailScreen extends StatefulWidget {
  final Booking booking;
  final AppUser user;
  const BookingDetailScreen(
      {super.key, required this.booking, required this.user});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final _damage = TextEditingController();
  final _extra = TextEditingController();
  bool _loading = false;

  Future<void> _complete() async {
    setState(() => _loading = true);
    try {
      await FirebaseService.completeBooking(
        widget.booking.id,
        widget.booking.vehicleId,
        _damage.text.trim().isEmpty ? null : _damage.text.trim(),
        double.tryParse(_extra.text),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final fmt = DateFormat('dd MMM yyyy');
    final days = b.endDate.difference(b.startDate).inDays;
    final isAdmin = widget.user.role == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(b.customerName,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800))),
                      StatusBadge(b.status),
                    ]),
                    const Divider(height: 24),
                    _row(Icons.directions_car, 'Vehicle', b.vehicleName),
                    _row(Icons.phone, 'Contact', b.contact),
                    _row(Icons.badge, 'CNIC', b.cnic),
                    _row(Icons.calendar_today, 'Start',
                        fmt.format(b.startDate)),
                    _row(
                        Icons.calendar_month, 'End', fmt.format(b.endDate)),
                    _row(Icons.timelapse, 'Duration', '$days days'),
                    const Divider(height: 24),
                    _row(Icons.attach_money, 'Total',
                        'Rs. ${b.totalAmount.toStringAsFixed(0)}',
                        bold: true),
                    _row(Icons.payment, 'Advance Paid',
                        'Rs. ${b.advancePaid.toStringAsFixed(0)}'),
                    _row(Icons.money_off, 'Remaining',
                        'Rs. ${b.remaining.toStringAsFixed(0)}',
                        color: b.remaining > 0
                            ? RentoraTheme.error
                            : RentoraTheme.success),
                    if (b.damageNotes != null) ...[
                      const Divider(height: 24),
                      _row(Icons.warning_amber, 'Damage Notes',
                          b.damageNotes!),
                    ],
                    if (b.extraCharges != null)
                      _row(Icons.add_circle_outline, 'Extra Charges',
                          'Rs. ${b.extraCharges!.toStringAsFixed(0)}'),

                    if (isAdmin && b.createdBy.isNotEmpty) ...[
                      const Divider(height: 24),
                      const Text(
                        'Booking Agent',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.black54),
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<AppUser?>(
                        future: FirebaseService.getUser(b.createdBy),
                        builder: (context, snap) {
                          if (snap.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)));
                          }
                          final agent = snap.data;
                          if (agent == null) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.indigo.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                  Colors.indigo.withOpacity(0.15),
                                  child: Text(
                                    agent.name.isNotEmpty
                                        ? agent.name[0].toUpperCase()
                                        : 'A',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Colors.indigo,
                                        fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        agent.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: Colors.indigo),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        agent.email,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black45),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color:
                                    Colors.indigo.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'AGENT',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.indigo,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (b.status == 'active') ...[
              const SizedBox(height: 24),
              const Text('Complete Return',
                  style:
                  TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                controller: _damage,
                decoration: const InputDecoration(
                    labelText: 'Damage Notes (optional)',
                    prefixIcon: Icon(Icons.warning_amber)),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _extra,
                decoration: const InputDecoration(
                    labelText: 'Extra Charges (Rs.)',
                    prefixIcon: Icon(Icons.add_circle_outline)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark as Completed'),
                  onPressed: _loading ? null : _complete,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: RentoraTheme.primary),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(color: Colors.black54, fontSize: 14)),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontWeight:
                    bold ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 14,
                    color: color)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// AGENTS TAB
// ─────────────────────────────────────────────

class AgentsTab extends StatelessWidget {
  final AppUser user;
  const AgentsTab({super.key, required this.user});

  Future<void> _deleteAgent(BuildContext context, AppUser agent) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_remove, color: Colors.red),
            SizedBox(width: 10),
            Text('Delete Agent'),
          ],
        ),
        content: Text(
            'Delete agent "${agent.name}"? They will no longer be able to access the app.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseService.deleteAgent(agent.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${agent.name} has been removed'),
            backgroundColor: RentoraTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => AddAgentScreen(user: user))),
          ),
        ],
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: FirebaseService.agentsStream(user.companyId),
        builder: (context, snap) {
          final agents = snap.data ?? [];
          if (agents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline,
                      size: 72, color: Colors.black12),
                  const SizedBox(height: 16),
                  const Text('No agents yet',
                      style:
                      TextStyle(color: Colors.black45, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Tap + to add your first agent',
                      style:
                      TextStyle(color: Colors.black38, fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: agents.length,
            itemBuilder: (context, i) {
              final a = agents[i];
              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  leading: CircleAvatar(
                    backgroundColor: a.disabled
                        ? Colors.grey.shade400
                        : RentoraTheme.primary,
                    child: Text(
                        a.name.isNotEmpty
                            ? a.name[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(a.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.email,
                          style: const TextStyle(fontSize: 12)),
                      if (a.disabled)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Disabled',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: !a.disabled,
                        onChanged: (v) => FirebaseService.updateAgentStatus(
                            a.uid, !v),
                        activeColor: RentoraTheme.success,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 22),
                        tooltip: 'Delete Agent',
                        onPressed: () => _deleteAgent(context, a),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ADD AGENT SCREEN
// ─────────────────────────────────────────────

class AddAgentScreen extends StatefulWidget {
  final AppUser user;
  const AddAgentScreen({super.key, required this.user});

  @override
  State<AddAgentScreen> createState() => _AddAgentScreenState();
}

class _AddAgentScreenState extends State<AddAgentScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _create() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseService.createAgent(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        companyId: widget.user.companyId,
      );
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _CredentialsDialog(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Agent')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            children: [
              const SizedBox(height: 8),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: 'Agent Full Name',
                    prefixIcon: Icon(Icons.person)),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(
                    labelText: 'Email', prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscure = !_obscure),
                  ),
                ),
                obscureText: _obscure,
                validator: (v) =>
                (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _create,
                  child: _loading
                      ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : const Text('Create Agent'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CREDENTIALS DIALOG
// ─────────────────────────────────────────────

class _CredentialsDialog extends StatefulWidget {
  final String name;
  final String email;
  final String password;
  const _CredentialsDialog({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  State<_CredentialsDialog> createState() => _CredentialsDialogState();
}

class _CredentialsDialogState extends State<_CredentialsDialog> {
  bool _obscurePassword = true;

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label copied!')));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: RentoraTheme.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_circle,
                color: RentoraTheme.success, size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Agent Created!',
                style:
                TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Share these credentials with ${widget.name}:',
              style: const TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 16),
          _credRow(
            label: 'Email',
            value: widget.email,
            icon: Icons.email_outlined,
            onCopy: () => _copy(widget.email, 'Email'),
          ),
          const SizedBox(height: 10),
          _credRow(
            label: 'Password',
            value: _obscurePassword
                ? '•' * widget.password.length
                : widget.password,
            icon: Icons.lock_outline,
            onCopy: () => _copy(widget.password, 'Password'),
            trailing: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility
                    : Icons.visibility_off,
                size: 18,
                color: RentoraTheme.primary,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Save these now — the password cannot be retrieved later.',
                    style: TextStyle(
                        fontSize: 11, color: Colors.blue, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _credRow({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onCopy,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: RentoraTheme.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBCCEE)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: RentoraTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black45,
                        fontWeight: FontWeight.w600)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (trailing != null) trailing,
          IconButton(
            icon: const Icon(Icons.copy,
                size: 16, color: RentoraTheme.primary),
            onPressed: onCopy,
            tooltip: 'Copy $label',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ADMIN SETTINGS SCREEN
// ─────────────────────────────────────────────

class AdminSettingsScreen extends StatelessWidget {
  final AppUser user;
  const AdminSettingsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: RentoraTheme.primary,
                    child: Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(user.email,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 13)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: RentoraTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Admin',
                            style: TextStyle(
                                color: RentoraTheme.primary,
                                fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('App',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _tile(context, 'Privacy Policy', Icons.privacy_tip_outlined, () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen()));
          }),
          _tile(context, 'Contact Us', Icons.contact_support_outlined, () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ContactUsScreen()));
          }),
          _tile(context, 'About Rentora', Icons.info_outline, () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AboutScreen()));
          }),
          const SizedBox(height: 8),
          const Text('Account',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          // ── FIXED: uses AppLogout instead of FirebaseService.signOut() ──
          _tile(context, 'Logout', Icons.logout, () async {
            await AppLogout.logout(context);
          }, color: RentoraTheme.error),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String title, IconData icon,
      VoidCallback onTap,
      {Color? color}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color ?? RentoraTheme.primary),
        title: Text(title,
            style: TextStyle(fontWeight: FontWeight.w500, color: color)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black26),
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ABOUT SCREEN
// ─────────────────────────────────────────────

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Rentora')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [RentoraTheme.primary, RentoraTheme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                      color: RentoraTheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ],
              ),
              child: const Icon(Icons.directions_car,
                  color: Colors.white, size: 50),
            ),
            const SizedBox(height: 16),
            const Text('Rentora',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: RentoraTheme.primary)),
            const Text('Smart Rentals. Total Control.',
                style: TextStyle(color: Colors.black54, fontSize: 14)),
            const SizedBox(height: 30),
            _section('What is Rentora?',
                'Rentora is a professional car rental management application built for small and medium businesses. It helps you manage your fleet, bookings, payments, and agents all in one place.'),
            _section('Role-Based Access',
                'Rentora supports two roles — Admin (business owner) and Agent (staff). Admins have full control, while agents can manage bookings and record payments.'),
            _section('Cloud-Powered',
                'All data is securely stored in Firebase with real-time syncing across devices. Vehicle images are stored via Cloudinary for fast, reliable access.'),
            _section('Our Mission',
                'To empower rental businesses of all sizes with simple, powerful tools that scale with them — from a one-car operation to a full fleet.'),
            const SizedBox(height: 20),
            const Text('© 2024 Rentora. All rights reserved.',
                style: TextStyle(color: Colors.black38, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: RentoraTheme.primary)),
          const SizedBox(height: 6),
          Text(body,
              style: const TextStyle(
                  color: Colors.black54, fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PRIVACY POLICY SCREEN
// ─────────────────────────────────────────────

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            if (request.url.startsWith('http') ||
                request.url.startsWith('https')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    _loadHtml();
  }

  Future<void> _loadHtml() async {
    final html = await rootBundle.loadString('assets/privacy_policy.html');
    await _controller.loadHtmlString(html, baseUrl: 'about:blank');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2979FF)),
                  SizedBox(height: 12),
                  Text(
                    'Loading privacy policy…',
                    style: TextStyle(color: Color(0xFF8898AA), fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CONTACT US SCREEN
// ─────────────────────────────────────────────

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [RentoraTheme.primary, RentoraTheme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.contact_support_outlined,
                      color: Colors.white, size: 36),
                  SizedBox(height: 12),
                  Text(
                    'Get in Touch',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "We're here to help. Reach out to us anytime.",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'PATRICIA IW ROSSELL LLC',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: RentoraTheme.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: RentoraTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.email_outlined,
                          color: RentoraTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Colors.black54)),
                          SizedBox(height: 2),
                          Text('bagay810@gmail.com',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: RentoraTheme.primary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy,
                          color: RentoraTheme.primary, size: 20),
                      tooltip: 'Copy email',
                      onPressed: () {
                        Clipboard.setData(
                            const ClipboardData(text: 'bagay810@gmail.com'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email copied to clipboard!'),
                            backgroundColor: RentoraTheme.success,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.schedule_outlined, size: 18, color: Colors.blue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'We typically respond within 5 business days.',
                      style:
                      TextStyle(fontSize: 13, color: Colors.blue, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}