import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/codigo_postal.dart';

class CodigosPostaisScreen extends StatefulWidget {
  const CodigosPostaisScreen({super.key});

  @override
  State<CodigosPostaisScreen> createState() => _CodigosPostaisScreenState();
}

class _CodigosPostaisScreenState extends State<CodigosPostaisScreen> {
  final _searchController = TextEditingController();
  List<CodigoPostal> _codigosPostais = [];
  List<CodigoPostal> _codigosFiltrados = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Getter para acessar o cliente Supabase
  SupabaseClient get supabase => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadCodigosPostais();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCodigosPostais() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('🔍 Tentando buscar dados da tabela codigo_postal...');
      
      final response = await supabase
          .from('codigo_postal')
          .select('*')
          .order('cod_postal');

      print('📊 Resposta do Supabase: $response');
      print('📊 Tipo da resposta: ${response.runtimeType}');
      print('📊 Número de registos: ${response.length}');

      final codigosPostais = (response as List)
          .map((json) => CodigoPostal.fromJson(json))
          .toList();

      setState(() {
        _codigosPostais = codigosPostais;
        _codigosFiltrados = codigosPostais;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar códigos postais: $e';
        _isLoading = false;
      });
    }
  }

  void _filtrarCodigosPostais(String query) {
    setState(() {
      if (query.isEmpty) {
        _codigosFiltrados = _codigosPostais;
      } else {
        _codigosFiltrados = _codigosPostais.where((codigo) {
          return codigo.codPostal.toLowerCase().contains(query.toLowerCase()) ||
                 codigo.codLocalidade.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Códigos Postais'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadCodigosPostais,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Pesquisar por código postal ou localidade',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filtrarCodigosPostais,
            ),
          ),

          // Contador de resultados
          if (!_isLoading && _errorMessage.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    '${_codigosFiltrados.length} códigos postais encontrados',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Lista de códigos postais
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
            Text('Carregando códigos postais...'),
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
              onPressed: _loadCodigosPostais,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_codigosFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Nenhum código postal encontrado'
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
      itemCount: _codigosFiltrados.length,
      itemBuilder: (context, index) {
        final codigo = _codigosFiltrados[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                codigo.codPostal.substring(0, 1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              codigo.codPostal,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            subtitle: Text(codigo.codLocalidade),
            trailing: const Icon(Icons.location_on, color: Colors.grey),
          ),
        );
      },
    );
  }
}
