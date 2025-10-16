import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/livro.dart';
import '../models/requisicao.dart';

class LivroDetalhesScreen extends StatefulWidget {
  final Livro livro;

  const LivroDetalhesScreen({super.key, required this.livro});

  @override
  State<LivroDetalhesScreen> createState() => _LivroDetalhesScreenState();
}

class _LivroDetalhesScreenState extends State<LivroDetalhesScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _exemplares = [];

  SupabaseClient get supabase => Supabase.instance.client;
  User? get user => supabase.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadExemplares();
  }

  Future<void> _loadExemplares() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('📖 Carregando exemplares do livro ${widget.livro.liCod}...');
      
      final response = await supabase
          .from('livro_exemplar')
          .select('lex_cod, lex_estado, lex_disponivel')
          .eq('lex_li_cod', widget.livro.liCod!)
          .order('lex_cod');

      setState(() {
        _exemplares = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      print('✅ ${_exemplares.length} exemplares carregados');
    } catch (e) {
      print('❌ Erro ao carregar exemplares: $e');
      setState(() {
        _errorMessage = 'Erro ao carregar exemplares: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _reservarLivro() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Precisa estar logado para reservar livros'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Encontrar um exemplar disponível
    final exemplarDisponivel = _exemplares.firstWhere(
      (exemplar) => exemplar['lex_disponivel'] == true,
      orElse: () => {},
    );

    if (exemplarDisponivel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não há exemplares disponíveis para reserva'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Confirmar reserva
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Reserva'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Deseja reservar o livro:'),
            const SizedBox(height: 8),
            Text(
              '"${widget.livro.liTitulo}"',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Autor: ${widget.livro.autorNome}'),
            const SizedBox(height: 16),
            const Text(
              'A reserva terá duração de 14 dias.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('📝 Criando reserva...');
      print('👤 Utilizador: ${user!.email}');
      print('📖 Exemplar: ${exemplarDisponivel['lex_cod']}');

      // Primeiro, vamos buscar ou criar o utente
      int utenteId = await _getOrCreateUtente();

      // Criar a requisição
      final requisicao = Requisicao(
        reUtCod: utenteId,
        reLexCod: exemplarDisponivel['lex_cod'],
        reDataRequisicao: DateTime.now(),
      );

      final response = await supabase
          .from('requisicao')
          .insert(requisicao.toInsert())
          .select()
          .single();

      // Marcar o exemplar como indisponível
      await supabase
          .from('livro_exemplar')
          .update({'lex_disponivel': false})
          .eq('lex_cod', exemplarDisponivel['lex_cod']);

      print('✅ Reserva criada com sucesso: ${response['re_cod']}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Livro reservado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      // Atualizar a lista de exemplares
      await _loadExemplares();

    } catch (e) {
      print('❌ Erro ao reservar livro: $e');
      setState(() {
        _errorMessage = 'Erro ao reservar livro: $e';
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao reservar livro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<int> _getOrCreateUtente() async {
    try {
      // Tentar encontrar o utente pelo email
      final response = await supabase
          .from('utente')
          .select('ut_cod')
          .eq('ut_email', user!.email!)
          .maybeSingle();

      if (response != null) {
        return response['ut_cod'];
      }

      // Se não existe, criar novo utente
      final newUtente = await supabase
          .from('utente')
          .insert({
            'ut_nome': user!.email!.split('@')[0], // Usar parte do email como nome
            'ut_email': user!.email!,
          })
          .select('ut_cod')
          .single();

      return newUtente['ut_cod'];
    } catch (e) {
      print('❌ Erro ao obter/criar utente: $e');
      throw 'Erro ao processar dados do utilizador';
    }
  }

  @override
  Widget build(BuildContext context) {
    final exemplaresDisponiveis = _exemplares.where((e) => e['lex_disponivel'] == true).length;
    final exemplaresTotal = _exemplares.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Livro'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do livro
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Icon(
                            Icons.book,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.livro.liTitulo,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'por ${widget.livro.autorNome}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Informações do livro
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informações',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Autor', widget.livro.autorNome),
                    _buildInfoRow('Editora', widget.livro.editoraNome),
                    if (widget.livro.liAno != null)
                      _buildInfoRow('Ano', widget.livro.anoString),
                    if (widget.livro.liEdicao != null)
                      _buildInfoRow('Edição', widget.livro.liEdicao!),
                    if (widget.livro.liGenero != null)
                      _buildInfoRow('Género', widget.livro.liGenero!),
                    if (widget.livro.liIsbn != null)
                      _buildInfoRow('ISBN', widget.livro.liIsbn!),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Disponibilidade
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Disponibilidade',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_errorMessage.isNotEmpty)
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      )
                    else ...[
                      Row(
                        children: [
                          Icon(
                            exemplaresDisponiveis > 0 
                                ? Icons.check_circle 
                                : Icons.cancel,
                            color: exemplaresDisponiveis > 0 
                                ? Colors.green 
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$exemplaresDisponiveis de $exemplaresTotal exemplares disponíveis',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: exemplaresDisponiveis > 0 
                                  ? Colors.green 
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      
                      if (_exemplares.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('Exemplares:', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        ..._exemplares.map((exemplar) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                exemplar['lex_disponivel'] 
                                    ? Icons.circle 
                                    : Icons.circle_outlined,
                                size: 12,
                                color: exemplar['lex_disponivel'] 
                                    ? Colors.green 
                                    : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Exemplar #${exemplar['lex_cod']} - ${exemplar['lex_estado']} - ',
                              ),
                              Text(
                                exemplar['lex_disponivel'] ? 'Disponível' : 'Reservado',
                                style: TextStyle(
                                  color: exemplar['lex_disponivel'] 
                                      ? Colors.green 
                                      : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botão de reserva
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: (_isLoading || exemplaresDisponiveis == 0) 
                    ? null 
                    : _reservarLivro,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.book_online),
                label: Text(
                  _isLoading 
                      ? 'Reservando...'
                      : exemplaresDisponiveis > 0 
                          ? 'Reservar Livro'
                          : 'Indisponível',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: exemplaresDisponiveis > 0 
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Informação sobre reservas
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'As reservas têm duração de 14 dias. Após esse período, o livro ficará novamente disponível.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
