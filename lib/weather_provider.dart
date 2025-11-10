import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'weather_model.dart'; // Import our new model

// This is the main provider for our app's logic
final weatherProvider = AsyncNotifierProvider<WeatherNotifier, AppData>(
  WeatherNotifier.new,
);

class WeatherNotifier extends AsyncNotifier<AppData> {
  // --- Constants ---
  static const String _cacheKey = 'last_weather_result';
  final String _index = "224183N";
  final String _lat = "7.2";
  final String _lon = "83.1";
  late final String _apiUrl;

  // --- Initialization ---
  @override
  FutureOr<AppData> build() {
    _apiUrl =
        "https://api.open-meteo.com/v1/forecast?latitude=$_lat&longitude=$_lon&current_weather=true";

    // On app start, try to load from cache
    return _loadFromCache();
  }

  // --- Public Methods ---

  // Main method called by the UI
  Future<void> fetchWeather() async {
    // 1. Set state to loading
    state = const AsyncValue.loading();

    // 2. Update state with the result of our logic
    state = await AsyncValue.guard(() async {
      try {
        // 3. Try fetching from the network
        final http.Response response = await http.get(Uri.parse(_apiUrl));

        if (response.statusCode == 200) {
          // Success!
          final data = json.decode(response.body);
          final weather = WeatherData.fromJson(data);

          // Save to cache
          _saveToCache(response.body);

          return AppData(
            weatherData: weather,
            lastUpdated: DateTime.now(), // From device clock
            isCached: false,
            requestUrl: _apiUrl,
          );
        } else {
          // Handle server error
          throw Exception('Failed to load weather: ${response.statusCode}');
        }
      } catch (e) {
        // 4. Network or parsing error. Try to use cached data.
        // We re-throw the error so the UI can show it.
        throw Exception('Network Error: $e');
      }
    });
  }

  // --- Private Helper Methods ---

  Future<AppData> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedString = prefs.getString(_cacheKey);

    if (cachedString != null) {
      // We have cached data
      final data = json.decode(cachedString);
      final weather = WeatherData.fromJson(data);
      return AppData(
        weatherData: weather,
        lastUpdated: DateTime.now(), // Note: This is load time, not fetch time
        isCached: true, // Mark as cached
        requestUrl: _apiUrl,
      );
    } else {
      // No cache, return empty initial state
      return AppData(requestUrl: _apiUrl);
    }
  }

  Future<void> _saveToCache(String responseBody) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, responseBody);
  }

  // --- Helper for UI ---
  // We'll use this to get the index and coords for the UI
  String get index => _index;
  String get lat => _lat;
  String get lon => _lon;
}
