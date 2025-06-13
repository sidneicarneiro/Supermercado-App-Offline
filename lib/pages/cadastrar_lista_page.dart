import 'package:flutter/material.dart';
import '../data/lista_repository.dart';
import 'listar_listas_page.dart';
import '../models/lista_compra.dart';
import '../models/item_lista.dart';

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

  final FocusNode _focusNodeMercado = FocusNode();
  final FocusNode _focusNodeProduto = FocusNode();
  final LayerLink _layerLinkMercado = LayerLink();
  final LayerLink _layerLinkProduto = LayerLink();
  OverlayEntry? _overlayEntryMercado;
  OverlayEntry? _overlayEntryProduto;

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
    final results = await repo.buscarMercados(query); // Implemente este método no repositório
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
        "quantidade": int.tryParse(quantidade) ?? 1,
      });
      _nomeProdutoController.clear();
      _quantidadeController.clear();
      _sugestoesProduto = [];
    });
    _removeOverlayProduto();
  }

  void _cadastrarLista() async {
    if (_formKey.currentState!.validate() && _itens.isNotEmpty) {
      final lista = ListaCompra(nomeLista: _nomeMercadoController.text);
      final itens = _itens
          .map((e) => ItemLista(
        nomeProduto: e['nomeProduto'],
        quantidade: e['quantidade'],
      ))
          .toList();
      await repo.inserirLista(lista, itens);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lista cadastrada!')),
      );
      _nomeMercadoController.clear();
      setState(() {
        _itens.clear();
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ListarListasPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Lista')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CompositedTransformTarget(
                link: _layerLinkMercado,
                child: TextFormField(
                  controller: _nomeMercadoController,
                  focusNode: _focusNodeMercado,
                  decoration: const InputDecoration(labelText: 'Nome do Mercado'),
                  validator: (value) => value!.isEmpty ? 'Informe o nome do mercado' : null,
                  autofillHints: null,
                  enableSuggestions: false,
                  autocorrect: false,
                  onChanged: (value) => _buscarSugestoesMercado(value),
                  onTap: () {
                    if (_nomeMercadoController.text.length >= 2) {
                      _buscarSugestoesMercado(_nomeMercadoController.text);
                    }
                  },
                  onEditingComplete: _removeOverlayMercado,
                ),
              ),
              if (_carregandoSugestoesMercado)
                const LinearProgressIndicator(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CompositedTransformTarget(
                      link: _layerLinkProduto,
                      child: TextFormField(
                        controller: _nomeProdutoController,
                        focusNode: _focusNodeProduto,
                        decoration: const InputDecoration(labelText: 'Nome do Produto'),
                        onChanged: (value) => _buscarSugestoesProduto(value),
                        autofillHints: null,
                        enableSuggestions: false,
                        autocorrect: false,
                        onTap: () {
                          if (_nomeProdutoController.text.length >= 3) {
                            _buscarSugestoesProduto(_nomeProdutoController.text);
                          }
                        },
                        onEditingComplete: _removeOverlayProduto,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      controller: _quantidadeController,
                      decoration: const InputDecoration(labelText: 'Qtd'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _adicionarItem,
                    tooltip: 'Adicionar Produto',
                  ),
                ],
              ),
              if (_carregandoSugestoesProduto)
                const LinearProgressIndicator(),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _itens.length,
                  itemBuilder: (context, index) {
                    final item = _itens[index];
                    return ListTile(
                      title: Text(item['nomeProduto']),
                      subtitle: Text('Quantidade: ${item['quantidade']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _itens.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _cadastrarLista,
                child: const Text('Cadastrar Lista'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}