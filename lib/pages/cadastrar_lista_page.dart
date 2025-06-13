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
  final _nomeListaController = TextEditingController();
  final _nomeProdutoController = TextEditingController();
  final _quantidadeController = TextEditingController();
  final List<Map<String, dynamic>> _itens = [];
  final repo = ListaRepository();

  List<String> _sugestoes = [];
  bool _carregandoSugestoes = false;
  final FocusNode _focusNodeProduto = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _nomeListaController.dispose();
    _nomeProdutoController.dispose();
    _quantidadeController.dispose();
    _focusNodeProduto.dispose();
    _removeOverlay();
    super.dispose();
  }

  Future<void> _buscarSugestoes(String query) async {
    if (query.length < 3) {
      _removeOverlay();
      setState(() => _sugestoes = []);
      return;
    }
    setState(() => _carregandoSugestoes = true);
    final results = await repo.buscarProdutos(query);
    setState(() {
      _sugestoes = results;
      _carregandoSugestoes = false;
    });
    _showOverlay();
  }

  void _showOverlay() {
    _removeOverlay();
    if (_sugestoes.isEmpty || !_focusNodeProduto.hasFocus) return;
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 32, // padding horizontal
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56), // altura do campo + margem
          child: Material(
            elevation: 4,
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: _sugestoes.map((s) {
                return ListTile(
                  title: Text(s),
                  onTap: () {
                    _nomeProdutoController.text = s;
                    _removeOverlay();
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
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
      _sugestoes = [];
    });
    _removeOverlay();
  }

  void _cadastrarLista() async {
    if (_formKey.currentState!.validate() && _itens.isNotEmpty) {
      final lista = ListaCompra(nomeLista: _nomeListaController.text);
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
      _nomeListaController.clear();
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
              TextFormField(
                controller: _nomeListaController,
                decoration: const InputDecoration(labelText: 'Nome da Lista'),
                validator: (value) => value!.isEmpty ? 'Informe o nome da lista' : null,
                autofillHints: null,
                enableSuggestions: false,
                autocorrect: false,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CompositedTransformTarget(
                      link: _layerLink,
                      child: TextFormField(
                        controller: _nomeProdutoController,
                        focusNode: _focusNodeProduto,
                        decoration: const InputDecoration(labelText: 'Nome do Produto'),
                        onChanged: (value) => _buscarSugestoes(value),
                        autofillHints: null,
                        enableSuggestions: false,
                        autocorrect: false,
                        onTap: () {
                          if (_nomeProdutoController.text.length >= 3) {
                            _buscarSugestoes(_nomeProdutoController.text);
                          }
                        },
                        onEditingComplete: _removeOverlay,
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
              if (_carregandoSugestoes)
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