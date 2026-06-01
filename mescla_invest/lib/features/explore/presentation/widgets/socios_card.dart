import 'package:flutter/material.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';

class SociosCard extends StatelessWidget {
  final List<Map<String, dynamic>> socios;
  final List<String> mentoresConselho;

  const SociosCard({
    super.key,
    required this.socios,
    this.mentoresConselho = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.groups_outlined, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Estrutura societária',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (socios.isEmpty)
            Text(
              'Estrutura societária não informada.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textBody.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...socios.map(_buildSocioTile),
          if (mentoresConselho.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.school_outlined, size: 18, color: AppColors.teal),
                SizedBox(width: 6),
                Text(
                  'Mentores & conselho',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: mentoresConselho.map(_buildMentorChip).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSocioTile(Map<String, dynamic> socio) {
    final nome = socio['nome']?.toString() ?? '—';
    final percentualRaw = socio['percentual'];
    final percentual = percentualRaw is num
        ? percentualRaw.toDouble()
        : double.tryParse(percentualRaw?.toString() ?? '') ?? 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _buildInitialsAvatar(nome),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nome,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${percentual.toStringAsFixed(percentual == percentual.roundToDouble() ? 0 : 1)}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(String nome) {
    final parts = nome.trim().split(RegExp(r'\s+'));
    String initials;
    if (parts.length >= 2 && parts.first.isNotEmpty && parts.last.isNotEmpty) {
      initials = (parts.first[0] + parts.last[0]).toUpperCase();
    } else if (parts.first.length >= 2) {
      initials = parts.first.substring(0, 2).toUpperCase();
    } else {
      initials = parts.first.isEmpty ? '?' : parts.first[0].toUpperCase();
    }

    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildMentorChip(String nome) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline, size: 14, color: AppColors.teal),
          const SizedBox(width: 6),
          Text(
            nome,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
