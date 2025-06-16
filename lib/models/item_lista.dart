import 'categoria.dart';

class ItemLista {
  int? idItemProduto;
  int? idLista;
  int categoria;
  String nomeProduto;
  double quantidade;
  String? unidade;
  double? preco;

  ItemLista({
    this.idItemProduto,
    this.idLista,
    required this.categoria,
    required this.nomeProduto,
    required this.quantidade,
    this.unidade,
    this.preco,
  });

  factory ItemLista.fromMap(Map<String, dynamic> map) {
    return ItemLista(
      idItemProduto: map['id'] as int?,
      idLista: map['idLista'] as int?,
      nomeProduto: map['nomeProduto'] as String,
      quantidade: (map['quantidade'] as num).toDouble(),
      unidade: map['unidade'] != null ? (map['unidade'] as String) : 'un',
      preco: map['preco'] != null ? (map['preco'] as num).toDouble() : null,
      categoria: map['categoria'] != null ? map['categoria'] as int : 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (idItemProduto != null) 'id': idItemProduto,
      if (idLista != null) 'idLista': idLista,
      'nomeProduto': nomeProduto,
      'quantidade': quantidade,
      'unidade': unidade ?? 'un',
      'preco': preco,
      'categoria': categoria,
    };
  }

  String? quantidadeFormatada() {
    if (quantidade % 1 == 0) {
      return quantidade.toStringAsFixed(0);
    }
    return quantidade.toStringAsFixed(2);
  }

  ItemLista copyWith({
    int? idItemProduto,
    double? preco,
    double? quantidade,
    int? categoria,
    String? nomeProduto,
    String? unidade,
  }) {
    return ItemLista(
      idItemProduto: idItemProduto ?? this.idItemProduto,
      idLista: idLista,
      categoria: categoria ?? this.categoria,
      nomeProduto: nomeProduto ?? this.nomeProduto,
      quantidade: quantidade ?? this.quantidade,
      unidade: unidade ?? this.unidade,
      preco: preco ?? this.preco,
    );
  }
}