import 'dart:convert';
import 'package:http/http.dart' as http;
import 'flight_data.dart';

class FlightService {
  static const String _apiKey = 'c67958a5-c01f-4923-b6d8-6fdb2bb4a409';
  static const String _baseUrl = 'https://airlabs.co/api/v9/schedules';

  Future<List<FlightData>> fetchArrivals(String airportCode) async {
    return _fetchFlights(airportCode, 'Arrival');
  }

  Future<List<FlightData>> fetchDepartures(String airportCode) async {
    return _fetchFlights(airportCode, 'Departure');
  }

  Future<List<FlightData>> _fetchFlights(
      String airportCode, String type) async {
    final param = type == 'Arrival' ? 'arr_iata' : 'dep_iata';
    final url = Uri.parse('$_baseUrl?$param=$airportCode&api_key=$_apiKey');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['error'] != null) {
          throw Exception(data['error']['message'] ?? 'API Error');
        }

        final List<dynamic>? responseList = data['response'];
        if (responseList == null) {
          return [];
        }

        return responseList
            .map((json) => FlightData.fromJson(json, type))
            .toList();
      } else {
        throw Exception(
            'Failed to load flights (Status: ${response.statusCode})');
      }
    } catch (e) {
      // Re-throw to be handled by the UI
      throw Exception('Could not fetch flights: $e');
    }
  }
}
