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

    final indexController = TextEditingController(
      text: weatherState.value?.index ?? providerNotifier.index,
    );

    final formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Weather Dashboard')),
      resizeToAvoidBottomInset:
          true, // allow body to resize when keyboard shows
      body: SafeArea(
        child: SingleChildScrollView(
          // makes content scrollable
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Index Input (editable + validated)
                TextFormField(
                  controller: indexController,
                  decoration: const InputDecoration(
                    labelText: 'Student Index',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 7,
                  onChanged: (value) {
                    final upperValue = value.toUpperCase();
                    if (upperValue != value) {
                      indexController.value = indexController.value.copyWith(
                        text: upperValue,
                        selection: TextSelection.collapsed(
                          offset: upperValue.length,
                        ),
                      );
                    }
                    ref.read(weatherProvider.notifier).setIndex(upperValue);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your index';
                    }
                    final regex = RegExp(r'^[0-9]{6}[A-Z]$');
                    if (!regex.hasMatch(value)) {
                      return 'Index must be 6 digits + 1 letter (e.g. 224183N)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 2. Fetch Button
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      ref.read(weatherProvider.notifier).fetchWeather();
                    }
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

                // 3. Results
                weatherState.when(
                  data: (appData) =>
                      _buildResultsUI(context, providerNotifier, appData),
                  error: (error, stackTrace) => _buildErrorUI(
                    context,
                    providerNotifier,
                    error.toString(),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
          ),
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
            Text(
              'Lat: ${data.lat.toStringAsFixed(2)}, Lon: ${data.lon.toStringAsFixed(2)}',
            ),
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
  Widget _buildErrorUI(
    BuildContext context,
    WeatherNotifier notifier,
    String error,
  ) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              error,
              style: TextStyle(color: Colors.red[800]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => notifier.fetchWeather(),
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => notifier.loadCachedData(),
                  child: const Text('Show cached'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
