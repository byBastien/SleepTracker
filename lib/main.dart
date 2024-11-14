import 'package:flutter/material.dart';
import 'fuzzy_logic.dart'; // Import the fuzzy logic class

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Sleep Tracker Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Sleep Tracker Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<SleepRating> _sleepHistory = [];
  final int _duration = 5;
  final int _rhythm = 5;
  final int _stress = 5;
  final int _environment = 5;

  final FuzzyLogic fuzzyLogic = FuzzyLogic(); // Create an instance of FuzzyLogic

  void _showRatingDialog() {
    int tempDuration = _duration;
    int tempRhythm = _rhythm;
    int tempStress = _stress;
    int tempEnvironment = _environment;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Rate Your Sleep'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSlider('Duration', tempDuration, (value) {
                      setDialogState(() {
                        tempDuration = value.toInt();
                      });
                    }),
                    _buildSlider('Rhythm', tempRhythm, (value) {
                      setDialogState(() {
                        tempRhythm = value.toInt();
                      });
                    }),
                    _buildSlider('Stress', tempStress, (value) {
                      setDialogState(() {
                        tempStress = value.toInt();
                      });
                    }),
                    _buildSlider('Environment', tempEnvironment, (value) {
                      setDialogState(() {
                        tempEnvironment = value.toInt();
                      });
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();

                    double sleepQuality = fuzzyLogic.computeSleepQuality(
                      tempRhythm.toDouble(),
                      tempStress.toDouble(),
                      tempDuration.toDouble(),
                      tempEnvironment.toDouble(),
                    );

                    // Add a new instance of SleepRating with independent values
                    setState(() {
                      _sleepHistory.insert(
                        0,
                        SleepRating(
                          duration: tempDuration,
                          rhythm: tempRhythm,
                          stress: tempStress,
                          environment: tempEnvironment,
                          date: DateTime.now(),
                          sleepQuality: sleepQuality, // Assign the computed quality
                        ),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Predicted Sleep Quality: $sleepQuality')),
                      );
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Method to calculate the average sleep quality for the last 7 entries
  double _calculateAverageSleepQuality() {
    int count = _sleepHistory.length < 7 ? _sleepHistory.length : 7;
    if (count == 0) return 0.0;

    double totalQuality = 0;
    for (int i = 0; i < count; i++) {
      totalQuality += _sleepHistory[i].sleepQuality;
    }
    return totalQuality / count;
  }

  String _getSleepQualityLabel(double sleepQuality) {
    if (sleepQuality < 4) {
      return 'Bad';
    } else if (sleepQuality < 6) {
      return 'Okay';
    } else if (sleepQuality < 8) {
      return 'Good';
    } else {
      return 'Excellent';
    }
  }

  IconData _getSleepQualityIcon(double sleepQuality) {
    if (sleepQuality < 4) {
      return Icons.sentiment_very_dissatisfied;
    } else if (sleepQuality < 6) {
      return Icons.sentiment_dissatisfied;
    } else if (sleepQuality < 8) {
      return Icons.sentiment_satisfied;
    } else {
      return Icons.sentiment_very_satisfied;
    }
  }

  Widget _buildSlider(String label, int value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          label: value.toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double averageSleepQuality = _calculateAverageSleepQuality();
    String qualityLabel = _getSleepQualityLabel(averageSleepQuality);
    IconData qualityIcon = _getSleepQualityIcon(averageSleepQuality);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              '7-Day Average Sleep Quality:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  qualityIcon,
                  size: 48,
                  color: Colors.blueAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  '${averageSleepQuality.toStringAsFixed(2)} ($qualityLabel)',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Rating History:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _buildHistoryList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showRatingDialog,
        tooltip: 'Rate Sleep',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_sleepHistory.isEmpty) {
      return const Text('No history available yet.');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _sleepHistory.length,
      itemBuilder: (context, index) {
        final sleepRating = _sleepHistory[index];
        String qualityLabel = _getSleepQualityLabel(sleepRating.sleepQuality); // Get the quality label

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${sleepRating.date.toLocal()}'.split('.')[0],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Duration: ${sleepRating.duration}'),
                Text('Rhythm: ${sleepRating.rhythm}'),
                Text('Stress: ${sleepRating.stress}'),
                Text('Environment: ${sleepRating.environment}'),
                Text('Sleep Quality: ${sleepRating.sleepQuality.toStringAsFixed(2)} ($qualityLabel)'), // Display quality with label
              ],
            ),
          ),
        );
      },
    );
  }
}

class SleepRating {
  final int duration;
  final int rhythm;
  final int stress;
  final int environment;
  final DateTime date;
  final double sleepQuality;

  SleepRating({
    required this.duration,
    required this.rhythm,
    required this.stress,
    required this.environment,
    required this.date,
    required this.sleepQuality,
  });
}
