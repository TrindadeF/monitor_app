import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../models/ride_data.dart';
import 'ocr_service.dart';
import 'package:flutter/painting.dart' show decodeImageFromList;
import 'package:permission_handler/permission_handler.dart';

@pragma('vm:entry-point')
class ScreenCaptureService {
  static const MethodChannel _methodChannel = MethodChannel('com.example.monitor_app/media_projection');
  static const EventChannel _eventChannel = EventChannel('com.example.monitor_app/ride_events');
  
  final OcrService _ocrService = OcrService();
  final StreamController<RideData> _rideDataController = StreamController<RideData>.broadcast();
  StreamSubscription<dynamic>? _notificationSubscription;
  bool _isCapturing = false;
  // Stream para escutar os dados das corridas
  Stream<RideData> get rideDataStream => _rideDataController.stream;

  // Iniciar monitoramento por eventos
  Future<void> startCapturing() async {
    if (_isCapturing) return;
    
    // Verificar e solicitar permissões necessárias
    await _checkAndRequestPermissions();
    
    // Configurar stream de eventos para receber notificações
    _notificationSubscription = _eventChannel
        .receiveBroadcastStream()
        .listen(_onRideNotification);
        
    _isCapturing = true;
    debugPrint('Monitoramento por eventos iniciado');
}
  // Método para parar o monitoramento
  void stopCapturing() {
    _isCapturing = false;
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    debugPrint('Monitoramento por eventos parado');
  }
  
  // Handler para notificações de corridas
  RideData? _lastRideData;
  DateTime? _lastRideTimestamp;
  Future<void> _onRideNotification(dynamic event) async {
    try {
      if (event is! Map<dynamic, dynamic>) return;
      final eventType = event['eventType'] as String?;
      if (eventType != 'ride_notification') return;

      // Debounce: não processar se chamado em menos de 3s
      final now = DateTime.now();
      if (_lastRideTimestamp != null && now.difference(_lastRideTimestamp!).inSeconds < 3) {
        debugPrint('Ignorando notificação duplicada (debounce)');
        return;
      }

      // Capturar a tela quando receber uma notificação
      final rideData = await _captureAndAnalyzeScreenWithReturn();
      if (rideData != null) {
        // Filtro de duplicatas: só processa se diferente do último
        if (_lastRideData != null && _isSameRide(_lastRideData!, rideData)) {
          debugPrint('Ignorando RideData duplicado');
          return;
        }
        _lastRideData = rideData;
        _lastRideTimestamp = now;
        _rideDataController.add(rideData);
        debugPrint('Dados extraídos: R\$${rideData.price}, ${rideData.distance}km, ${rideData.time}min');
        await _showOverlay(rideData);
      }
    } catch (e) {
      debugPrint('Erro ao processar notificação de corrida: $e');
    }
  }

  // Função para comparar se dois RideData são "iguais" (mesmo preço, distância e tempo)
  bool _isSameRide(RideData a, RideData b) {
    return (a.price?.toStringAsFixed(2) == b.price?.toStringAsFixed(2)) &&
           (a.distance?.toStringAsFixed(2) == b.distance?.toStringAsFixed(2)) &&
           (a.time?.toStringAsFixed(2) == b.time?.toStringAsFixed(2));
  }

  // Versão do método de captura que retorna RideData (para filtro de duplicatas)
  Future<RideData?> _captureAndAnalyzeScreenWithReturn() async {
    try {
      final Uint8List? screenshotBytes = await _methodChannel.invokeMethod('captureScreen');
      if (screenshotBytes == null) {
        debugPrint('Falha ao capturar a tela');
        return null;
      }
      final ui.Image image = await decodeImageFromList(screenshotBytes);
      final rideData = await _ocrService.extractRideDataFromImage(image);
      if (rideData.isValid()) {
        return rideData;
      }
    } catch (e) {
      debugPrint('Erro durante captura e análise: $e');
    }
    return null;
  }
  

  
  // Mostra overlay com as informações calculadas
  Future<void> _showOverlay(RideData rideData) async {
    try {
      await _methodChannel.invokeMethod('showOverlay', {
        'price': rideData.price ?? 0.0,
        'pricePerKm': rideData.pricePerKm ?? 0.0,
        'pricePerMinute': rideData.pricePerMinute ?? 0.0,
        'pricePerSegment': rideData.pricePerTotalSegment ?? 0.0,
      });
    } catch (e) {
      debugPrint('Erro ao mostrar overlay: $e');
    }
  }
  
  // Verificar e solicitar todas as permissões necessárias
  Future<bool> _checkAndRequestPermissions() async {
    // Permissão para captura de tela
    final bool hasMediaPermission = await _methodChannel.invokeMethod('hasMediaProjectionPermission');
    if (!hasMediaPermission) {
      final bool permissionGranted = await _methodChannel.invokeMethod('requestMediaProjection');
      if (!permissionGranted) {
        debugPrint('Permissão de captura de tela negada');
        return false;
      }
    }
    
    // Permissão para overlay do sistema
    final bool hasOverlayPermission = await _methodChannel.invokeMethod('checkOverlayPermission');
    if (!hasOverlayPermission) {
      await _methodChannel.invokeMethod('requestOverlayPermission');
    }
    
    // Permissão para escutar notificações
    final bool hasNotificationListenerPermission = 
        await _methodChannel.invokeMethod('checkNotificationListenerPermission');
    if (!hasNotificationListenerPermission) {
      await _methodChannel.invokeMethod('requestNotificationListenerPermission');
    }
    
    // Permissão para notificações regulares
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    
    // Permissão para armazenamento
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }
    
    return true;
  }
  
  // Inicializar serviço em background
  static Future<void> initializeBackgroundService() async {
    final service = FlutterBackgroundService();
    
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onBackgroundStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'monitor_app_channel',
        initialNotificationTitle: 'Monitor de Corridas',
        initialNotificationContent: 'Monitorando apps de corrida',
        foregroundServiceNotificationId: 888,
      ),      
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: (ServiceInstance service) async => true,
        onBackground: (ServiceInstance service) async => true,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onBackgroundStart(ServiceInstance service) async {
    ScreenCaptureService captureService = ScreenCaptureService();

    service.on('startMonitoring').listen((event) {
      captureService.startCapturing();
    });

    service.on('stopMonitoring').listen((event) {
      captureService.stopCapturing();
    });

    // Definir a notificação de foreground APENAS uma vez ao iniciar
    if (service is AndroidServiceInstance) {
      AndroidServiceInstance androidService = service;
      if (await androidService.isForegroundService()) {
        await androidService.setForegroundNotificationInfo(
          title: "Monitor de Corridas",
          content: "Monitorando apps de corrida",
          // IMPORTANTE: prioridade baixa para não vibrar nem incomodar
          // O plugin flutter_background_service_android suporta channelId customizado
          // O canal já é criado como 'monitor_app_channel' no seu setup
        );
      }
    }

    return true;
  }

  void dispose() {
    stopCapturing();
    _rideDataController.close();
    _ocrService.dispose();
  }
}
