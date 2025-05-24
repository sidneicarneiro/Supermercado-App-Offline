import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';

// Modelos
class ItemLista {
  final int idItemProduto;
  final String nomeProduto;
  final int quantidade;
  double? preco;

  ItemLista({
    required this.idItemProduto,
    required this.nomeProduto,
    required this.quantidade,
    this.preco,
  });

  factory ItemLista.fromJson(Map<String, dynamic> json) {
    return ItemLista(
      idItemProduto: json['idItemProduto'],
      nomeProduto: json['nomeProduto'],
      quantidade: json['quantidade'],
      preco: (json['preco'] != null) ? (json['preco'] as num).toDouble() : null,
    );
  }
}

class ListaCompra {
  final int id;
  final String nomeLista;
  final String? dataCompra;
  final List<ItemLista> itens;

  ListaCompra({
    required this.id,
    required this.nomeLista,
    required this.dataCompra,
    required this.itens,
  });

  factory ListaCompra.fromJson(Map<String, dynamic> json) {
    var itensJson = json['itens'] as List;
    List<ItemLista> itens = itensJson.map((e) => ItemLista.fromJson(e)).toList();
    return ListaCompra(
      id: json['id'],
      nomeLista: json['nomeLista'],
      dataCompra: json['dataCompra'],
      itens: itens,
    );
  }
}

class ListarListaPage extends StatefulWidget {
  const ListarListaPage({super.key});

  @override
  State<ListarListaPage> createState() => _ListarListaPageState();
}

class _ListarListaPageState extends State<ListarListaPage> {
  late Future<List<ListaCompra>> _listasFuture;
  final Map<int, TextEditingController> _precoControllers = {};
  final Map<int, Color> _precoFieldColors = {};
  final Map<int, DateTime?> _datasEditaveis = {};
  final Map<int, bool> _salvandoData = {};

  Future<List<ListaCompra>> fetchListas() async {
    final response = await http.get(Uri.parse('$kApiHost/listas'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ListaCompra.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao carregar listas');
    }
  }

  @override
  void initState() {
    super.initState();
    _listasFuture = fetchListas();
  }

  Future<void> _gravarPreco(int idItemProduto, String preco) async {
    final url = Uri.parse('$kApiHost/item-lista/$idItemProduto?preco=$preco');
    try {
      final response = await http.put(url);
      setState(() {
        _precoFieldColors[idItemProduto] =
        (response.statusCode == 200) ? Colors.green[100]! : Colors.red[100]!;
      });
    } catch (_) {
      setState(() {
        _precoFieldColors[idItemProduto] = Colors.red[100]!;
      });
    }
  }

  Future<void> _salvarDataCompra(int index, ListaCompra lista) async {
    final data = _datasEditaveis[index];
    if (data == null) return;
    setState(() {
      _salvandoData[index] = true;
    });
    final url = Uri.parse('$kApiHost/lista/${lista.id}?dataCompra=${data.toIso8601String()}');
    try {
      await http.put(url);
    } finally {
      setState(() {
        _salvandoData[index] = false;
      });
    }
  }

  Future<void> _selecionarData(int index, ListaCompra lista) async {
    final dataAtual = _datasEditaveis[index] ?? (lista.dataCompra != null ? DateTime.parse(lista.dataCompra!) : DateTime.now());
    final novaData = await showDatePicker(
      context: context,
      initialDate: dataAtual,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (novaData != null) {
      setState(() {
        _datasEditaveis[index] = novaData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listar Listas'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<ListaCompra>>(
          future: _listasFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Nenhuma lista encontrada.'));
            }
            final listas = snapshot.data!;
            return ListView.builder(
              itemCount: listas.length,
              itemBuilder: (context, index) {
                final lista = listas[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lista.nomeLista,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => _selecionarData(index, lista),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    (_datasEditaveis[index] ?? (lista.dataCompra != null ? DateTime.parse(lista.dataCompra!) : null)) != null
                                        ? '${(_datasEditaveis[index] ?? DateTime.parse(lista.dataCompra!)).day.toString().padLeft(2, '0')}/'
                                        '${(_datasEditaveis[index] ?? DateTime.parse(lista.dataCompra!)).month.toString().padLeft(2, '0')}/'
                                        '${(_datasEditaveis[index] ?? DateTime.parse(lista.dataCompra!)).year}'
                                        : 'Sem data',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: _salvandoData[index] == true
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.save, size: 18),
                              tooltip: 'Salvar data',
                              onPressed: _salvandoData[index] == true
                                  ? null
                                  : () => _salvarDataCompra(index, lista),
                            ),
                          ],
                        ),
                        const Divider(),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: lista.itens.length,
                          itemBuilder: (context, itemIndex) {
                            final item = lista.itens[itemIndex];
                            _precoControllers.putIfAbsent(
                              item.idItemProduto,
                                  () => TextEditingController(
                                  text: item.preco?.toStringAsFixed(2) ?? ''),
                            );
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(item.nomeProduto),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text('Qtd: ${item.quantidade}'),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      color: _precoFieldColors[item.idItemProduto],
                                      child: TextField(
                                        controller: _precoControllers[item.idItemProduto],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Preço',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.secondary,
                                      foregroundColor: colorScheme.onSecondary,
                                    ),
                                    onPressed: () {
                                      final preco = _precoControllers[item.idItemProduto]!.text;
                                      _gravarPreco(item.idItemProduto, preco);
                                    },
                                    child: const Text('Gravar'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}