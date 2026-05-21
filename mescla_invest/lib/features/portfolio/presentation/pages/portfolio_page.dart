import 'package:flutter/material.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';
import 'package:mescla_invest/features/portfolio/models/investimento_model.dart';
import 'package:mescla_invest/features/portfolio/presentation/widgets/ativo_card_widget.dart';
import 'package:mescla_invest/features/portfolio/presentation/widgets/filtro_ativos_widget.dart';
import 'package:mescla_invest/features/portfolio/presentation/widgets/resumo_portfolio_header.dart';
import 'package:mescla_invest/services/firestore_service.dart';

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
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Meus Investimentos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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

                return ListView(
                  children: [
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ResumoPortfolioHeader(
                        valorTotal: valorTotal,
                        variacaoEmReais: variacaoReais,
                        variacaoPercentual: variacaoPercentual,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Filtrar por estágio'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: FiltroAtivosWidget(
                        selecionado: _filtroSelecionado,
                        onSelecionar: (filtro) =>
                            setState(() => _filtroSelecionado = filtro),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Seus Ativos'),
                    const SizedBox(height: 4),
                    if (filtrados.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'Nenhum investimento para o filtro selecionado.',
                            style: TextStyle(
                              color: AppColors.textBody,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else
                      ...filtrados.map((inv) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 6),
                            child: AtivoCardWidget(
                              ativo: inv,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/analise',
                                arguments: inv,
                              ),
                            ),
                          )),
                    const SizedBox(height: 32),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
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
