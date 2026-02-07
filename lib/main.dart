import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WarungPay POS',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
      ),
      home: const WarungPayPOS(),
    );
  }
}

class WarungPayPOS extends StatefulWidget {
  const WarungPayPOS({super.key});

  @override
  State<WarungPayPOS> createState() => _WarungPayPOSState();
}

class _WarungPayPOSState extends State<WarungPayPOS> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  bool _isFormatting = false;
  bool _showQR = false;
  String _qrData = '';
  String _txId = '';

  static const String hardcodedQr = 'solana:YourWalletAddressHere?amount=1';

  late final AnimationController _pulseController;

  bool get _hasDigits {
    final digits = _controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_isFormatting) return;
    _isFormatting = true;
    final raw = _controller.text;
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final formatted = _formatRupiah(digits);
    _controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    setState(() {});
    _isFormatting = false;
  }

  String _formatRupiah(String digits) {
    if (digits.isEmpty) return '';
    final buffer = StringBuffer();
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      buffer.write(digits[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }
    final reversed = buffer.toString().split('').reversed.join();
    return 'Rp $reversed';
  }

  void _generateQr() {
    if (!_hasDigits) return;
    setState(() {
      _qrData = hardcodedQr; // hardcoded as requested
      _txId = 'TX${DateTime.now().millisecondsSinceEpoch % 1000000}';
      _showQR = true;
    });
  }

  Future<void> _copyAmount() async {
    final text = _controller.text;
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jumlah disalin ke clipboard')));
  }

  Future<void> _copyQrData() async {
    if (_qrData.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _qrData));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR data disalin')));
  }

  void _appendDigit(String d) {
    final digits = _controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    final newDigits = digits + d;
    final formatted = _formatRupiah(newDigits);
    _isFormatting = true;
    _controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _isFormatting = false;
    setState(() {});
  }

  void _doubleZero() {
    _appendDigit('00');
  }

  void _backspace() {
    final digits = _controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;
    final newDigits = digits.substring(0, digits.length - 1);
    final formatted = _formatRupiah(newDigits);
    _isFormatting = true;
    _controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _isFormatting = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.storefront, color: Colors.indigo.shade700, size: 22),
            ),
            const SizedBox(width: 10),
            const Text('WarungPay POS', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: LayoutBuilder(builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 900;
                  return isNarrow ? _buildColumnLayout() : _buildRowLayout();
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColumnLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInputCard(),
          const SizedBox(height: 18),
          _buildQrCard(adaptToFullWidth: true),
        ],
      ),
    );
  }

  Widget _buildRowLayout() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(flex: 4, child: _buildInputCard()),
          const SizedBox(width: 24),
          Flexible(flex: 5, child: _buildQrCard()),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Total Belanja (IDR)',
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Rp 0',
                      filled: true,
                      fillColor: Colors.white,
                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _controller.clear();
                      _showQR = false;
                      _qrData = '';
                      _txId = '';
                    });
                  },
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _hasDigits ? _generateQr : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: _hasDigits ? Colors.indigo : Colors.grey,
                    ),
                    child: const Text('Generate QR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Tooltip(
                  message: 'Salin jumlah',
                  child: IconButton(
                    onPressed: _controller.text.isEmpty ? null : _copyAmount,
                    icon: const Icon(Icons.copy),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Tampilan kasir siap digunakan — tampilkan QR kepada customer untuk pembayaran.',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            const SizedBox(height: 14),
            // Numeric keypad
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.6,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var i = 1; i <= 9; i++) _buildKeyButton(i.toString()),
                  _buildKeyButton('00', isWide: true),
                  _buildKeyButton('0'),
                  _buildBackspaceButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCard({bool adaptToFullWidth = false}) {
    final size = adaptToFullWidth ? 320.0 : 280.0;
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'QR Pembayaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ScaleTransition(
              scale: Tween(begin: 0.98, end: 1.02).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(red: 0, green: 0, blue: 0, alpha: 0.06), blurRadius: 10, offset: const Offset(0, 6)),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: _showQR
                      ? GestureDetector(
                          key: const ValueKey('qr'),
                          onLongPress: _copyQrData,
                          child: QrImageView(
                            data: _qrData,
                            version: QrVersions.auto,
                            size: size,
                            backgroundColor: Colors.white,
                          ),
                        )
                      : SizedBox(
                          key: const ValueKey('placeholder'),
                          height: size,
                          width: size,
                          child: Center(
                            child: Icon(Icons.qr_code_2, size: 90, color: Colors.grey[300]),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Show formatted amount under QR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _controller.text.isEmpty ? 'Rp 0' : _controller.text,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tekan dan tahan QR untuk menyalin',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _controller.text.isEmpty ? null : _copyAmount,
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Salin jumlah',
                  )
                ],
              ),
            ),
            if (_txId.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Transaksi: $_txId', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _txId.isEmpty
                          ? null
                          : () {
                              Clipboard.setData(ClipboardData(text: _txId));
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID transaksi disalin')));
                            },
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Salin ID transaksi',
                    )
                  ],
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'Menunggu pembayaran dari customer...',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade50,
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Status: MENUNGGU PEMBAYARAN',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (_showQR)
              TextButton(
                onPressed: () {
                  setState(() {
                    _showQR = false;
                    _qrData = '';
                    _txId = '';
                  });
                },
                child: const Text('Reset'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyButton(String label, {bool isWide = false}) {
    return ElevatedButton(
      onPressed: () {
        if (label == '00') {
          _doubleZero();
        } else {
          _appendDigit(label);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildBackspaceButton() {
    return ElevatedButton(
      onPressed: _backspace,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: const Icon(Icons.backspace_outlined),
    );
  }
}
