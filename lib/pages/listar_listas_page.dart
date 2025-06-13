import 'package:flutter/material.dart';
import '../models/lista_compra.dart';
import '../data/lista_repository.dart';
import 'detalhe_lista_page.dart';

class ListarListasPage extends StatefulWidget {
  const ListarListasPage({Key? key}) : super(key: key);

  @override
  State<ListarListasPage> createState() => _ListarListasPageState();
}

class _ListarListasPageState extends State<ListarListasPage> {
  late Future<List<ListaCompra>> _listasFuture;
  final repo = ListaRepository();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    setState(() {
      _listasFuture = repo.listarListas();
    });
  }

  void _confirmarExcluirLista(int idLista, String nomeLista) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir lista'),
        content: Text('Tem certeza que deseja excluir a lista "$nomeLista"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmado == true) {
      await repo.excluirLista(idLista);
      _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          return ListView.builder(
            itemCount: listas.length,
            itemBuilder: (context, index) {
              final lista = listas[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(lista.nomeLista),
                  subtitle: lista.dataCompra != null
                      ? Text('Data: ${lista.dataCompra}')
                      : null,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetalheListaPage(idLista: lista.id!),
                      ),
                    );
                    _carregar();
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Excluir lista',
                    onPressed: () => _confirmarExcluirLista(lista.id!, lista.nomeLista),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}