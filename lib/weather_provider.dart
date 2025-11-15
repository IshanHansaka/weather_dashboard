import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'weather_model.dart';

final weatherProvider = AsyncNotifierProvider<WeatherNotifier, AppData>(
  WeatherNotifier.new,
);

class WeatherNotifier extends AsyncNotifier<AppData> {
  static const String _cacheKey = 'last_weather_result';
  static const String _cacheTimeKey = 'last_weather_time';
  String _currentIndex = "";
  late double _lat;
  late double _lon;
  late String _apiUrl;

  @override
  FutureOr<AppData> build() {
    _updateCoordsAndUrl();

    return AppData(
      requestUrl: _apiUrl,
      index: _currentIndex,
      lat: _lat,
      lon: _lon,
    );
  }

  Future<void> fetchWeather() async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      try {
        final http.Response response = await http.get(Uri.parse(_apiUrl));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final weather = WeatherData.fromJson(data);

          _saveToCache(response.body);

          return AppData(
            weatherData: weather,
            lastUpdated: DateTime.now(),
            isCached: false,
            requestUrl: _apiUrl,
            index: _currentIndex,
            lat: _lat,
            lon: _lon,
          );
        } else {
          throw Exception('Failed to load weather: ${response.statusCode}');
        }
      } catch (e) {
        try {
          final AppData cached = await _loadFromCache();
          if (cached.weatherData != null) {
            return cached;
          }
        } catch (_) {
          // Ignore cache load errors
        }

        throw Exception('Network error and no cached data available: $e');
      }
    });
  }

  Future<void> loadCachedData() async {
    final cached = await _loadFromCache();
    state = AsyncValue.data(cached);
  }

  void setIndex(String newIndex) {
    if (newIndex.length >= 4) {
      _currentIndex = newIndex;
      _updateCoordsAndUrl();
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

  Future<AppData> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedString = prefs.getString(_cacheKey);
    final cachedTimeString = prefs.getString(_cacheTimeKey);

    if (cachedString != null && cachedTimeString != null) {
      final data = json.decode(cachedString);
      final weather = WeatherData.fromJson(data);
      final lastUpdated = DateTime.parse(cachedTimeString);
      return AppData(
        weatherData: weather,
        lastUpdated: lastUpdated,
        isCached: true,
        requestUrl: _apiUrl,
        index: _currentIndex,
        lat: _lat,
        lon: _lon,
      );
    } else {
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

  String get index => _currentIndex;
  double get lat => _lat;
  double get lon => _lon;
}
