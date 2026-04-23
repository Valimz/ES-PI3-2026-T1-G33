// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

import 'package:flutter/material.dart';
import 'package:mescla_invest/features/portfolio/data/portfolio_mock_data.dart';
import 'package:mescla_invest/features/portfolio/models/investimento_model.dart';
import 'package:mescla_invest/features/portfolio/presentation/widgets/ativo_card_widget.dart';
import 'package:mescla_invest/features/portfolio/presentation/widgets/filtro_ativos_widget.dart';
import 'package:mescla_invest/features/portfolio/presentation/widgets/resumo_portfolio_header.dart';

// Tela principal da carteira com resumo consolidado e lista de ativos.
class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  FiltroAtivo _filtroSelecionado = FiltroAtivo.todos;

  @override
  Widget build(BuildContext context) {
    // Recalcula os indicadores a partir do filtro ativo para manter o resumo coerente.
    final ativosFiltrados = _filtrarAtivos(mockPortfolio, _filtroSelecionado);
    final valorTotal = _valorTotalCarteira(ativosFiltrados);
    final variacaoReais = _variacaoTotalEmReais(ativosFiltrados);
    final variacaoPercentual = _variacaoTotalPercentual(
      valorTotal,
      variacaoReais,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Portfólio'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResumoPortfolioHeader(
                valorTotal: valorTotal,
                variacaoEmReais: variacaoReais,
                variacaoPercentual: variacaoPercentual,
              ),
              const SizedBox(height: 16),
              Text(
                'Filtrar ativos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              FiltroAtivosWidget(
                selecionado: _filtroSelecionado,
                onSelecionar: (filtro) {
                  setState(() => _filtroSelecionado = filtro);
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ativosFiltrados.isEmpty
                    ? const Center(
                        child: Text('Nenhum ativo para o filtro selecionado.'),
                      )
                    : ListView.separated(
                        itemCount: ativosFiltrados.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final ativo = ativosFiltrados[index];
                          return AtivoCardWidget(ativo: ativo);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<InvestimentoModel> _filtrarAtivos(
    List<InvestimentoModel> ativos,
    FiltroAtivo filtro,
  ) {
    // Usa uma heurística simples no ticker para separar ações de cripto.
    switch (filtro) {
      case FiltroAtivo.todos:
        return ativos;
      case FiltroAtivo.acoes:
        return ativos.where((ativo) => _isAcao(ativo.ticker)).toList();
      case FiltroAtivo.cripto:
        return ativos.where((ativo) => _isCripto(ativo.ticker)).toList();
    }
  }

  bool _isCripto(String ticker) {
    return !RegExp(r'\d').hasMatch(ticker) && ticker.length <= 4;
  }

  bool _isAcao(String ticker) {
    return RegExp(r'\d').hasMatch(ticker);
  }

  double _valorTotalCarteira(List<InvestimentoModel> ativos) {
    return ativos.fold(
      0,
      (acumulado, ativo) =>
          acumulado + (ativo.posicao.quantidade * ativo.posicao.valorAtual),
    );
  }

  double _variacaoTotalEmReais(List<InvestimentoModel> ativos) {
    return ativos.fold(
      0,
      (acumulado, ativo) => acumulado + ativo.variacao.variacaoEmReais,
    );
  }

  double _variacaoTotalPercentual(double valorTotal, double variacaoReais) {
    // Evita divisão por zero quando ainda não há base de cálculo.
    final base = valorTotal - variacaoReais;
    if (base == 0) {
      return 0;
    }
    return (variacaoReais / base) * 100;
  }
}
