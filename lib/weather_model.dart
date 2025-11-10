import 'package:flutter/foundation.dart';

// This represents the entire JSON response
class WeatherData {
  final CurrentWeather currentWeather;
  final double latitude;
  final double longitude;

  WeatherData({
    required this.currentWeather,
    required this.latitude,
    required this.longitude,
  });

  // A 'factory constructor' to create a WeatherData object from JSON
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      currentWeather: CurrentWeather.fromJson(json['current_weather']),
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
    );
  }
}

// This represents the 'current_weather' object inside the JSON
class CurrentWeather {
  final double temperature;
  final double windSpeed;
  final int weatherCode;

  CurrentWeather({
    required this.temperature,
    required this.windSpeed,
    required this.weatherCode,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature: json['temperature'] as double,
      windSpeed: json['windspeed'] as double,
      weatherCode: json['weathercode'] as int,
    );
  }
}

// This is our complete, "real-world" state
// It holds the API data, the cache status, and the last update time.
@immutable
class AppData {
  final WeatherData? weatherData;
  final DateTime? lastUpdated;
  final bool isCached;
  final String requestUrl;

  const AppData({
    this.weatherData,
    this.lastUpdated,
    this.isCached = false,
    required this.requestUrl,
  });

  // Helper method to create a copy with new values
  AppData copyWith({
    WeatherData? weatherData,
    DateTime? lastUpdated,
    bool? isCached,
    String? requestUrl,
  }) {
    return AppData(
      weatherData: weatherData ?? this.weatherData,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isCached: isCached ?? this.isCached,
      requestUrl: requestUrl ?? this.requestUrl,
    );
  }
}
