import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  List<Map<String, dynamic>> _historico = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _filtro = 'todos'; // todos, devolvidos, atrasados

  SupabaseClient get supabase => Supabase.instance.client;
  User? get user => supabase.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadHistorico();
  }

  Future<void> _loadHistorico() async {
    if (user == null) {
      setState(() {
        _errorMessage = 'Precisa estar logado para ver o histórico';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('📚 Carregando histórico do utilizador: ${user!.email}');

      // Primeiro, obter o ID do utente
      final utenteResponse = await supabase
          .from('utente')
          .select('ut_cod')
          .eq('ut_email', user!.email!)
          .maybeSingle();

      if (utenteResponse == null) {
        setState(() {
          _historico = [];
          _isLoading = false;
        });
        return;
      }

      final utenteId = utenteResponse['ut_cod'];

      // Buscar todo o histórico de reservas
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
              livro:lex_li_cod(
                li_cod,
                li_titulo,
                li_ano,
                li_isbn,
                li_genero,
                autor:li_autor(au_nome),
                editora:li_editora(ed_nome)
              )
            )
          ''')
          .eq('re_ut_cod', utenteId)
          .order('re_data_requisicao', ascending: false);

      setState(() {
        _historico = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      print('📊 Histórico carregado: ${_historico.length} registos');
    } catch (e) {
      print('❌ Erro ao carregar histórico: $e');
      setState(() {
        _errorMessage = 'Erro ao carregar histórico: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _historicoFiltrado {
    switch (_filtro) {
      case 'devolvidos':
        return _historico.where((h) => h['re_data_devolucao'] != null).toList();
      case 'ativos':
        return _historico.where((h) => h['re_data_devolucao'] == null).toList();
      case 'atrasados':
        return _historico.where((h) {
          if (h['re_data_devolucao'] != null) return false;
          final dataRequisicao = DateTime.parse(h['re_data_requisicao']);
          final hoje = DateTime.now();
          final prazo = dataRequisicao.add(const Duration(days: 14));
          return hoje.isAfter(prazo);
        }).toList();
      default:
        return _historico;
    }
  }

  Map<String, int> get _estatisticas {
    final total = _historico.length;
    final devolvidos = _historico.where((h) => h['re_data_devolucao'] != null).length;
    final ativos = _historico.where((h) => h['re_data_devolucao'] == null).length;
    final atrasados = _historico.where((h) {
      if (h['re_data_devolucao'] != null) return false;
      final dataRequisicao = DateTime.parse(h['re_data_requisicao']);
      final hoje = DateTime.now();
      final prazo = dataRequisicao.add(const Duration(days: 14));
      return hoje.isAfter(prazo);
    }).length;

    return {
      'total': total,
      'devolvidos': devolvidos,
      'ativos': ativos,
      'atrasados': atrasados,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _estatisticas;
    final historicoFiltrado = _historicoFiltrado;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Reservas'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadHistorico,
          ),
        ],
      ),
      body: Column(
        children: [
          // Estatísticas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resumo das suas reservas:',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            user?.email ?? 'Utilizador',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Total', stats['total']!, Colors.blue),
                    _buildStatCard('Ativas', stats['ativos']!, Colors.green),
                    _buildStatCard('Devolvidas', stats['devolvidos']!, Colors.grey),
                    _buildStatCard('Atrasadas', stats['atrasados']!, Colors.red),
                  ],
                ),
              ],
            ),
          ),

          // Filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Filtrar: '),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Todas', 'todos', stats['total']!),
                        const SizedBox(width: 8),
                        _buildFilterChip('Ativas', 'ativos', stats['ativos']!),
                        const SizedBox(width: 8),
                        _buildFilterChip('Devolvidas', 'devolvidos', stats['devolvidos']!),
                        const SizedBox(width: 8),
                        _buildFilterChip('Atrasadas', 'atrasados', stats['atrasados']!),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Lista do histórico
          Expanded(
            child: _buildContent(historicoFiltrado),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filtro == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _filtro = value;
        });
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> historico) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando histórico...'),
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
              onPressed: _loadHistorico,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (historico.isEmpty) {
      String mensagem;
      switch (_filtro) {
        case 'devolvidos':
          mensagem = 'Nenhum livro devolvido ainda';
          break;
        case 'ativos':
          mensagem = 'Nenhuma reserva ativa';
          break;
        case 'atrasados':
          mensagem = 'Nenhuma reserva atrasada';
          break;
        default:
          mensagem = 'Nenhuma reserva encontrada';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              mensagem,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Vá para "Pesquisar Livros" para fazer reservas!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: historico.length,
      itemBuilder: (context, index) {
        final reserva = historico[index];
        return _buildHistoricoCard(reserva);
      },
    );
  }

  Widget _buildHistoricoCard(Map<String, dynamic> reserva) {
    final livroData = reserva['livro_exemplar']['livro'];
    final dataRequisicao = DateTime.parse(reserva['re_data_requisicao']);
    final dataDevolucao = reserva['re_data_devolucao'] != null 
        ? DateTime.parse(reserva['re_data_devolucao'])
        : null;

    final titulo = livroData['li_titulo'] ?? 'Título desconhecido';
    final autor = livroData['autor']?['au_nome'] ?? 'Autor desconhecido';
    final genero = livroData['li_genero'] ?? '';
    final ano = livroData['li_ano']?.toString() ?? '';
    final exemplarId = reserva['livro_exemplar']['lex_cod'];
    final estado = reserva['livro_exemplar']['lex_estado'];

    final isAtivo = dataDevolucao == null;
    final isAtrasado = isAtivo && DateTime.now().isAfter(dataRequisicao.add(const Duration(days: 14)));

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!isAtivo) {
      statusColor = Colors.grey;
      statusText = 'Devolvido';
      statusIcon = Icons.check_circle;
    } else if (isAtrasado) {
      statusColor = Colors.red;
      statusText = 'Atrasado';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.green;
      statusText = 'Ativo';
      statusIcon = Icons.schedule;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isAtivo ? 4 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Container(
                  width: 40,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Icon(Icons.book, color: statusColor),
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
                      if (genero.isNotEmpty || ano.isNotEmpty)
                        Text(
                          [genero, ano].where((s) => s.isNotEmpty).join(' • '),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Detalhes
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Reservado:', 
                          '${dataRequisicao.day}/${dataRequisicao.month}/${dataRequisicao.year}'),
                      if (dataDevolucao != null)
                        _buildDetailRow('Devolvido:', 
                            '${dataDevolucao.day}/${dataDevolucao.month}/${dataDevolucao.year}'),
                      _buildDetailRow('Exemplar:', '#$exemplarId ($estado)'),
                    ],
                  ),
                ),
              ],
            ),

            // Informação adicional para reservas ativas
            if (isAtivo) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isAtrasado ? Colors.red.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAtrasado ? Icons.warning : Icons.info,
                      size: 16,
                      color: isAtrasado ? Colors.red.shade700 : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isAtrasado 
                            ? 'Esta reserva está atrasada. Por favor, devolva o livro.'
                            : 'Prazo de devolução: ${dataRequisicao.add(const Duration(days: 14)).day}/${dataRequisicao.add(const Duration(days: 14)).month}/${dataRequisicao.add(const Duration(days: 14)).year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isAtrasado ? Colors.red.shade700 : Colors.blue.shade700,
                        ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
