import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Extracted receipt data from AI scanning.
class ReceiptData {
  final String? merchantName;
  final DateTime? date;
  final double? amount;
  final String? category;
  final String? rawResponse;

  ReceiptData({
    this.merchantName,
    this.date,
    this.amount,
    this.category,
    this.rawResponse,
  });

  bool get isValid =>
      merchantName != null && amount != null && amount! > 0;
}

/// Service for scanning receipts using Gemini AI.
class GeminiReceiptService {
  GenerativeModel? _model;

  void initialize(String apiKey) {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
  }

  bool get isInitialized => _model != null;

  /// Scans receipt image and extracts structured data.
  Future<ReceiptData> scanReceipt(Uint8List imageBytes) async {
    if (_model == null) {
      throw Exception('AI service not initialized. Please add your API key in Settings.');
    }

    try {
      final prompt = TextPart(
        '''Analyze this receipt image and extract the following information.
Return ONLY a valid JSON object with these exact keys:
{
  "merchant_name": "store or merchant name",
  "date": "YYYY-MM-DD format",
  "amount": numeric total amount (number only, no currency symbol),
  "category": one of "food", "shopping", "travel", "utilities", "entertainment", "others"
}

Rules:
- For amount, extract the TOTAL/GRAND TOTAL amount. Use just the number.
- For category, choose the most appropriate one based on the merchant type.
- If you cannot determine a field, use null.
- Do NOT include any text outside the JSON object.''',
      );

      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await _model!.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      final text = response.text;
      if (text == null || text.isEmpty) {
        return ReceiptData(rawResponse: 'No response from AI');
      }

      return _parseResponse(text);
    } catch (e) {
      if (e.toString().contains('API key')) {
        throw Exception('Invalid API key. Please check your Gemini API key in Settings.');
      }
      throw Exception('Failed to scan receipt: ${e.toString()}');
    }
  }

  ReceiptData _parseResponse(String text) {
    try {
      // Extract JSON from response (handle markdown code blocks)
      String jsonStr = text.trim();
      if (jsonStr.contains('```json')) {
        jsonStr = jsonStr.split('```json')[1].split('```')[0].trim();
      } else if (jsonStr.contains('```')) {
        jsonStr = jsonStr.split('```')[1].split('```')[0].trim();
      }

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      DateTime? parsedDate;
      if (json['date'] != null) {
        try {
          parsedDate = DateTime.parse(json['date'].toString());
        } catch (_) {
          parsedDate = DateTime.now();
        }
      }

      double? parsedAmount;
      if (json['amount'] != null) {
        parsedAmount = double.tryParse(json['amount'].toString());
      }

      return ReceiptData(
        merchantName: json['merchant_name']?.toString(),
        date: parsedDate,
        amount: parsedAmount,
        category: json['category']?.toString(),
        rawResponse: text,
      );
    } catch (e) {
      return ReceiptData(rawResponse: text);
    }
  }
}
