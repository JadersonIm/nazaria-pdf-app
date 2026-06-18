import 'dart:convert';
import 'package:http/http.dart' as http;

class DatabricksService {
  static const String _host = 'https://dbc-5a404ecd-3ffa.cloud.databricks.com';
  static const String _token = String.fromEnvironment('DATABRICKS_TOKEN');
  static const int _jobId = 875690728918670;

  static Map<String, String> get _headers => {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      };

  /// Dispara o job e retorna o run_id
  static Future<int> triggerJob({
    required String modo,
    String codigoRede = '',
    String codigoCliente = '',
    String cnpj = '',
    String telefone = '',
  }) async {
    final body = json.encode({
      'job_id': _jobId,
      'notebook_params': {
        'modo': modo,
        'codigo_rede': codigoRede,
        'codigo_cliente': codigoCliente,
        'cnpj': cnpj,
        'output_path': '/Volumes/nazaria_pdfs/raw',
        'telefone': telefone,
      },
    });

    final resp = await http.post(
      Uri.parse('$_host/api/2.1/jobs/run-now'),
      headers: _headers,
      body: body,
    );

    if (resp.statusCode != 200) {
      throw Exception('Erro ao disparar job: ${resp.body}');
    }
    final data = json.decode(resp.body);
    return data['run_id'] as int;
  }

  /// Aguarda o job terminar e retorna o output JSON do notebook
  static Future<Map<String, dynamic>> waitForCompletion(int runId) async {
    while (true) {
      await Future.delayed(const Duration(seconds: 10));

      final resp = await http.get(
        Uri.parse('$_host/api/2.1/jobs/runs/get?run_id=$runId'),
        headers: _headers,
      );

      final data = json.decode(resp.body);
      final state = data['state']['life_cycle_state'] as String;

      if (state == 'TERMINATED' || state == 'INTERNAL_ERROR') {
        final resultState = data['state']['result_state'] as String;
        if (resultState != 'SUCCESS') {
          throw Exception('Job falhou: $resultState');
        }

        // Buscar output da task
        final taskRunId = data['tasks'][0]['run_id'] as int;
        final outResp = await http.get(
          Uri.parse('$_host/api/2.1/jobs/runs/get-output?run_id=$taskRunId'),
          headers: _headers,
        );
        final outData = json.decode(outResp.body);
        final result = outData['notebook_output']['result'] as String;
        return json.decode(result) as Map<String, dynamic>;
      }
    }
  }

  /// Baixa o PDF do Volumes e retorna os bytes
  static Future<List<int>> downloadPdf(String outputPath) async {
    // Converte /Volumes/... para o path da Files API
    final apiPath = outputPath.startsWith('/Volumes')
        ? outputPath
        : '/Volumes${outputPath}';

    final resp = await http.get(
      Uri.parse('$_host/api/2.1/fs/files$apiPath'),
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (resp.statusCode != 200) {
      throw Exception('Erro ao baixar PDF: ${resp.statusCode}');
    }
    return resp.bodyBytes;
  }
}
