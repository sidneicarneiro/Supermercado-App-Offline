class Categoria {
  final int id;
  final String nome;
  final String descricao;
  final String? icone;
  final List<Subcategoria> subcategorias;

  Categoria({
    required this.id,
    required this.nome,
    required this.descricao,
    this.icone,
    required this.subcategorias,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      nome: json['nome'],
      descricao: json['descricao'],
      icone: json['icone'],
      subcategorias: (json['subcategorias'] as List)
          .map((sub) => Subcategoria.fromJson(sub))
          .toList(),
    );
  }
}

class Subcategoria {
  final int id;
  final String nome;
  final String descricao;
  final String? icone;

  Subcategoria({
    required this.id,
    required this.nome,
    required this.descricao,
    this.icone,
  });

  factory Subcategoria.fromJson(Map<String, dynamic> json) {
    return Subcategoria(
      id: json['id'],
      nome: json['nome'],
      descricao: json['descricao'],
      icone: json['icone'],
    );
  }
}