import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/encryption/encryption_service.dart';
import '../../core/storage/app_database.dart';

class _CategoryStat {
  final String name;
  int count = 0;
  int weightSum = 0;
  _CategoryStat(this.name);
  double get avgWeight => count == 0 ? 0 : weightSum / count;
}

class _PeriodStat {
  final String label;
  int count = 0;
  int weightSum = 0;
  _PeriodStat(this.label);
  double get avgWeight => count == 0 ? 0 : weightSum / count;
}

class DailyStatsScreen extends StatefulWidget {
  final AppDatabase database;
  final EncryptionService encryptionService;
  const DailyStatsScreen({super.key, required this.database, required this.encryptionService});

  @override
  State<DailyStatsScreen> createState() => _DailyStatsScreenState();
}

class _DailyStatsScreenState extends State<DailyStatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Στατιστικά'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Σύνολο'),
            Tab(text: 'Ανά μήνα'),
            Tab(text: 'Ανά χρόνο'),
          ],
        ),
      ),
      body: StreamBuilder(
        stream: widget.database.select(widget.database.dailyEntries).watch(),
        builder: (context, snapshot) {
          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return const Center(child: Text('Δεν υπάρχουν ακόμα καταχωρήσεις.'));
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _OverallTab(entries: entries),
              _MonthlyTab(entries: entries),
              _YearlyTab(entries: entries),
            ],
          );
        },
      ),
    );
  }
}

// ── Συνολικά stats ────────────────────────────────────────────────────────────

class _OverallTab extends StatelessWidget {
  final List<DailyEntry> entries;
  const _OverallTab({required this.entries});

  @override
  Widget build(BuildContext context) {
    final byCategory = <String, _CategoryStat>{};
    int totalWeight = 0;
    int minWeight = 999, maxWeight = 0;
    final byDayOfWeek = List.filled(7, 0); // 0=Δευ, 6=Κυρ
    final Set<String> uniqueDays = {};
    DailyEntry? latestEntry;

    for (final e in entries) {
      final key = e.tag ?? 'Χωρίς κατηγορία';
      final stat = byCategory.putIfAbsent(key, () => _CategoryStat(key));
      stat.count++;
      stat.weightSum += e.weight;
      totalWeight += e.weight;
      if (e.weight < minWeight) minWeight = e.weight;
      if (e.weight > maxWeight) maxWeight = e.weight;
      byDayOfWeek[(e.timestamp.weekday - 1) % 7]++;
      uniqueDays.add('${e.timestamp.year}-${e.timestamp.month}-${e.timestamp.day}');
      if (latestEntry == null || e.timestamp.isAfter(latestEntry.timestamp)) {
        latestEntry = e;
      }
    }

    final stats = byCategory.values.toList()..sort((a, b) => b.count.compareTo(a.count));
    final avgWeight = entries.isEmpty ? 0.0 : totalWeight / entries.length;
    final busyDow = byDayOfWeek.indexOf(byDayOfWeek.reduce((a, b) => a > b ? a : b));
    const dowLabels = ['Δευ', 'Τρι', 'Τετ', 'Πεμ', 'Παρ', 'Σαβ', 'Κυρ'];
    final maxDow = byDayOfWeek.reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stat cards
        Row(children: [
          Expanded(child: _statCard(context, 'Σύνολο', entries.length.toString())),
          const SizedBox(width: 12),
          Expanded(child: _statCard(context, 'Ημέρες', uniqueDays.length.toString())),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _statCard(context, 'Μέση βαρύτητα', avgWeight.toStringAsFixed(1))),
          const SizedBox(width: 12),
          Expanded(child: _statCard(context, 'Πυκνότητα', '${(entries.length / (uniqueDays.isEmpty ? 1 : uniqueDays.length)).toStringAsFixed(1)}/ημ')),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _statCard(context, 'Ελάχ. βαρύτητα', minWeight.toString())),
          const SizedBox(width: 12),
          Expanded(child: _statCard(context, 'Μέγ. βαρύτητα', maxWeight.toString())),
        ]),
        const SizedBox(height: 24),

        // Ημέρα εβδομάδας bar chart
        Text('Καταχωρήσεις ανά ημέρα εβδομάδας', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: BarChart(BarChartData(
            maxY: (maxDow + 1).toDouble(),
            barGroups: List.generate(7, (i) => BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: byDayOfWeek[i].toDouble(),
                color: i == busyDow
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primaryContainer,
                width: 22,
                borderRadius: BorderRadius.circular(4),
              ),
            ])),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                  getTitlesWidget: (v, m) => Text(dowLabels[v.toInt()], style: const TextStyle(fontSize: 11)))),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
          )),
        ),
        const SizedBox(height: 24),

        // Ανά κατηγορία
        Text('Ανά κατηγορία', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (stats.isNotEmpty) SizedBox(
          height: 200,
          child: BarChart(BarChartData(
            maxY: (stats.first.count + 1).toDouble(),
            barGroups: List.generate(stats.length, (i) => BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: stats[i].count.toDouble(),
                color: Theme.of(context).colorScheme.secondary,
                width: 18,
                borderRadius: BorderRadius.circular(4),
              ),
            ])),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                  getTitlesWidget: (v, m) {
                    final i = v.toInt();
                    if (i < 0 || i >= stats.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(stats[i].name, style: const TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis),
                    );
                  })),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
          )),
        ),
        const SizedBox(height: 8),
        for (final s in stats)
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: Text(s.name),
            subtitle: Text('Μέση βαρύτητα ${s.avgWeight.toStringAsFixed(1)}'),
            trailing: Text('${s.count} (${((s.count / entries.length) * 100).toStringAsFixed(0)}%)'),
          ),
      ],
    );
  }
}

