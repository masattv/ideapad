import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool useShimmer;

  const LoadingIndicator({
    Key? key,
    this.message,
    this.useShimmer = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          color: colorScheme.primary,
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (useShimmer) {
      return Center(
        child: Shimmer.fromColors(
          baseColor: colorScheme.surfaceVariant,
          highlightColor: colorScheme.surface,
          child: content,
        ),
      );
    }

    return Center(child: content);
  }
}

/// アイデアカードのローディング状態を表示するウィジェット
class LoadingIdeaCards extends StatelessWidget {
  final int count;

  const LoadingIdeaCards({Key? key, this.count = 3}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: count,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return _buildShimmerCard(context);
      },
    );
  }

  Widget _buildShimmerCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Shimmer.fromColors(
        baseColor: colorScheme.surfaceVariant,
        highlightColor: colorScheme.surface,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
