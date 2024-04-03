import 'package:flutter/material.dart';

class ConvertedClassesCard extends StatelessWidget {
  const ConvertedClassesCard({
    super.key,
    required this.title,
    required this.convertedModels,
  });

  final String title;
  final String? convertedModels;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                width: 1,
                color: Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: convertedModels != null
                ? SelectableText(
                    convertedModels!,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
