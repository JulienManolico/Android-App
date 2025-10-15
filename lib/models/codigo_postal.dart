class CodigoPostal {
  final String codPostal;
  final String codLocalidade;

  CodigoPostal({
    required this.codPostal,
    required this.codLocalidade,
  });

  // Converter de JSON (dados do Supabase) para CodigoPostal
  factory CodigoPostal.fromJson(Map<String, dynamic> json) {
    return CodigoPostal(
      codPostal: json['cod_postal'] ?? '',
      codLocalidade: json['cod_localidade'] ?? '',
    );
  }

  // Converter de CodigoPostal para JSON
  Map<String, dynamic> toJson() {
    return {
      'cod_postal': codPostal,
      'cod_localidade': codLocalidade,
    };
  }

  @override
  String toString() {
    return 'CodigoPostal{codPostal: $codPostal, codLocalidade: $codLocalidade}';
  }
}
