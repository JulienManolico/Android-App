class Autor {
  final int? auCod;
  final String auNome;
  final String? auPais;

  Autor({
    this.auCod,
    required this.auNome,
    this.auPais,
  });

  factory Autor.fromJson(Map<String, dynamic> json) {
    return Autor(
      auCod: json['au_cod'],
      auNome: json['au_nome'] ?? '',
      auPais: json['au_pais'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'au_cod': auCod,
      'au_nome': auNome,
      'au_pais': auPais,
    };
  }

  @override
  String toString() {
    return 'Autor{auCod: $auCod, auNome: $auNome, auPais: $auPais}';
  }
}
