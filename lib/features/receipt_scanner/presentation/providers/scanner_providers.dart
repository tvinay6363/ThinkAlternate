import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_spend/features/receipt_scanner/data/services/gemini_receipt_service.dart';
import 'package:smart_spend/features/settings/presentation/providers/settings_providers.dart';

/// Provides the GeminiReceiptService singleton.
final receiptServiceProvider = Provider<GeminiReceiptService>((ref) {
  final service = GeminiReceiptService();
  final apiKey = ref.watch(apiKeyProvider);
  if (apiKey.isNotEmpty) {
    service.initialize(apiKey);
  }
  return service;
});

/// Scanning state for the receipt scanner.
enum ScanningState { idle, scanning, success, error }

/// State object for the receipt scanner.
class ScannerState {
  final ScanningState status;
  final ReceiptData? data;
  final String? errorMessage;
  final Uint8List? imageBytes;

  const ScannerState({
    this.status = ScanningState.idle,
    this.data,
    this.errorMessage,
    this.imageBytes,
  });

  ScannerState copyWith({
    ScanningState? status,
    ReceiptData? data,
    String? errorMessage,
    Uint8List? imageBytes,
  }) {
    return ScannerState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }
}

/// Manages receipt scanning state.
final scannerProvider =
    StateNotifierProvider<ScannerNotifier, ScannerState>((ref) {
  final service = ref.watch(receiptServiceProvider);
  return ScannerNotifier(service);
});

class ScannerNotifier extends StateNotifier<ScannerState> {
  final GeminiReceiptService _service;

  ScannerNotifier(this._service) : super(const ScannerState());

  Future<void> scanReceipt(Uint8List imageBytes) async {
    state = ScannerState(
      status: ScanningState.scanning,
      imageBytes: imageBytes,
    );

    try {
      final data = await _service.scanReceipt(imageBytes);
      state = ScannerState(
        status: ScanningState.success,
        data: data,
        imageBytes: imageBytes,
      );
    } catch (e) {
      state = ScannerState(
        status: ScanningState.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
        imageBytes: imageBytes,
      );
    }
  }

  void reset() {
    state = const ScannerState();
  }
}
