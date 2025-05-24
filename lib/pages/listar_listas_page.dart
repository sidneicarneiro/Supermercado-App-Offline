import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import '../utils/auth_utils.dart';
import 'detalhe_lista_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ListaCompra {
  final int id;
  final String nomeLista;
  final String? dataCompra;

  ListaCompra({required this.id, required this.nomeLista, required this.dataCompra});

  factory ListaCompra.fromJson(Map<String, dynamic> json) {
    return ListaCompra(
      id: json['id'],
      nomeLista: json['nomeLista'],
      dataCompra: json['dataCompra'],
    );
  }
}

class ListarListasPage extends StatefulWidget {
  const ListarListasPage({super.key});

  @override
  State<ListarListasPage> createState() => _ListarListasPageState();
}

class _ListarListasPageState extends State<ListarListasPage> {
  late Future<List<ListaCompra>> _listasFuture;

  Future<List<ListaCompra>> fetchListas() async {
    final headers = await getAuthHeaders();
    final response = await http.get(
        Uri.parse('$kApiHost/listas'),
        headers: headers
    );
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Listas de Compras')),
      body: FutureBuilder<List<ListaCompra>>(
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
          return ListView.separated(
            itemCount: listas.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final lista = listas[index];
              return ListTile(
                title: Text(lista.nomeLista),
                subtitle: Text(
                  lista.dataCompra != null
                      ? 'Data: ${DateTime.parse(lista.dataCompra!).day.toString().padLeft(2, '0')}/'
                        '${DateTime.parse(lista.dataCompra!).month.toString().padLeft(2, '0')}/'
                        '${DateTime.parse(lista.dataCompra!).year}'
                      : 'Sem data',
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetalheListaPage(idLista: lista.id),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                  ),
                  child: const Text('Detalhes'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}