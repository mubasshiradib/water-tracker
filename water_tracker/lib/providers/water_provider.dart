import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/water_log.dart';

class WaterState {
  final int dailyGoal; // in ml, e.g. 2000
  final List<WaterLog> logs;
  final DateTime lastResetDate;

  WaterState({
    required this.dailyGoal,
    required this.logs,
    required this.lastResetDate,
  });

  int get currentIntake => logs.fold(0, (sum, log) => sum + log.amount);
  double get progressPercentage => dailyGoal > 0 ? (currentIntake / dailyGoal).clamp(0.0, 1.0) : 0.0;

  WaterState copyWith({
    int? dailyGoal,
    List<WaterLog>? logs,
    DateTime? lastResetDate,
  }) {
    return WaterState(
      dailyGoal: dailyGoal ?? this.dailyGoal,
      logs: logs ?? this.logs,
      lastResetDate: lastResetDate ?? this.lastResetDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyGoal': dailyGoal,
      'logs': logs.map((log) => log.toJson()).toList(),
      'lastResetDate': lastResetDate.toIso8601String(),
    };
  }

  factory WaterState.fromJson(Map<String, dynamic> json) {
    return WaterState(
      dailyGoal: json['dailyGoal'] as int? ?? 2000,
      logs: (json['logs'] as List<dynamic>?)
              ?.map((e) => WaterLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastResetDate: json['lastResetDate'] != null
          ? DateTime.parse(json['lastResetDate'] as String)
          : DateTime.now(),
    );
  }
}

// Global provider for shared preferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// Water tracker state provider using the modern Riverpod Notifier API
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
        
        final today = DateTime.now();
        if (_isSameDay(today, loadedState.lastResetDate)) {
          return loadedState;
        } else {
          // Reset logs on day rollover
          final newState = WaterState(
            dailyGoal: loadedState.dailyGoal,
            logs: [],
            lastResetDate: today,
          );
          Future.microtask(() => _saveState(newState));
          return newState;
        }
      } catch (e) {
        // Fallback to default state if decoding fails
      }
    }
    final today = DateTime.now();
    final defaultState = WaterState(dailyGoal: 2000, logs: [], lastResetDate: today);
    Future.microtask(() => _saveState(defaultState));
    return defaultState;
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  void checkDailyReset() {
    final today = DateTime.now();
    if (!_isSameDay(today, state.lastResetDate)) {
      state = state.copyWith(
        logs: [],
        lastResetDate: today,
      );
      _saveState();
    }
  }

  Future<void> _saveState([WaterState? stateToSave]) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final targetState = stateToSave ?? state;
    await prefs.setString(_storageKey, jsonEncode(targetState.toJson()));
  }

  void addWater(int amount) {
    checkDailyReset(); // Check for rollover before performing action
    final newLog = WaterLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      amount: amount,
    );
    state = state.copyWith(logs: [...state.logs, newLog]);
    _saveState();
  }

  void removeLog(String id) {
    checkDailyReset(); // Check for rollover before performing action
    state = state.copyWith(
      logs: state.logs.where((log) => log.id != id).toList(),
    );
    _saveState();
  }

  void setDailyGoal(int newGoal) {
    checkDailyReset(); // Check for rollover before performing action
    if (newGoal > 0) {
      state = state.copyWith(dailyGoal: newGoal);
      _saveState();
    }
  }

  void resetToday() {
    state = state.copyWith(
      logs: [],
      lastResetDate: DateTime.now(),
    );
    _saveState();
  }
}

final waterProvider = NotifierProvider<WaterNotifier, WaterState>(WaterNotifier.new);
