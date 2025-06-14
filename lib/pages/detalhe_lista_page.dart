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
  final Map<int, GlobalKey> _nomeKeys = {};
  OverlayEntry? _overlayEntry;

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

  DateTime? parseDataCompra(String? data) {
    if (data == null || data.isEmpty) return null;
    try {
      if (data.contains('/')) {
        final partes = data.split('/');
        if (partes.length == 3) {
          final ano = int.parse(partes[0]);
          final mes = int.parse(partes[1]);
          final dia = int.parse(partes[2]);
          return DateTime(ano, mes, dia);
        }
      }
      // fallback para o parse padrão
      return DateTime.parse(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> _selecionarData(ListaCompra lista) async {
    final dataAtual = _dataEditavel ?? (lista.dataCompra != null ? parseDataCompra(lista.dataCompra) : null);
    final novaData = await showDatePicker(
      context: context,
      initialDate: dataAtual ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (novaData != null) {
      setState(() {
        _dataEditavel = novaData;
        _salvandoData = true;
      });
      final dataFormatada = '${novaData.year.toString().padLeft(4, '0')}/${novaData.month.toString().padLeft(2, '0')}/${novaData.day.toString().padLeft(2, '0')}';
      await repo.atualizarDataCompra(lista.id!, dataFormatada);
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
                        final results = await _buscarProdutos(textEditingValue.text);
                        return results;
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(labelText: 'Nome do Produto'),
                          validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                          autofillHints: null,
                          enableSuggestions: false,
                          autocorrect: false,
                          onChanged: (value) {
                            nomeController.text = value;
                          },
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

  void _mostrarNomeCompleto(int idItemProduto, String nomeProduto) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    final key = _nomeKeys[idItemProduto];
    if (key == null) return;
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    final position = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy - renderBox.size.height - 8,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 350),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              nomeProduto,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
    Future.delayed(const Duration(seconds: 1), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
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
          final dataCompra = _dataEditavel ?? (lista.dataCompra != null ? parseDataCompra(lista.dataCompra) : null);
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
                                _nomeKeys.putIfAbsent(item.idItemProduto!, () => GlobalKey());
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
                                                child: GestureDetector(
                                                  onTap: () => _mostrarNomeCompleto(item.idItemProduto!, item.nomeProduto),
                                                  child: Container(
                                                    key: _nomeKeys[item.idItemProduto!],
                                                    child: Text(
                                                      item.nomeProduto,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
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
                                  'Total: \$ ${total.toStringAsFixed(2)}',
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