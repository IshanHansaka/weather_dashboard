import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'weather_model.dart';
import 'weather_provider.dart';

void main() {
  runApp(const ProviderScope(child: WeatherApp()));
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
      ),
      home: const WeatherScreen(),
    );
  }
}

class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the state from the provider
    final AsyncValue<AppData> weatherState = ref.watch(weatherProvider);

    // Get the provider's notifier to access its helper methods (like get index)
    final providerNotifier = ref.read(weatherProvider.notifier);

    final indexController = TextEditingController(text: providerNotifier.index);

    return Scaffold(
      appBar: AppBar(title: const Text('Weather Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Index Input (now read-only as the value is fixed)
            TextField(
              controller: indexController,
              readOnly: true, // As per logic, it's derived
              decoration: const InputDecoration(
                labelText: 'Student Index',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Fetch Button
            ElevatedButton(
              onPressed: () {
                // Call the function inside our Notifier
                ref.read(weatherProvider.notifier).fetchWeather();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Fetch Weather'),
            ),
            const SizedBox(height: 24),

            // 3. Results Area - This is where the magic happens
            weatherState.when(
              // --- Data (Success) State ---
              data: (appData) =>
                  _buildResultsUI(context, providerNotifier, appData),

              // --- Error State ---
              error: (error, stackTrace) =>
                  _buildErrorUI(context, error.toString()),

              // --- Loading State ---
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to build for the Success state
  Widget _buildResultsUI(
    BuildContext context,
    WeatherNotifier notifier,
    AppData data,
  ) {
    final weather =
        data.weatherData; // This might be null if only loaded from cache

    // Format the last updated time for display
    final String formattedTime = data.lastUpdated != null
        ? DateFormat('MMM d, yyyy - hh:mm a').format(data.lastUpdated!)
        : "Never";

    // Add (cached) tag if needed
    final String updateTag = data.isCached ? " (cached)" : "";

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Computed Coords
            Text(
              'Coordinates:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('Lat: ${notifier.lat}, Lon: ${notifier.lon}'),
            const Divider(height: 24),

            // Weather Results
            Text(
              'Current Weather:',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            // Handle case where we have cached data but no weather
            weather != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Temperature: ${weather.currentWeather.temperature} °C',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Wind Speed: ${weather.currentWeather.windSpeed} km/h',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Weather Code: ${weather.currentWeather.weatherCode}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  )
                : const Text('No weather data available. Tap fetch.'),

            const Divider(height: 24),

            // Meta Info
            Text(
              'Last Updated: $formattedTime$updateTag',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            SelectableText(
              'Request URL: ${data.requestUrl}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to build for the Error state
  Widget _buildErrorUI(BuildContext context, String error) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 40),
            const SizedBox(height: 12),
            Text(
              'Failed to fetch weather',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.red[900]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your network connection and try again. $error',
              style: TextStyle(color: Colors.red[800]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
