# 🪶 Alternativas Leves para Gerar APK

## 🚀 Opção 1: Android SDK Command Line Tools (Recomendado)

### Download Direto (Sem Android Studio)
1. Baixe apenas o **Android SDK Command Line Tools**:
   - Vá para: https://developer.android.com/studio#command-tools
   - Baixe: "Command line tools only" (cerca de 100MB vs 1GB+ do Android Studio)

2. Extraia para: `C:\Android\cmdline-tools\`

3. Configure as variáveis de ambiente:
   ```
   ANDROID_HOME = C:\Android
   PATH = %ANDROID_HOME%\cmdline-tools\latest\bin
   PATH = %ANDROID_HOME%\platform-tools
   ```

4. Instale apenas o necessário:
   ```powershell
   sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
   ```

## 🛠️ Opção 2: Usar Flutter Web (Mais Leve)

Se não precisar especificamente de APK, pode usar Flutter Web:

```powershell
C:\src\flutter\bin\flutter.bat build web
```

O resultado será uma pasta `build/web` que pode ser hospedada em qualquer servidor.

## 📱 Opção 3: Usar um Serviço Online

### GitHub Actions (Gratuito)
1. Crie um repositório no GitHub
2. Adicione este arquivo `.github/workflows/build.yml`:

```yaml
name: Build APK
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
    - run: flutter pub get
    - run: flutter build apk --release
    - uses: actions/upload-artifact@v3
      with:
        name: apk
        path: build/app/outputs/flutter-apk/app-release.apk
```

### Outros Serviços Online:
- **Codemagic** (gratuito para projetos públicos)
- **Bitrise** (plano gratuito)
- **AppVeyor** (gratuito para projetos públicos)

## 🔧 Opção 4: Configuração Mínima Local

### Instalar apenas o essencial:
```powershell
# Baixar Android SDK Platform Tools (apenas 5MB)
# https://developer.android.com/studio/releases/platform-tools

# Configurar variáveis:
ANDROID_HOME = C:\Android
PATH = %ANDROID_HOME%\platform-tools
```

### Tentar build sem SDK completo:
```powershell
C:\src\flutter\bin\flutter.bat build apk --debug --no-tree-shake-icons
```

## 🌐 Opção 5: Flutter Web + PWA

Transforme sua app em uma PWA (Progressive Web App):

1. **Build para Web:**
   ```powershell
   C:\src\flutter\bin\flutter.bat build web --web-renderer html
   ```

2. **Adicionar manifest.json** (já existe no projeto)

3. **Usuários podem "instalar" no dispositivo** como app nativo

## 📊 Comparação de Tamanhos:

| Opção | Tamanho | Complexidade | Resultado |
|-------|---------|--------------|-----------|
| Android Studio | ~3GB | Alta | APK Nativo |
| SDK Command Line | ~200MB | Média | APK Nativo |
| Flutter Web | ~50MB | Baixa | Web App |
| Serviço Online | 0MB | Baixa | APK Nativo |
| PWA | ~50MB | Baixa | App "Nativo" |

## 🎯 Recomendação

Para o seu caso, recomendo:

1. **Se quer APK nativo:** Use SDK Command Line Tools
2. **Se quer simplicidade:** Use Flutter Web + PWA
3. **Se quer automatizar:** Use GitHub Actions

## 🚀 Comando Rápido para Testar

Tente primeiro este comando (pode funcionar sem SDK completo):
```powershell
cd "C:\Users\aluno\Desktop\Nova pasta\flutter_application_1"
C:\src\flutter\bin\flutter.bat build web
```

Isso criará uma versão web da sua app que funciona em qualquer navegador!
