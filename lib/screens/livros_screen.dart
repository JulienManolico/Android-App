import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/livro.dart';
import 'livro_detalhes_screen.dart';

class LivrosScreen extends StatefulWidget {
  const LivrosScreen({super.key});

  @override
  State<LivrosScreen> createState() => _LivrosScreenState();
}

class _LivrosScreenState extends State<LivrosScreen> {
  final _searchController = TextEditingController();
  List<Livro> _livros = [];
  List<Livro> _livrosFiltrados = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _filtroSelecionado = 'todos';

  SupabaseClient get supabase => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadLivros();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLivros() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('📚 Carregando livros...');
      
      // Query com JOIN para buscar livros com autor e editora
      final response = await supabase
          .from('livro')
          .select('''
            li_cod,
            li_titulo,
            li_ano,
            li_edicao,
            li_isbn,
            li_genero,
            li_autor,
            li_editora,
            autor:li_autor(au_cod, au_nome, au_pais),
            editora:li_editora(ed_cod, ed_nome, ed_pais)
          ''')
          .order('li_titulo');

      print('📊 Resposta recebida: ${response.length} livros');

      final livros = (response as List).map((json) {
        // Processar dados do JOIN
        final livroData = Map<String, dynamic>.from(json);
        
        // Extrair dados do autor se existir
        if (livroData['autor'] != null) {
          final autorData = livroData['autor'];
          livroData['au_nome'] = autorData['au_nome'];
          livroData['au_pais'] = autorData['au_pais'];
        }
        
        // Extrair dados da editora se existir
        if (livroData['editora'] != null) {
          final editoraData = livroData['editora'];
          livroData['ed_nome'] = editoraData['ed_nome'];
          livroData['ed_pais'] = editoraData['ed_pais'];
        }

        return Livro.fromJsonWithJoin(livroData);
      }).toList();

      // Buscar exemplares disponíveis para cada livro
      await _loadExemplaresDisponiveis(livros);

      setState(() {
        _livros = livros;
        _livrosFiltrados = livros;
        _isLoading = false;
      });

      print('✅ ${livros.length} livros carregados com sucesso');
    } catch (e) {
      print('❌ Erro ao carregar livros: $e');
      setState(() {
        _errorMessage = 'Erro ao carregar livros: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadExemplaresDisponiveis(List<Livro> livros) async {
    try {
      for (var livro in livros) {
        final response = await supabase
            .from('livro_exemplar')
            .select('lex_cod')
            .eq('lex_li_cod', livro.liCod!)
            .eq('lex_disponivel', true);
        
        // Atualizar o número de exemplares disponíveis
        final exemplaresCount = response.length;
        // Como não podemos modificar o objeto diretamente, vamos criar um novo
        final index = livros.indexOf(livro);
        if (index >= 0) {
          livros[index] = Livro(
            liCod: livro.liCod,
            liTitulo: livro.liTitulo,
            liAno: livro.liAno,
            liEdicao: livro.liEdicao,
            liIsbn: livro.liIsbn,
            liEditora: livro.liEditora,
            liAutor: livro.liAutor,
            liGenero: livro.liGenero,
            autor: livro.autor,
            editora: livro.editora,
            exemplaresDisponiveis: exemplaresCount,
          );
        }
      }
    } catch (e) {
      print('⚠️ Erro ao carregar exemplares: $e');
    }
  }

  void _filtrarLivros(String query) {
    setState(() {
      if (query.isEmpty) {
        _livrosFiltrados = _livros;
      } else {
        _livrosFiltrados = _livros.where((livro) {
          final titulo = livro.liTitulo.toLowerCase();
          final autor = livro.autorNome.toLowerCase();
          final editora = livro.editoraNome.toLowerCase();
          final genero = (livro.liGenero ?? '').toLowerCase();
          final isbn = (livro.liIsbn ?? '').toLowerCase();
          final searchLower = query.toLowerCase();

          return titulo.contains(searchLower) ||
                 autor.contains(searchLower) ||
                 editora.contains(searchLower) ||
                 genero.contains(searchLower) ||
                 isbn.contains(searchLower);
        }).toList();
      }

      // Aplicar filtro de disponibilidade
      if (_filtroSelecionado == 'disponiveis') {
        _livrosFiltrados = _livrosFiltrados.where((livro) => livro.temExemplaresDisponiveis).toList();
      }
    });
  }

  void _aplicarFiltro(String filtro) {
    setState(() {
      _filtroSelecionado = filtro;
    });
    _filtrarLivros(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca - Livros'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadLivros,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Pesquisar livros...',
                    hintText: 'Título, autor, editora, género ou ISBN',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _filtrarLivros,
                ),
                const SizedBox(height: 12),
                
                // Filtros
                Row(
                  children: [
                    const Text('Filtrar: '),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Todos'),
                            selected: _filtroSelecionado == 'todos',
                            onSelected: (_) => _aplicarFiltro('todos'),
                          ),
                          FilterChip(
                            label: const Text('Disponíveis'),
                            selected: _filtroSelecionado == 'disponiveis',
                            onSelected: (_) => _aplicarFiltro('disponiveis'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contador de resultados
          if (!_isLoading && _errorMessage.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    '${_livrosFiltrados.length} livros encontrados',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Lista de livros
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando livros...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLivros,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_livrosFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Nenhum livro encontrado'
                  : 'Nenhum resultado para "${_searchController.text}"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _livrosFiltrados.length,
      itemBuilder: (context, index) {
        final livro = _livrosFiltrados[index];
        return _buildLivroCard(livro);
      },
    );
  }

  Widget _buildLivroCard(Livro livro) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: livro.temExemplaresDisponiveis 
              ? Colors.green 
              : Colors.red,
          child: Icon(
            livro.temExemplaresDisponiveis 
                ? Icons.book 
                : Icons.book_outlined,
            color: Colors.white,
          ),
        ),
        title: Text(
          livro.liTitulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Autor: ${livro.autorNome}'),
            Text('Editora: ${livro.editoraNome}'),
            if (livro.liGenero != null)
              Text('Género: ${livro.liGenero}'),
            Row(
              children: [
                Icon(
                  livro.temExemplaresDisponiveis 
                      ? Icons.check_circle 
                      : Icons.cancel,
                  size: 16,
                  color: livro.temExemplaresDisponiveis 
                      ? Colors.green 
                      : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  livro.temExemplaresDisponiveis 
                      ? '${livro.exemplaresDisponiveis} disponível(eis)'
                      : 'Indisponível',
                  style: TextStyle(
                    color: livro.temExemplaresDisponiveis 
                        ? Colors.green 
                        : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LivroDetalhesScreen(livro: livro),
            ),
          );
        },
      ),
    );
  }
}
