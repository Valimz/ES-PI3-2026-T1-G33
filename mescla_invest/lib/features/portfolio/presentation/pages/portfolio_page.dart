// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

import 'package:flutter/material.dart';
import 'package:mescla_invest/features/portfolio/data/portfolio_mock_data.dart';
import 'package:mescla_invest/features/portfolio/models/investimento_model.dart';
import 'package:mescla_invest/features/portfolio/presentation/widgets/ativo_card_widget.dart';
import 'package:mescla_invest/features/portfolio/presentation/widgets/filtro_ativos_widget.dart';
import 'package:mescla_invest/features/portfolio/presentation/widgets/resumo_portfolio_header.dart';

// Tela principal da carteira com resumo consolidado e lista de startups do Mescla.
class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  FiltroStartup _filtroSelecionado = FiltroStartup.todos;

  @override
  Widget build(BuildContext context) {
    // Recalcula os indicadores a partir do filtro ativo para manter o resumo coerente.
    final investimentosFiltrados = _filtrarStartups(mockPortfolio, _filtroSelecionado);
    final valorTotal = _valorTotalCarteira(investimentosFiltrados);
    final variacaoReais = _variacaoTotalEmReais(investimentosFiltrados);
    final variacaoPercentual = _variacaoTotalPercentual(
      valorTotal,
      variacaoReais,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Investimentos'), centerTitle: true),
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
                'Filtrar por estágio',
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
                child: investimentosFiltrados.isEmpty
                    ? const Center(
                        child: Text('Nenhum investimento para o filtro selecionado.'),
                      )
                    : ListView.separated(
                        itemCount: investimentosFiltrados.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final investimento = investimentosFiltrados[index];
                          return AtivoCardWidget(ativo: investimento);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<InvestimentoModel> _filtrarStartups(
    List<InvestimentoModel> investimentos,
    FiltroStartup filtro,
  ) {
    switch (filtro) {
      case FiltroStartup.todos:
        return investimentos;
      case FiltroStartup.nova:
        return investimentos.where((inv) => inv.estagio == EstagioStartup.nova).toList();
      case FiltroStartup.emOperacao:
        return investimentos.where((inv) => inv.estagio == EstagioStartup.emOperacao).toList();
      case FiltroStartup.emExpansao:
        return investimentos.where((inv) => inv.estagio == EstagioStartup.emExpansao).toList();
    }
  }

  double _valorTotalCarteira(List<InvestimentoModel> investimentos) {
    return investimentos.fold(
      0,
      (acumulado, inv) =>
          acumulado + (inv.posicao.quantidade * inv.posicao.valorAtual),
    );
  }

  double _variacaoTotalEmReais(List<InvestimentoModel> investimentos) {
    return investimentos.fold(
      0,
      (acumulado, inv) => acumulado + inv.variacao.variacaoEmReais,
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
