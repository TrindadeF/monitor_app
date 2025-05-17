import 'package:flutter/material.dart';

class PriceIndicator extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onToggle;
  final bool isActive;
  const PriceIndicator({
    super.key,
    required this.label,
    required this.value,
    required this.onToggle,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? Colors.green : Color.fromRGBO(128, 128, 128, 0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Switch para habilitar/desabilitar o indicador
              Switch(
                value: isActive,
                onChanged: (_) => onToggle(),
                activeColor: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value ?? '-- / --',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
