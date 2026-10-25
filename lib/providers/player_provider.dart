import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class PlayerProvider extends ChangeNotifier {
  int _coins = 0;
  int _gems = 0;
  int _level = 1;
  int _xp = 0;
  int _dailyStreak = 0;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  List<String> _unlockedThemes = ['default'];

  int get coins => _coins;
  int get gems => _gems;
  int get level => _level;
  int get xp => _xp;
  int get dailyStreak => _dailyStreak;
  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  List<String> get unlockedThemes => _unlockedThemes;

  int get xpForNextLevel => _level * 500;
  double get xpProgress => _xp / xpForNextLevel;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _coins = prefs.getInt(StorageKeys.coins) ?? 0;
    _gems = prefs.getInt(StorageKeys.gems) ?? 0;
    _level = prefs.getInt(StorageKeys.level) ?? 1;
    _xp = prefs.getInt(StorageKeys.xp) ?? 0;
    _dailyStreak = prefs.getInt(StorageKeys.loginStreak) ?? 0;
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    _hapticsEnabled = prefs.getBool('haptics_enabled') ?? true;
    _checkDailyStreak(prefs);
    notifyListeners();
  }

  void _checkDailyStreak(SharedPreferences prefs) {
    final lastPlay = prefs.getString(StorageKeys.lastLoginDate);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastPlay == null) {
      _dailyStreak = 1;
    } else {
      final last = DateTime.parse(lastPlay);
      final diff = DateTime.now().difference(last).inDays;
      if (diff == 1) {
        _dailyStreak++;
      } else if (diff > 1) {
        _dailyStreak = 1;
      }
    }
    prefs.setString(StorageKeys.lastLoginDate, today);
    prefs.setInt(StorageKeys.loginStreak, _dailyStreak);
  }

  Future<void> addRewards({int coins = 0, int gems = 0, int xp = 0}) async {
    _coins += coins;
    _gems += gems;
    _xp += xp;
    await _checkLevelUp();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StorageKeys.coins, _coins);
    await prefs.setInt(StorageKeys.gems, _gems);
    await prefs.setInt(StorageKeys.xp, _xp);
    notifyListeners();
  }

  Future<void> _checkLevelUp() async {
    while (_xp >= xpForNextLevel) {
      _xp -= xpForNextLevel;
      _level++;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StorageKeys.level, _level);
  }

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', _soundEnabled);
    notifyListeners();
  }

  Future<void> toggleHaptics() async {
    _hapticsEnabled = !_hapticsEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptics_enabled', _hapticsEnabled);
    notifyListeners();
  }
}
