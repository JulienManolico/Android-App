# 🔐 Configuração de Autenticação - Supabase

## ✅ **O que já está implementado:**

- ✅ **Tela de Login/Registo** moderna e responsiva
- ✅ **Autenticação por email** e password
- ✅ **Autenticação com Google** (requer configuração)
- ✅ **Navegação automática** baseada no estado de login
- ✅ **Tela principal** com menu de opções
- ✅ **Logout** funcional
- ✅ **Validação de formulários**
- ✅ **Tratamento de erros** em português

## 🚀 **Para ativar a autenticação:**

### 1. **Configurar no Supabase Dashboard:**

1. Vá para **Authentication** → **Settings**
2. **Ative** os seguintes providers:
   - ✅ **Email** (já deve estar ativo)
   - ✅ **Google** (opcional)

### 2. **Configurar Google Sign-In (Opcional):**

#### **A. No Google Cloud Console:**
1. Vá para [console.cloud.google.com](https://console.cloud.google.com/)
2. Crie um novo projeto ou selecione um existente
3. **APIs & Services** → **Credentials**
4. **Create Credentials** → **OAuth 2.0 Client IDs**
5. Configure para:
   - **Web application** (para Flutter Web)
   - **Android** (para Android)
   - **iOS** (para iOS)

#### **B. No Supabase:**
1. **Authentication** → **Providers** → **Google**
2. **Enable Google provider**
3. Cole o **Client ID** e **Client Secret** do Google

#### **C. No código Flutter:**
Edite o arquivo `lib/screens/auth_screen.dart` nas linhas 65-66:
```dart
const webClientId = 'SEU_GOOGLE_WEB_CLIENT_ID';
const iosClientId = 'SEU_GOOGLE_IOS_CLIENT_ID';
```

### 3. **Configurar políticas de autenticação:**

No **SQL Editor** do Supabase:
```sql
-- Permitir que utilizadores autenticados vejam os dados
CREATE POLICY "Authenticated users can read" ON public.codigo_postal
FOR SELECT USING (auth.role() = 'authenticated');

-- Aplicar a todas as tabelas
CREATE POLICY "Authenticated users can read" ON public.editora
FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can read" ON public.autor
FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can read" ON public.genero
FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can read" ON public.livro
FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can read" ON public.livro_exemplar
FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can read" ON public.utente
FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can read" ON public.requisicao
FOR SELECT USING (auth.role() = 'authenticated');
```

## 🎯 **Funcionalidades da App:**

### **Tela de Login:**
- 📧 **Login com email** e password
- 🆕 **Registo de nova conta**
- 🔄 **Toggle** entre login e registo
- 🌐 **Login com Google** (opcional)
- ✅ **Validação** de campos
- ❌ **Tratamento de erros** em português

### **Tela Principal:**
- 👋 **Boas-vindas** personalizadas
- 📊 **Menu em grid** com 6 opções:
  - 📍 **Códigos Postais** (funcional)
  - 📚 **Livros** (em desenvolvimento)
  - 👥 **Autores** (em desenvolvimento)
  - 🏢 **Editoras** (em desenvolvimento)
  - 👤 **Utentes** (em desenvolvimento)
  - 📋 **Requisições** (em desenvolvimento)
- 🚪 **Logout** no menu superior

## 🔧 **Para testar:**

1. **Execute a app:** `flutter run`
2. **Registe uma conta** com o seu email
3. **Confirme o email** (verifique a caixa de entrada)
4. **Faça login** com as credenciais
5. **Explore o menu** da tela principal

## 🛠️ **Próximos desenvolvimentos:**

- 📚 **Tela de gestão de livros**
- 👥 **Tela de gestão de autores**
- 🏢 **Tela de gestão de editoras**
- 👤 **Tela de gestão de utentes**
- 📋 **Tela de gestão de requisições**
- 🔍 **Pesquisa avançada**
- 📊 **Dashboard com estatísticas**

## 🆘 **Resolução de problemas:**

**Erro: "Email not confirmed"**
- Verifique a caixa de entrada do email
- Clique no link de confirmação

**Erro: "Invalid login credentials"**
- Verifique se o email e password estão corretos
- Certifique-se de que confirmou o email

**Google Sign-In não funciona:**
- Configure as credenciais do Google Cloud Console
- Adicione os Client IDs no código Flutter
