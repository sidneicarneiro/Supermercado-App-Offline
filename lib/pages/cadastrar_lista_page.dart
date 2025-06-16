import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols_map.dart';
import 'package:material_symbols_icons/get.dart';
import '../models/lista_compra.dart';
import '../models/item_lista.dart';
import '../models/categoria.dart';
import '../data/lista_repository.dart';
import '../data/categorias_repository.dart';
import 'listar_listas_page.dart';
import '../utils/utilidades.dart';

class CadastrarListaPage extends StatefulWidget {
  const CadastrarListaPage({super.key});

  @override
  State<CadastrarListaPage> createState() => _CadastrarListaPageState();
}

class _CadastrarListaPageState extends State<CadastrarListaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeMercadoController = TextEditingController();
  final _nomeProdutoController = TextEditingController();
  final _quantidadeController = TextEditingController();
  final List<Map<String, dynamic>> _itens = [];
  final repo = ListaRepository();

  List<String> _sugestoesMercado = [];
  List<String> _sugestoesProduto = [];
  bool _carregandoSugestoesMercado = false;
  bool _carregandoSugestoesProduto = false;
  bool _carregandoCategorias = true;

  final FocusNode _focusNodeMercado = FocusNode();
  final FocusNode _focusNodeProduto = FocusNode();
  final LayerLink _layerLinkMercado = LayerLink();
  final LayerLink _layerLinkProduto = LayerLink();
  OverlayEntry? _overlayEntryMercado;
  OverlayEntry? _overlayEntryProduto;

  final List<String> _unidades = ['un', 'kg', 'g', 'L', 'ml', 'pacote', 'cx', 'dz'];
  String _unidadeSelecionada = 'un';
  List<Categoria> _categorias = [];
  Categoria? _categoriaSelecionada;
  Subcategoria? _subcategoriaSelecionada;

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
  }

  Future<void> _carregarCategorias() async {
    final repo = CategoriasRepository();
    _categorias = await repo.categorias();
    setState(() {
      _categoriaSelecionada = _categorias.first;
      _subcategoriaSelecionada = _categoriaSelecionada!.subcategorias.first;
      _carregandoCategorias = false;
    });
  }

  Map<Categoria, List<Map<String, dynamic>>> _agruparItensPorCategoria() {
    Map<int, Categoria> categoriasPorId = {
      for (var cat in _categorias) cat.id: cat
    };
    Map<int, Subcategoria> subcategoriasPorId = {
      for (var cat in _categorias)
        for (var sub in cat.subcategorias) sub.id: sub
    };

    Map<Categoria, List<Map<String, dynamic>>> agrupado = {};
    for (var item in _itens) {
      final subId = item['categoria'];
      final sub = subcategoriasPorId[subId];
      final cat = _categorias.firstWhere((c) => c.subcategorias.any((s) => s.id == subId));
      agrupado.putIfAbsent(cat, () => []).add(item);
    }
    return agrupado;
  }

  @override
  void dispose() {
    _nomeMercadoController.dispose();
    _nomeProdutoController.dispose();
    _quantidadeController.dispose();
    _focusNodeMercado.dispose();
    _focusNodeProduto.dispose();
    _removeOverlayMercado();
    _removeOverlayProduto();
    super.dispose();
  }

  Future<void> _buscarSugestoesMercado(String query) async {
    if (query.length < 2) {
      _removeOverlayMercado();
      setState(() => _sugestoesMercado = []);
      return;
    }
    setState(() => _carregandoSugestoesMercado = true);
    final results = await repo.buscarMercados(query);
    setState(() {
      _sugestoesMercado = results;
      _carregandoSugestoesMercado = false;
    });
    _showOverlayMercado();
  }

  Future<void> _buscarSugestoesProduto(String query) async {
    if (query.length < 3) {
      _removeOverlayProduto();
      setState(() => _sugestoesProduto = []);
      return;
    }
    setState(() => _carregandoSugestoesProduto = true);
    final results = await repo.buscarProdutos(query);
    setState(() {
      _sugestoesProduto = results;
      _carregandoSugestoesProduto = false;
    });
    _showOverlayProduto();
  }

  void _showOverlayMercado() {
    _removeOverlayMercado();
    if (_sugestoesMercado.isEmpty || !_focusNodeMercado.hasFocus) return;
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    _overlayEntryMercado = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLinkMercado,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 4,
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: _sugestoesMercado.map((s) {
                return ListTile(
                  title: Text(s),
                  onTap: () {
                    _nomeMercadoController.text = s;
                    _removeOverlayMercado();
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntryMercado!);
  }

  void _showOverlayProduto() {
    _removeOverlayProduto();
    if (_sugestoesProduto.isEmpty || !_focusNodeProduto.hasFocus) return;
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    _overlayEntryProduto = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLinkProduto,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 4,
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: _sugestoesProduto.map((s) {
                return ListTile(
                  title: Text(s),
                  onTap: () {
                    _nomeProdutoController.text = s;
                    _removeOverlayProduto();
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntryProduto!);
  }

  void _removeOverlayMercado() {
    _overlayEntryMercado?.remove();
    _overlayEntryMercado = null;
  }

  void _removeOverlayProduto() {
    _overlayEntryProduto?.remove();
    _overlayEntryProduto = null;
  }

  void _adicionarItem() {
    final nomeProduto = _nomeProdutoController.text.trim();
    final quantidade = _quantidadeController.text.trim();

    if (nomeProduto.isEmpty || quantidade.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Erro'),
          content: const Text('Preencha o nome do produto e a quantidade.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _itens.add({
        "nomeProduto": nomeProduto,
        "quantidade": double.tryParse(quantidade) ?? 1,
        "unidade": _unidadeSelecionada,
        "categoria": _subcategoriaSelecionada?.id,
      });
      _nomeProdutoController.clear();
      _quantidadeController.clear();
      _unidadeSelecionada = _unidades.first;
      _sugestoesProduto = [];
    });
    _removeOverlayProduto();
  }

  void _cadastrarLista() async {
    if (_itens.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Aviso'),
          content: const Text('Adicione pelo menos um produto à lista antes de cadastrar.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      final lista = ListaCompra(nomeLista: _nomeMercadoController.text);
      final itens = _itens
          .map((e) => ItemLista(
        nomeProduto: e['nomeProduto'],
        quantidade: e['quantidade'],
        unidade: e['unidade'],
        categoria: e['categoria'],
      ))
          .toList();
      await repo.inserirLista(lista, itens);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ListarListasPage()),
      );
    }
  }

  // Função para abrir o popup de seleção de categoria/subcategoria
  Future<void> _selecionarSubcategoria() async {
    Categoria? categoriaSelecionada = _categoriaSelecionada;
    Subcategoria? subcategoriaSelecionada = _subcategoriaSelecionada;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Selecionar Categoria e Subcategoria'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<Categoria>(
                      value: categoriaSelecionada,
                      isExpanded: true,
                      items: _categorias
                          .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat.nome),
                      ))
                          .toList(),
                      onChanged: (cat) {
                        setStateDialog(() {
                          categoriaSelecionada = cat;
                          subcategoriaSelecionada = cat!.subcategorias.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButton<Subcategoria>(
                      value: subcategoriaSelecionada,
                      isExpanded: true,
                      items: categoriaSelecionada!.subcategorias
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
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  icon: Icon(getMaterialSymbol(subcategoriaSelecionada!.icone ?? 'category')),
                  label: const Text('Adicionar Categoria'),
                  onPressed: () {
                    setState(() {
                      _categoriaSelecionada = categoriaSelecionada;
                      _subcategoriaSelecionada = subcategoriaSelecionada;
                    });
                    Navigator.of(context).pop();
                  },
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
    if (_carregandoCategorias) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Lista')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: CompositedTransformTarget(
                link: _layerLinkMercado,
                child: TextFormField(
                  controller: _nomeMercadoController,
                  focusNode: _focusNodeMercado,
                  decoration: const InputDecoration(labelText: 'Nome do Mercado'),
                  validator: (value) => value!.isEmpty ? 'Informe o nome do mercado' : null,
                  onChanged: (value) => _buscarSugestoesMercado(value),
                  onTap: () {
                    if (_nomeMercadoController.text.length >= 2) {
                      _buscarSugestoesMercado(_nomeMercadoController.text);
                    }
                  },
                  onEditingComplete: _removeOverlayMercado,
                ),
              ),
            ),
            if (_carregandoSugestoesMercado)
              const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: IconButton(
                      icon: Icon(
                        getMaterialSymbol(_subcategoriaSelecionada?.icone ?? 'category'),
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                      tooltip: 'Selecionar Categoria/Subcategoria',
                      onPressed: _selecionarSubcategoria,
                    )
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: CompositedTransformTarget(
                      link: _layerLinkProduto,
                      child: TextFormField(
                        controller: _nomeProdutoController,
                        focusNode: _focusNodeProduto,
                        decoration: const InputDecoration(labelText: 'Nome do Produto'),
                        onChanged: (value) => _buscarSugestoesProduto(value),
                        onTap: () {
                          if (_nomeProdutoController.text.length >= 3) {
                            _buscarSugestoesProduto(_nomeProdutoController.text);
                          }
                        },
                        onEditingComplete: _removeOverlayProduto,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 40,
                    child: TextFormField(
                      controller: _quantidadeController,
                      decoration: const InputDecoration(labelText: 'Qtd'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 75,
                    child: DropdownButtonFormField<String>(
                      value: _unidadeSelecionada,
                      items: _unidades
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _unidadeSelecionada = v!;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Und.'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _adicionarItem,
                    tooltip: 'Adicionar Produto',
                  ),
                ],
              ),
            ),
            if (_carregandoSugestoesProduto)
              const LinearProgressIndicator(),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Builder(
                  builder: (context) {
                    final agrupado = _agruparItensPorCategoria();
                    if (agrupado.isEmpty) {
                      return const Center(child: Text('Nenhum produto adicionado.'));
                    }
                    return ListView(
                      children: agrupado.entries.expand((entry) {
                        final categoria = entry.key;
                        final itens = entry.value;
                        return [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              categoria.nome,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          ...itens.map((item) {
                            final sub = categoria.subcategorias.firstWhere((s) => s.id == item['categoria']);
                            return ListTile(
                              leading: Icon(getMaterialSymbol(sub.icone ?? 'category')),
                              title: Text(item['nomeProduto']),
                              subtitle: Text('Quantidade: ${formatarQuantidade(item['quantidade'])} ${item['unidade'] ?? ''}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    _itens.remove(item);
                                  });
                                },
                              ),
                            );
                          }),
                        ];
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _cadastrarLista,
        label: const Text('Cadastrar Lista'),
        icon: const Icon(Icons.check),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}