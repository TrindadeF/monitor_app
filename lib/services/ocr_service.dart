import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart'; // Adicione esta importação para usar Size
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/ride_data.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();
  Future<RideData> extractRideDataFromImage(ui.Image uiImage) async {
    // Converter ui.Image para File ou InputImage
    final bytes = await _convertUiImageToBytes(uiImage);
    
    // Versão atualizada para google_ml_kit 0.16.3+
    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(uiImage.width.toDouble(), uiImage.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.bgra8888,
        bytesPerRow: uiImage.width * 4,
      ),
    );

    // Processar OCR
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    final text = recognizedText.text;
    
    // Analisar texto para extrair dados relevantes
    return _extractRideDataFromText(text);
  }
  
  Future<Uint8List> _convertUiImageToBytes(ui.Image uiImage) async {
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
  
  RideData _extractRideDataFromText(String text) {
    // Regex para pegar deslocamento até o passageiro
    final pickupRegex = RegExp(r'(\d{1,3})\s*minutos?\s*\((\d{1,3}(?:[.,]\d+))\s*k[mM]\) de distância', caseSensitive: false);
    final tripRegex = RegExp(r'Viagem de\s*(\d{1,3})\s*minutos?\s*\((\d{1,3}(?:[.,]\d+))\s*k[mM]\)', caseSensitive: false);
    final priceRegex = RegExp(r'(?:R\$[\s]*)?(\d{1,3}(?:[.,]\d{2}))[\s]*R?\$?', caseSensitive: false, multiLine: true);

    double? price;
    double? pickupTime;
    double? pickupDistance;
    double? tripTime;
    double? tripDistance;

    // 1. Extrai "6 minutos (1.6 km) de distância" (pickup)
    final pickupMatch = pickupRegex.firstMatch(text);
    if (pickupMatch != null) {
      pickupTime = double.tryParse(pickupMatch.group(1) ?? '');
      pickupDistance = double.tryParse((pickupMatch.group(2) ?? '').replaceAll(',', '.'));
    }

    // 2. Extrai "Viagem de 11 minutos (4.0 km)" (trip)
    final tripMatch = tripRegex.firstMatch(text);
    if (tripMatch != null) {
      tripTime = double.tryParse(tripMatch.group(1) ?? '');
      tripDistance = double.tryParse((tripMatch.group(2) ?? '').replaceAll(',', '.'));
    }

    // 3. Preço (sempre pega o primeiro valor de R$)
    final priceMatch = priceRegex.firstMatch(text);
    if (priceMatch != null) {
      final priceText = priceMatch.group(1)?.replaceAll(',', '.');
      price = priceText != null ? double.tryParse(priceText) : null;
    }

    return RideData(
      price: price,
      pickupTime: pickupTime,
      pickupDistance: pickupDistance,
      tripTime: tripTime,
      tripDistance: tripDistance,
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}