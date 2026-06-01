# MesclaInvest App (Flutter)

Aplicativo Flutter do projeto MesclaInvest, usado para simular investimentos em startups do ecossistema Mescla.

## Visão geral

Este app consome:

- Firebase Auth
- Firebase Firestore
- Firebase Cloud Functions
- Backend HTTP/Socket para fluxos em tempo real

Em modo debug, o app foi configurado para usar Firebase Emulator Suite automaticamente.
Em modo release, o app usa os serviços reais do Firebase.

## Requisitos

- Flutter SDK instalado e no PATH
- Dart SDK (incluído com Flutter)
- Firebase CLI instalado (para desenvolvimento com emuladores)
- Node.js LTS (necessário para Cloud Functions no backend)

## Estrutura relevante

```text
ES-PI3-2026-T1-G33/
├── backend/
│   ├── firebase.json
│   ├── .firebaserc
│   └── functions/
│       ├── src/
│       └── package.json
└── mescla_invest/
	├── lib/
	├── assets/
	├── web/
	└── pubspec.yaml
```

## 1. Instalar dependências do app

No diretório do app:

```bash
cd mescla_invest
flutter pub get
```

## 2. Preparar backend para emuladores (desenvolvimento local)

No diretório do backend, instale as dependências das Functions e gere o build:

```bash
cd ../backend/functions
npm install
npm run build
```

Depois inicie os emuladores a partir da pasta backend:

```bash
cd ..
firebase emulators:start
```

Portas usadas:

- Auth: 9099
- Functions: 5001
- Firestore: 8080
- Storage: 9199
- Emulator UI: 4000

## 3. Rodar o app em debug (com emuladores)

De volta à pasta do app:

```bash
cd ../mescla_invest
flutter run
```

Para web (Chrome), você pode usar:

```bash
flutter run -d chrome
```

## 4. Rodar em release (Firebase real)

```bash
flutter run --release
```

Em release, o app não usa emuladores locais.

## Configuração automática de emulador no app

Quando em debug, o app configura automaticamente:

- Auth Emulator
- Firestore Emulator
- Functions Emulator

Host padrão:

- Web/Desktop: localhost
- Android Emulator: 10.0.2.2

Para Android físico ou outra máquina na rede, sobrescreva o host:

```bash
flutter run --dart-define=EMULATOR_HOST=192.168.0.10
```

## Troubleshooting

### Erro de pacote não encontrado (cloud_functions, url_launcher)

Execute novamente:

```bash
flutter pub get
```

Se persistir, rode:

```bash
flutter clean
flutter pub get
```

### Erro ao compilar para web

Valide o projeto com:

```bash
flutter analyze
flutter build web
```

### Emulador Firebase não sobe

- Confirme login no Firebase CLI: `firebase login`
- Confirme projeto padrão em `backend/.firebaserc`
- Verifique se as portas (9099, 5001, 8080, 9199, 4000) estão livres

## Comandos úteis

```bash
flutter devices
flutter analyze
flutter test
flutter build web
```

## Observação

Se você alterar dependências no pubspec.yaml, rode `flutter pub get` antes de executar o app.
