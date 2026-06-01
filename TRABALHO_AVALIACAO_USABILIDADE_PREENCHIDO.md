# Trabalho de Avaliação de Usabilidade e Avaliação Heurística
**Disciplina:** Projeto de Interação e Experiência do Usuário
**Projeto:** MesclaInvest

---

## 1. Identificação da equipe
**Equipe:** Grupo 33 (ES-PI3-2026-T1-G33)

---

## 2. Breve descritivo do projeto
O **MesclaInvest** é uma aplicação de investimentos focada em conectar investidores a startups promissoras. O sistema permite que os usuários visualizem um catálogo de startups em destaque, analisem detalhes de cada empresa, invistam comprando tokens (participações) e acompanhem o rendimento de suas carteiras através de um dashboard interativo. O objetivo principal é democratizar e facilitar o investimento em startups de maneira intuitiva e segura, utilizando uma interface mobile (desenvolvida em Flutter) e um backend robusto (Node.js/TypeScript).

---

## 3. Recorte da análise
**Fluxo selecionado:** Fluxo de compra de tokens (investimento em uma startup) e acompanhamento no dashboard.

Este fluxo contempla:
1. A tela inicial (Home/Dashboard) com a listagem de startups em destaque.
2. A tela (ou modal popup) de detalhes da startup selecionada.
3. O formulário de confirmação de investimento (compra de tokens).
4. O retorno ao dashboard e à tela de carteira (Wallet) para visualização do saldo atualizado e da transação concluída.

*(Este fluxo foi escolhido por ser o núcleo principal do valor de negócio proposto no Documento de Visão).*

---

## 4. Parte I – Teste de usabilidade

### 4.1 Objetivo do teste
Avaliar a fluidez e a clareza do processo de investimento em uma startup, verificando se os usuários conseguem compreender as informações da empresa, entender o custo do token e concluir a transação sem erros ou frustrações. Também se busca avaliar se o feedback de sucesso (notificação e atualização do saldo na carteira) é percebido de forma imediata e clara.

### 4.2 Perfil dos participantes
Jovens adultos e adultos (20 a 35 anos) com interesse em tecnologia e diversificação de renda, mas que não necessariamente possuem experiência profunda no mercado de capitais ou em plataformas complexas de trade. Esse perfil representa o público-alvo principal do MesclaInvest: investidores iniciantes ou intermediários buscando aplicações dinâmicas.

### 4.3 Tarefas definidas
1. Acessar o aplicativo e localizar uma startup específica no catálogo da tela inicial.
2. Abrir os detalhes da startup e identificar qual é o valor unitário do seu token.
3. Iniciar o processo de investimento clicando no botão "Investir".
4. Preencher o valor do investimento desejado no formulário.
5. Confirmar a transação.
6. Navegar até a aba "Carteira" (Wallet) e verificar se o saldo foi deduzido e se o novo ativo consta na lista.

### 4.4 Roteiro do teste
1. Recepção e explicação do propósito do teste (deixando claro que estamos avaliando o aplicativo e não a capacidade do usuário).
2. Solicitação de consentimento para observação e gravação.
3. **Cenário apresentado:** *"Imagine que você possui saldo na sua conta MesclaInvest e decidiu investir em uma nova startup de saúde/tecnologia listada no aplicativo. Siga os passos que achar necessários para concluir a compra das cotas e, ao final, confira se o ativo já aparece na sua carteira."*
4. Observação silenciosa do usuário realizando as tarefas (sem interferência).
5. Perguntas de apoio pós-tarefa: *"O que você achou das informações de confirmação?", "Ficou claro qual o valor total da operação e quantos tokens você estava adquirindo?"*
6. Agradecimento e encerramento.

