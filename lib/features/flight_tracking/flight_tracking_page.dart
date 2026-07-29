import 'package:flutter/material.dart';
import 'package:aiaprtd_member/features/flight_tracking/flight_tracking_dummy_data.dart';

class FlightTrackingPage extends StatefulWidget {
  const FlightTrackingPage({super.key});

  @override
  State<FlightTrackingPage> createState() => _FlightTrackingPageState();
}

class _FlightTrackingPageState extends State<FlightTrackingPage>
    with SingleTickerProviderStateMixin {
  final List<Map<String, String>> _airports = [
    {'code': 'CMB', 'name': 'Katunayake (BIA)'},
    {'code': 'HRI', 'name': 'Mattala (MRIA)'},
    {'code': 'RML', 'name': 'Ratmalana (RMA)'},
    {'code': 'JAF', 'name': 'Jaffna (JIA)'},
    {'code': 'BTC', 'name': 'Batticaloa (BIA)'},
  ];

  String _selectedAirport = 'CMB';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Flight Tracking",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Airport Selector
          Container(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _airports.map((airport) {
                  final isSelected = _selectedAirport == airport['code'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedAirport = airport['code']!;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                              : (isDark ? Colors.grey[800] : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_airport_rounded,
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600]),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${airport['code']} - ${airport['name']}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[800]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Custom TabBar for Arrivals / Departures
          Container(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: colorScheme.primary,
              indicatorWeight: 3,
              labelColor: colorScheme.primary,
              unselectedLabelColor:
                  isDark ? Colors.grey[500] : Colors.grey[600],
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              tabs: const [
                Tab(text: "ARRIVALS"),
                Tab(text: "DEPARTURES"),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFlightList(type: 'Arrival'),
                _buildFlightList(type: 'Departure'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightList({required String type}) {
    // Filter dummy data based on tab type
    final flights = dummyFlights.where((f) => f.type == type).toList();

    if (_selectedAirport != 'CMB') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.airplanemode_inactive_rounded,
                size: 64, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              "No flights available for $_selectedAirport currently.",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Text(
              "(Dummy data only available for CMB)",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: flights.length,
      itemBuilder: (context, index) {
        final flight = flights[index];
        return _buildFlightCard(flight);
      },
    );
  }

  Widget _buildFlightCard(FlightData flight) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color statusColor;
    switch (flight.status) {
      case 'Landed':
      case 'Departed':
        statusColor = Colors.green;
        break;
      case 'Delayed':
        statusColor = Colors.redAccent;
        break;
      case 'En Route':
      case 'Boarding':
        statusColor = Colors.orangeAccent;
        break;
      default:
        statusColor = Colors.blueAccent;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top Row: Airline & Flight No. + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.flight,
                          size: 20, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          flight.flightNumber,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          flight.airline,
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    flight.status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            // Bottom Row: Times and Route
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Times
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sch: ${flight.scheduledTime}",
                      style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                          fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Est: ${flight.estimatedTime}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                // Route
                Row(
                  children: [
                    Text(
                      flight.type == 'Arrival'
                          ? flight.origin.split(' ').first
                          : flight.origin.split(' ').first,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        flight.type == 'Arrival'
                            ? Icons.flight_land
                            : Icons.flight_takeoff,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      flight.type == 'Arrival'
                          ? flight.destination.split(' ').first
                          : flight.destination.split(' ').first,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