// ── Ανά μήνα ─────────────────────────────────────────────────────────────────

class _MonthlyTab extends StatelessWidget {
  final List<DailyEntry> entries;
  const _MonthlyTab({required this.entries});

  @override
  Widget build(BuildContext context) {
    // Ομαδοποίηση ανά YYYY-MM
    final byMonth = <String, _PeriodStat>{};
    for (final e in entries) {
      final key = '${e.timestamp.year}-${e.timestamp.month.toString().padLeft(2, '0')}';
      final stat = byMonth.putIfAbsent(key, () => _PeriodStat(key));
      stat.count++;
      stat.weightSum += e.weight;
    }
    final months = byMonth.values.toList()..sort((a, b) => a.label.compareTo(b.label));
    final maxCount = months.isEmpty ? 1 : months.map((m) => m.count).reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Καταχωρήσεις ανά μήνα', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: BarChart(BarChartData(
            maxY: (maxCount + 1).toDouble(),
            barGroups: List.generate(months.length, (i) => BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: months[i].count.toDouble(),
                color: Theme.of(context).colorScheme.primary,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ])),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                  getTitlesWidget: (v, m) {
                    final i = v.toInt();
                    if (i < 0 || i >= months.length) return const SizedBox.shrink();
                    final parts = months[i].label.split('-');
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('${parts[1]}/${parts[0].substring(2)}', style: const TextStyle(fontSize: 9)),
                    );
                  })),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
          )),
        ),
        const SizedBox(height: 16),
        for (final m in months.reversed)
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: Text(m.label),
            subtitle: Text('Μέση βαρύτητα ${m.avgWeight.toStringAsFixed(1)}'),
            trailing: Text('${m.count} καταχ.'),
          ),
      ],
    );
  }
}

// ── Ανά χρόνο ─────────────────────────────────────────────────────────────────

class _YearlyTab extends StatelessWidget {
  final List<DailyEntry> entries;
  const _YearlyTab({required this.entries});

  @override
  Widget build(BuildContext context) {
    final byYear = <int, _PeriodStat>{};
    for (final e in entries) {
      final y = e.timestamp.year;
      final stat = byYear.putIfAbsent(y, () => _PeriodStat(y.toString()));
      stat.count++;
      stat.weightSum += e.weight;
    }
    final years = byYear.values.toList()..sort((a, b) => a.label.compareTo(b.label));
    final maxCount = years.isEmpty ? 1 : years.map((y) => y.count).reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Καταχωρήσεις ανά χρόνο', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: BarChart(BarChartData(
            maxY: (maxCount + 1).toDouble(),
            barGroups: List.generate(years.length, (i) => BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: years[i].count.toDouble(),
                color: Theme.of(context).colorScheme.tertiary,
                width: 32,
                borderRadius: BorderRadius.circular(4),
              ),
            ])),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                  getTitlesWidget: (v, m) {
                    final i = v.toInt();
                    if (i < 0 || i >= years.length) return const SizedBox.shrink();
                    return Text(years[i].label, style: const TextStyle(fontSize: 11));
                  })),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
          )),
        ),
        const SizedBox(height: 16),
        for (final y in years.reversed) ...[
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(y.label),
            subtitle: Text('Μέση βαρύτητα ${y.avgWeight.toStringAsFixed(1)}'),
            trailing: Text('${y.count} καταχ.'),
          ),
          // Στήλη βαρύτητας ανά μήνα για το χρόνο αυτό
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _monthBreakdown(context, y.label),
          ),
        ],
      ],
    );
  }

  Widget _monthBreakdown(BuildContext context, String year) {
    final byMonth = List.filled(12, 0);
    for (final e in entries) {
      if (e.timestamp.year.toString() == year) {
        byMonth[e.timestamp.month - 1]++;
      }
    }
    const monthLabels = ['Ι', 'Φ', 'Μ', 'Α', 'Μ', 'Ι', 'Ι', 'Α', 'Σ', 'Ο', 'Ν', 'Δ'];
    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(12, (i) {
          final maxVal = byMonth.reduce((a, b) => a > b ? a : b);
          final height = maxVal == 0 ? 0.0 : (byMonth[i] / maxVal) * 56;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 2),
                Text(monthLabels[i], style: const TextStyle(fontSize: 8)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

Widget _statCard(BuildContext context, String label, String value) => Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
        ]),
      ),
    );
