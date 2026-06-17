import 'package:flutter_gemma/flutter_gemma.dart';

class GemmaService {
  static final GemmaService _instance = GemmaService._internal();
  factory GemmaService() => _instance;
  GemmaService._internal();

  bool _isInitialized = false;
  dynamic _gemmaPlugin;

  Future<void> initialize() async {
    // TEMPORARY: Bypassing Gemma initialization to prevent native crash on Android emulator
    _isInitialized = false;
    return;
    /*
    try {
      await FlutterGemma.initialize();
      _gemmaPlugin = FlutterGemmaPlugin.instance;
      _isInitialized = true;
    } catch (e) {
      // Catch initialization errors gracefully (e.g. on unsupported platforms or missing models)
      _isInitialized = false;
    }
    */
  }

  Future<String> generateReminderMessage({required int currentIntake, required int dailyGoal}) async {
    if (_isInitialized && _gemmaPlugin != null) {
      try {
        final prompt = "Write a friendly, motivational hydration reminder for a water tracking app. The user has drank $currentIntake ml out of a daily goal of $dailyGoal ml today, and they are behind schedule. Keep it under 15 words.";
        final response = await _gemmaPlugin.getResponse(prompt: prompt);
        if (response != null && response.trim().isNotEmpty) {
          return response.trim();
        }
      } catch (e) {
        // Fallback if model inference fails
      }
    }

    return _generateFallbackMessage(currentIntake, dailyGoal);
  }

  String _generateFallbackMessage(int currentIntake, int dailyGoal) {
    final percentage = dailyGoal > 0 ? (currentIntake / dailyGoal * 100).toStringAsFixed(0) : "0";
    final messages = [
      "Time for a refreshing glass! You've had $currentIntake of $dailyGoal ml ($percentage%) today.",
      "Stay hydrated! Just a small glass helps you reach your $dailyGoal ml target.",
      "Keep going! You are currently at $percentage% of your daily hydration goal.",
      "Your body needs water to stay energized. Current progress: $currentIntake/$dailyGoal ml.",
      "A sip now keeps you active! You've logged $currentIntake ml today.",
      "Hydration check! Let's get closer to your $dailyGoal ml goal today.",
    ];
    final index = DateTime.now().millisecond % messages.length;
    return messages[index];
  }
}
