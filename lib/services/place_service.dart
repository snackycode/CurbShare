import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlacesService {
  final String apiKey = "Input your PlaceService API Key";

  /// Fetch autocomplete suggestions
  Future<List<Map<String, dynamic>>> getAutocomplete(String input) async {
    final encodedInput = Uri.encodeComponent(input);
    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedInput&key=$apiKey&types=geocode&language=en";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['predictions']);
    } else {
      throw Exception("Failed to fetch suggestions");
    }
  }

  /// Fetch place details (lat/lng) using place_id
  Future<LatLng> getPlaceDetails(String placeId) async {
    final url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final location = data['result']['geometry']['location'];
      return LatLng(location['lat'], location['lng']);
    } else {
      throw Exception("Failed to fetch place details");
    }
  }

  Future<String?> reverseGeocode(LatLng latLng) async {
    try {
      final url =
          "https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$apiKey";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          // Return the formatted address of the first result
          return data['results'][0]['formatted_address'];
        }
      }
      return null;
    } catch (e) {
      print("Reverse geocode error: $e");
      return null;
    }
  }
}
