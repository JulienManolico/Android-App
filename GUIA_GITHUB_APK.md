# 🚀 Como Gerar APK com GitHub Actions

## 📋 Passo a Passo Completo

### 1. **Criar Repositório no GitHub**
1. Vá para [github.com](https://github.com)
2. Clique em **"New repository"**
3. Nome: `biblioteca-app` (ou o que preferir)
4. **IMPORTANTE:** Marque como **"Private"** (não público)
5. **NÃO** marque "Add README" (já temos um)
6. Clique **"Create repository"**

### 2. **Configurar Git Local**
Abra o PowerShell no diretório do projeto e execute:

```powershell
cd "C:\Users\aluno\Desktop\Nova pasta\flutter_application_1"

# Inicializar git (se ainda não foi feito)
git init

# Adicionar arquivos
git add .

# Primeiro commit
git commit -m "Initial commit: Biblioteca App with Supabase"

# Conectar ao repositório GitHub (substitua SEU_USUARIO e SEU_REPOSITORIO)
git remote add origin https://github.com/SEU_USUARIO/SEU_REPOSITORIO.git

# Fazer push
git branch -M main
git push -u origin main
```

### 3. **Verificar GitHub Actions**
1. Vá para o seu repositório no GitHub
2. Clique na aba **"Actions"**
3. Deve aparecer o workflow **"Build APK"**
4. Clique nele para ver o progresso

### 4. **Baixar o APK**
Após o build completar (cerca de 5-10 minutos):

#### Opção A: Artifacts
1. Na aba **"Actions"**
2. Clique na execução bem-sucedida
3. Role para baixo até **"Artifacts"**
4. Baixe **"app-release-apk"**

#### Opção B: Releases (Automático)
1. Vá para a aba **"Releases"**
2. Baixe a versão mais recente
3. O APK estará anexado

## 🔄 **Para Novos Builds**

Sempre que fizer alterações:

```powershell
git add .
git commit -m "Descrição das alterações"
git push origin main
```

O APK será gerado automaticamente!

## ⚙️ **Configurações Avançadas**

### Build Manual
1. Vá para **"Actions"** → **"Build APK"**
2. Clique **"Run workflow"**
3. Selecione a branch **"main"**
4. Clique **"Run workflow"**

### Alterar Versão do Flutter
Edite `.github/workflows/build.yml`:
```yaml
flutter-version: '3.24.0'  # Mude aqui
```

## 🆘 **Resolução de Problemas**

### Erro: "Repository not found"
- Verifique se o repositório é privado
- Confirme o nome do usuário/repositório

### Erro: "Permission denied"
- Use token de acesso pessoal em vez de senha
- Vá para Settings → Developer settings → Personal access tokens

### Build falha
- Verifique os logs na aba "Actions"
- Confirme se todas as dependências estão no `pubspec.yaml`

## 🎯 **Vantagens desta Abordagem**

✅ **Gratuito** - GitHub Actions é gratuito para repositórios privados  
✅ **Automático** - APK gerado a cada push  
✅ **Sem instalação** - Não precisa do Android Studio  
✅ **Histórico** - Mantém versões anteriores  
✅ **Fácil** - Apenas push do código  

## 📱 **Resultado Final**

- APK otimizado para produção
- Conecta ao Supabase
- Todas as funcionalidades incluídas
- Pronto para instalar no Android

**O APK será gerado automaticamente sempre que fizer push!** 🚀
