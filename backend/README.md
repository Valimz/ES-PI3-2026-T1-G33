# Backend

Scripts úteis para desenvolvimento local com Firebase Emulator Suite.

## Comandos

```powershell
npm run functions:build
npm run emulators:start
npm run e2e:test
npm run e2e:test:wallet
npm run e2e:test:p2p
npm run e2e:test:graph
npm run e2e:test:notifications
```

## O que cada comando faz

- `functions:build`: compila as Cloud Functions em TypeScript.
- `emulators:start`: sobe Auth, Functions e Firestore localmente.
- `e2e:test`: sobe os emuladores automaticamente e executa a suíte Flutter do app.
- Os comandos `e2e:test:*` executam apenas o arquivo de teste correspondente.

## Portas usadas

- Auth: `9099`
- Functions: `5001`
- Firestore: `8080`

Execute esses comandos a partir da pasta `backend`.
