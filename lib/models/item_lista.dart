class ItemLista {
  int? idItemProduto;
  int? idLista;
  String nomeProduto;
  int quantidade;
  double? preco;

  ItemLista({
    this.idItemProduto,
    this.idLista,
    required this.nomeProduto,
    required this.quantidade,
    this.preco,
  });

  factory ItemLista.fromMap(Map<String, dynamic> map) {
    return ItemLista(
      idItemProduto: map['id'] as int?,
      idLista: map['idLista'] as int?,
      nomeProduto: map['nomeProduto'] as String,
      quantidade: map['quantidade'] as int,
      preco: map['preco'] != null ? (map['preco'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (idItemProduto != null) 'id': idItemProduto,
      if (idLista != null) 'idLista': idLista,
      'nomeProduto': nomeProduto,
      'quantidade': quantidade,
      'preco': preco,
    };
  }
}