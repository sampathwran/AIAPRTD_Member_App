class FlightData {
  final String flightNumber;
  final String airline;
  final String airlineIata; // e.g. UL, EK
  final String origin;
  final String destination;
  final String scheduledTime;
  final String estimatedTime;
  final String status; // 'Landed', 'En Route', 'Delayed', 'Scheduled'
  final String type; // 'Arrival' or 'Departure'

  FlightData({
    required this.flightNumber,
    required this.airline,
    required this.airlineIata,
    required this.origin,
    required this.destination,
    required this.scheduledTime,
    required this.estimatedTime,
    required this.status,
    required this.type,
  });
}

// Dummy data for CMB (Bandaranaike International Airport)
final List<FlightData> dummyFlights = [
  // Arrivals
  FlightData(
    flightNumber: 'UL 504',
    airline: 'SriLankan Airlines',
    airlineIata: 'UL',
    origin: 'London (LHR)',
    destination: 'Colombo (CMB)',
    scheduledTime: '12:45 PM',
    estimatedTime: '12:40 PM',
    status: 'Landed',
    type: 'Arrival',
  ),
  FlightData(
    flightNumber: 'EK 654',
    airline: 'Emirates',
    airlineIata: 'EK',
    origin: 'Dubai (DXB)',
    destination: 'Colombo (CMB)',
    scheduledTime: '02:15 PM',
    estimatedTime: '02:15 PM',
    status: 'En Route',
    type: 'Arrival',
  ),
  FlightData(
    flightNumber: 'QR 668',
    airline: 'Qatar Airways',
    airlineIata: 'QR',
    origin: 'Doha (DOH)',
    destination: 'Colombo (CMB)',
    scheduledTime: '03:30 PM',
    estimatedTime: '04:15 PM',
    status: 'Delayed',
    type: 'Arrival',
  ),
  FlightData(
    flightNumber: 'FZ 547',
    airline: 'flydubai',
    airlineIata: 'FZ',
    origin: 'Dubai (DXB)',
    destination: 'Colombo (CMB)',
    scheduledTime: '05:00 PM',
    estimatedTime: '05:00 PM',
    status: 'Scheduled',
    type: 'Arrival',
  ),

  // Departures
  FlightData(
    flightNumber: 'UL 115',
    airline: 'SriLankan Airlines',
    airlineIata: 'UL',
    origin: 'Colombo (CMB)',
    destination: 'Male (MLE)',
    scheduledTime: '01:30 PM',
    estimatedTime: '01:30 PM',
    status: 'Departed',
    type: 'Departure',
  ),
  FlightData(
    flightNumber: 'EK 655',
    airline: 'Emirates',
    airlineIata: 'EK',
    origin: 'Colombo (CMB)',
    destination: 'Dubai (DXB)',
    scheduledTime: '03:15 PM',
    estimatedTime: '03:15 PM',
    status: 'Boarding',
    type: 'Departure',
  ),
  FlightData(
    flightNumber: 'SQ 469',
    airline: 'Singapore Airlines',
    airlineIata: 'SQ',
    origin: 'Colombo (CMB)',
    destination: 'Singapore (SIN)',
    scheduledTime: '04:45 PM',
    estimatedTime: '05:10 PM',
    status: 'Delayed',
    type: 'Departure',
  ),
];
