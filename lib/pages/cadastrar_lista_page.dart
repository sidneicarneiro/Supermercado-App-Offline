import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import '../utils/auth_utils.dart';

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

  void _adicionarItem() {
    if (_nomeProdutoController.text.isNotEmpty && _quantidadeController.text.isNotEmpty) {
      setState(() {
        _itens.add({
          "nomeProduto": _nomeProdutoController.text,
          "quantidade": int.tryParse(_quantidadeController.text) ?? 1,
        });
        _nomeProdutoController.clear();
        _quantidadeController.clear();
      });
    }
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
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nomeProdutoController,
                      decoration: const InputDecoration(labelText: 'Nome do Produto'),
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
      )
    );
  }
}