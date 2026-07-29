class FlightData {
  final String flightNumber;
  final String airline;
  final String airlineIata;
  final String origin;
  final String destination;
  final String scheduledTime;
  final String estimatedTime;
  final String status;
  final String type; // 'Arrival' or 'Departure'

  // Extended fields
  final String? actualDepTime;
  final String? actualArrTime;
  final String? terminal;
  final String? gate;
  final String? baggageBelt;
  final String? callsign;
  final String? aircraftIcao;

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
    this.actualDepTime,
    this.actualArrTime,
    this.terminal,
    this.gate,
    this.baggageBelt,
    this.callsign,
    this.aircraftIcao,
  });

  factory FlightData.fromJson(Map<String, dynamic> json, String type) {
    // AirLabs gives status as lowercase: landed, active, scheduled
    String rawStatus = json['status'] ?? 'scheduled';
    int delay =
        (type == 'Arrival' ? json['arr_delayed'] : json['dep_delayed']) ?? 0;

    String status = 'Scheduled';
    if (rawStatus == 'landed') {
      status = 'Landed';
    } else if (rawStatus == 'active') {
      status = delay > 15 ? 'Delayed' : 'En Route';
    } else if (rawStatus == 'scheduled' && delay > 15) {
      status = 'Delayed';
    }

    // Format time: YYYY-MM-DD HH:MM -> HH:MM
    String formatTime(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty) return '--:--';
      try {
        final parts = timeStr.split(' ');
        if (parts.length > 1) {
          return parts[1];
        }
      } catch (e) {
        return timeStr;
      }
      return timeStr;
    }

    String schedTime =
        type == 'Arrival' ? (json['arr_time'] ?? '') : (json['dep_time'] ?? '');
    String estTime = type == 'Arrival'
        ? (json['arr_estimated'] ?? schedTime)
        : (json['dep_estimated'] ?? schedTime);

    return FlightData(
      flightNumber: json['flight_iata'] ?? (json['flight_number'] ?? 'Unknown'),
      airline:
          json['airline_icao'] ?? json['airline_iata'] ?? 'Unknown Airline',
      airlineIata: json['airline_iata'] ?? '',
      origin: json['dep_iata'] ?? 'Unknown',
      destination: json['arr_iata'] ?? 'Unknown',
      scheduledTime: formatTime(schedTime),
      estimatedTime: formatTime(estTime),
      status: status,
      type: type,
      actualDepTime: formatTime(json['dep_actual']),
      actualArrTime: formatTime(json['arr_actual']),
      terminal: type == 'Arrival' ? json['arr_terminal'] : json['dep_terminal'],
      gate: type == 'Arrival' ? json['arr_gate'] : json['dep_gate'],
      baggageBelt:
          type == 'Arrival' ? json['arr_baggage'] : json['dep_baggage'],
      callsign: json['flight_icao'],
      aircraftIcao: json['aircraft_icao'],
    );
  }
}
