import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLogin = true;
  bool _isLoading = false;
  String _errorMessage = '';

  SupabaseClient get supabase => Supabase.instance.client;

  // Função para verificar conexão com Supabase
  Future<void> _checkConnection() async {
    try {
      print('🔍 Testando conexão com Supabase...');
      // Tentar fazer uma consulta simples para testar a conexão
      await supabase.from('codigo_postal').select('cod_postal').limit(1);
      print('📊 Conexão com Supabase: OK');
    } catch (e) {
      print('❌ Erro de conexão com Supabase: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      print('🔍 Tentando ${_isLogin ? 'login' : 'registo'}');
      print('📧 Email: "$email"');
      print('🔑 Password length: ${password.length}');
      
      if (_isLogin) {
        // Verificar conexão primeiro
        await _checkConnection();
        
        // Login
        print('🔐 Fazendo login...');
        final response = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        print('✅ Login bem-sucedido!');
        print('👤 User: ${response.user?.email}');
        print('🎫 Session: ${response.session != null ? 'Ativa' : 'Nula'}');
      } else {
        // Registo com configuração especial
        print('📝 Iniciando registo...');
        
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: null, // Não redirecionar
        );
        
        print('📝 Registo concluído');
        print('👤 User criado: ${response.user?.email}');
        print('🎫 Session: ${response.session != null ? 'Ativa' : 'Nula'}');
        print('✉️ Email confirmado: ${response.user?.emailConfirmedAt != null}');
        
        if (!mounted) return;
        
        // Se tem sessão ativa, redirecionar imediatamente
        if (response.session != null) {
          print('✅ Login automático bem-sucedido!');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
          return;
        }
        
        // Se não tem sessão, mostrar mensagem e mudar para login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Conta criada com sucesso!'),
                Text('Email: $email'),
                const Text('Agora faça login com essas credenciais.'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        
        setState(() {
          _isLogin = true; // Mudar para modo login
          _errorMessage = ''; // Limpar erros
        });
        return;
      }
      
      if (!mounted) return;
      
      // Navegar para a tela principal
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
      
    } catch (e) {
      print('❌ Erro de autenticação: $e');
      setState(() {
        _errorMessage = _getErrorMessage(e.toString());
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  String _getErrorMessage(String error) {
    print('🔍 Analisando erro: $error');
    
    if (error.contains('Invalid login credentials')) {
      return 'Email ou password incorretos.';
    } else if (error.contains('Email not confirmed')) {
      return 'Conta não confirmada automaticamente.\nTente fazer login novamente.';
    } else if (error.contains('Password should be at least 6 characters')) {
      return 'A password deve ter pelo menos 6 caracteres';
    } else if (error.contains('Unable to validate email address')) {
      return 'Email inválido';
    } else if (error.contains('User already registered')) {
      return 'Este email já está registado.\nTente fazer login em vez de registar.';
    } else if (error.contains('Signup not allowed')) {
      return 'Registo não permitido.\nContacte o administrador.';
    } else if (error.contains('User not found')) {
      return 'Utilizador não encontrado.\nVerifique o email ou registe-se primeiro.';
    }
    return 'Erro: $error';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo/Título
                        Icon(
                          Icons.library_books,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Biblioteca Digital',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin ? 'Faça login na sua conta' : 'Crie a sua conta',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Campo Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o seu email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Por favor, insira um email válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Campo Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira a sua password';
                            }
                            if (value.length < 6) {
                              return 'A password deve ter pelo menos 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Mensagem de erro
                        if (_errorMessage.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Botão Login/Registo
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signInWithEmail,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    _isLogin ? 'Entrar' : 'Registar',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const SizedBox(height: 8),

                        // Botão de debug (temporário)
                        if (!_isLoading)
                          TextButton(
                            onPressed: () async {
                              try {
                                print('🔍 Testando conexão...');
                                await _checkConnection();
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Conexão OK! Verifique os logs.'),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro de conexão: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text('🔍 Testar Conexão'),
                          ),

                        const SizedBox(height: 8),

                        // Toggle Login/Registo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin ? 'Não tem conta?' : 'Já tem conta?',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _errorMessage = '';
                                });
                              },
                              child: Text(
                                _isLogin ? 'Registar' : 'Entrar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
