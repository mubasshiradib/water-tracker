import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/water_log.dart';

class WaterState {
  final int dailyGoal; // in ml, e.g. 2000
  final List<WaterLog> logs;

  WaterState({
    required this.dailyGoal,
    required this.logs,
  });

  int get currentIntake => logs.fold(0, (sum, log) => sum + log.amount);
  double get progressPercentage => dailyGoal > 0 ? (currentIntake / dailyGoal).clamp(0.0, 1.0) : 0.0;

  WaterState copyWith({
    int? dailyGoal,
    List<WaterLog>? logs,
  }) {
    return WaterState(
      dailyGoal: dailyGoal ?? this.dailyGoal,
      logs: logs ?? this.logs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyGoal': dailyGoal,
      'logs': logs.map((log) => log.toJson()).toList(),
    };
  }

  factory WaterState.fromJson(Map<String, dynamic> json) {
    return WaterState(
      dailyGoal: json['dailyGoal'] as int? ?? 2000,
      logs: (json['logs'] as List<dynamic>?)
              ?.map((e) => WaterLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// Global provider for shared preferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// Water tracker state provider using the modern Riverpod 3.0 Notifier API
class WaterNotifier extends Notifier<WaterState> {
  static const String _storageKey = 'water_tracker_state_v1';

  @override
  WaterState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final String? jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        final loadedState = WaterState.fromJson(decoded);
        
        // Filter out logs that are not from today, so it resets daily
        final today = DateTime.now();
        final filteredLogs = loadedState.logs.where((log) {
          return log.timestamp.year == today.year &&
              log.timestamp.month == today.month &&
              log.timestamp.day == today.day;
        }).toList();

        return loadedState.copyWith(logs: filteredLogs);
      } catch (e) {
        // Fallback to default state if decoding fails
      }
    }
    return WaterState(dailyGoal: 2000, logs: []);
  }

  Future<void> _saveState() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
  }

  void addWater(int amount) {
    final newLog = WaterLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      amount: amount,
    );
    state = state.copyWith(logs: [...state.logs, newLog]);
    _saveState();
  }

  void removeLog(String id) {
    state = state.copyWith(
      logs: state.logs.where((log) => log.id != id).toList(),
    );
    _saveState();
  }

  void setDailyGoal(int newGoal) {
    if (newGoal > 0) {
      state = state.copyWith(dailyGoal: newGoal);
      _saveState();
    }
  }

  void resetToday() {
    state = state.copyWith(logs: []);
    _saveState();
  }
}

final waterProvider = NotifierProvider<WaterNotifier, WaterState>(WaterNotifier.new);
