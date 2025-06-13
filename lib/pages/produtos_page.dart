import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/lista_repository.dart';

class ProdutosPage extends StatefulWidget {
  const ProdutosPage({super.key});

  @override
  State<ProdutosPage> createState() => _ProdutosPageState();
}

class _ProdutosPageState extends State<ProdutosPage> {
  final repo = ListaRepository();
  Map<String, List<_ProdutoPrecoPorData>> _historicoCompleto = {};
  Map<String, List<_ProdutoPrecoPorData>> _historicoFiltrado = {};
  String _busca = '';
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() => _carregando = true);

    final listas = await repo.listarListas();
    final Map<String, List<_ProdutoPrecoPorData>> historico = {};

    for (final lista in listas) {
      final itens = await repo.listarItens(lista.id!);
      for (final item in itens) {
        historico.putIfAbsent(item.nomeProduto, () => []);
        historico[item.nomeProduto]!.add(
          _ProdutoPrecoPorData(
            data: lista.dataCompra ?? '',
            preco: item.preco,
            quantidade: item.quantidade,
          ),
        );
      }
    }

    setState(() {
      _historicoCompleto = historico;
      _aplicarFiltro();
      _carregando = false;
    });
  }

  void _aplicarFiltro() {
    if (_busca.isEmpty) {
      _historicoFiltrado = Map.from(_historicoCompleto);
    } else {
      _historicoFiltrado = {
        for (var entry in _historicoCompleto.entries)
          if (entry.key.toLowerCase().contains(_busca.toLowerCase()))
            entry.key: entry.value
      };
    }
  }

  void _onBuscar(String value) {
    setState(() {
      _busca = value;
      _aplicarFiltro();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Preços dos Produtos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar produto',
                prefixIcon: Icon(Icons.search),
              ),
              autofillHints: null,
              enableSuggestions: false,
              autocorrect: false,
              onChanged: _onBuscar,
            ),
            const SizedBox(height: 16),
            if (_carregando)
              const Center(child: CircularProgressIndicator())
            else if (_historicoFiltrado.isEmpty)
              const Center(child: Text('Nenhum produto encontrado.'))
            else
              Expanded(
                child: ListView(
                  children: _historicoFiltrado.entries.map((entry) {
                    final nomeProduto = entry.key;
                    final precos = entry.value
                      ..removeWhere((p) => p.preco == null || p.data.isEmpty)
                      ..sort((a, b) => a.data.compareTo(b.data));
                    if (precos.isEmpty) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(nomeProduto, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Sem dados de preço para exibir o gráfico.'),
                        ),
                      );
                    }
                    final menorPreco = precos.map((p) => p.preco!).reduce((a, b) => a < b ? a : b);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ExpansionTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nomeProduto,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Menor preço: \$ ${menorPreco.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        children: [
                          SizedBox(
                            height: 220,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: _buildLineChart(precos),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<_ProdutoPrecoPorData> precos) {
    final pontos = <FlSpot>[];
    final labels = <int, String>{};
    for (var i = 0; i < precos.length; i++) {
      final p = precos[i];
      try {
        final partes = p.data.split('-');
        if (partes.length == 3) {
          final dia = partes[2].padLeft(2, '0');
          final mes = partes[1].padLeft(2, '0');
          labels[i] = '$dia/$mes';
        } else {
          labels[i] = p.data;
        }
        pontos.add(FlSpot(i.toDouble(), p.preco ?? 0));
      } catch (_) {}
    }
    if (pontos.isEmpty) {
      return const Center(child: Text('Sem dados para o gráfico.'));
    }
    return LineChart(
      LineChartData(
        minY: pontos.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 1,
        maxY: pontos.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 1,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                return Text(labels[idx] ?? '', style: const TextStyle(fontSize: 10));
              },
              interval: 1,
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: pontos,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}

class _ProdutoPrecoPorData {
  final String data;
  final double? preco;
  final int quantidade;

  _ProdutoPrecoPorData({
    required this.data,
    required this.preco,
    required this.quantidade,
  });
}