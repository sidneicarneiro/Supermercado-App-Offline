import 'package:flutter/material.dart';
import '../models/produto_preco_data.dart';
import '../data/lista_repository.dart';
import 'widgets/produto_line_chart.dart';
import 'dart:async';

class ProdutosPage extends StatefulWidget {
  const ProdutosPage({super.key});

  @override
  State<ProdutosPage> createState() => _ProdutosPageState();
}

class _ProdutosPageState extends State<ProdutosPage> {
  final repo = ListaRepository();
  Map<String, List<ProdutoPrecoPorData>> _historicoCompleto = {};
  Map<String, List<ProdutoPrecoPorData>> _historicoFiltrado = {};
  String _busca = '';
  bool _carregando = false;

  // Controle do ponto selecionado no gráfico
  int? _pontoSelecionado;
  double? _precoSelecionado;
  Offset? _posicaoLabel;
  Timer? _timerLabel;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() => _carregando = true);

    final listas = await repo.listarListas();
    final Map<String, List<ProdutoPrecoPorData>> historico = {};

    for (final lista in listas) {
      final itens = await repo.listarItens(lista.id!);
      for (final item in itens) {
        historico.putIfAbsent(item.nomeProduto, () => []);
        historico[item.nomeProduto]!.add(
          ProdutoPrecoPorData(
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
  void dispose() {
    _timerLabel?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entriesOrdenadas = _historicoFiltrado.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Preços')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar produto',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onBuscar,
            ),
            const SizedBox(height: 16),
            if (_carregando)
              const Center(child: CircularProgressIndicator())
            else if (entriesOrdenadas.isEmpty)
              const Center(child: Text('Nenhum produto encontrado.'))
            else
              Expanded(
                child: ListView(
                  children: entriesOrdenadas.map((entry) {
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
                                'Menor preço: € ${menorPreco.toStringAsFixed(2)}',
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

  Widget _buildLineChart(List<ProdutoPrecoPorData> precos) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ProdutoLineChart(precos: precos);
      },
    );
  }
}