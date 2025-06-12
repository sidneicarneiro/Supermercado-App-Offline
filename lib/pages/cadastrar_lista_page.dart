import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import '../utils/auth_utils.dart';
import 'listar_listas_page.dart';

class CadastrarListaPage extends StatefulWidget {
  const CadastrarListaPage({super.key});

  @override
  State<CadastrarListaPage> createState() => _CadastrarListaPageState();
}

class _CadastrarListaPageState extends State<CadastrarListaPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeListaController = TextEditingController();
  final TextEditingController _nomeProdutoController = TextEditingController();
  final TextEditingController _quantidadeController = TextEditingController();
  final List<Map<String, dynamic>> _itens = [];

  Future<List<String>> _buscarProdutos(String query) async {
    if (query.length < 3) return [];
    final url = Uri.parse('$kApiHost/produtos/busca-parcial?nome=$query');
    final headers = await getAuthHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map<String>((item) => item['nome'] as String).toList();
    }
    return [];
  }

  void _adicionarItem() {
    final nomeProduto = _nomeProdutoController.text.trim();
    final quantidade = _quantidadeController.text.trim();

    if (nomeProduto.isEmpty || quantidade.isEmpty) return;

    final existe = _itens.any((item) =>
        item['nomeProduto'].toString().toLowerCase() == nomeProduto.toLowerCase());

    if (existe) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Produto duplicado'),
          content: const Text('Este produto já foi adicionado à lista.'),
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
    });
  }

  void _cadastrarLista() async {
    if (_formKey.currentState!.validate() && _itens.isNotEmpty) {
      final url = Uri.parse('$kApiHost/lista');
      final body = jsonEncode({
        "nomeLista": _nomeListaController.text,
        "itens": _itens,
      });
      final headers = await getAuthHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
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
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cadastrar: ${response.statusCode}')),
        );
      }
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
                autocorrect: false
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) async {
                        if (textEditingValue.text.length < 3) return const Iterable<String>.empty();
                        return await _buscarProdutos(textEditingValue.text);
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        _nomeProdutoController.text = controller.text;
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(labelText: 'Nome do Produto'),
                          autofillHints: null,
                          enableSuggestions: false,
                          autocorrect: false
                        );
                      },
                      onSelected: (String selection) {
                        _nomeProdutoController.text = selection;
                      },
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