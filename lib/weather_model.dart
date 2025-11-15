import 'package:flutter/foundation.dart';

class WeatherData {
  final CurrentWeather currentWeather;
  final double latitude;
  final double longitude;

  WeatherData({
    required this.currentWeather,
    required this.latitude,
    required this.longitude,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      currentWeather: CurrentWeather.fromJson(json['current_weather']),
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
    );
  }
}

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

@immutable
class AppData {
  final WeatherData? weatherData;
  final DateTime? lastUpdated;
  final bool isCached;
  final String requestUrl;
  final String index;
  final double lat;
  final double lon;

  const AppData({
    this.weatherData,
    this.lastUpdated,
    this.isCached = false,
    required this.requestUrl,
    required this.index,
    required this.lat,
    required this.lon,
  });

  AppData copyWith({
    WeatherData? weatherData,
    DateTime? lastUpdated,
    bool? isCached,
    String? requestUrl,
    String? index,
    double? lat,
    double? lon,
  }) {
    return AppData(
      weatherData: weatherData ?? this.weatherData,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isCached: isCached ?? this.isCached,
      requestUrl: requestUrl ?? this.requestUrl,
      index: index ?? this.index,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
    );
  }
}
