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
      debugShowCheckedModeBanner: false,
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

// 1. Change to ConsumerStatefulWidget
class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  // 2. Create the State class
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

// 3. Rename the class to _WeatherScreenState and extend ConsumerState
class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  // 4. Define your controller here, outside the build method
  late final TextEditingController _indexController;
  final _formKey = GlobalKey<FormState>(); // Also make the form key a property

  @override
  void initState() {
    super.initState();
    // 5. Initialize the controller in initState
    // We use ref.read() here because we only want the *initial* value,
    // we don't need to listen for changes here.
    _indexController = TextEditingController(
      text: ref.read(weatherProvider.notifier).index,
    );
  }

  @override
  void dispose() {
    // 6. Always dispose your controllers!
    _indexController.dispose();
    super.dispose();
  }

  // 7. The build method is now inside the State class
  @override
  Widget build(BuildContext context) {
    // Get the state from the provider
    final AsyncValue<AppData> weatherState = ref.watch(weatherProvider);

    // Get the provider's notifier to access its helper methods
    final providerNotifier = ref.read(weatherProvider.notifier);

    // We no longer define the controller here!

    return Scaffold(
      appBar: AppBar(title: const Text('Weather Dashboard')),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          // 8. Use the state-level form key
          child: Form(
            key: _formKey, // <-- Use the property
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Index Input
                TextFormField(
                  // 9. Use the state-level controller
                  controller: _indexController, // <-- Use the property
                  decoration: InputDecoration(
                    labelText: 'Student Index',
                    hintText: 'e.g., 224183N',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 7,
                  onChanged: (value) {
                    final upperValue = value.toUpperCase();
                    if (upperValue != value) {
                      // 10. Update the state-level controller
                      _indexController.value = _indexController.value.copyWith(
                        text: upperValue,
                        selection: TextSelection.collapsed(
                          offset: upperValue.length,
                        ),
                      );
                    }
                    // This is still correct, as it updates the provider's state
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
                    // 11. Use the state-level form key
                    if (_formKey.currentState!.validate()) {
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

  // --- No changes to your _buildResultsUI or _buildErrorUI methods ---
  // (I've removed them from this code block for brevity,
  // just keep your existing methods as they are)
  Widget _buildResultsUI(
    BuildContext context,
    WeatherNotifier notifier,
    AppData data,
  ) {
    final weather =
        data.weatherData; // This might be null if only loaded from cache

    // Format the last updated time for display
    final String formattedTime = data.lastUpdated != null
        ? DateFormat('MMM d, yyyy - hh:mm:ss a').format(data.lastUpdated!)
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
