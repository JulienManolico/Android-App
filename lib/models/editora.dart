class Editora {
  final int? edCod;
  final String edNome;
  final String edPais;
  final String? edMorada;
  final String? edCodPostal;
  final String? edEmail;
  final String? edTlm;

  Editora({
    this.edCod,
    required this.edNome,
    required this.edPais,
    this.edMorada,
    this.edCodPostal,
    this.edEmail,
    this.edTlm,
  });

  factory Editora.fromJson(Map<String, dynamic> json) {
    return Editora(
      edCod: json['ed_cod'],
      edNome: json['ed_nome'] ?? '',
      edPais: json['ed_pais'] ?? '',
      edMorada: json['ed_morada'],
      edCodPostal: json['ed_cod_postal'],
      edEmail: json['ed_email'],
      edTlm: json['ed_tlm'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ed_cod': edCod,
      'ed_nome': edNome,
      'ed_pais': edPais,
      'ed_morada': edMorada,
      'ed_cod_postal': edCodPostal,
      'ed_email': edEmail,
      'ed_tlm': edTlm,
    };
  }

  @override
  String toString() {
    return 'Editora{edCod: $edCod, edNome: $edNome, edPais: $edPais}';
  }
}
