import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/skeleton_loader.dart';

class PujaDetailSkeleton extends StatelessWidget {
  const PujaDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.pujaRed,
            flexibleSpace: FlexibleSpaceBar(
              background: const SkeletonLoader(
                width: double.infinity,
                height: 350,
                borderRadius: 0,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLoader(width: 250, height: 32),
                  const SizedBox(height: 12),
                  const SkeletonLoader(width: 150, height: 16),
                  const SizedBox(height: 24),
                  Row(
                    children: const [
                      SkeletonLoader(width: 100, height: 40, borderRadius: 20),
                      SizedBox(width: 12),
                      SkeletonLoader(width: 100, height: 40, borderRadius: 20),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const SkeletonLoader(
                    width: double.infinity,
                    height: 80,
                    borderRadius: 16,
                  ),
                  const SizedBox(height: 32),
                  const SkeletonLoader(width: 120, height: 14),
                  const SizedBox(height: 16),
                  const SkeletonLoader(width: double.infinity, height: 20),
                  const SizedBox(height: 12),
                  const SkeletonLoader(width: double.infinity, height: 20),
                  const SizedBox(height: 12),
                  const SkeletonLoader(width: 200, height: 20),
                  const SizedBox(height: 32),
                  const SkeletonLoader(width: 120, height: 14),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      SkeletonLoader(width: 120, height: 50, borderRadius: 25),
                      SizedBox(width: 12),
                      SkeletonLoader(width: 120, height: 50, borderRadius: 25),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Theme.of(context).cardColor,
        child: SafeArea(
          child: Row(
            children: const [
              Expanded(child: SkeletonLoader(width: double.infinity, height: 56, borderRadius: 12)),
              SizedBox(width: 12),
              Expanded(child: SkeletonLoader(width: double.infinity, height: 56, borderRadius: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
