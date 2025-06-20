import '../models/lista_compra.dart';
import '../models/item_lista.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ListaRepository {
  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<void> resetarBanco() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'listas.db');
    await deleteDatabase(path);
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'listas.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE listas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nomeLista TEXT,
            dataCompra TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE itens (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            idLista INTEGER,
            categoria INTEGER,
            nomeProduto TEXT,
            quantidade NUMERIC(6,2),
            unidade Text,
            preco REAL,
            FOREIGN KEY (idLista) REFERENCES listas(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  Future<List<ListaCompra>> listarListas() async {
    final database = await db;
    final result = await database.query('listas', orderBy: 'id DESC');
    return result.map((e) => ListaCompra.fromMap(e)).toList();
  }

  Future<void> inserirLista(ListaCompra lista, List<ItemLista> itens) async {
    final database = await db;
    final id = await database.insert('listas', lista.toMap());
    for (final item in itens) {
      await database.insert('itens', {
        ...item.toMap(),
        'idLista': id,
      });
    }
  }

  Future<List<ItemLista>> listarItens(int idLista) async {
    final database = await db;
    final result = await database.query(
      'itens',
      where: 'idLista = ?',
      whereArgs: [idLista],
    );
    return result.map((e) => ItemLista.fromMap(e)).toList();
  }

  Future<List<String>> buscarProdutos(String query) async {
    final database = await db;
    final result = await database.rawQuery(
      '''
      SELECT DISTINCT nomeProduto FROM itens
      WHERE nomeProduto LIKE ?
      ORDER BY nomeProduto
      ''',
      ['%$query%'],
    );
    return result.map((e) => e['nomeProduto'] as String).toList();
  }

  Future<List<String>> buscarMercados(String query) async {
    final database = await db;
    final result = await database.rawQuery(
      '''
      SELECT DISTINCT nomeLista FROM listas
      WHERE nomeLista LIKE ?
      ORDER BY nomeLista
      ''',
      ['%$query%'],
    );
    return result.map((e) => e['nomeLista'] as String).toList();
  }

  Future<void> excluirLista(int idLista) async {
    final database = await db;
    await database.delete('itens', where: 'idLista = ?', whereArgs: [idLista]);
    await database.delete('listas', where: 'id = ?', whereArgs: [idLista]);
  }

  Future<void> atualizarDataCompra(int idLista, String novaData) async {
    final database = await db;
    await database.update(
      'listas',
      {'dataCompra': novaData},
      where: 'id = ?',
      whereArgs: [idLista],
    );
  }

  Future<void> atualizarItemLista(ItemLista item) async {
    final database = await db;
    await database.update(
      'itens',
      {
        'categoria': item.categoria,
        'nomeProduto': item.nomeProduto,
        'quantidade': item.quantidade,
        'unidade': item.unidade,
        'preco': item.preco,
      },
      where: 'id = ?',
      whereArgs: [item.idItemProduto],
    );
  }

  Future<void> excluirItem(int idItemProduto) async {
    final database = await db;
    await database.delete(
      'itens',
      where: 'id = ?',
      whereArgs: [idItemProduto],
    );
  }

  Future<ItemLista> adicionarItem(int idLista, ItemLista item) async {
    final database = await db;
    final id = await database.insert(
      'itens',
      {
        ...item.toMap(),
        'idLista': idLista,
      },
    );
    // Retorna o item com o id gerado
    return item.copyWith(idItemProduto: id);
  }

  Future<List<ItemLista>> buscarHistoricoProduto(String nomeProduto) async {
    final database = await db;
    final result = await database.query(
      'itens',
      where: 'nomeProduto = ? AND preco IS NOT NULL',
      whereArgs: [nomeProduto],
      orderBy: 'id DESC',
    );
    return result.map((e) => ItemLista.fromMap(e)).toList();
  }

  Future<double?> buscarMenorPrecoProduto(String nomeProduto) async {
    final historico = await buscarHistoricoProduto(nomeProduto);
    if (historico.isEmpty) return null;
    return historico
        .map((e) => e.preco ?? double.infinity)
        .reduce((a, b) => a < b ? a : b);
  }
}