import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  bool _isMonitoringActive = false;
  bool _showPricePerKm = true;
  bool _showPricePerMinute = true;
  bool _showPricePerTotalSegment = true;

  // Getters
  bool get isMonitoringActive => _isMonitoringActive;
  bool get showPricePerKm => _showPricePerKm;
  bool get showPricePerMinute => _showPricePerMinute;
  bool get showPricePerTotalSegment => _showPricePerTotalSegment;

  // Construtor que carrega as preferências salvas
  AppSettings() {
    _loadSettings();
  }

  // Métodos de toggle
  void toggleMonitoringActive() {
    _isMonitoringActive = !_isMonitoringActive;
    _saveSettings();
    notifyListeners();
  }

  void toggleShowPricePerKm() {
    _showPricePerKm = !_showPricePerKm;
    _saveSettings();
    notifyListeners();
  }

  void toggleShowPricePerMinute() {
    _showPricePerMinute = !_showPricePerMinute;
    _saveSettings();
    notifyListeners();
  }

  void toggleShowPricePerTotalSegment() {
    _showPricePerTotalSegment = !_showPricePerTotalSegment;
    _saveSettings();
    notifyListeners();
  }

  // Carregar configurações salvas
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isMonitoringActive = prefs.getBool('isMonitoringActive') ?? false;
    _showPricePerKm = prefs.getBool('showPricePerKm') ?? true;
    _showPricePerMinute = prefs.getBool('showPricePerMinute') ?? true;
    _showPricePerTotalSegment = prefs.getBool('showPricePerTotalSegment') ?? true;
    
    notifyListeners();
  }

  // Salvar configurações
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMonitoringActive', _isMonitoringActive);
    await prefs.setBool('showPricePerKm', _showPricePerKm);
    await prefs.setBool('showPricePerMinute', _showPricePerMinute);
    await prefs.setBool('showPricePerTotalSegment', _showPricePerTotalSegment);
  }
}
