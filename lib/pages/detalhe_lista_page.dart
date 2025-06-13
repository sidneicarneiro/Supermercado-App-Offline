import 'package:flutter/material.dart';
import '../data/lista_repository.dart';
import '../models/lista_compra.dart';
import '../models/item_lista.dart';

class DetalheListaPage extends StatefulWidget {
  final int idLista;
  const DetalheListaPage({super.key, required this.idLista});

  @override
  State<DetalheListaPage> createState() => _DetalheListaPageState();
}

class _DetalheListaPageState extends State<DetalheListaPage> {
  final repo = ListaRepository();
  late Future<ListaCompra> _listaFuture;
  late Future<List<ItemLista>> _itensFuture;
  DateTime? _dataEditavel;
  bool _salvandoData = false;
  final Map<int, TextEditingController> _precoControllers = {};
  final Map<int, TextEditingController> _quantidadeControllers = {};
  final Map<int, bool> _showSuccessIcon = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _listaFuture = repo.listarListas().then((listas) => listas.firstWhere((l) => l.id == widget.idLista));
    _itensFuture = repo.listarItens(widget.idLista);
  }

  Future<List<String>> _buscarProdutos(String query) async {
    if (query.length < 3) return [];
    return await repo.buscarProdutos(query);
  }

  Future<void> _selecionarData(ListaCompra lista) async {
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
      await repo.atualizarDataCompra(lista.id!, novaData.toIso8601String());
      setState(() {
        _salvandoData = false;
        _carregar();
      });
    }
  }

  Future<void> _gravarItem(ItemLista item) async {
    item.preco = double.tryParse(_precoControllers[item.idItemProduto!]!.text);
    item.quantidade = int.tryParse(_quantidadeControllers[item.idItemProduto!]!.text) ?? 1;
    await repo.atualizarItem(item);
    setState(() {
      _showSuccessIcon[item.idItemProduto!] = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _showSuccessIcon[item.idItemProduto!] = false;
      _carregar();
    });
  }

  Future<void> _excluirItem(int idItemProduto) async {
    await repo.excluirItem(idItemProduto);
    setState(() {
      _carregar();
    });
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
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) async {
                        if (textEditingValue.text.length < 3) return const Iterable<String>.empty();
                        return await _buscarProdutos(textEditingValue.text);
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        nomeController.text = controller.text;
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(labelText: 'Nome do Produto'),
                          validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                          autofillHints: null,
                          enableSuggestions: false,
                          autocorrect: false,
                        );
                      },
                      onSelected: (String selection) {
                        nomeController.text = selection;
                      },
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
                      autofillHints: null,
                      enableSuggestions: false,
                      autocorrect: false,
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
                    await repo.adicionarItem(
                      widget.idLista,
                      ItemLista(
                        nomeProduto: nomeController.text,
                        quantidade: int.parse(quantidadeController.text),
                      ),
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    setState(() {
                      _carregar();
                    });
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da Lista')),
      body: FutureBuilder<ListaCompra>(
        future: _listaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Nenhum detalhe encontrado.'));
          }
          final lista = snapshot.data!;
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
                  child: FutureBuilder<List<ItemLista>>(
                    future: _itensFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final itens = snapshot.data!;
                      final total = itens.fold<double>(
                        0,
                            (sum, item) => sum + (item.quantidade * (item.preco ?? 0)),
                      );
                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: itens.length,
                              itemBuilder: (context, index) {
                                final item = itens[index];
                                _precoControllers.putIfAbsent(
                                  item.idItemProduto!,
                                      () => TextEditingController(
                                    text: item.preco?.toStringAsFixed(2) ?? '',
                                  ),
                                );
                                _quantidadeControllers.putIfAbsent(
                                  item.idItemProduto!,
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
                                              if (_showSuccessIcon[item.idItemProduto!] == true)
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
                                            controller: _quantidadeControllers[item.idItemProduto!],
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
                                            controller: _precoControllers[item.idItemProduto!],
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
                                          onPressed: () => _excluirItem(item.idItemProduto!),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: colorScheme.secondary,
                                            foregroundColor: colorScheme.onSecondary,
                                            minimumSize: const Size(50, 36),
                                            padding: EdgeInsets.zero,
                                          ),
                                          onPressed: () => _gravarItem(item),
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
                      );
                    },
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