# ES-PI3-2026-T1-G33

## Integrantes

• Cauã Bianchi Ferroni<br>
• Felipe Augusto dos Santos Silva<br>
• Leonardo Santiago Tenca<br>
• Marina Hehnes Esposito<br>
• Vinicius Valim de Vechi Cardoso

## Descrição

O **MesclaInvest** é um aplicativo móvel que consiste em um ambiente digital de investimento simulado, focado em startups vinculadas ao ecossistema de inovação **Mescla**.

O objetivo é proporcionar uma experiência prática na modelagem e desenvolvimento de um sistema que utiliza o conceito de tokenização para representar participações econômicas em startups em estágios iniciais. A plataforma funciona como um simulador de corretora, onde usuários podem navegar por um catálogo de projetos inovadores e realizar operações de compra e venda de tokens em um ambiente controlado, promovendo transparência e integração entre a universidade e a sociedade

## Técnologias utilizadas

**Backend**

• Node.js<br>
• TypeScript / JavaScript

**Frontend**

• Flutter<br>
• Dart

**Banco de dados**

• Firebase Firestore

**Ambiente de desenvolvimento**

• Microsoft Visual Studio Code<br>
• Android Studio

**Controle de Versão e Repositório**

• Git<br>
• Repositório hospedado **exclusivamente** no GitHub

## Instruções para execução

Para executar o sistema em ambiente de testes, siga os passos abaixo:

**Pré-requisitos**:<br>
Node.js (LTS) instalado.<br>
Flutter SDK configurado.<br>

**IDEs recomendadas**<br>
VS Code ou Android Studio.

**Estrutura do Repositório**:

```text
ES-PI3-2026-T1-G33/
├── backend/            
│   ├── src/
│   ├── package.json
│   └── .env.example
├── mobile/             
│   ├── lib/
│   └── pubspec.yaml
└── README.md
```
### 1. Obtendo o Código-Fonte

Primeiro, faça o download do repositório para o seu ambiente local e acesse o diretório principal:

```bash
git clone https://github.com/[seu-usuario]/ES-PI3-2026-T1-G33.git
cd ES-PI3-2026-T1-G33
```

### 2. Subindo a API (Backend)

A API foi construída em Node.js. Para rodá-la, você precisará instalar os pacotes e configurar a conexão com o Firebase.

```bash
# Entre no diretório da API
cd backend

# Baixe todas as dependências do projeto
npm install

# Crie o seu arquivo de configuração local baseado no template
cp .env.exemplo .env

# Após preencher o .env com suas chaves, inicie o servidor
npm run dev
```

### 3. Configuração das Credenciais (Firebase)

No arquivo `.env` gerado (dentro da pasta `backend`), você deve inserir as chaves do projeto Firebase da sua equipe. A estrutura do arquivo deve ficar assim:

```env
# Porta de execução da API
PORT=3000

# Credenciais de acesso ao Firebase
FIREBASE_PROJECT_ID=insira_aqui_seu_project_id
FIREBASE_PRIVATE_KEY=insira_aqui_sua_private_key
FIREBASE_CLIENT_EMAIL=insira_aqui_seu_client_email
```

### 4. Iniciando o Aplicativo (Mobile)

Com o backend rodando, abra um novo terminal para compilar e executar o frontend em Flutter.

```bash
# Vá para a pasta do aplicativo
cd mobile

# Atualize e baixe os pacotes do Dart/Flutter
flutter pub get

# Liste os emuladores ou aparelhos físicos disponíveis
flutter devices

# Inicie o app no dispositivo de sua escolha
flutter run
```
