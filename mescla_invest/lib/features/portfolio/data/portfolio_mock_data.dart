// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

import 'package:mescla_invest/features/portfolio/models/investimento_model.dart';
import 'package:mescla_invest/features/portfolio/models/posicao_model.dart';
import 'package:mescla_invest/features/portfolio/models/variacao_model.dart';

/// Base de exemplo com startups reais do Mescla extraído da planilha de cadastro.
/// Cada investimento contém dados completos da startup e posição do usuário.
final List<InvestimentoModel> mockPortfolio = [
  InvestimentoModel(
    id: '1',
    nome: 'EcoTech',
    descricao: 'Plataforma de monitoramento ambiental para empresas',
    estagio: EstagioStartup.emOperacao,
    setor: 'Cleantech',
    capitalAportado: 300000.0,
    tokensEmitidos: 100000,
    socios: ['Ana Souza', 'Carlos Lima'],
    participacaoSocietaria: [60.0, 40.0],
    mentoresConselho: ['Mariana Prado'],
    videoDemo: 'https://exemplo.com/demo1',
    status: StatusStartup.ativa,
    sumarioExecutivo: 'EcoTech monitora emissões e consumo de recursos naturais em tempo real, ajudando empresas a cumprirem metas ESG com dashboards automatizados e relatórios regulatórios.',
    perguntasRespostas: [
      {'pergunta': 'Quais setores são atendidos?', 'resposta': 'Indústria, mineração e logística são os principais segmentos atendidos atualmente.'},
      {'pergunta': 'Como é feita a coleta de dados?', 'resposta': 'Via sensores IoT instalados nas instalações e integração com ERPs já existentes.'},
    ],
    posicao: PosicaoModel(
      quantidade: 5000.0,
      precoMedio: 3.00,
      valorAtual: 3.50,
    ),
    variacao: VariacaoModel(variacaoPercentual: 16.67, variacaoEmReais: 2500.0),
  ),
  InvestimentoModel(
    id: '2',
    nome: 'FinFlow',
    descricao: 'Gestão de fluxo de caixa para MEIs',
    estagio: EstagioStartup.emExpansao,
    setor: 'Fintech',
    capitalAportado: 500000.0,
    tokensEmitidos: 250000,
    socios: ['Roberto Dias', 'Julia Mota'],
    participacaoSocietaria: [50.0, 50.0],
    mentoresConselho: ['Ricardo Santos'],
    videoDemo: 'https://exemplo.com/demo2',
    status: StatusStartup.ativa,
    sumarioExecutivo: 'FinFlow automatiza conciliação bancária, projeções de caixa e emissão de DRE para MEIs, reduzindo em 70% o tempo gasto com gestão financeira manual.',
    perguntasRespostas: [
      {'pergunta': 'É necessário conhecimento contábil?', 'resposta': 'Não. A plataforma foi desenhada para empreendedores sem formação financeira, com linguagem simples e visual.'},
      {'pergunta': 'Integra com bancos?', 'resposta': 'Sim, via Open Finance integramos com mais de 15 instituições financeiras automaticamente.'},
    ],
    posicao: PosicaoModel(
      quantidade: 8000.0,
      precoMedio: 2.00,
      valorAtual: 1.80,
    ),
    variacao: VariacaoModel(
      variacaoPercentual: -10.0,
      variacaoEmReais: -1600.0,
    ),
  ),
  InvestimentoModel(
    id: '3',
    nome: 'AgroSmart',
    descricao: 'IOT para otimização de irrigação',
    estagio: EstagioStartup.nova,
    setor: 'AgTech',
    capitalAportado: 150000.0,
    tokensEmitidos: 75000,
    socios: ['Marcos Vinicius'],
    participacaoSocietaria: [100.0],
    mentoresConselho: ['Arnaldo Souza'],
    videoDemo: 'https://exemplo.com/demo3',
    status: StatusStartup.ativa,
    sumarioExecutivo: 'AgroSmart instala sensores de umidade e temperatura no solo que, integrados à previsão climática, automatizam válvulas de irrigação e reduzem o consumo de água em até 35%.',
    perguntasRespostas: [
      {'pergunta': 'Funciona sem internet no campo?', 'resposta': 'Sim, os sensores operam offline e sincronizam os dados quando há sinal disponível.'},
      {'pergunta': 'Qual o prazo de retorno do investimento para o produtor?', 'resposta': 'Em média 18 meses, considerando a redução na conta de energia e no desperdício de água.'},
    ],
    posicao: PosicaoModel(
      quantidade: 3500.0,
      precoMedio: 2.00,
      valorAtual: 2.40,
    ),
    variacao: VariacaoModel(variacaoPercentual: 20.0, variacaoEmReais: 1400.0),
  ),
  InvestimentoModel(
    id: '4',
    nome: 'HealthVibe',
    descricao: 'Telemedicina com IA para triagem',
    estagio: EstagioStartup.emOperacao,
    setor: 'HealthTech',
    capitalAportado: 800000.0,
    tokensEmitidos: 400000,
    socios: ['Beatriz Luz', 'Hugo Vaz'],
    participacaoSocietaria: [70.0, 30.0],
    mentoresConselho: ['Sandra Meireles'],
    videoDemo: 'https://exemplo.com/demo4',
    status: StatusStartup.ativa,
    sumarioExecutivo: 'HealthVibe oferece triagem médica por IA antes da consulta, reduzindo em 40% o tempo de espera e direcionando o paciente ao especialista correto já na primeira consulta.',
    perguntasRespostas: [
      {'pergunta': 'A triagem por IA é segura?', 'resposta': 'Sim, o modelo foi treinado com mais de 2 milhões de casos clínicos e validado por um comitê médico independente.'},
      {'pergunta': 'Atende planos de saúde?', 'resposta': 'Temos convênio com 8 operadoras de planos de saúde e também atendimento particular.'},
    ],
    posicao: PosicaoModel(
      quantidade: 2000.0,
      precoMedio: 2.50,
      valorAtual: 2.75,
    ),
    variacao: VariacaoModel(variacaoPercentual: 10.0, variacaoEmReais: 500.0),
  ),
  InvestimentoModel(
    id: '5',
    nome: 'EduNext',
    descricao: 'Plataforma de cursos gamificados',
    estagio: EstagioStartup.nova,
    setor: 'EduTech',
    capitalAportado: 450000.0,
    tokensEmitidos: 200000,
    socios: ['Tiago André'],
    participacaoSocietaria: [100.0],
    mentoresConselho: ['Fernando Silva'],
    videoDemo: 'https://exemplo.com/demo5',
    status: StatusStartup.ativa,
    sumarioExecutivo: 'EduNext transforma conteúdo técnico em missões, conquistas e rankings, aumentando a taxa de conclusão de cursos online de 15% para 68% nos pilotos realizados.',
    perguntasRespostas: [
      {'pergunta': 'Quais áreas de conhecimento são cobertas?', 'resposta': 'Programação, design, marketing digital e empreendedorismo são as trilhas principais no lançamento.'},
      {'pergunta': 'Há certificado reconhecido pelo MEC?', 'resposta': 'Estamos em processo de credenciamento junto ao MEC. Atualmente emitimos certificados com validade no mercado de trabalho parceiro.'},
    ],
    posicao: PosicaoModel(
      quantidade: 2500.0,
      precoMedio: 2.25,
      valorAtual: 2.50,
    ),
    variacao: VariacaoModel(variacaoPercentual: 11.11, variacaoEmReais: 625.0),
  ),
];
