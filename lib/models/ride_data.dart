class RideData {
  final double? price;
  final double? pickupDistance; // até o passageiro
  final double? pickupTime;     // até o passageiro
  final double? tripDistance;   // da viagem
  final double? tripTime;       // da viagem

  // Para compatibilidade antiga
  double? get distance => tripDistance;
  double? get time => tripTime;

  // Métricas calculadas
  double? get pricePerKm => price != null && tripDistance != null && tripDistance! > 0
      ? price! / tripDistance!
      : null;

  double? get pricePerMinute => price != null && tripTime != null && tripTime! > 0
      ? price! / tripTime!
      : null;

  double? get pricePerTotalSegment {
    final totalDistance = (pickupDistance ?? 0) + (tripDistance ?? 0);
    final totalTime = (pickupTime ?? 0) + (tripTime ?? 0);
    if (price != null && (totalDistance > 0 || totalTime > 0)) {
      // Cálculo ponderado: igual ao anterior, mas usando o total
      return price! / ((totalDistance / 10) + (totalTime / 60));
    }
    return null;
  }

  RideData({
    this.price,
    this.pickupDistance,
    this.pickupTime,
    this.tripDistance,
    this.tripTime,
  });

  bool isValid() {
    return price != null && ((pickupDistance != null && pickupTime != null) || (tripDistance != null && tripTime != null));
  }
}
