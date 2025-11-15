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
  static const String _cacheTimeKey = 'last_weather_time';
  String _currentIndex = "";
  late double _lat;
  late double _lon;
  late String _apiUrl;

  // --- Initialization ---
  @override
  FutureOr<AppData> build() {
    _updateCoordsAndUrl();

    // Start with empty state, no cache loading on app start
    return AppData(
      requestUrl: _apiUrl,
      index: _currentIndex,
      lat: _lat,
      lon: _lon,
    );
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
            index: _currentIndex,
            lat: _lat,
            lon: _lon,
          );
        } else {
          // Handle server error
          throw Exception('Failed to load weather: ${response.statusCode}');
        }
      } catch (e) {
        // 4. Network or parsing error. Try to use cached data.
        // If cached data exists, return it (marked as cached). Otherwise rethrow.
        try {
          final AppData cached = await _loadFromCache();
          if (cached.weatherData != null) {
            return cached;
          }
        } catch (_) {
          // ignore cache load errors; we'll rethrow the original
        }

        // No cached data available -> rethrow as a clearer exception
        throw Exception('Network error and no cached data available: $e');
      }
    });
  }

  /// Public method to explicitly load cached data into state (useful for "Show cached" button)
  Future<void> loadCachedData() async {
    final cached = await _loadFromCache();
    state = AsyncValue.data(cached);
  }

  void setIndex(String newIndex) {
    if (newIndex.length >= 4) {
      _currentIndex = newIndex;
      _updateCoordsAndUrl();
      // Update state with new coords
      state = AsyncValue.data(
        AppData(
          index: _currentIndex,
          lat: _lat,
          lon: _lon,
          requestUrl: _apiUrl,
          weatherData: state.value?.weatherData,
          lastUpdated: state.value?.lastUpdated,
          isCached: state.value?.isCached ?? false,
        ),
      );
    }
  }

  void _updateCoordsAndUrl() {
    if (_currentIndex.length < 4) {
      _lat = 0.0;
      _lon = 0.0;
      _apiUrl = "";
      return;
    }
    int firstTwo = int.parse(_currentIndex.substring(0, 2));
    int nextTwo = int.parse(_currentIndex.substring(2, 4));
    _lat = 5 + (firstTwo / 10.0);
    _lon = 79 + (nextTwo / 10.0);
    _apiUrl =
        "https://api.open-meteo.com/v1/forecast?latitude=$_lat&longitude=$_lon&current_weather=true";
  }

  // --- Private Helper Methods ---

  Future<AppData> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedString = prefs.getString(_cacheKey);
    final cachedTimeString = prefs.getString(_cacheTimeKey);

    if (cachedString != null && cachedTimeString != null) {
      // We have cached data
      final data = json.decode(cachedString);
      final weather = WeatherData.fromJson(data);
      final lastUpdated = DateTime.parse(cachedTimeString);
      return AppData(
        weatherData: weather,
        lastUpdated: lastUpdated,
        isCached: true, // Mark as cached
        requestUrl: _apiUrl,
        index: _currentIndex,
        lat: _lat,
        lon: _lon,
      );
    } else {
      // No cache, return empty initial state
      return AppData(
        requestUrl: _apiUrl,
        index: _currentIndex,
        lat: _lat,
        lon: _lon,
      );
    }
  }

  Future<void> _saveToCache(String responseBody) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, responseBody);
    await prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());
  }

  // --- Helper for UI ---
  // We'll use this to get the index and coords for the UI
  String get index => _currentIndex;
  double get lat => _lat;
  double get lon => _lon;
}
