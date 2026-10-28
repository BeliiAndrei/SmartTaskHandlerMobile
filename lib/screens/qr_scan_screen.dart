import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool _detected = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Сканировать QR-код')),
    body: Stack(
      children: [
        MobileScanner(
          errorBuilder: (context, error) => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Камера недоступна. Разрешите доступ к камере и попробуйте снова.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          onDetect: (capture) {
            if (_detected || capture.barcodes.isEmpty) return;
            final value = capture.barcodes.first.rawValue;
            if (value == null || value.isEmpty) return;
            _detected = true;
            Navigator.of(context).pop(value);
          },
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Наведите камеру на QR-код для подтверждения',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
