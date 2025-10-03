import 'package:finora_app/constants/colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeeklyRevenueChart extends StatelessWidget {
  final AppColors colors;
  final bool isExpanded;

  const WeeklyRevenueChart({
    Key? key,
    required this.colors,
    this.isExpanded = false, // Valor por defecto para móvil
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> ingresosData = [
      const FlSpot(0, 1500),
      const FlSpot(1, 1800),
      const FlSpot(2, 1600),
      const FlSpot(3, 2200),
      const FlSpot(4, 2500),
      const FlSpot(5, 2300),
      const FlSpot(6, 2800),
    ];

    final List<FlSpot> egresosData = [
      const FlSpot(0, 800),
      const FlSpot(1, 900),
      const FlSpot(2, 750),
      const FlSpot(3, 1100),
      const FlSpot(4, 1000),
      const FlSpot(5, 1200),
      const FlSpot(6, 1300),
    ];

    final chartWidget = LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colors.textSecondary.withOpacity(0.1),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: colors.textSecondary.withOpacity(0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(fontSize: 12);
                String text;
                switch (value.toInt()) {
                  case 0: text = 'L'; break;
                  case 1: text = 'M'; break;
                  case 2: text = 'M'; break;
                  case 3: text = 'J'; break;
                  case 4: text = 'V'; break;
                  case 5: text = 'S'; break;
                  case 6: text = 'D'; break;
                  default: return Container();
                }
                return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: style));
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: colors.textSecondary.withOpacity(0.1)),
        ),
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: ingresosData,
            isCurved: true,
            color: AppColors.statCardSuccess,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.statCardSuccess.withOpacity(0.2),
            ),
          ),
          LineChartBarData(
            spots: egresosData,
            isCurved: true,
            color: AppColors.accent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.accent.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );

    return Card(
      surfaceTintColor: colors.backgroundCard,
      color: colors.backgroundCard,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Balance Semanal",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (isExpanded)
              Expanded(child: chartWidget)
            else
              // CAMBIO: Reducimos la altura para la vista móvil
              //SizedBox(height: 160, child: chartWidget),
              SizedBox(height: 270, child: chartWidget),
          ],
        ),
      ),
    );
  }
}