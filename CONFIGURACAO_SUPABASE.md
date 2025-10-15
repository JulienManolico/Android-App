# 🚀 Como Configurar o Supabase na sua App

## 📋 Passos para conectar:

### 1. **Obter as credenciais do Supabase**
1. Vá para [app.supabase.com](https://app.supabase.com/)
2. Selecione o seu projeto
3. Vá para **Settings** → **API**
4. Copie:
   - **Project URL** (ex: `https://seuprojetoid.supabase.co`)
   - **anon public key** (chave longa que começa com `eyJhbGciOiJIUzI1NiIs...`)

### 2. **Configurar as credenciais na app**
Abra o arquivo `lib/main.dart` e substitua as linhas 9-10:

```dart
await Supabase.initialize(
  url: 'https://seuprojetoid.supabase.co',  // ← Cole aqui a sua URL
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',  // ← Cole aqui a sua chave
);
```

### 3. **Configurar políticas RLS no Supabase**
No Supabase Dashboard:
1. Vá para **Authentication** → **Policies**
2. Para a tabela `codigo_postal`, adicione esta política:

```sql
CREATE POLICY "Allow public read access" ON codigo_postal
FOR SELECT USING (true);
```

### 4. **Executar a aplicação**
```bash
flutter pub get
flutter run
```

## 🎯 Funcionalidades da App:

✅ **Lista todos os códigos postais** da base de dados  
✅ **Pesquisa por código postal** (ex: "1000")  
✅ **Pesquisa por localidade** (ex: "Lisboa")  
✅ **Interface moderna** com contador de resultados  
✅ **Atualização manual** com botão refresh  
✅ **Tratamento de erros** com mensagens claras  

## 🔧 Estrutura do Projeto:

- `lib/main.dart` - Configuração inicial e tela principal
- `lib/models/codigo_postal.dart` - Modelo de dados
- `lib/screens/codigos_postais_screen.dart` - Tela de listagem
- `pubspec.yaml` - Dependências do Supabase

## 🆘 Resolução de Problemas:

**Erro: "Failed to fetch"**
- Verifique se as credenciais estão corretas
- Confirme se a política RLS está configurada

**Erro: "Table 'codigo_postal' doesn't exist"**
- Certifique-se de que criou a tabela no Supabase
- Verifique se inseriu os dados de exemplo

**Lista vazia**
- Confirme se os dados foram inseridos corretamente
- Verifique a conexão com a internet
