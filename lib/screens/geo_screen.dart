import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../providers/instagram_provider.dart';
import '../widgets/geo_bar.dart';
import '../widgets/shimmer_loader.dart';

class GeoScreen extends ConsumerStatefulWidget {
  const GeoScreen({super.key});

  @override
  ConsumerState<GeoScreen> createState() => _GeoScreenState();
}

class _GeoScreenState extends ConsumerState<GeoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static const List<Color> _barColors = [
    AppColors.accentGold,
    AppColors.accentGoldBright,
    AppColors.accentAluminum,
    AppColors.accentGold,
    AppColors.accentGoldBright,
    AppColors.accentAluminum,
    AppColors.accentGold,
    AppColors.accentGoldBright,
  ];

  @override
  Widget build(BuildContext context) {
    final geoState = ref.watch(geoDataProvider);
    final countries = ref.watch(geoCountriesProvider);
    final cities = ref.watch(geoCitiesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('التحليل الجغرافي', style: TextStyle(color: AppColors.text)),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentGold,
          labelColor: AppColors.accentGold,
          unselectedLabelColor: AppColors.muted,
          tabs: const [
            Tab(text: 'حسب الدولة'),
            Tab(text: 'حسب المدينة'),
          ],
        ),
      ),
      body: geoState.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: ShimmerCardList(count: 6, cardHeight: 70),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.muted, size: 48),
              const SizedBox(height: 12),
              Text('خطأ في تحميل البيانات: $e',
                  style: const TextStyle(color: AppColors.muted, fontSize: 14)),
            ],
          ),
        ),
        data: (_) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildGeoList(countries),
              _buildGeoList(cities),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGeoList(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public_off, size: 60,
                color: AppColors.muted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'لا تتوفر بيانات جغرافية',
              style: TextStyle(color: AppColors.muted, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'تحتاج حساب بزنس/كريتور مع 100+ متابع',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        return GeoBar(
          country: item['name'] as String,
          percentage: item['percentage'] as double,
          engagementRate: 0,
          bestTime: '',
          color: _barColors[index % _barColors.length],
        ).animate().fadeIn(
              delay: Duration(milliseconds: index * 80),
              duration: 400.ms,
            ).slideX(begin: 0.1);
      },
    );
  }
}
