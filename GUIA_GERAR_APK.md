# 📱 Como Gerar APK da Biblioteca App

## 🚨 Problema Atual
O Flutter precisa do Android SDK configurado para gerar APKs. Vamos resolver isso!

## 🔧 Configuração Necessária

### 1. **Instalar Android Studio**
1. Baixe o [Android Studio](https://developer.android.com/studio)
2. Instale com as configurações padrão
3. Durante a instalação, certifique-se de instalar:
   - Android SDK
   - Android SDK Platform
   - Android Virtual Device

### 2. **Configurar Variáveis de Ambiente**
1. Abra as **Configurações do Sistema** → **Sobre** → **Configurações avançadas do sistema**
2. Clique em **Variáveis de Ambiente**
3. Adicione estas variáveis:

**ANDROID_HOME:**
- Nome: `ANDROID_HOME`
- Valor: `C:\Users\[SEU_USUARIO]\AppData\Local\Android\Sdk`

**PATH:**
- Adicione ao PATH: `%ANDROID_HOME%\platform-tools`
- Adicione ao PATH: `%ANDROID_HOME%\tools`

### 3. **Ativar Modo Desenvolvedor**
1. Pressione `Windows + I` para abrir Configurações
2. Vá para **Atualização e Segurança** → **Para desenvolvedores**
3. Ative o **Modo de desenvolvedor**

### 4. **Verificar Instalação**
Abra o PowerShell e execute:
```powershell
flutter doctor
```

Deve mostrar que o Android SDK está configurado.

## 🏗️ Gerar o APK

### Opção 1: APK de Debug (Mais Fácil)
```powershell
cd "C:\Users\aluno\Desktop\Nova pasta\flutter_application_1"
C:\src\flutter\bin\flutter.bat build apk --debug
```

### Opção 2: APK de Release (Recomendado)
```powershell
cd "C:\Users\aluno\Desktop\Nova pasta\flutter_application_1"
C:\src\flutter\bin\flutter.bat build apk --release
```

## 📍 Localização do APK
Após a compilação, o APK estará em:
```
flutter_application_1\build\app\outputs\flutter-apk\
```

- **Debug:** `app-debug.apk`
- **Release:** `app-release.apk`

## ✅ Verificações Importantes

### 🔗 Conexão com Supabase
O APK já está configurado para conectar ao Supabase com:
- **URL:** `https://djfkoacmmbdufucriqyd.supabase.co`
- **Chave:** Configurada no `main.dart`

### 📱 Funcionalidades Incluídas
- ✅ Autenticação de utilizadores
- ✅ Lista de livros
- ✅ Detalhes dos livros
- ✅ Histórico de requisições
- ✅ Códigos postais
- ✅ Minhas reservas

## 🚀 Instalação no Dispositivo

1. **Ativar Fontes Desconhecidas:**
   - Configurações → Segurança → Fontes desconhecidas (ativar)

2. **Transferir APK:**
   - Copie o APK para o dispositivo Android
   - Toque no arquivo para instalar

3. **Permissões:**
   - O app pedirá permissões de internet (necessário para Supabase)

## 🆘 Resolução de Problemas

**Erro: "No Android SDK found"**
- Verifique se o ANDROID_HOME está configurado
- Reinicie o PowerShell após configurar as variáveis

**Erro: "Building with plugins requires symlink support"**
- Ative o Modo Desenvolvedor no Windows

**APK não instala no dispositivo:**
- Verifique se as "Fontes desconhecidas" estão ativadas
- Certifique-se de que o APK não está corrompido

## 📞 Suporte
Se tiver problemas, verifique:
1. `flutter doctor` - mostra problemas de configuração
2. Logs de erro durante a compilação
3. Configuração das variáveis de ambiente
