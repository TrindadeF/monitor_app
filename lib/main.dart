import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
import 'models/app_settings.dart';
import 'services/ride_viewmodel.dart';
import 'services/screen_capture_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar orientação da tela para apenas vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  await _requestPermissions();

  // Configurar canal de notificação
  await setupNotificationChannel();
  
  // Inicializar o serviço
  await ScreenCaptureService.initializeBackgroundService();
  
  runApp(const MyApp());
}

Future<void> setupNotificationChannel() async {
  if (Platform.isAndroid) {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'monitor_app_channel', // Mesmo ID usado na configuração do serviço
      'Monitor de Corridas',
      description: 'Notificações do Monitor de Corridas',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}

Future<void> _requestPermissions() async {
  // No Android 10+, precisamos de permissões para dados de mídia
  // O MediaProjection em si é solicitado em tempo de execução na implementação nativa
  await Permission.storage.request();
  
  // Em Android 11+, solicitar também permissões específicas para todas as mídias
  if (await Permission.photos.request().isGranted) {
    debugPrint('Permissão de fotos concedida');
  }

  // Verificar se temos permissão para ficar em primeiro plano (necessário para serviço em background)
  if (await Permission.notification.request().isDenied) {
    debugPrint('Permissão de notificação negada - pode afetar o serviço em background');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettings()),
        ChangeNotifierProxyProvider<AppSettings, RideViewModel>(
          create: (context) => RideViewModel(
            settings: Provider.of<AppSettings>(context, listen: false),
          ),
          update: (context, settings, previous) => 
            previous ?? RideViewModel(settings: settings),
        ),
      ],
      child: MaterialApp(
        title: 'Monitor de Corridas',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            elevation: 0,
          ),
        ),
        home:  HomeScreen(),
      ),
    );
  }
}
