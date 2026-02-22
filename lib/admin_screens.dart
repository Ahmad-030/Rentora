// admin_screens.dart — Admin Dashboard, Vehicles, Bookings, Agents, Settings

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'shared.dart';

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
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.directions_car_outlined), selectedIcon: Icon(Icons.directions_car), label: 'Vehicles'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Agents'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
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
              child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              final available = vehicles.where((v) => v.status == 'available').length;
              final rented = vehicles.where((v) => v.status == 'rented').length;
              final today = DateTime.now();
              final todayRevenue = bookings
                  .where((b) =>
              b.status == 'completed' &&
                  b.endDate.year == today.year &&
                  b.endDate.month == today.month &&
                  b.endDate.day == today.day)
                  .fold(0.0, (sum, b) => sum + b.totalAmount);
              final pending = bookings.where((b) => b.remaining > 0 && b.status == 'active').length;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome, ${user.name.split(' ').first} 👋',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Here\'s your fleet overview',
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
                          title: "Today's Revenue",
                          value: 'Rs. ${todayRevenue.toStringAsFixed(0)}',
                          icon: Icons.attach_money,
                          color: Colors.teal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Recent Bookings',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    if (bookings.isEmpty)
                      const Center(
                          child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('No bookings yet', style: TextStyle(color: Colors.black45))))
                    else
                      ...bookings.take(5).map((b) => BookingTile(booking: b)),
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
// VEHICLES TAB (shared between Admin & Agent view)
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
                    builder: (_) => VehicleFormScreen(user: user, vehicle: null))),
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
                  Icon(Icons.directions_car, size: 80, color: Colors.black12),
                  const SizedBox(height: 16),
                  const Text('No vehicles added yet', style: TextStyle(color: Colors.black45)),
                  if (isAdmin) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Vehicle'),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => VehicleFormScreen(user: user, vehicle: null))),
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
                      builder: (_) => VehicleDetailScreen(vehicle: vehicles[i], user: user)))
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
  const VehicleFormScreen({super.key, required this.user, required this.vehicle});

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
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _imageFile = File(picked.path));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.vehicle == null ? 'Add Vehicle' : 'Edit Vehicle')),
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
                      child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity))
                      : _existingImageUrl.isNotEmpty
                      ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(_existingImageUrl,
                          fit: BoxFit.cover, width: double.infinity))
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_a_photo, size: 40, color: RentoraTheme.primary),
                      SizedBox(height: 8),
                      Text('Tap to upload image',
                          style: TextStyle(color: Colors.black45)),
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
                decoration: const InputDecoration(labelText: 'Status', prefixIcon: Icon(Icons.info_outline)),
                items: ['available', 'rented', 'maintenance']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
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
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(widget.vehicle == null ? 'Add Vehicle' : 'Update Vehicle'),
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
  const VehicleDetailScreen({super.key, required this.vehicle, required this.user});

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
                    builder: (_) => VehicleFormScreen(user: user, vehicle: vehicle))),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Vehicle'),
                  content: const Text('Are you sure you want to delete this vehicle?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
                    child: Icon(Icons.directions_car, size: 80, color: RentoraTheme.primary)),
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
                                fontSize: 22, fontWeight: FontWeight.w800))),
                    StatusBadge(vehicle.status),
                  ]),
                  const SizedBox(height: 8),
                  Text(vehicle.model, style: const TextStyle(color: Colors.black54, fontSize: 16)),
                  const SizedBox(height: 16),
                  _info('Number Plate', vehicle.plate, Icons.badge),
                  _info('Daily Rate', 'Rs. ${vehicle.pricePerDay.toStringAsFixed(0)}', Icons.attach_money),
                  _info('Status', vehicle.status.toUpperCase(), Icons.info_outline),
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
          Text('$label: ', style: const TextStyle(color: Colors.black54, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BOOKINGS TAB (shared admin + agent)
// ─────────────────────────────────────────────

class BookingsTab extends StatefulWidget {
  final AppUser user;
  final bool isAdmin;
  const BookingsTab({super.key, required this.user, required this.isAdmin});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> with SingleTickerProviderStateMixin {
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
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => BookingFormScreen(user: widget.user))),
          )
        ],
      ),
      body: StreamBuilder<List<Booking>>(
        stream: FirebaseService.bookingsStream(widget.user.companyId),
        builder: (context, snap) {
          final all = snap.data ?? [];
          final active = all.where((b) => b.status == 'active').toList();
          final completed = all.where((b) => b.status == 'completed').toList();
          return TabBarView(
            controller: _tabs,
            children: [
              _bookingList(context, active),
              _bookingList(context, completed),
            ],
          );
        },
      ),
    );
  }

  Widget _bookingList(BuildContext context, List<Booking> bookings) {
    if (bookings.isEmpty) {
      return const Center(child: Text('No bookings', style: TextStyle(color: Colors.black45)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: bookings.length,
      itemBuilder: (context, i) => BookingTile(
        booking: bookings[i],
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    BookingDetailScreen(booking: bookings[i], user: widget.user))),
      ),
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
      setState(() => _vehicles = v.where((x) => x.status == 'available').toList());
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customer,
                decoration: const InputDecoration(
                    labelText: 'Customer Name', prefixIcon: Icon(Icons.person)),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contact,
                decoration: const InputDecoration(
                    labelText: 'Contact Number', prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cnic,
                decoration:
                const InputDecoration(labelText: 'CNIC', prefixIcon: Icon(Icons.badge)),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              const Text('Vehicle & Dates',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              DropdownButtonFormField<Vehicle>(
                value: _selectedVehicle,
                decoration: const InputDecoration(
                    labelText: 'Select Vehicle', prefixIcon: Icon(Icons.directions_car)),
                items: _vehicles
                    .map((v) => DropdownMenuItem(value: v, child: Text('${v.name} - ${v.plate}')))
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
                    labelText: 'Advance Payment (Rs.)', prefixIcon: Icon(Icons.payments)),
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
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
  const BookingDetailScreen({super.key, required this.booking, required this.user});

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final fmt = DateFormat('dd MMM yyyy');
    final days = b.endDate.difference(b.startDate).inDays;

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
                                  fontSize: 20, fontWeight: FontWeight.w800))),
                      StatusBadge(b.status),
                    ]),
                    const Divider(height: 24),
                    _row(Icons.directions_car, 'Vehicle', b.vehicleName),
                    _row(Icons.phone, 'Contact', b.contact),
                    _row(Icons.badge, 'CNIC', b.cnic),
                    _row(Icons.calendar_today, 'Start', fmt.format(b.startDate)),
                    _row(Icons.calendar_month, 'End', fmt.format(b.endDate)),
                    _row(Icons.timelapse, 'Duration', '$days days'),
                    const Divider(height: 24),
                    _row(Icons.attach_money, 'Total', 'Rs. ${b.totalAmount.toStringAsFixed(0)}',
                        bold: true),
                    _row(Icons.payment, 'Advance Paid',
                        'Rs. ${b.advancePaid.toStringAsFixed(0)}'),
                    _row(Icons.money_off, 'Remaining',
                        'Rs. ${b.remaining.toStringAsFixed(0)}',
                        color: b.remaining > 0 ? RentoraTheme.error : RentoraTheme.success),
                    if (b.damageNotes != null) ...[
                      const Divider(height: 24),
                      _row(Icons.warning_amber, 'Damage Notes', b.damageNotes!),
                    ],
                    if (b.extraCharges != null)
                      _row(Icons.add_circle_outline, 'Extra Charges',
                          'Rs. ${b.extraCharges!.toStringAsFixed(0)}'),
                  ],
                ),
              ),
            ),
            if (b.status == 'active') ...[
              const SizedBox(height: 24),
              const Text('Complete Return',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                controller: _damage,
                decoration: const InputDecoration(
                    labelText: 'Damage Notes (optional)', prefixIcon: Icon(Icons.warning_amber)),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _extra,
                decoration: const InputDecoration(
                    labelText: 'Extra Charges (Rs.)', prefixIcon: Icon(Icons.add_circle_outline)),
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
          Text('$label: ', style: const TextStyle(color: Colors.black54, fontSize: 14)),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => AddAgentScreen(user: user))),
          ),
        ],
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: FirebaseService.agentsStream(user.companyId),
        builder: (context, snap) {
          final agents = snap.data ?? [];
          if (agents.isEmpty) {
            return const Center(
                child: Text('No agents yet', style: TextStyle(color: Colors.black45)));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: agents.length,
            itemBuilder: (context, i) {
              final a = agents[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: RentoraTheme.primary,
                    child: Text(a.name.isNotEmpty ? a.name[0].toUpperCase() : 'A',
                        style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(a.email),
                  trailing: Switch(
                    value: !a.disabled,
                    onChanged: (v) => FirebaseService.updateAgentStatus(a.uid, !v),
                    activeColor: RentoraTheme.success,
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
// ─────────────────────────────────────────────
// ADD AGENT SCREEN  (updated — no sign-out warning)
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
      // Show credentials dialog — admin stays logged in
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                    labelText: 'Agent Full Name', prefixIcon: Icon(Icons.person)),
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
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                obscureText: _obscure,
                validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
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
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
// CREDENTIALS DIALOG — shown after agent is created
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: RentoraTheme.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_circle, color: RentoraTheme.success, size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Agent Created!',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
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
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
                    style: TextStyle(fontSize: 11, color: Colors.blue, height: 1.4),
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
            icon: const Icon(Icons.copy, size: 16, color: RentoraTheme.primary),
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
          // Profile card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: RentoraTheme.primary,
                    child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
                        style:
                        const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(user.email, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: RentoraTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Admin',
                            style: TextStyle(color: RentoraTheme.primary, fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('App', style: TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _tile(context, 'Privacy Policy', Icons.privacy_tip_outlined, () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
          }),
          _tile(context, 'Contact Us', Icons.contact_support_outlined, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactUsScreen()));
          }),
          _tile(context, 'About Rentora', Icons.info_outline, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
          }),
          const SizedBox(height: 8),
          const Text('Account',
              style: TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _tile(context, 'Logout', Icons.logout, () async {
            await FirebaseService.signOut();
          }, color: RentoraTheme.error),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String title, IconData icon, VoidCallback onTap,
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
// ABOUT SCREEN (HTML-style with Flutter)
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
                color: RentoraTheme.primary,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                      color: RentoraTheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ],
              ),
              child: const Icon(Icons.directions_car, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 16),
            const Text('Rentora',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: RentoraTheme.primary)),
            const Text('Smart Rentals. Total Control.',
                style: TextStyle(color: Colors.black54, fontSize: 14)),
            const SizedBox(height: 6),
            const Text('Version 1.0.0',
                style: TextStyle(color: Colors.black38, fontSize: 12)),
            const SizedBox(height: 30),
            _section('What is Rentora?',
                'Rentora is a professional car rental management application built for small and medium businesses. It helps you manage your fleet, bookings, payments, and agents all in one place.'),
            _section('Role-Based Access',
                'Rentora supports two roles — Admin (business owner) and Agent (staff). Admins have full control, while agents can manage bookings and record payments.'),
            _section('Cloud-Powered',
                'All data is securely stored in Firebase with real-time syncing across devices. Vehicle images are stored in Firebase Cloud Storage for fast, reliable access.'),
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
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: RentoraTheme.primary)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(color: Colors.black54, fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PRIVACY POLICY SCREEN
// ─────────────────────────────────────────────

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Privacy Policy',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: RentoraTheme.primary)),
            const SizedBox(height: 4),
            const Text('Last updated: January 2024',
                style: TextStyle(color: Colors.black38, fontSize: 12)),
            const SizedBox(height: 24),
            _section('1. Information We Collect',
                'Rentora collects business information including company name, owner details, contact information, vehicle data, booking records, and payment information. This data is necessary to operate the rental management service.'),
            _section('2. How We Use Your Information',
                'The information collected is used solely to operate and improve the Rentora service. We do not sell, trade, or share your personal or business information with third parties, except as required by law.'),
            _section('3. Data Storage & Security',
                'All data is securely stored using Google Firebase, which employs industry-standard encryption and security practices. Access to data is strictly limited to authorized users within your company account.'),
            _section('4. Role-Based Access',
                'Your company data is only accessible by users you authorize (Admins and Agents). Admin users have full access, while Agent access is restricted to operational features only.'),
            _section('5. Data Retention',
                'Your data is retained as long as you maintain an active account on Rentora. Upon account deletion, all associated data will be permanently removed within 30 days.'),
            _section('6. Cookies & Tracking',
                'Rentora does not use cookies or tracking technologies for marketing purposes. Firebase may collect anonymous usage statistics to improve app performance.'),
            _section('7. Children\'s Privacy',
                'Rentora is a business application not intended for use by individuals under the age of 18. We do not knowingly collect data from minors.'),
            _section('8. Changes to This Policy',
                'We may update this Privacy Policy from time to time. Changes will be notified through the app. Continued use of the service after changes constitutes acceptance of the updated policy.'),
            _section('9. Contact',
                'If you have any questions about this Privacy Policy, please contact us at privacy@rentora.app'),
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
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(color: Colors.black54, fontSize: 14, height: 1.6)),
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
            const Text('Get in Touch',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: RentoraTheme.primary)),
            const SizedBox(height: 8),
            const Text("We're here to help. Reach out to us anytime.",
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 28),
            _contactCard(Icons.email_outlined, 'Email Support', 'support@rentora.app',
                'For general inquiries and technical support'),
            const SizedBox(height: 14),
            _contactCard(Icons.phone_outlined, 'Phone Support', '+1 (800) RENTORA',
                'Mon–Fri, 9 AM to 6 PM'),
            const SizedBox(height: 14),
            _contactCard(Icons.chat_bubble_outline, 'Live Chat', 'Available in app',
                'Chat with our support team directly'),
            const SizedBox(height: 14),
            _contactCard(Icons.language_outlined, 'Website', 'www.rentora.app',
                'Documentation and FAQs'),
            const SizedBox(height: 30),
            const Text('Send us a message',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 14),
            const TextField(
              decoration: InputDecoration(
                  labelText: 'Your Name', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                  labelText: 'Your Email', prefixIcon: Icon(Icons.email_outlined)),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                  labelText: 'Subject', prefixIcon: Icon(Icons.subject)),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                  labelText: 'Message', prefixIcon: Icon(Icons.message_outlined)),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Send Message'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message sent! We\'ll respond within 24 hours.')));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactCard(IconData icon, String title, String value, String subtitle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: RentoraTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: RentoraTheme.primary),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(value,
                    style: const TextStyle(color: RentoraTheme.primary, fontSize: 13)),
                Text(subtitle,
                    style: const TextStyle(color: Colors.black45, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}