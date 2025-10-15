import 'autor.dart';
import 'editora.dart';

class Livro {
  final int? liCod;
  final String liTitulo;
  final int? liAno;
  final String? liEdicao;
  final String? liIsbn;
  final int? liEditora;
  final int? liAutor;
  final String? liGenero;
  
  // Objetos relacionados (quando fazemos JOIN)
  final Autor? autor;
  final Editora? editora;
  final int? exemplaresDisponiveis;

  Livro({
    this.liCod,
    required this.liTitulo,
    this.liAno,
    this.liEdicao,
    this.liIsbn,
    this.liEditora,
    this.liAutor,
    this.liGenero,
    this.autor,
    this.editora,
    this.exemplaresDisponiveis,
  });

  factory Livro.fromJson(Map<String, dynamic> json) {
    return Livro(
      liCod: json['li_cod'],
      liTitulo: json['li_titulo'] ?? '',
      liAno: json['li_ano'],
      liEdicao: json['li_edicao'],
      liIsbn: json['li_isbn'],
      liEditora: json['li_editora'],
      liAutor: json['li_autor'],
      liGenero: json['li_genero'],
      autor: json['autor'] != null ? Autor.fromJson(json['autor']) : null,
      editora: json['editora'] != null ? Editora.fromJson(json['editora']) : null,
      exemplaresDisponiveis: json['exemplares_disponiveis'],
    );
  }

  // Factory para criar a partir de dados com JOIN
  factory Livro.fromJsonWithJoin(Map<String, dynamic> json) {
    return Livro(
      liCod: json['li_cod'],
      liTitulo: json['li_titulo'] ?? '',
      liAno: json['li_ano'],
      liEdicao: json['li_edicao'],
      liIsbn: json['li_isbn'],
      liEditora: json['li_editora'],
      liAutor: json['li_autor'],
      liGenero: json['li_genero'],
      autor: json['au_nome'] != null ? Autor(
        auCod: json['li_autor'],
        auNome: json['au_nome'],
        auPais: json['au_pais'],
      ) : null,
      editora: json['ed_nome'] != null ? Editora(
        edCod: json['li_editora'],
        edNome: json['ed_nome'],
        edPais: json['ed_pais'],
      ) : null,
      exemplaresDisponiveis: json['exemplares_disponiveis'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'li_cod': liCod,
      'li_titulo': liTitulo,
      'li_ano': liAno,
      'li_edicao': liEdicao,
      'li_isbn': liIsbn,
      'li_editora': liEditora,
      'li_autor': liAutor,
      'li_genero': liGenero,
    };
  }

  String get autorNome => autor?.auNome ?? 'Autor desconhecido';
  String get editoraNome => editora?.edNome ?? 'Editora desconhecida';
  String get anoString => liAno?.toString() ?? 'Ano desconhecido';
  bool get temExemplaresDisponiveis => (exemplaresDisponiveis ?? 0) > 0;

  @override
  String toString() {
    return 'Livro{liCod: $liCod, liTitulo: $liTitulo, autor: ${autor?.auNome}, editora: ${editora?.edNome}}';
  }
}
