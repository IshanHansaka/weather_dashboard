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

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  late final TextEditingController _indexController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _indexController = TextEditingController(
      text: ref.read(weatherProvider.notifier).index,
    );
  }

  @override
  void dispose() {
    _indexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AppData> weatherState = ref.watch(weatherProvider);

    final providerNotifier = ref.read(weatherProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Weather Dashboard')),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _indexController,
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
                      _indexController.value = _indexController.value.copyWith(
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

                ElevatedButton(
                  onPressed: () {
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

  Widget _buildResultsUI(
    BuildContext context,
    WeatherNotifier notifier,
    AppData data,
  ) {
    final weather =
        data.weatherData;

    final String formattedTime = data.lastUpdated != null
        ? DateFormat('MMM d, yyyy - hh:mm:ss a').format(data.lastUpdated!)
        : "Never";

    final String updateTag = data.isCached ? " (cached)" : "";

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coordinates:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Lat: ${data.lat.toStringAsFixed(2)}, Lon: ${data.lon.toStringAsFixed(2)}',
            ),
            const Divider(height: 24),

            Text(
              'Current Weather:',
              style: Theme.of(context).textTheme.titleMedium,
            ),

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
