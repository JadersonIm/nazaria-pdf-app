import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import '../services/databricks_service.dart';

class PdfViewerScreen extends StatefulWidget {
  final String modo;
  final String codigoRede;
  final String codigoCliente;
  final String telefone;

  const PdfViewerScreen({
    super.key,
    required this.modo,
    required this.codigoRede,
    required this.codigoCliente,
    required this.telefone,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  PdfController? _pdfController;
  String _status = 'Iniciando geração do PDF...';
  bool _erro = false;
  int? _totalPages;

  @override
  void initState() {
    super.initState();
    _gerar();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _gerar() async {
    try {
      _setStatus('Disparando job Databricks...');
      final runId = await DatabricksService.triggerJob(
        modo: widget.modo,
        codigoRede: widget.codigoRede,
        codigoCliente: widget.codigoCliente,
        telefone: widget.telefone,
      );

      _setStatus('Gerando PDF (pode levar ~2 minutos)...');
      final result = await DatabricksService.waitForCompletion(runId);

      final outputPath = result['output_path'] as String;
      final sizeMb = result['size_mb'];
      _setStatus('Baixando PDF (${sizeMb}MB)...');

      final bytes = await DatabricksService.downloadPdf(outputPath);

      _setStatus('Abrindo visualizador...');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/relatorio.pdf');
      await file.writeAsBytes(bytes);

      final controller = PdfController(
        document: PdfDocument.openFile(file.path),
      );

      if (!mounted) return;
      setState(() {
        _pdfController = controller;
        _status = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = true;
        _status = 'Erro: $e';
      });
    }
  }

  void _setStatus(String msg) {
    if (!mounted) return;
    setState(() => _status = msg);
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.modo == 'rede_agregado'
        ? 'Rede ${widget.codigoRede}'
        : 'Cliente ${widget.codigoCliente}';

    return Scaffold(
      appBar: AppBar(
        title: Text('Relatório — $titulo'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          if (_pdfController != null && _totalPages != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  'PDF · $_totalPages pág.',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
      body: _pdfController != null
          ? PdfView(
              controller: _pdfController!,
              onDocumentLoaded: (doc) =>
                  setState(() => _totalPages = doc.pagesCount),
            )
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_erro) ...[
                    const SpinKitFadingCircle(
                        color: Color(0xFF1A237E), size: 60),
                    const SizedBox(height: 24),
                  ] else
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: _erro ? Colors.red : Colors.black87,
                      ),
                    ),
                  ),
                  if (_erro) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _erro = false;
                          _status = 'Tentando novamente...';
                        });
                        _gerar();
                      },
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
