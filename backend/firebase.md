#  Firebase Firestore — Documentação do Banco de Dados

## Visão Geral

Banco de dados NoSQL orientado a documentos com **3 coleções principais**:

- `p2p_offers` — Ofertas de compra/venda entre usuários
- `startups` — Startups disponíveis para investimento
- `users` — Usuários cadastrados na plataforma

---

## Estrutura

```
Firestore (default)
│
├── p2p_offers/
│   └── {offerId}
│       ├── createdAt (timestamp)
│       ├── price (number)
│       ├── quotas (number)
│       ├── sellerId (string → ref: users)
│       ├── startupName (string)
│       └── status (string)
│
├── startups/
│   └── {startupId}
│       ├── name (string)
│       ├── stage (string)
│       ├── val (string)
│       ├── description (string)
│       ├── sector (string)
│       ├── capitalAportado (number)
│       ├── tokensEmitidos (number)
│       ├── socios (array<map>)
│       │   └── { nome: string, percentual: number }
│       ├── mentoresConselho (array<string>)
│       ├── videoUrl (string | null)
│       ├── status (string)
│       └── faq (array<map>)
│           └── { pergunta: string, resposta: string, publico: boolean }
│
└── users/
    └── {userId}
        ├── cpf (string)
        ├── createdAt (timestamp)
        ├── email (string)
        ├── nome (string)
        ├── telefone (string)
        └── wallet/ (subcoleção)
            └── main
                ├── appreciation (string)
                └── balance (string)
```

---

## Coleção: `p2p_offers`

Ofertas P2P criadas pelos vendedores da plataforma.

**Caminho:** `/p2p_offers/{offerId}`

| Campo | Tipo | Exemplo | Descrição |
|-------|------|---------|-----------|
| `createdAt` | timestamp | `7 mai 2026, 12:15:55` | Data e hora de criação da oferta |
| `price` | number | `1000` | Preço unitário do token ofertado |
| `quotas` | number | `26.7` | Quantidade de tokens disponíveis |
| `sellerId` | string | `YkgslmTG1R7H4x...` | UID do vendedor (ref: users) |
| `startupName` | string | `Educa+` | Nome da startup relacionada |
| `status` | string | `active` | Status: `active` \| `inactive` \| `sold` |

---

## Coleção: `startups`

Startups cadastradas e disponíveis para investimento.

**Caminho:** `/startups/{startupId}`

| Campo | Tipo | Exemplo | Descrição |
|-------|------|---------|-----------|
| `name` | string | `Mobility Z` | Nome da startup |
| `stage` | string | `Em expansão` | Estágio atual: `Nova` \| `Em operação` \| `Em expansão` |
| `val` | string | `R$ 98,00` | Valor de avaliação do token |
| `description` | string | `Plataforma de mobilidade urbana...` | Sumário executivo da startup |
| `sector` | string | `Mobilidade` | Setor de atuação (ex: Cleantech, Healthtech, Fintech) |
| `capitalAportado` | number | `1500000` | Capital total já aportado, em reais |
| `tokensEmitidos` | number | `120000` | Quantidade total de tokens emitidos |
| `socios` | array<map> | ver abaixo | Estrutura societária da startup |
| `mentoresConselho` | array<string> | `['Mariana Prado']` | Mentores ou membros do conselho consultivo |
| `videoUrl` | string \| null | `https://...` | URL do vídeo demonstrativo (pode ser `null`) |
| `status` | string | `ativa` | Status da startup: `ativa` \| `pausada` \| `encerrada` |
| `faq` | array<map> | ver abaixo | Perguntas e respostas (públicas e privadas) |

### Subestrutura: `socios[]`

Cada elemento do array `socios` é um mapa com:

| Campo | Tipo | Exemplo | Descrição |
|-------|------|---------|-----------|
| `nome` | string | `Ana Souza` | Nome completo do sócio |
| `percentual` | number | `45` | Percentual de participação societária (0–100) |

### Subestrutura: `faq[]`

Cada elemento do array `faq` é um mapa com:

| Campo | Tipo | Exemplo | Descrição |
|-------|------|---------|-----------|
| `pergunta` | string | `Como funciona o token?` | Pergunta do FAQ |
| `resposta` | string | `O token representa...` | Resposta correspondente |
| `publico` | boolean | `true` | Se `true`, é exibida na tela pública da startup |

---

## Coleção: `users`

Usuários cadastrados na plataforma.

**Caminho:** `/users/{userId}`

| Campo | Tipo | Exemplo | Descrição |
|-------|------|---------|-----------|
| `cpf` | string | `1234567890` | CPF sem formatação |
| `createdAt` | timestamp | `7 mai 2026, 08:29:55` | Data do cadastro |
| `email` | string | `teste@gmail.com` | E-mail do usuário |
| `nome` | string | `Valim` | Nome completo |
| `telefone` | string | `19999999999` | Telefone com DDD |

### Subcoleção: `wallet`

**Caminho:** `/users/{userId}/wallet/main`

| Campo | Tipo | Exemplo | Descrição |
|-------|------|---------|-----------|
| `appreciation` | string | `+ 0,0%` | Percentual de valorização |
| `balance` | string | `R$ 0,00` | Saldo disponível na carteira |