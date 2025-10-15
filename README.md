# 📚 Sistema de Biblioteca Flutter

Um sistema completo de gestão de biblioteca desenvolvido em Flutter com integração Supabase.

## 🚀 Funcionalidades

- ✅ **Autenticação de utilizadores** (Login/Registo)
- ✅ **Catálogo de livros** com pesquisa avançada
- ✅ **Sistema de reservas** de livros
- ✅ **Gestão de exemplares** disponíveis
- ✅ **Histórico de reservas** do utilizador
- ✅ **Interface moderna** e responsiva

## 🛠️ Tecnologias

- **Flutter** - Framework de desenvolvimento
- **Supabase** - Backend como serviço (BaaS)
- **Dart** - Linguagem de programação

## 📱 Como Executar

### Pré-requisitos
- Flutter SDK instalado
- Conta no Supabase

### Instalação
1. Clone o repositório
2. Instale as dependências:
   ```bash
   flutter pub get
   ```
3. Configure as credenciais do Supabase no `lib/main.dart`
4. Execute o projeto:
   ```bash
   flutter run -d chrome
   ```

## 🌐 Deploy Online

Este projeto está configurado para deploy automático no GitHub Pages.

### Acesso Online
- **URL**: [https://seuusuario.github.io/biblioteca-flutter](https://seuusuario.github.io/biblioteca-flutter)

## 📊 Estrutura do Projeto

```
lib/
├── main.dart                 # Configuração inicial
├── models/                   # Modelos de dados
│   ├── livro.dart
│   ├── autor.dart
│   ├── editora.dart
│   └── requisicao.dart
├── screens/                  # Telas da aplicação
│   ├── auth_screen.dart
│   ├── home_screen.dart
│   ├── livros_screen.dart
│   ├── livro_detalhes_screen.dart
│   ├── minhas_reservas_screen.dart
│   └── historico_screen.dart
└── services/                 # Serviços (futuro)
```

## 🔧 Configuração do Supabase

1. Crie um projeto no [Supabase](https://supabase.com)
2. Configure as tabelas necessárias
3. Atualize as credenciais no `main.dart`

## 📝 Licença

Este projeto é de uso educacional.

## 👨‍💻 Desenvolvido por

[Seu Nome] - Sistema de Biblioteca Flutter