import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ride_viewmodel.dart';
import '../widgets/price_indicator.dart';
import '../widgets/monitor_control.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Constants
  static const MethodChannel _methodChannel = MethodChannel('com.example.monitor_app/media_projection');
    // Estado das permissões
  bool _hasNotificationListenerPermission = false;
  bool _hasOverlayPermission = false;
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }
  Future<void> _checkPermissions() async {
    // Verificar permissão de notificação regular
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    
    // Verificar permissão de armazenamento
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }
    
    // Verificar permissões específicas do Android
    try {
      _hasNotificationListenerPermission = await _methodChannel.invokeMethod('checkNotificationListenerPermission') ?? false;
      _hasOverlayPermission = await _methodChannel.invokeMethod('checkOverlayPermission') ?? false;
    } catch (e) {
      debugPrint('Erro ao verificar permissões: $e');
    }
    
    // Atualizar a UI
    setState(() {});
  }
    // Solicitar permissão de notificação listener
  Future<void> _requestNotificationListenerPermission() async {
    await _methodChannel.invokeMethod('requestNotificationListenerPermission');
    // Atualizar o estado depois de algum tempo, pois precisamos voltar do settings
    Future.delayed(const Duration(seconds: 1), () => _checkPermissions());
  }
  
  // Solicitar permissão de overlay
  Future<void> _requestOverlayPermission() async {
    await _methodChannel.invokeMethod('requestOverlayPermission');
    // Atualizar o estado depois de algum tempo, pois precisamos voltar do settings
    Future.delayed(const Duration(seconds: 1), () => _checkPermissions());
  }
    // Removido método não utilizado de captura de tela,
  // pois será solicitada pelo serviço quando necessário
  
  // Método para iniciar o monitoramento
  Future<void> _startMonitoring() async {
    // Verificar se todas as permissões estão concedidas
    if (!_hasNotificationListenerPermission || !_hasOverlayPermission) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Permissões necessárias'),
          content: Text('Para que o app funcione corretamente, é necessário conceder todas as permissões.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    // O serviço vai solicitar MediaProjection se necessário
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<RideViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Monitor de Corridas'),
            backgroundColor: Colors.black,
            actions: [
              // Botão para iniciar/parar monitoramento
              IconButton(
                icon: Icon(
                  viewModel.isMonitoring ? Icons.visibility : Icons.visibility_off,
                  color: viewModel.isMonitoring ? Colors.green : Colors.grey,
                ),
                onPressed: () async {
                  if (!viewModel.isMonitoring) {
                    await _startMonitoring();
                  }
                  viewModel.toggleMonitoring();
                },
                tooltip: viewModel.isMonitoring ? 'Parar monitoramento' : 'Iniciar monitoramento',
              ),
            ],
          ),
          body: Container(
            color: Colors.grey[900],
            child: Column(
              children: [
                // Status do monitoramento
                Container(
                  padding: const EdgeInsets.all(16),
                  color: viewModel.isMonitoring ? const Color.fromRGBO(0, 255, 0, 0.2) : const Color.fromRGBO(255, 0, 0, 0.2),
                  child: Row(
                    children: [
                      Icon(
                        viewModel.isMonitoring ? Icons.check_circle : Icons.error,
                        color: viewModel.isMonitoring ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        viewModel.isMonitoring ? 'Monitoramento ativo' : 'Monitoramento inativo',
                        style: TextStyle(
                          color: viewModel.isMonitoring ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                  // Seção de permissões
                if (!_hasNotificationListenerPermission || !_hasOverlayPermission)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.yellow),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.yellow.withAlpha(25),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Permissões pendentes:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.yellow,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Permissão de notificação
                        if (!_hasNotificationListenerPermission)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.notifications_active, color: Colors.yellow),
                            title: const Text('Acesso a Notificações', style: TextStyle(color: Colors.white)),
                            subtitle: const Text(
                              'Para detectar ofertas de corrida em tempo real', 
                              style: TextStyle(color: Colors.white70)
                            ),
                            trailing: ElevatedButton(
                              onPressed: _requestNotificationListenerPermission,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow,
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Permitir'),
                            ),
                          ),
                          
                        // Permissão de overlay
                        if (!_hasOverlayPermission)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.layers, color: Colors.yellow),
                            title: const Text('Sobrepor a outros apps', style: TextStyle(color: Colors.white)),
                            subtitle: const Text(
                              'Para exibir métricas sobre apps de corrida', 
                              style: TextStyle(color: Colors.white70)
                            ),
                            trailing: ElevatedButton(
                              onPressed: _requestOverlayPermission,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow,
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Permitir'),
                            ),
                          ),
                      ],
                    ),
                  ),
                
                // Área de exibição dos valores calculados
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Toggles SEMPRE visíveis
                        PriceIndicator(
                          label: 'VALOR/KM',
                          value: viewModel.pricePerKmFormatted,
                          onToggle: viewModel.toggleShowPricePerKm,
                          isActive: viewModel.showPricePerKm,
                        ),
                        const SizedBox(height: 24),
                        PriceIndicator(
                          label: 'VALOR/MINUTO',
                          value: viewModel.pricePerMinuteFormatted,
                          onToggle: viewModel.toggleShowPricePerMinute,
                          isActive: viewModel.showPricePerMinute,
                        ),
                        const SizedBox(height: 24),
                        PriceIndicator(
                          label: 'VALOR/TRECHO',
                          value: viewModel.pricePerTotalSegmentFormatted,
                          onToggle: viewModel.toggleShowPricePerTotalSegment,
                          isActive: viewModel.showPricePerTotalSegment,
                        ),
                        const SizedBox(height: 32),
                        // Mensagem quando não há dados
                        if (viewModel.latestRideData == null && viewModel.isMonitoring)
                          const Text(
                            'Aguardando detecção de corrida...',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        // Mensagem quando o monitoramento está desligado
                        if (!viewModel.isMonitoring)
                          const Text(
                            'Toque no ícone de visibilidade para iniciar o monitoramento',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Controle de monitoramento na parte inferior
          bottomNavigationBar: const MonitorControl(),
        );
      },
    );
  }
}
