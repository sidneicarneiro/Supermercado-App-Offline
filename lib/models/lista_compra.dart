class ListaCompra {
  final int? id;
  final String nomeLista;
  final String? dataCompra;

  ListaCompra({
    this.id,
    required this.nomeLista,
    this.dataCompra,
  });

  factory ListaCompra.fromMap(Map<String, dynamic> map) {
    return ListaCompra(
      id: map['id'] as int?,
      nomeLista: map['nomeLista'] as String,
      dataCompra: map['dataCompra'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nomeLista': nomeLista,
      'dataCompra': dataCompra,
    };
  }
}