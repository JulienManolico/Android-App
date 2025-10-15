class Requisicao {
  final int? reCod;
  final int reUtCod;
  final int reLexCod;
  final DateTime reDataRequisicao;
  final DateTime? reDataDevolucao;

  Requisicao({
    this.reCod,
    required this.reUtCod,
    required this.reLexCod,
    required this.reDataRequisicao,
    this.reDataDevolucao,
  });

  factory Requisicao.fromJson(Map<String, dynamic> json) {
    return Requisicao(
      reCod: json['re_cod'],
      reUtCod: json['re_ut_cod'],
      reLexCod: json['re_lex_cod'],
      reDataRequisicao: DateTime.parse(json['re_data_requisicao']),
      reDataDevolucao: json['re_data_devolucao'] != null 
          ? DateTime.parse(json['re_data_devolucao'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      're_cod': reCod,
      're_ut_cod': reUtCod,
      're_lex_cod': reLexCod,
      're_data_requisicao': reDataRequisicao.toIso8601String().split('T')[0],
      're_data_devolucao': reDataDevolucao?.toIso8601String().split('T')[0],
    };
  }

  Map<String, dynamic> toInsert() {
    return {
      're_ut_cod': reUtCod,
      're_lex_cod': reLexCod,
      're_data_requisicao': reDataRequisicao.toIso8601String().split('T')[0],
    };
  }

  bool get estaDevolvido => reDataDevolucao != null;
  bool get estaAtrasado {
    if (estaDevolvido) return false;
    final hoje = DateTime.now();
    final prazo = reDataRequisicao.add(const Duration(days: 14)); // 14 dias de prazo
    return hoje.isAfter(prazo);
  }

  @override
  String toString() {
    return 'Requisicao{reCod: $reCod, reUtCod: $reUtCod, reLexCod: $reLexCod, reDataRequisicao: $reDataRequisicao}';
  }
}
