# Trabalho de Prototipação UX/UI
**Disciplina:** UX/UI para Engenharia de Software
**Projeto:** MesclaInvest

---

## 1. Identificação da equipe
**Equipe:** Grupo 33 (ES-PI3-2026-T1-G33)

---

## 2. Breve descritivo do projeto
O **MesclaInvest** é uma plataforma mobile de investimentos que visa democratizar o acesso ao mercado de startups. O problema principal que buscamos resolver é a alta complexidade e a barreira de entrada (financeira e de conhecimento) que investidores comuns enfrentam ao tentar investir em empresas nascentes. A solução proposta é um aplicativo onde startups promissoras são listadas e os usuários podem adquirir participações através da compra de tokens de forma simples e intuitiva. O contexto de uso é focado em dispositivos móveis (smartphones), permitindo que o usuário acompanhe seus ativos e descubra novas oportunidades de qualquer lugar.

---

## 3. Público-alvo e perfil do usuário
**Público-alvo:** Jovens e adultos (aproximadamente 20 a 35 anos), profissionais e estudantes, que já possuem algum hábito de poupar ou investir (mesmo que em renda fixa) e desejam diversificar sua carteira assumindo riscos controlados no ecossistema de inovação.

**Características e Necessidades:**
- **Familiaridade com tecnologia:** São nativos digitais, habituados a bancos digitais (como Nubank, Inter) e corretoras modernas.
- **Dificuldades:** Sentem-se intimidados por gráficos complexos (candlesticks), excesso de jargão financeiro (valuation, term sheets) e burocracia.
- **Expectativas:** Buscam uma interface limpa, transparente em relação a taxas/riscos e processos de compra que sejam concluídos em poucos cliques. Querem sentir segurança no ambiente do aplicativo.

---

## 4. Principais funcionalidades
As funcionalidades essenciais foram organizadas da seguinte forma (foco principal no investidor):

1. **Catálogo de Startups (Explore/Home):** Listagem de startups em destaque e categorizadas, com resumos objetivos (Pitch, Setor, Valor do Token).
2. **Fluxo de Investimento (Compra de Tokens):** Modal simplificado para aquisição de participação na startup escolhida, convertendo moeda fiduciária para tokens da empresa.
3. **Carteira (Wallet):** Dashboard interativo exibindo o saldo atual, o histórico de transações e a lista de ativos (startups investidas) na carteira do usuário.
4. **Sistema de Notificações:** Alertas em tempo real sobre atualizações no status do investimento e confirmações de transações concluídas.

---

## 5. Mapa mental / organização das ideias
O mapa mental elaborado pela equipe, contendo a estrutura de navegação e a hierarquia da informação da plataforma, encontra-se disponível no arquivo anexo **"MesclaInvest (PI3)_MapaMental.pdf"**. 

*Local:* Repositório principal do GitHub da Equipe 33 (Grupo 33), diretamente na raiz do projeto.

---

## 6. Wireframes de baixa fidelidade
Durante a fase inicial, desenvolvemos wireframes com os seguintes objetivos:
- **Tela Home:** Estruturar a exibição dos "Cards" das startups para focar nas imagens e no segmento da empresa.
- **Tela de Detalhes da Startup:** Definir a hierarquia (Descrição da empresa -> Valor do Token -> Botão de Ação "Investir").
- **Modal de Checkout:** Testar campos de entrada para o investimento (R$ vs Qtd. de Tokens), priorizando a clareza e visibilidade dos botões.
- **Tela de Carteira:** Esboçar a disposição do saldo total no topo e a lista de ativos em rolagens verticais logo abaixo, utilizando o padrão mental que os usuários já possuem de apps bancários.

---

## 7. Identidade visual da solução
A identidade visual do MesclaInvest foi projetada para transmitir **inovação, segurança e dinamismo**:
- **Cores:** Utilização de tons escuros (Dark Mode nativo) para gerar contraste e reduzir a fadiga visual, transmitindo um aspecto premium e moderno. Detalhes de ação e botões principais utilizam cores vibrantes (como verdes e roxos/azuis neon) para destacar o "caminho feliz" do investimento.
- **Tipografia:** Famílias tipográficas modernas, limpas e sem serifa (como Roboto/Inter), focando na legibilidade de números e dados financeiros.
- **Elementos UI:** Uso intensivo de Cards com bordas arredondadas e leves sombras (ou efeito de "glassmorphism"), separando os agrupamentos de informação de forma amigável sem sobrecarregar a tela.

---

## 8. Protótipo de alta fidelidade
O protótipo de alta fidelidade resultou na implementação interativa do aplicativo desenvolvida no framework **Flutter**. 
- *Acesso:* O código final e a interface implementada podem ser executados e visualizados a partir da pasta `/mescla_invest` do nosso repositório. *(Caso a equipe possua um link do Figma complementar, ele estaria referenciado aqui).*
- **Justificativa das decisões:** A adoção de *Bottom Navigation* (navegação inferior) facilita o uso com apenas uma mão. As animações de transição entre a tela principal e os detalhes da startup mantêm o usuário imerso no fluxo, não o deixando "perdido" no aplicativo. O uso de popups (modais dialogs) para compra evita mudanças bruscas de contexto de tela.

---

## 9. Considerações finais
A prototipação do MesclaInvest trouxe como principal aprendizado o desafio de **balancear densidade de informação financeira com simplicidade de uso**. Percebemos que minimizar o atrito visual e guiar o usuário passo a passo no investimento aumenta a confiança na plataforma. Em futuras evoluções, a interface de detalhamento da startup pode ganhar gráficos interativos (para usuários mais avançados) e uma área de educação financeira nativa, tornando a experiência de UX ainda mais completa.
