import 'dart:async';
import 'package:flutter/material.dart';
import '../data/lista_repository.dart';
import '../data/categorias_repository.dart';
import '../models/lista_compra.dart';
import '../models/item_lista.dart';
import '../models/categoria.dart';
import '../utils/utilidades.dart';

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
  Timer? _debounce;
  final List<String> _unidades = ['un', 'kg', 'g', 'L', 'ml', 'pacote', 'cx', 'dz'];
  final Map<int, FocusNode> _precoFocusNodes = {};
  final Map<int, FocusNode> _quantidadeFocusNodes = {};
  final Map<int, FocusNode> _nomeProdutoFocusNodes = {};
  List<Categoria> _categorias = [];
  bool _carregandoCategorias = true;
  final _categoriaRepository = CategoriasRepository();
  List<ItemLista> _itens = [];

  @override
  void initState() {
    super.initState();
    _carregar();
    CategoriasRepository().categorias().then((cats) {
      setState(() {
        _categorias = cats;
        _carregandoCategorias = false;
      });
    });
  }

  void _carregar() {
    _listaFuture = repo.listarListas().then((listas) => listas.firstWhere((l) => l.id == widget.idLista));
    _itensFuture = repo.listarItens(widget.idLista);
  }

  Map<Categoria, List<ItemLista>> _agruparItensPorCategoria(List<ItemLista> itens, List<Categoria> categorias) {
    final Map<Categoria, List<ItemLista>> agrupado = {};
    for (final item in itens) {
      final categoria = categorias.firstWhere(
            (cat) => cat.subcategorias.any((sub) => sub.id == item.categoria),
        orElse: () => categorias.first,
      );
      agrupado.putIfAbsent(categoria, () => []).add(item);
    }
    return agrupado;
  }

  void _salvarPreco(ItemLista item, String novoValor) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      double? novoPreco = double.tryParse(novoValor.replaceAll(',', '.'));
      await repo.atualizarItemLista(item.copyWith(preco: novoPreco));
      setState(() {
        final idx = _itens.indexWhere((i) => i.idItemProduto == item.idItemProduto);
        if (idx != -1) {
          _itens[idx] = _itens[idx].copyWith(preco: novoPreco);
          _showSuccessIcon[item.idItemProduto!] = true;
        }
      });
      // Esconde o ícone após 1 segundo
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _showSuccessIcon[item.idItemProduto!] = false;
          });
        }
      });
    });
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

  Future<void> _excluirItem(int idItemProduto) async {
    await repo.excluirItem(idItemProduto);
    setState(() {
      _carregar();
    });
  }

  Future<void> _adicionarItemDialog() async {
    final nomeController = TextEditingController();
    final quantidadeController = TextEditingController();
    final precoController = TextEditingController();
    String unidadeSelecionada = _unidades.first;
    final formKey = GlobalKey<FormState>();
    bool carregando = false;
    Categoria? categoriaSelecionada = _categorias.isNotEmpty ? _categorias.first : null;
    Subcategoria? subcategoriaSelecionada = categoriaSelecionada?.subcategorias.first;

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
                    DropdownButtonFormField<Categoria>(
                      value: categoriaSelecionada,
                      items: _categorias
                          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat.nome)))
                          .toList(),
                      onChanged: (cat) {
                        setStateDialog(() {
                          categoriaSelecionada = cat;
                          subcategoriaSelecionada = cat?.subcategorias.first;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Categoria'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Subcategoria>(
                      value: subcategoriaSelecionada,
                      items: (categoriaSelecionada?.subcategorias ?? [])
                          .map((sub) => DropdownMenuItem(
                        value: sub,
                        child: Row(
                          children: [
                            Icon(getMaterialSymbol(sub.icone ?? 'category')),
                            const SizedBox(width: 8),
                            Text(sub.nome),
                          ],
                        ),
                      ))
                          .toList(),
                      onChanged: (sub) {
                        setStateDialog(() {
                          subcategoriaSelecionada = sub;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Subcategoria'),
                    ),
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
                        if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Quantidade inválida';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: unidadeSelecionada,
                      items: _unidades
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) {
                        setStateDialog(() {
                          unidadeSelecionada = v ?? _unidades.first;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Und.'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: precoController,
                      decoration: const InputDecoration(labelText: 'Preço (€)'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v != null && v.isNotEmpty && double.tryParse(v.replaceAll(',', '.')) == null) return 'Preço inválido';
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
                    var itemLista = ItemLista(
                      categoria: subcategoriaSelecionada?.id ?? 0,
                      nomeProduto: nomeController.text,
                      quantidade: double.parse(quantidadeController.text.replaceAll(',', '.')),
                      unidade: unidadeSelecionada,
                      preco: precoController.text.isNotEmpty ? double.tryParse(precoController.text.replaceAll(',', '.')) : null,
                    );
                    itemLista = await repo.adicionarItem(
                      widget.idLista,
                      itemLista,
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    setState(() {
                     _itens.add(itemLista);
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

  Future<void> _editarItemDialog(ItemLista item) async {
    final nomeController = TextEditingController(text: item.nomeProduto);
    final quantidadeController = TextEditingController(text: item.quantidade.toString());
    final precoController = TextEditingController(text: item.preco?.toString() ?? '');
    String unidadeSelecionada = item.unidade ?? _unidades.first;
    final formKey = GlobalKey<FormState>();
    bool carregando = false;
    Categoria categoriaSelecionada = await _categoriaRepository.buscarCategoriaPorSubcategoria(item.categoria);
    categoriaSelecionada = _categorias.firstWhere(
          (cat) => cat.id == categoriaSelecionada.id,
      orElse: () => _categorias.first,
    );
    Subcategoria subcategoriaSelecionada = categoriaSelecionada.subcategorias.firstWhere(
          (sub) => sub.id == item.categoria,
      orElse: () => categoriaSelecionada.subcategorias.first,
    );
    final resultado = await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Editar Item'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Categoria>(
                      value: categoriaSelecionada,
                      items: _categorias
                          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat.nome)))
                          .toList(),
                      onChanged: (cat) {
                        setStateDialog(() {
                          categoriaSelecionada = cat ?? _categorias.first;
                          subcategoriaSelecionada = (cat ?? _categorias.first).subcategorias.first;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Categoria'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Subcategoria>(
                      value: subcategoriaSelecionada,
                      items: (categoriaSelecionada?.subcategorias ?? [])
                          .map((sub) => DropdownMenuItem(
                        value: sub,
                        child: Row(
                          children: [
                            Icon(getMaterialSymbol(sub.icone ?? 'category')),
                            const SizedBox(width: 8),
                            Text(sub.nome),
                          ],
                        ),
                      )).toList(),
                      onChanged: (sub) {
                        setStateDialog(() {
                          subcategoriaSelecionada = sub ?? _categorias.first.subcategorias.first;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Subcategoria'),
                    ),
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) async {
                        if (textEditingValue.text.length < 3) return const Iterable<String>.empty();
                        final results = await _buscarProdutos(textEditingValue.text);
                        return results;
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        controller.text = nomeController.text;
                        controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: controller.text.length),
                        );
                        return TextFormField(
                          controller: controller,
                          focusNode: _nomeProdutoFocusNodes[item.idItemProduto!],
                          decoration: const InputDecoration(labelText: 'Nome do Produto'),
                          validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
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
                      focusNode: _quantidadeFocusNodes[item.idItemProduto!],
                      decoration: const InputDecoration(labelText: 'Quantidade'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Informe a quantidade';
                        if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Quantidade inválida';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: unidadeSelecionada,
                      items: _unidades
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) {
                        setStateDialog(() {
                          unidadeSelecionada = v ?? _unidades.first;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Und.'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: precoController,
                      focusNode: _precoFocusNodes[item.idItemProduto!],
                      decoration: const InputDecoration(labelText: 'Preço (€)'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v != null && v.isNotEmpty && double.tryParse(v.replaceAll(',', '.')) == null) return 'Preço inválido';
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
                    final itemLista = ItemLista(
                      idItemProduto: item.idItemProduto,
                      idLista: item.idLista,
                      categoria: subcategoriaSelecionada.id,
                      nomeProduto: nomeController.text,
                      quantidade: double.parse(quantidadeController.text.replaceAll(',', '.')),
                      unidade: unidadeSelecionada,
                      preco: precoController.text.isNotEmpty ? double.tryParse(precoController.text.replaceAll(',', '.')) : null,
                    );
                    await repo.atualizarItemLista(
                      itemLista,
                    );
                    if (!context.mounted) return;
                    if (_precoControllers[item.idItemProduto!] != null) {
                      _precoControllers[item.idItemProduto!]!.text =
                      precoController.text.isNotEmpty ? double.parse(precoController.text.replaceAll(',', '.')).toStringAsFixed(2) : '';
                    }
                    Navigator.pop(context, true);
                    setState(() {
                      _itens.firstWhere((it) => it.idItemProduto == item.idItemProduto, orElse: () => item)
                          .copyWith(
                        categoria: subcategoriaSelecionada.id,
                        nomeProduto: nomeController.text,
                        quantidade: double.parse(quantidadeController.text.replaceAll(',', '.')),
                        unidade: unidadeSelecionada,
                        preco: precoController.text.isNotEmpty ? double.tryParse(precoController.text.replaceAll(',', '.')) : null,
                      );
                    });
                  },
                  child: carregando
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (!mounted) return;
    if (resultado == true) {
      setState(() {
        _carregar();
      });
    }
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
    for (final node in _precoFocusNodes.values) {
      node.dispose();
    }
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
                      if (_itens.isEmpty && snapshot.hasData) {
                        _itens = List<ItemLista>.from(snapshot.data!);
                      }
                      final total = _itens.fold<double>(
                        0,
                            (sum, item) => sum + (item.quantidade * (item.preco ?? 0)),
                      );
                      return Column(
                        children: [
                          Expanded(
                            child: FutureBuilder<List<Categoria>>(
                              future: CategoriasRepository().categorias(),
                              builder: (context, catSnapshot) {
                                if (!catSnapshot.hasData) return const SizedBox();
                                final categorias = catSnapshot.data!;
                                final agrupado = _agruparItensPorCategoria(_itens, categorias);
                                if (agrupado.isEmpty) {
                                  return const Center(child: Text('Nenhum produto adicionado.'));
                                }
                                return ListView(
                                  children: agrupado.entries.expand((entry) {
                                    final categoria = entry.key;
                                    final itensCat = entry.value;
                                    return [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Text(
                                          categoria.nome,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                      ),
                                      ...itensCat.map((item) {
                                        final sub = categoria.subcategorias.firstWhere((s) => s.id == item.categoria, orElse: () => categoria.subcategorias.first);
                                        if (_precoControllers[item.idItemProduto!] == null) {
                                          _precoControllers[item.idItemProduto!] = TextEditingController(
                                            text: item.preco != null ? item.preco!.toStringAsFixed(2) : '',
                                          );
                                        }
                                        return Card(
                                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  getMaterialSymbol(sub.icone ?? 'category'),
                                                  size: 22,
                                                  color: (item.preco != null && item.preco! > 0.0) ? Colors.green : Colors.black54,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  flex: 2,
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
                                                Expanded(
                                                  flex: 1,
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        flex: 2,
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                                          alignment: Alignment.centerLeft,
                                                          child: Text(
                                                            formatarQuantidade(item.quantidade),
                                                            style: const TextStyle(
                                                              fontSize: 14,
                                                              color: Colors.black87,
                                                              fontFamily: 'Roboto',
                                                              fontWeight: FontWeight.normal,
                                                              height: 1.2,
                                                            ),
                                                            overflow: TextOverflow.visible,
                                                            textAlign: TextAlign.left,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        item.unidade ?? '',
                                                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  flex: 1,
                                                  child: Row(
                                                    children: [
                                                      const Text(
                                                        '€',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.black87,
                                                          fontFamily: 'Roboto',
                                                          fontWeight: FontWeight.normal,
                                                          height: 1.2,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: TextField(
                                                          controller: _precoControllers[item.idItemProduto!],
                                                          focusNode: _precoFocusNodes[item.idItemProduto!],
                                                          keyboardType: TextInputType.number,
                                                          decoration: const InputDecoration(
                                                            border: InputBorder.none,
                                                            isDense: true,
                                                            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                                          ),
                                                          onChanged: (value) {
                                                            if (_debounce?.isActive ?? false) _debounce!.cancel();
                                                            _debounce = Timer(const Duration(seconds: 2), () {
                                                              _salvarPreco(item, value);
                                                            });
                                                          },
                                                        )
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                SizedBox(
                                                  width: 40,
                                                  child: IconButton(
                                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                                    tooltip: 'Editar item',
                                                    onPressed: () => _editarItemDialog(item),
                                                  )
                                                ),
                                                SizedBox(
                                                  width: 40,
                                                  child: IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                    tooltip: 'Excluir item',
                                                    onPressed: () => _excluirItem(item.idItemProduto!),
                                                  )
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ];
                                  }).toList(),
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
                                  'Total: € ${total.toStringAsFixed(2)}',
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