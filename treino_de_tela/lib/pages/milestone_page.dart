import 'package:flutter/material.dart';

class MilestonePage extends StatelessWidget {
  const MilestonePage({super.key});

  static final List<Map<String, String>> _milestones = [
    {
      'title': 'Lançamento da Plataforma',
      'description': 'A empresa disponibilizou a primeira versão da plataforma para usuários.',
      'date': '12/03/2026',
    },
    {
      'title': 'Primeiros 100 Investidores',
      'description': 'Atingimos a marca de 100 investidores ativos na plataforma.',
      'date': '28/04/2026',
    },
    {
      'title': 'Nova Rota P2P',
      'description': 'Adicionada funcionalidade de negociação peer-to-peer entre usuários.',
      'date': '05/05/2026',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marcos da Empresa'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemCount: _milestones.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final milestone = _milestones[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          milestone['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    milestone['description'] ?? '',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    milestone['date'] ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
