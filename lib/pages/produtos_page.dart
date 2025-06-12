import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import '../utils/auth_utils.dart';
import 'package:fl_chart/fl_chart.dart';

class ProdutosPage extends StatefulWidget {
  const ProdutosPage({super.key});

  @override
  State<ProdutosPage> createState() => _ProdutosPageState();
}

class _ProdutosPageState extends State<ProdutosPage> {
  late Future<List<Produto>> _produtosFuture;

  @override
  void initState() {
    super.initState();
    _produtosFuture = fetchProdutos();
  }

  Future<List<Produto>> fetchProdutos() async {
    final url = Uri.parse('$kApiHost/produtos/precos-por-data');
    final headers = await getAuthHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Produto.fromJson(e)).toList();
    }
    throw Exception('Erro ao buscar produtos');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produtos')),
      body: FutureBuilder<List<Produto>>(
        future: _produtosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum produto encontrado.'));
          }
          final produtos = snapshot.data!;
          return ListView.builder(
            itemCount: produtos.length,
            itemBuilder: (context, index) {
              final produto = produtos[index];
              final temGrafico = produto.precos.length > 1;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(produto.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      if (temGrafico)
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < 0 || idx >= produto.precos.length) return const SizedBox.shrink();
                                      final data = DateTime.parse(produto.precos[idx].data);
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      );
                                    },
                                    reservedSize: 32,
                                    interval: 1,
                                  ),
                                ),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: true),
                              minX: 0,
                              maxX: (produto.precos.length - 1).toDouble(),
                              minY: produto.precos.map((e) => e.preco).reduce((a, b) => a < b ? a : b) - 1,
                              maxY: produto.precos.map((e) => e.preco).reduce((a, b) => a > b ? a : b) + 1,
                              lineBarsData: [
                                LineChartBarData(
                                  isCurved: true,
                                  color: Colors.blue,
                                  barWidth: 3,
                                  dotData: FlDotData(show: true),
                                  spots: [
                                    for (int i = 0; i < produto.precos.length; i++)
                                      FlSpot(i.toDouble(), produto.precos[i].preco)
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (produto.precos.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: produto.precos.map((preco) {
                            final data = DateTime.parse(preco.data);
                            return Text(
                              'Data: ${data.day.toString().padLeft(2, '0')}/'
                              '${data.month.toString().padLeft(2, '0')}/'
                              '${data.year} - Preço: R\$ ${preco.preco.toStringAsFixed(2)}',
                            );
                          }).toList(),
                        )
                      else
                        const Text('Sem preços cadastrados'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class Produto {
  final int id;
  final String nome;
  final List<PrecoProduto> precos;

  Produto({required this.id, required this.nome, required this.precos});

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'],
      nome: json['nome'],
      precos: (json['precos'] as List?)
              ?.map((e) => PrecoProduto.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class PrecoProduto {
  final String data;
  final double preco;

  PrecoProduto({required this.data, required this.preco});

  factory PrecoProduto.fromJson(Map<String, dynamic> json) {
    return PrecoProduto(
      data: json['data'],
      preco: (json['preco'] as num).toDouble(),
    );
  }
}