import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

/// Renders the lightweight Markdown subset used by the admin-managed policy
/// content (terms / privacy / refund) into organized, styled sections.
///
/// Supported syntax (kept in sync with the dashboard `Markdown.jsx` renderer):
///   `## Heading`      → section heading
///   `### Sub-heading` → sub heading
///   `- bullet`        → bullet item (consecutive lines grouped)
///   blank line        → paragraph break (consecutive text lines are joined)
class PolicyMarkdown extends StatelessWidget {
  const PolicyMarkdown({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final blocks = _parse(text);
    final children = <Widget>[];

    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      if (i > 0) {
        children.add(
          SizedBox(height: b.type == _BlockType.h2 ? AppSizes.xl : AppSizes.md),
        );
      }
      children.add(b.build());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  static List<_Block> _parse(String source) {
    final lines = source.replaceAll('\r\n', '\n').split('\n');
    final blocks = <_Block>[];
    final paragraph = <String>[];
    final bullets = <String>[];

    void flushParagraph() {
      if (paragraph.isNotEmpty) {
        blocks.add(_Block(_BlockType.p, text: paragraph.join(' ')));
        paragraph.clear();
      }
    }

    void flushBullets() {
      if (bullets.isNotEmpty) {
        blocks.add(_Block(_BlockType.ul, items: List.of(bullets)));
        bullets.clear();
      }
    }

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) {
        flushParagraph();
        flushBullets();
      } else if (line.startsWith('### ')) {
        flushParagraph();
        flushBullets();
        blocks.add(_Block(_BlockType.h3, text: line.substring(4)));
      } else if (line.startsWith('## ')) {
        flushParagraph();
        flushBullets();
        blocks.add(_Block(_BlockType.h2, text: line.substring(3)));
      } else if (line.startsWith('- ')) {
        flushParagraph();
        bullets.add(line.substring(2));
      } else {
        flushBullets();
        paragraph.add(line);
      }
    }
    flushParagraph();
    flushBullets();
    return blocks;
  }
}

enum _BlockType { h2, h3, p, ul }

class _Block {
  _Block(this.type, {this.text = '', this.items = const []});

  final _BlockType type;
  final String text;
  final List<String> items;

  Widget build() {
    switch (type) {
      case _BlockType.h2:
        return Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.secondary,
            height: 1.5,
          ),
        );
      case _BlockType.h3:
        return Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            height: 1.5,
          ),
        );
      case _BlockType.p:
        return Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.mutedForeground,
            height: 1.7,
          ),
        );
      case _BlockType.ul:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '•  ',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        height: 1.7,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.mutedForeground,
                          height: 1.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
    }
  }
}
