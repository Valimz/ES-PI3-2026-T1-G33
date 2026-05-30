import 'package:flutter/material.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';

class SumarioExecutivoCard extends StatefulWidget {
  final String? description;
  final String? sector;
  final int collapsedMaxLines;

  const SumarioExecutivoCard({
    super.key,
    required this.description,
    this.sector,
    this.collapsedMaxLines = 4,
  });

  @override
  State<SumarioExecutivoCard> createState() => _SumarioExecutivoCardState();
}

class _SumarioExecutivoCardState extends State<SumarioExecutivoCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final description = widget.description?.trim() ?? '';
    final sector = widget.sector?.trim() ?? '';
    final isEmpty = description.isEmpty;

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
              Icon(Icons.description_outlined,
                  size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Sobre a startup',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (sector.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.category_outlined,
                    size: 16, color: AppColors.teal),
                const SizedBox(width: 6),
                Text(
                  sector,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.teal,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: Text(
              isEmpty ? 'Informações em breve.' : description,
              maxLines: _expanded || isEmpty ? null : widget.collapsedMaxLines,
              overflow: _expanded || isEmpty
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textBody,
                fontStyle:
                    isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          if (!isEmpty && _needsExpansion(description))
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? 'ver menos' : 'ver mais'),
              ),
            ),
        ],
      ),
    );
  }

  bool _needsExpansion(String description) {
    return description.length > 180 ||
        '\n'.allMatches(description).length >= widget.collapsedMaxLines;
  }
}
