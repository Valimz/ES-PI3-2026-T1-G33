import 'package:flutter/material.dart';
import 'package:treino_de_tela/features/portfolio/models/investimento_model.dart';
import 'package:treino_de_tela/features/portfolio/presentation/widgets/ativo_card_widget.dart';
import 'package:treino_de_tela/features/portfolio/presentation/widgets/filtro_ativos_widget.dart';
import 'package:treino_de_tela/features/portfolio/presentation/widgets/resumo_portfolio_header.dart';
import 'package:treino_de_tela/services/firestore_service.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  FiltroStartup _filtroSelecionado = FiltroStartup.todos;

  late final Stream<List<Map<String, dynamic>>> _startupsStream;
  late final Stream<List<Map<String, dynamic>>> _assetsStream;

  @override
  void initState() {
    super.initState();
    _startupsStream = FirestoreService().getStartups();
    _assetsStream = FirestoreService().getUserAssets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Meus Investimentos'), centerTitle: true),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _startupsStream,
          builder: (context, startupsSnapshot) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _assetsStream,
              builder: (context, assetsSnapshot) {
                if (startupsSnapshot.connectionState ==
                        ConnectionState.waiting ||
                    assetsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final startups = startupsSnapshot.data ?? [];
                final assets = assetsSnapshot.data ?? [];

                // Join: só mostra startups em que o usuário tem posição (quotas > 0)
                final investimentos = startups
                    .map((startup) {
                      final assetDoc = assets.cast<Map<String, dynamic>?>().firstWhere(
                            (a) => a?['name'] == startup['name'],
                            orElse: () => null,
                          );

                      if (assetDoc == null) return null;

                      final amountStr =
                          assetDoc['amount']?.toString().split(' ').first ??
                              '0';
                      final quantidade = double.tryParse(
                              amountStr.replaceAll(',', '.')) ??
                          0.0;
                      if (quantidade <= 0) return null;

                      return InvestimentoModel.fromFirestore(startup,
                          assetDoc: assetDoc);
                    })
                    .whereType<InvestimentoModel>()
                    .toList();

                final filtrados =
                    _filtrarStartups(investimentos, _filtroSelecionado);
                final valorTotal = _valorTotal(filtrados);
                final variacaoReais = _variacaoReais(filtrados);
                final variacaoPercentual =
                    _variacaoPercentual(valorTotal, variacaoReais);

                return Padding(
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
                      Text('Filtrar por estágio',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      FiltroAtivosWidget(
                        selecionado: _filtroSelecionado,
                        onSelecionar: (filtro) =>
                            setState(() => _filtroSelecionado = filtro),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: filtrados.isEmpty
                            ? const Center(
                                child: Text(
                                    'Nenhum investimento para o filtro selecionado.'))
                            : ListView.separated(
                                itemCount: filtrados.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final inv = filtrados[index];
                                  return AtivoCardWidget(
                                    ativo: inv,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/analise',
                                      arguments: inv,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<InvestimentoModel> _filtrarStartups(
      List<InvestimentoModel> inv, FiltroStartup filtro) {
    switch (filtro) {
      case FiltroStartup.todos:
        return inv;
      case FiltroStartup.nova:
        return inv
            .where((i) => i.estagio == EstagioStartup.nova)
            .toList();
      case FiltroStartup.emOperacao:
        return inv
            .where((i) => i.estagio == EstagioStartup.emOperacao)
            .toList();
      case FiltroStartup.emExpansao:
        return inv
            .where((i) => i.estagio == EstagioStartup.emExpansao)
            .toList();
    }
  }

  double _valorTotal(List<InvestimentoModel> inv) => inv.fold(
      0, (acc, i) => acc + (i.posicao.quantidade * i.posicao.valorAtual));

  double _variacaoReais(List<InvestimentoModel> inv) =>
      inv.fold(0, (acc, i) => acc + i.variacao.variacaoEmReais);

  double _variacaoPercentual(double valorTotal, double variacaoReais) {
    final base = valorTotal - variacaoReais;
    if (base == 0) return 0;
    return (variacaoReais / base) * 100;
  }
}
