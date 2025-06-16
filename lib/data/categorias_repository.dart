import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/categoria.dart';

class CategoriasRepository {
  var listaCategorias = [];

  Future<List<Categoria>> categorias() async {
    final String jsonString = await rootBundle.loadString('lib/data/categoria.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);

    return (jsonMap['categorias'] as List)
        .map((cat) => Categoria.fromJson(cat))
        .toList();
  }

  Future<Subcategoria> buscarSubcategoriaPorId(int id) async {
    if (listaCategorias.isEmpty) {
      listaCategorias = await categorias();
    }
    for (final categoria in listaCategorias) {
      for (final subcategoria in categoria.subcategorias) {
        if (subcategoria.id == id) {
          return subcategoria;
        }
      }
    }
    return listaCategorias.first.subcategorias.first;
  }

  Future<Categoria> buscarCategoriaPorSubcategoria(int subcategoriaId) async {
    if (listaCategorias.isEmpty) {
      listaCategorias = await categorias();
    }
    for (final categoria in listaCategorias) {
      for (final subcategoria in categoria.subcategorias) {
        if (subcategoria.id == subcategoriaId) {
          return categoria;
        }
      }
    }
    return listaCategorias.first;
  }
}