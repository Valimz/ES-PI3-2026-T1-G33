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
│       └── val (string)
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
| `price` | number | `1000` | Preço unitário da cota ofertada |
| `quotas` | number | `26.7` | Quantidade de cotas disponíveis |
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
| `stage` | string | `Em expansão` | Estágio atual da startup |
| `val` | string | `R$ 98,00` | Valor de avaliação da cota |

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