### 4.5 Registro das observações
- **Tarefas 1 e 2:** Os usuários encontraram a startup rapidamente. A apresentação em cards e o popup de detalhes foram elogiados por serem diretos.
- **Tarefas 3 e 4:** Durante a entrada de dados, houve hesitação em relação à unidade de medida no input. O usuário ficou na dúvida se deveria digitar a quantidade de tokens desejada ou o valor total em reais (R$). Além disso, em dispositivos com tela menor, o teclado virtual sobrepôs o botão de "Confirmar", forçando o usuário a tentar ocultar o teclado manualmente.
- **Tarefa 5:** Ação concluída tecnicamente sem erros do sistema (backend processou a compra corretamente).
- **Tarefa 6:** A transação foi efetivada, porém, na aba de Carteira, a atualização de dados ocorre sem grande alarde visual. Dois participantes demoraram alguns segundos para perceber que o investimento já constava ali e sugeriram que houvesse uma confirmação mais "comemorativa".

### 4.6 Análise dos resultados
Os resultados indicam que o fluxo é rápido e atende ao propósito, mas apresenta atritos na interação com formulários. O problema mais crítico é a sobreposição de elementos da UI pelo teclado (falta de responsividade no popup), seguido da falta de clareza no campo de input. O feedback visual no fechamento da compra também precisa ser aprimorado para garantir a certeza da ação.

### 4.7 Sugestões de melhoria
1. Incluir uma máscara (placeholder) e um texto auxiliar no campo de texto para indicar claramente se a entrada deve ser "Qtd." ou "R$". Idealmente, exibir a conversão simultânea logo abaixo do campo.
2. Ajustar a propriedade do modal/diálogo no Flutter (`SingleChildScrollView` + `Padding` dinâmico do `viewInsets`) para que o layout suba acompanhando a abertura do teclado.
3. Implementar uma notificação de sucesso em formato de "SnackBar" animado ou tela de sucesso explícita logo após a compra.

---

## 5. Parte II – Avaliação heurística

### 5.1 Heurísticas consideradas
Avaliação conduzida com base nas **10 Heurísticas de Usabilidade de Jakob Nielsen**, com ênfase nas principais diretrizes aplicáveis à interfaces mobile de investimento.

### 5.2 Problemas identificados
- **Problema 1 (Heurística 4 - Prevenção de erros e Heurística 2 - Compatibilidade com o mundo real):** Campo de input no modal de investimento não esclarece a unidade da moeda/ativo, propiciando compras com valores equivocados.
- **Problema 2 (Heurística 3 - Controle e liberdade do usuário):** Botão de "Confirmar Investimento" sendo bloqueado/oculto pelo teclado virtual do smartphone.
- **Problema 3 (Heurística 1 - Visibilidade do status do sistema):** Atualização silenciosa dos dados na Carteira após a compra, sem um feedback animado imediato de que a transação processou.

### 5.3 Justificativa da análise
- **O Problema 1** possui severidade alta no contexto de aplicativos financeiros, pois o erro do usuário resulta em um impacto financeiro direto (investir mais ou menos do que o planejado).
- **O Problema 2** quebra o fluxo de navegação e causa grande frustração, impedindo usuários com telas menores de finalizar o fluxo principal.
- **O Problema 3** afeta a confiança do sistema. Sem um aviso de que a transação finalizou corretamente, o usuário pode tentar refazer a operação por achar que "não deu certo", podendo ocasionar ordens duplicadas de investimento.

### 5.4 Sugestões de melhoria
- Refatorar o campo de digitação de valores para incluir validações em tempo real e formato contábil claro.
- Corrigir a hierarquia e os insets do teclado nos modais (`Dialogs` e `BottomSheets`) no front-end em Flutter.
- O sistema de notificações via WebSocket (já em desenvolvimento no backend) e o serviço interno devem disparar alertas sonoros/visuais para compras finalizadas com sucesso, mantendo o usuário perfeitamente atualizado.

---

## 6. Conclusão final
Tanto o teste empírico (usabilidade) quanto a inspeção teórica (avaliação heurística) convergiram para a identificação de atritos na fase de "checkout" do investimento. A interface geral do **MesclaInvest** atinge o propósito de ser moderna e simplificada, apresentando muito bem as startups no catálogo. Contudo, intervenções técnicas na responsividade frente ao teclado e feedbacks interativos mais claros após transações de sucesso são fundamentais para elevar a confiabilidade e evitar erros do usuário. As melhorias sugeridas são perfeitamente executáveis dentro da stack atual do projeto.
