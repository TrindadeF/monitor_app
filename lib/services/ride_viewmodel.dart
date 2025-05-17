import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../models/ride_data.dart';
import '../models/app_settings.dart';
import '../services/screen_capture_service.dart';

class RideViewModel extends ChangeNotifier {
  final AppSettings _settings;
  final ScreenCaptureService _captureService;
  
  RideData? _latestRideData;
  StreamSubscription<RideData>? _rideDataSubscription;
  
  RideViewModel({
    required AppSettings settings,
    ScreenCaptureService? captureService,
  }) : _settings = settings,
       _captureService = captureService ?? ScreenCaptureService() {
    
    // Inscrever-se nas alterações de configurações
    _settings.addListener(_onSettingsChanged);
    
    // Iniciar ou parar o monitoramento com base nas configurações iniciais
    _onSettingsChanged();
  }
  
  // Getters
  RideData? get latestRideData => _latestRideData;
  bool get isMonitoring => _settings.isMonitoringActive;
  bool get showPricePerKm => _settings.showPricePerKm;
  bool get showPricePerMinute => _settings.showPricePerMinute;
  bool get showPricePerTotalSegment => _settings.showPricePerTotalSegment;
  
  // Métodos para exibir valores formatados
  String? get pricePerKmFormatted {
    if (!showPricePerKm || _latestRideData?.pricePerKm == null) return null;
    return 'R\$ ${_latestRideData!.pricePerKm!.toStringAsFixed(2)}/km';
  }
  
  String? get pricePerMinuteFormatted {
    if (!showPricePerMinute || _latestRideData?.pricePerMinute == null) return null;
    return 'R\$ ${_latestRideData!.pricePerMinute!.toStringAsFixed(2)}/min';
  }
  
  String? get pricePerTotalSegmentFormatted {
    if (!showPricePerTotalSegment || _latestRideData?.pricePerTotalSegment == null) return null;
    return 'R\$ ${_latestRideData!.pricePerTotalSegment!.toStringAsFixed(2)}/trecho';
  }
  
  // Toggle métodos
  void toggleMonitoring() {
    _settings.toggleMonitoringActive();
  }
  
  void toggleShowPricePerKm() {
    _settings.toggleShowPricePerKm();
  }
  
  void toggleShowPricePerMinute() {
    _settings.toggleShowPricePerMinute();
  }
  
  void toggleShowPricePerTotalSegment() {
    _settings.toggleShowPricePerTotalSegment();
  }
  
  // Método privado para reagir a alterações nas configurações
  void _onSettingsChanged() {
    if (_settings.isMonitoringActive) {
      _startMonitoring();
    } else {
      _stopMonitoring();
    }
    
    notifyListeners();
  }
  
  // Iniciar monitoramento
  Future<void> _startMonitoring() async {
    try {      // Iniciar o serviço em background
      final service = FlutterBackgroundService();
      service.startService();
      service.invoke('startMonitoring');
      
      // Inscrever-se para receber dados de corrida
      _rideDataSubscription = _captureService.rideDataStream.listen(_onNewRideData);
    } catch (e) {
      debugPrint('Erro ao iniciar monitoramento: $e');
    }
  }
  
  // Parar monitoramento
  Future<void> _stopMonitoring() async {
    try {      // Parar o serviço em background
      final service = FlutterBackgroundService();
      service.invoke('stopMonitoring');
      
      // Cancelar assinatura
      await _rideDataSubscription?.cancel();
      _rideDataSubscription = null;
    } catch (e) {
      debugPrint('Erro ao parar monitoramento: $e');
    }
  }
  
  // Tratamento de novos dados de corrida
  void _onNewRideData(RideData data) {
    _latestRideData = data;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _stopMonitoring();
    super.dispose();
  }
}
