// Dart code to replicate the fuzzy sleep quality logic from the Python example
import 'dart:math';

class FuzzyLogic {
  // Membership functions for each factor
  double trimf(double x, List<double> params) {
    double a = params[0];
    double b = params[1];
    double c = params[2];
    if (x <= a || x >= c) {
      return 0.0;
    } else if (x == b) {
      return 1.0;
    } else if (x < b) {
      return (x - a) / (b - a);
    } else {
      return (c - x) / (c - b);
    }
  }

  // Fuzzification of input values based on the membership functions
  Map<String, double> fuzzifyRhythm(double rhythm) {
    return {
      'poor': trimf(rhythm, [0, 0, 2.5]),
      'mediocre': trimf(rhythm, [0, 2.5, 5]),
      'average': trimf(rhythm, [2.5, 5, 7.5]),
      'decent': trimf(rhythm, [5, 7.5, 10]),
      'good': trimf(rhythm, [7.5, 10, 10]),
    };
  }

  Map<String, double> fuzzifyStress(double stress) {
    return {
      'poor': trimf(stress, [7.5, 10, 10]),
      'mediocre': trimf(stress, [5, 7.5, 10]),
      'average': trimf(stress, [2.5, 5, 7.5]),
      'decent': trimf(stress, [0, 2.5, 5]),
      'good': trimf(stress, [0, 0, 2.5]),
    };
  }

  Map<String, double> fuzzifyDuration(double duration) {
    return {
      'poor': trimf(duration, [0, 0, 2.5]),
      'mediocre': trimf(duration, [0, 2.5, 5]),
      'average': trimf(duration, [2.5, 5, 7.5]),
      'decent': trimf(duration, [5, 7.5, 10]),
      'good': trimf(duration, [7.5, 10, 10]),
    };
  }

  Map<String, double> fuzzifyEnvironment(double environment) {
    return {
      'poor': trimf(environment, [0, 0, 2.5]),
      'mediocre': trimf(environment, [0, 2.5, 5]),
      'average': trimf(environment, [2.5, 5, 7.5]),
      'decent': trimf(environment, [5, 7.5, 10]),
      'good': trimf(environment, [7.5, 10, 10]),
    };
  }

  // Defuzzification - computing sleep quality based on fuzzy rules
  double computeSleepQuality(double rhythm, double stress, double duration, double environment) {
    var rhythmFuzzy = fuzzifyRhythm(rhythm);
    var stressFuzzy = fuzzifyStress(stress);
    var durationFuzzy = fuzzifyDuration(duration);
    var environmentFuzzy = fuzzifyEnvironment(environment);

    // Define rules and calculate the sleep quality output
    double poor = max(
        max(
            max(rhythmFuzzy['poor']!, stressFuzzy['poor']!),
            max(durationFuzzy['poor']!, environmentFuzzy['poor']!)
        ),
        max(
            rhythmFuzzy['mediocre']! * stressFuzzy['poor']!,
            environmentFuzzy['poor']! * rhythmFuzzy['mediocre']!
        )
    );

    double mediocre = max(
        max(
            max(stressFuzzy['mediocre']!, environmentFuzzy['mediocre']!),
            max(durationFuzzy['mediocre']!, rhythmFuzzy['mediocre']!)
        ),
        max(
            environmentFuzzy['mediocre']! * (stressFuzzy['poor']! + rhythmFuzzy['poor']!),
            rhythmFuzzy['average']!
        )
    );

    double average = max(
        max(
            max(stressFuzzy['average']!, durationFuzzy['average']!),
            max(rhythmFuzzy['average']!, environmentFuzzy['average']!)
        ),
        max(
            durationFuzzy['average']! * rhythmFuzzy['decent']!,
            environmentFuzzy['average']! * stressFuzzy['average']!
        )
    );

    double decent = max(
        max(
            max(stressFuzzy['decent']!, durationFuzzy['decent']!),
            max(environmentFuzzy['decent']!, rhythmFuzzy['decent']!)
        ),
        max(
            durationFuzzy['decent']! * rhythmFuzzy['good']!,
            stressFuzzy['decent']! * environmentFuzzy['decent']!
        )
    );

    double good = max(
        max(
            max(rhythmFuzzy['good']!, durationFuzzy['good']!),
            max(environmentFuzzy['good']!, stressFuzzy['good']!)
        ),
        max(
            stressFuzzy['decent']! * durationFuzzy['good']!,
            environmentFuzzy['good']! * rhythmFuzzy['good']!
        )
    );

    // Defuzzification - weighted average approach
    double sleepQuality = (poor * 1.25 + mediocre * 2.5 + average * 5 + decent * 7.5 + good * 8.75) /
        (poor + mediocre + average + decent + good);

    return sleepQuality.isNaN ? 0.0 : sleepQuality;
  }
}
