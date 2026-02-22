// agent_screens.dart — Agent Dashboard

import 'package:flutter/material.dart';
import 'shared.dart';
import 'admin_screens.dart' show BookingsTab, VehiclesTab, PrivacyPolicyScreen, ContactUsScreen, AboutScreen;

class AgentDashboard extends StatefulWidget {
  final AppUser user;
  const AgentDashboard({super.key, required this.user});

  @override
  State<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard> {
  int _tab = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      AgentHomeTab(user: widget.user),
      BookingsTab(user: widget.user, isAdmin: false),
      VehiclesTab(user: widget.user, isAdmin: false),
      AgentSettingsScreen(user: widget.user),
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
              icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Bookings'),
          NavigationDestination(
              icon: Icon(Icons.directions_car_outlined),
              selectedIcon: Icon(Icons.directions_car),
              label: 'Fleet'),
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
// AGENT HOME
// ─────────────────────────────────────────────

class AgentHomeTab extends StatelessWidget {
  final AppUser user;
  const AgentHomeTab({super.key, required this.user});

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
              child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'G',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Booking>>(
        stream: FirebaseService.bookingsStream(user.companyId),
        builder: (context, snap) {
          final bookings = snap.data ?? [];
          final myBookings = bookings.where((b) => b.createdBy == user.uid).toList();
          final active = myBookings.where((b) => b.status == 'active').length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, ${user.name.split(' ').first} 👋',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text("Here's your activity",
                    style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: DashCard(
                        title: 'My Bookings',
                        value: '${myBookings.length}',
                        icon: Icons.calendar_month,
                        color: RentoraTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DashCard(
                        title: 'Active',
                        value: '$active',
                        icon: Icons.key,
                        color: RentoraTheme.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Recent Bookings',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (myBookings.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No bookings yet', style: TextStyle(color: Colors.black45)),
                    ),
                  )
                else
                  ...myBookings.take(5).map((b) => BookingTile(booking: b)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// AGENT SETTINGS
// ─────────────────────────────────────────────

class AgentSettingsScreen extends StatelessWidget {
  final AppUser user;
  const AgentSettingsScreen({super.key, required this.user});

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
                    child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(user.email,
                          style: const TextStyle(color: Colors.black54, fontSize: 13)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Agent',
                            style: TextStyle(color: Colors.green, fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('App',
              style: TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _tile(context, 'Privacy Policy', Icons.privacy_tip_outlined, () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
          }),
          _tile(context, 'Contact Us', Icons.contact_support_outlined, () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ContactUsScreen()));
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
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black26),
        onTap: onTap,
      ),
    );
  }
}