import 'package:flutter/material.dart';
import 'pdf_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _modo = 'rede_agregado';
  final _codigoRedeCtrl = TextEditingController(text: '9334');
  final _codigoClienteCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  bool _enviWhatsApp = false;

  @override
  void dispose() {
    _codigoRedeCtrl.dispose();
    _codigoClienteCtrl.dispose();
    _telefoneCtrl.dispose();
    super.dispose();
  }

  void _gerarPdf() {
    final modo = _modo;
    final codigoRede = _codigoRedeCtrl.text.trim();
    final codigoCliente = _codigoClienteCtrl.text.trim();
    final telefone = _enviWhatsApp ? _telefoneCtrl.text.trim() : '';

    if (modo == 'rede_agregado' && codigoRede.isEmpty) {
      _showError('Informe o código da rede.');
      return;
    }
    if (modo == 'cliente' && codigoCliente.isEmpty) {
      _showError('Informe o código ou CNPJ do cliente.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          modo: modo,
          codigoRede: codigoRede,
          codigoCliente: codigoCliente,
          telefone: telefone,
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nazaria — Relatório PDF'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tipo de relatório',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'rede_agregado', label: Text('Rede')),
                ButtonSegment(value: 'cliente', label: Text('Cliente')),
              ],
              selected: {_modo},
              onSelectionChanged: (s) => setState(() => _modo = s.first),
            ),
            const SizedBox(height: 24),
            if (_modo == 'rede_agregado') ...[
              TextField(
                controller: _codigoRedeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Código da rede',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
              ),
            ] else ...[
              TextField(
                controller: _codigoClienteCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Código do cliente ou CNPJ (14 dígitos)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Enviar também por WhatsApp'),
              value: _enviWhatsApp,
              onChanged: (v) => setState(() => _enviWhatsApp = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (_enviWhatsApp) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _telefoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone (ex: 5586999990000)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _gerarPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Gerar relatório',
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
