import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';
import 'package:mescla_invest/features/portfolio/presentation/widgets/filtro_ativos_widget.dart';
import 'package:mescla_invest/services/firestore_service.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _allStartups = [];
  List<Map<String, String>> _filteredStartups = [];
  FiltroStartup _filtroSelecionado = FiltroStartup.todos;
  late final StreamSubscription<List<Map<String, dynamic>>> _startupsSubscription;

  @override
  void initState() {
    super.initState();
    _startupsSubscription = FirestoreService().getStartups().listen((startups) {
      if (!mounted) return;
      setState(() {
        _allStartups = startups
            .map((e) => e.map((k, v) => MapEntry(k, v.toString())))
            .toList();
        _filterStartups();
      });
    });
    _searchController.addListener(_filterStartups);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _startupsSubscription.cancel();
    super.dispose();
  }

  void _filterStartups() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStartups = _allStartups.where((startup) {
        final nomeOk = (startup['name'] ?? '').toLowerCase().contains(query);

        final stage = (startup['stage'] ?? '').toLowerCase();
        final filtroOk = switch (_filtroSelecionado) {
          FiltroStartup.todos => true,
          FiltroStartup.nova => stage.contains('nova') || stage.contains('semente'),
          FiltroStartup.emOperacao => stage.contains('opera'),
          FiltroStartup.emExpansao => stage.contains('expans'),
        };

        return nomeOk && filtroOk;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Pesquisar startups...',
            prefixIcon: const Icon(Icons.search, color: AppColors.textBody),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: FiltroAtivosWidget(
              selecionado: _filtroSelecionado,
              onSelecionar: (filtro) {
                setState(() => _filtroSelecionado = filtro);
                _filterStartups();
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredStartups.length,
              itemBuilder: (context, index) {
                return _buildStartupCard(_filteredStartups[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartupCard(Map<String, String> startup) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: Navegar para StartupDetailPage
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.background,
                child: Icon(Icons.business_center,
                    color: AppColors.primary, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(startup['name'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text(startup['stage'] ?? '',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
              Text(startup['val'] ?? '',
                  style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
