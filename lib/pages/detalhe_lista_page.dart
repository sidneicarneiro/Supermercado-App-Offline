import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/auth_utils.dart';

class ItemLista {
  final int idItemProduto;
  final String nomeProduto;
  int quantidade;
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

class ListaCompraDetalhe {
  final int id;
  final String nomeLista;
  final String? dataCompra;
  final List<ItemLista> itens;

  ListaCompraDetalhe({
    required this.id,
    required this.nomeLista,
    required this.dataCompra,
    required this.itens,
  });

  factory ListaCompraDetalhe.fromJson(Map<String, dynamic> json) {
    var itensJson = json['itens'] as List;
    List<ItemLista> itens = itensJson.map((e) => ItemLista.fromJson(e)).toList();
    return ListaCompraDetalhe(
      id: json['id'],
      nomeLista: json['nomeLista'],
      dataCompra: json['dataCompra'],
      itens: itens,
    );
  }
}

class DetalheListaPage extends StatefulWidget {
  final int idLista;
  const DetalheListaPage({super.key, required this.idLista});

  @override
  State<DetalheListaPage> createState() => _DetalheListaPageState();
}

class _DetalheListaPageState extends State<DetalheListaPage> {
  late Future<ListaCompraDetalhe> _detalheFuture;
  DateTime? _dataEditavel;
  bool _salvandoData = false;
  final Map<int, TextEditingController> _precoControllers = {};
  final Map<int, TextEditingController> _quantidadeControllers = {};
  final Map<int, bool> _showSuccessIcon = {};

  Future<ListaCompraDetalhe> fetchDetalhe() async {
    final headers = await getAuthHeaders();
    final response = await http.get(
        Uri.parse('$kApiHost/lista/${widget.idLista}'),
        headers: headers,
    );
    if (response.statusCode == 200) {
      return ListaCompraDetalhe.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erro ao carregar detalhes');
    }
  }

  Future<void> _selecionarData(ListaCompraDetalhe lista) async {
    final dataAtual = _dataEditavel ?? (lista.dataCompra != null ? DateTime.parse(lista.dataCompra!) : DateTime.now());
    final novaData = await showDatePicker(
      context: context,
      initialDate: dataAtual,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (novaData != null) {
      setState(() {
        _dataEditavel = novaData;
        _salvandoData = true;
      });
      final headers = await getAuthHeaders();
      final url = Uri.parse('$kApiHost/lista/${lista.id}?dataCompra=${novaData.toIso8601String()}');
      try {
        await http.put(url, headers: headers);
        setState(() {
          _salvandoData = false;
        });
        setState(() {
          _detalheFuture = fetchDetalhe();
        });
      } catch (_) {
        setState(() {
          _salvandoData = false;
        });
      }
    }
  }

  Future<void> _gravarItem(int idItemProduto) async {
    final preco = _precoControllers[idItemProduto]?.text ?? '';
    final quantidade = _quantidadeControllers[idItemProduto]?.text ?? '';
    final url = Uri.parse('$kApiHost/item-lista/$idItemProduto?preco=$preco&quantidade=$quantidade');
    try {
      final headers = await getAuthHeaders();
      final response = await http.put(url, headers: headers);
      if (response.statusCode == 200) {
        setState(() {
          _showSuccessIcon[idItemProduto] = true;
        });
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _showSuccessIcon[idItemProduto] = false;
        });
        setState(() {
          _detalheFuture = fetchDetalhe();
        });
      }
    } catch (_) {}
  }

  Future<void> _excluirItem(int idItemProduto) async {
    final url = Uri.parse('$kApiHost/item-lista/$idItemProduto');
    try {
      final headers = await getAuthHeaders();
      final response = await http.delete(url, headers: headers);
      if (response.statusCode == 204) {
        // Atualiza a lista imediatamente após a exclusão
        setState(() {
          _detalheFuture = fetchDetalhe();
        });
      } else {
        // Opcional: exibir mensagem de erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir item, erro: ${response.statusCode}')),
        );
      }
    } catch (_) {
      // Opcional: exibir mensagem de erro
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir item')),
      );
    }
  }

  Future<void> _adicionarItemDialog() async {
    final nomeController = TextEditingController();
    final quantidadeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool carregando = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Adicionar Item'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nomeController,
                      decoration: const InputDecoration(labelText: 'Nome do Produto'),
                      validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: quantidadeController,
                      decoration: const InputDecoration(labelText: 'Quantidade'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Informe a quantidade';
                        if (int.tryParse(v) == null) return 'Quantidade inválida';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: carregando ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: carregando
                      ? null
                      : () async {
                    if (!formKey.currentState!.validate()) return;
                    setStateDialog(() => carregando = true);
                    final url = Uri.parse('$kApiHost/item-lista/${widget.idLista}');
                    final body = jsonEncode({
                      'nomeProduto': nomeController.text,
                      'quantidade': int.parse(quantidadeController.text),
                    });
                    try {
                      final response = await http.post(
                        url,
                        headers: {'Content-Type': 'application/json'},
                        body: body,
                      );
                      if (response.statusCode == 200 || response.statusCode == 201) {
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        setState(() {
                          _detalheFuture = fetchDetalhe();
                        });
                      }
                    } finally {
                      setStateDialog(() => carregando = false);
                    }
                  },
                  child: carregando
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _detalheFuture = fetchDetalhe();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da Lista')),
      body: FutureBuilder<ListaCompraDetalhe>(
        future: _detalheFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Nenhum detalhe encontrado.'));
          }
          final lista = snapshot.data!;
          final total = lista.itens.fold<double>(
            0,
                (sum, item) => sum + (item.quantidade * (item.preco ?? 0)),
          );
          final dataCompra = _dataEditavel ?? (lista.dataCompra != null ? DateTime.parse(lista.dataCompra!) : null);
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lista.nomeLista,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      dataCompra != null
                          ? 'Data: ${dataCompra.day.toString().padLeft(2, '0')}/'
                          '${dataCompra.month.toString().padLeft(2, '0')}/'
                          '${dataCompra.year}'
                          : 'Sem data',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_calendar),
                      tooltip: 'Editar data',
                      onPressed: _salvandoData ? null : () => _selecionarData(lista),
                    ),
                    if (_salvandoData)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Adicionar item',
                      onPressed: _adicionarItemDialog,
                    ),
                  ],
                ),
                const Divider(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: lista.itens.length,
                    itemBuilder: (context, index) {
                      final item = lista.itens[index];
                      _precoControllers.putIfAbsent(
                        item.idItemProduto,
                            () => TextEditingController(
                          text: item.preco?.toStringAsFixed(2) ?? '',
                        ),
                      );
                      _quantidadeControllers.putIfAbsent(
                        item.idItemProduto,
                            () => TextEditingController(
                          text: item.quantidade.toString(),
                        ),
                      );
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.nomeProduto,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_showSuccessIcon[item.idItemProduto] == true)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                flex: 1,
                                child: TextField(
                                  controller: _quantidadeControllers[item.idItemProduto],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Qtd',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                flex: 1,
                                child: TextField(
                                  controller: _precoControllers[item.idItemProduto],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Preço',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Excluir item',
                                onPressed: () => _excluirItem(item.idItemProduto),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.secondary,
                                  foregroundColor: colorScheme.onSecondary,
                                  minimumSize: const Size(50, 36),
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () => _gravarItem(item.idItemProduto),
                                child: const Text('Gravar', style: TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Total: R\$ ${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}