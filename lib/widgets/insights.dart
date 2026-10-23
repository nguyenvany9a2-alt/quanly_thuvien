import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/theme.dart';
import 'common.dart';

class InsightPanel extends StatelessWidget {
  final Map data;
  final bool staff;
  final VoidCallback? onOpen;
  const InsightPanel({
    super.key,
    required this.data,
    required this.staff,
    this.onOpen,
  });
  @override
  Widget build(BuildContext c) {
    final labels = staff
        ? ['Sẵn sàng', 'Đang mượn', 'Khác']
        : ['Đang mượn', 'Đã trả'];
    final values = staff
        ? [
            (data['available'] as num? ?? 0).toDouble(),
            (data['borrowed'] as num? ?? 0).toDouble(),
            math
                .max(
                  0,
                  ((data['copies'] as num? ?? 0) -
                      (data['available'] as num? ?? 0) -
                      (data['borrowed'] as num? ?? 0)),
                )
                .toDouble(),
          ]
        : [
            (data['borrowed'] as num? ?? 0).toDouble(),
            (data['returned'] as num? ?? 0).toDouble(),
          ];
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  staff ? 'Nhịp sống thư viện' : 'Hành trình của bạn',
                  style: Theme.of(c).textTheme.titleLarge,
                ),
              ),
              if (onOpen != null)
                IconButton(
                  tooltip: 'Xem báo cáo',
                  onPressed: onOpen,
                  icon: const Icon(Icons.north_east, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(112, 112),
                      painter: DonutPainter(values),
                    ),
                    Text(
                      '${values.fold<double>(0, (a, b) => a + b).toInt()}',
                      style: Theme.of(c).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: chartColors[i],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                labels[i],
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              '${values[i].toInt()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Quá hạn: ${data['overdue'] ?? 0}',
            style: TextStyle(color: Theme.of(c).colorScheme.error),
          ),
          if (values.every((e) => e == 0))
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Chưa có dữ liệu mượn trả.'),
            ),
        ],
      ),
    );
  }
}

const chartColors = [Color(0xFF689DB4), Color(0xFF234D6A), Color(0xFFB5D4E2)];

class DonutPainter extends CustomPainter {
  final List<double> values;
  DonutPainter(this.values);
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    final rect = Rect.fromLTWH(8, 8, s.width - 16, s.height - 16);
    p.color = const Color(0x33689DB4);
    c.drawOval(rect, p);
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total == 0) return;
    double start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final angle = values[i] / total * math.pi * 2;
      p.color = chartColors[i % 3];
      c.drawArc(rect, start, math.max(0, angle - .04), false, p);
      start += angle;
    }
  }

  @override
  bool shouldRepaint(covariant DonutPainter old) => old.values != values;
}

class MonthlyChart extends StatelessWidget {
  final List months;
  final bool line;
  const MonthlyChart({super.key, required this.months, this.line = false});
  @override
  Widget build(BuildContext c) {
    final sorted = List<Map>.from(months)
      ..sort((a, b) => '${a['month']}'.compareTo('${b['month']}'));
    if (sorted.isEmpty) {
      return const Panel(child: Text('Chưa có lượt giao sách để vẽ biểu đồ.'));
    }
    final max = sorted
        .map((e) => (e['count'] as num).toDouble())
        .reduce(math.max);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            line ? 'Xu hướng lượt mượn' : 'Lượt mượn theo tháng',
            style: Theme.of(c).textTheme.titleLarge,
          ),
          const SizedBox(height: 22),
          if (line)
            SizedBox(
              height: 120,
              width: double.infinity,
              child: CustomPaint(
                painter: TrendPainter(
                  sorted.map((e) => (e['count'] as num).toDouble()).toList(),
                ),
              ),
            )
          else
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final m in sorted)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${m['count']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 24,
                            height: max == 0
                                ? 2
                                : (m['count'] as num) / max * 105 + 2,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF8FC1D7), forest],
                              ),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final m in sorted)
                Expanded(
                  child: Text(
                    '${m['month']}'.substring(2),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
            ],
          ),
          if (line)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                sorted.map((m) => '${m['month']}: ${m['count']}').join('  ·  '),
                style: const TextStyle(fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

class TrendPainter extends CustomPainter {
  final List<double> values;
  TrendPainter(this.values);
  @override
  void paint(Canvas c, Size s) {
    final max = math.max(1.0, values.reduce(math.max));
    final p = Paint()
      ..color = const Color(0x26689DB4)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = i * s.height / 3;
      c.drawLine(Offset(0, y), Offset(s.width, y), p);
    }
    final points = [
      for (var i = 0; i < values.length; i++)
        Offset(
          values.length == 1 ? s.width / 2 : i * s.width / (values.length - 1),
          s.height - 8 - values[i] / max * (s.height - 16),
        ),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    p
      ..color = const Color(0xFF75AFC6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    c.drawPath(path, p);
    p.style = PaintingStyle.fill;
    for (final point in points) {
      c.drawCircle(point, 4, p);
    }
  }

  @override
  bool shouldRepaint(covariant TrendPainter old) => old.values != values;
}

class PersonalReport extends StatelessWidget {
  final Api api;
  const PersonalReport({super.key, required this.api});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Báo cáo cá nhân')),
    body: DataView(
      api: api,
      path: '/me/report',
      builder: (c, d, reload) => ListView(
        padding: const EdgeInsets.all(22),
        children: [
          InsightPanel(data: d, staff: false),
          const SizedBox(height: 18),
          MonthlyChart(months: d['monthly']),
          const SizedBox(height: 18),
          MonthlyChart(months: d['monthly'], line: true),
        ],
      ),
    ),
  );
}
