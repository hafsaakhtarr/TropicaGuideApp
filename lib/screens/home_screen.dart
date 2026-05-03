import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_config.dart';
import 'itinerary_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedTripId;

  @override
  Widget build(BuildContext context) {
    return selectedTripId == null
        ? _buildTripsListView()
        : ItineraryScreen(
            tripId: selectedTripId!,
            userId: widget.userId,
            onBack: () => setState(() => selectedTripId = null),
          );
  }

  Widget _buildTripsListView() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('travelers')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('TropicaGuide'),
              elevation: 0,
            ),
            body: const Center(child: Text('No data found')),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        List tripIds = userData['trips'] ?? [];

        return Scaffold(
          appBar: AppBar(
            title: const Text('TropicaGuide'),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => AuthService.signOut(),
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Trips',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (tripIds.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              const Text(
                                'No trips yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _showCreateTripDialog(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00D084),
                                ),
                                child: const Text(
                                  'Create First Trip',
                                  style: TextStyle(
                                    color: Color(0xFF0A1929),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: tripIds
                              .map((tripId) => _buildTripCard(tripId))
                              .toList(),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showCreateTripDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('New Trip'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D084),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTripCard(String tripId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('trips').doc(tripId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        Map<String, dynamic> trip = snapshot.data!.data() as Map<String, dynamic>;

        return GestureDetector(
          onTap: () => setState(() => selectedTripId = tripId),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A4A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00D084),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        trip['name'] ?? 'Untitled Trip',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: Color(0xFF00D084)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${(trip['activities'] ?? []).length} activities',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateTripDialog() {
    final nameController = TextEditingController();
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D2D3E),
        title: const Text(
          'Create New Trip',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Trip Name',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1A3A4A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: startDateController,
                style: const TextStyle(color: Colors.white),
                readOnly: true,
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    startDateController.text = picked.toString().split(' ')[0];
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Start Date',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1A3A4A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: endDateController,
                style: const TextStyle(color: Colors.white),
                readOnly: true,
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    endDateController.text = picked.toString().split(' ')[0];
                  }
                },
                decoration: InputDecoration(
                  hintText: 'End Date',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1A3A4A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  startDateController.text.isNotEmpty &&
                  endDateController.text.isNotEmpty) {
                try {
                  await TripService.createTrip(
                    widget.userId,
                    nameController.text,
                    DateTime.parse(startDateController.text),
                    DateTime.parse(endDateController.text),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D084),
            ),
            child: const Text(
              'Create',
              style: TextStyle(color: Color(0xFF0A1929), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(
              color: Color(0xFF00D084),
            ),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}