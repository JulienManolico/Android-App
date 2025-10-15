import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MinhasReservasScreen extends StatefulWidget {
  const MinhasReservasScreen({super.key});

  @override
  State<MinhasReservasScreen> createState() => _MinhasReservasScreenState();
}

class _MinhasReservasScreenState extends State<MinhasReservasScreen> {
  List<Map<String, dynamic>> _reservas = [];
  bool _isLoading = false;
  String _errorMessage = '';

  SupabaseClient get supabase => Supabase.instance.client;
  User? get user => supabase.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadMinhasReservas();
  }

  Future<void> _loadMinhasReservas() async {
    if (user == null) {
      setState(() {
        _errorMessage = 'Precisa estar logado para ver as reservas';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('📚 Carregando reservas do utilizador: ${user!.email}');

      // Primeiro, obter o ID do utente
      final utenteResponse = await supabase
          .from('utente')
          .select('ut_cod')
          .eq('ut_email', user!.email!)
          .maybeSingle();

      if (utenteResponse == null) {
        setState(() {
          _reservas = [];
          _isLoading = false;
        });
        return;
      }

      final utenteId = utenteResponse['ut_cod'];
      print('👤 ID do utente: $utenteId');

      // DEBUG: Buscar TODAS as reservas primeiro para debug
      final todasReservas = await supabase
          .from('requisicao')
          .select('re_cod, re_data_requisicao, re_data_devolucao, re_lex_cod')
          .eq('re_ut_cod', utenteId)
          .order('re_data_requisicao', ascending: false);
      
      print('🔍 DEBUG - Todas as reservas: ${todasReservas.length}');
      for (var reserva in todasReservas) {
        print('  - ID: ${reserva['re_cod']}, Devolução: ${reserva['re_data_devolucao']}');
      }

      // Buscar reservas ativas (não devolvidas)
      final response = await supabase
          .from('requisicao')
          .select('''
            re_cod,
            re_data_requisicao,
            re_data_devolucao,
            re_lex_cod,
            livro_exemplar:re_lex_cod(
              lex_cod,
              lex_estado,
              lex_disponivel,
              livro:lex_li_cod(
                li_cod,
                li_titulo,
                li_ano,
                li_isbn,
                autor:li_autor(au_nome),
                editora:li_editora(ed_nome)
              )
            )
          ''')
          .eq('re_ut_cod', utenteId)
          .isFilter('re_data_devolucao', null)
          .order('re_data_requisicao', ascending: false);

      print('📊 Reservas ativas encontradas: ${response.length}');

      setState(() {
        _reservas = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erro ao carregar reservas: $e');
      setState(() {
        _errorMessage = 'Erro ao carregar reservas: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _devolverLivro(int requisicaoId, int exemplarId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Devolução'),
        content: const Text('Deseja marcar este livro como devolvido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Devolver'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Iniciando devolução do livro...');
      print('📋 ID da requisição: $requisicaoId');
      print('📖 ID do exemplar: $exemplarId');

      // Usar transação para garantir consistência
      final dataDevolucao = DateTime.now().toIso8601String().split('T')[0];
      print('📅 Data de devolução: $dataDevolucao');
      
      // Atualizar requisição e exemplar em sequência
      final updateRequisicao = await supabase
          .from('requisicao')
          .update({'re_data_devolucao': dataDevolucao})
          .eq('re_cod', requisicaoId)
          .select();

      if (updateRequisicao.isEmpty) {
        throw Exception('Falha ao atualizar requisição');
      }

      print('✅ Requisição marcada como devolvida');

      final updateExemplar = await supabase
          .from('livro_exemplar')
          .update({'lex_disponivel': true})
          .eq('lex_cod', exemplarId)
          .select();

      if (updateExemplar.isEmpty) {
        throw Exception('Falha ao atualizar exemplar');
      }

      print('✅ Exemplar marcado como disponível');

      // Verificar se a atualização foi bem-sucedida
      final verificacao = await supabase
          .from('requisicao')
          .select('re_data_devolucao')
          .eq('re_cod', requisicaoId)
          .single();
      
      print('🔍 Verificação - Data de devolução: ${verificacao['re_data_devolucao']}');

      final verificacaoExemplar = await supabase
          .from('livro_exemplar')
          .select('lex_disponivel')
          .eq('lex_cod', exemplarId)
          .single();
      
      print('🔍 Verificação - Exemplar disponível: ${verificacaoExemplar['lex_disponivel']}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Livro devolvido com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      // Aguardar um pouco para garantir que as mudanças sejam propagadas
      await Future.delayed(const Duration(milliseconds: 500));

      // Recarregar a lista
      print('🔄 Recarregando lista de reservas...');
      await _loadMinhasReservas();
      
      print('🔄 Devolução concluída com sucesso!');
    } catch (e) {
      print('❌ Erro na devolução: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao devolver livro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _diasRestantes(DateTime dataRequisicao) {
    final hoje = DateTime.now();
    final prazoFinal = dataRequisicao.add(const Duration(days: 14));
    final diferenca = prazoFinal.difference(hoje).inDays;
    return diferenca;
  }

  bool _estaAtrasado(DateTime dataRequisicao) {
    return _diasRestantes(dataRequisicao) < 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Reservas'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadMinhasReservas,
          ),
        ],
      ),
      body: Column(
        children: [
          // Informação do utilizador
          if (user != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      user!.email!.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reservas de:',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          user!.email!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_reservas.length} ativas',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

          // Lista de reservas
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
            Text('Carregando suas reservas...'),
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
              onPressed: _loadMinhasReservas,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_reservas.isEmpty) {
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
            const Text(
              'Nenhuma reserva encontrada',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Vá para "Pesquisar Livros" para fazer sua primeira reserva!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Como agora buscamos apenas reservas ativas, todas são ativas
    final reservasAtivas = _reservas;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Reservas Ativas
        if (reservasAtivas.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.book_online, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                'Reservas Ativas (${reservasAtivas.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...reservasAtivas.map((reserva) => _buildReservaCard(reserva, true)),
          const SizedBox(height: 24),
        ],

      ],
    );
  }

  Widget _buildReservaCard(Map<String, dynamic> reserva, bool isAtiva) {
    final livroData = reserva['livro_exemplar']['livro'];
    final dataRequisicao = DateTime.parse(reserva['re_data_requisicao']);
    final dataDevolucao = reserva['re_data_devolucao'] != null 
        ? DateTime.parse(reserva['re_data_devolucao'])
        : null;

    final titulo = livroData['li_titulo'] ?? 'Título desconhecido';
    final autor = livroData['autor']?['au_nome'] ?? 'Autor desconhecido';
    final editora = livroData['editora']?['ed_nome'] ?? 'Editora desconhecida';
    final exemplarId = reserva['livro_exemplar']['lex_cod'];
    final estado = reserva['livro_exemplar']['lex_estado'];

    final diasRestantes = isAtiva ? _diasRestantes(dataRequisicao) : 0;
    final atrasado = isAtiva && _estaAtrasado(dataRequisicao);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isAtiva ? 4 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do livro
            Row(
              children: [
                Container(
                  width: 40,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isAtiva 
                        ? (atrasado ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1))
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isAtiva 
                          ? (atrasado ? Colors.red : Colors.green)
                          : Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.book,
                    color: isAtiva 
                        ? (atrasado ? Colors.red : Colors.green)
                        : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'por $autor',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Informações da reserva
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Reservado em:', 
                          '${dataRequisicao.day}/${dataRequisicao.month}/${dataRequisicao.year}'),
                      if (dataDevolucao != null)
                        _buildInfoRow('Devolvido em:', 
                            '${dataDevolucao.day}/${dataDevolucao.month}/${dataDevolucao.year}'),
                      _buildInfoRow('Exemplar:', '#$exemplarId ($estado)'),
                      _buildInfoRow('Editora:', editora),
                    ],
                  ),
                ),
              ],
            ),

            // Status e ações
            const SizedBox(height: 12),
            
            if (isAtiva) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: atrasado ? Colors.red.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      atrasado ? Icons.warning : Icons.schedule,
                      size: 16,
                      color: atrasado ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      atrasado 
                          ? 'Atrasado ${-diasRestantes} dias'
                          : diasRestantes > 0
                              ? '$diasRestantes dias restantes'
                              : 'Vence hoje',
                      style: TextStyle(
                        color: atrasado ? Colors.red.shade700 : Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading 
                      ? null 
                      : () => _devolverLivro(reserva['re_cod'], exemplarId),
                  icon: const Icon(Icons.keyboard_return),
                  label: const Text('Devolver Livro'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Devolvido',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
