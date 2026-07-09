import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  // --- Settings State ---
  double _appVolume = 0.7; // Default 70%
  bool _enableBatteryWarning = true; // Default ON
  bool _enableSeatbeltAudio = true; // Default ON

  bool _isLoaded = false;

  // --- Getters ---
  double get appVolume => _appVolume;
  bool get enableBatteryWarning => _enableBatteryWarning;
  bool get enableSeatbeltAudio => _enableSeatbeltAudio;
  bool get isLoaded => _isLoaded;

  // --- Init ---
  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _appVolume = prefs.getDouble('app_volume') ?? 0.7;
    _enableBatteryWarning = prefs.getBool('battery_warning') ?? true;
    _enableSeatbeltAudio = prefs.getBool('seatbelt_audio') ?? true;

    _isLoaded = true;
    notifyListeners();
  }

  // --- Setters ---
  Future<void> setAppVolume(double value) async {
    if (_appVolume == value) return;
    _appVolume = value.clamp(0.0, 1.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('app_volume', _appVolume);
  }

  Future<void> setBatteryWarning(bool value) async {
    if (_enableBatteryWarning == value) return;
    _enableBatteryWarning = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('battery_warning', _enableBatteryWarning);
  }

  Future<void> setSeatbeltAudio(bool value) async {
    if (_enableSeatbeltAudio == value) return;
    _enableSeatbeltAudio = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seatbelt_audio', _enableSeatbeltAudio);
  }
}
