import 'package:flutter/material.dart';
import 'main.dart'; // Para acessar AppColors

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _allStartups = [];
  List<Map<String, String>> _filteredStartups = [];

  @override
  void initState() {
    super.initState();
    // Dados simulados de startups
    _allStartups = [
      {"name": "EcoToken", "stage": "Em operação", "val": "RS 12,00"},
      {"name": "HealthTech", "stage": "Em expansão", "val": "RS 45,50"},
      {"name": "AgroData", "stage": "Nova", "val": "RS 5,00"},
      {"name": "FinSol", "stage": "Em operação", "val": "RS 28,75"},
      {"name": "Educa+", "stage": "Nova", "val": "RS 7,50"},
      {"name": "Mobility Z", "stage": "Em expansão", "val": "RS 98,00"},
    ];
    _filteredStartups = _allStartups;
    _searchController.addListener(_filterStartups);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStartups() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStartups = _allStartups.where((startup) {
        return startup['name']!.toLowerCase().contains(query);
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
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredStartups.length,
        itemBuilder: (context, index) {
          final startup = _filteredStartups[index];
          return _buildStartupCard(startup);
        },
      ),
    );
  }

  Widget _buildStartupCard(Map<String, String> startup) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.background,
              child: Icon(Icons.business_center, color: AppColors.primary, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(startup['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(startup['stage']!, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            Text(startup['val']!, style: const TextStyle(fontSize: 16, color: AppColors.accent, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
