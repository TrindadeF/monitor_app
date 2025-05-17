import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ride_viewmodel.dart';

class MonitorControl extends StatelessWidget {
  const MonitorControl({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RideViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          color: Colors.black,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botão principal para ligar/desligar o monitoramento
              ElevatedButton(
                onPressed: viewModel.toggleMonitoring,
                style: ElevatedButton.styleFrom(
                  backgroundColor: viewModel.isMonitoring ? Colors.red : Colors.green,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(viewModel.isMonitoring ? Icons.stop : Icons.play_arrow),
                    const SizedBox(width: 8),
                    Text(
                      viewModel.isMonitoring ? 'PARAR MONITORAMENTO' : 'INICIAR MONITORAMENTO',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Texto explicativo
              Text(
                viewModel.isMonitoring
                    ? 'O app está monitorando ativamente os cards de corrida'
                    : 'Clique para iniciar o monitoramento dos apps de corrida',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Aviso sobre permissões
              if (!viewModel.isMonitoring)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Certifique-se de que o app tem permissão para capturar a tela',
                    style: TextStyle(
                      color: Colors.orange[300],
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
