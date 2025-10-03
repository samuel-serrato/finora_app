import 'package:finora_app/constants/colors.dart';
import 'package:finora_app/screens/home.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CreditTypePieChart extends StatelessWidget {
  final AppColors colors;
  final HomeData? homeData; // Puede ser nulo mientras carga

  const CreditTypePieChart({
    Key? key,
    required this.colors,
    this.homeData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Usamos valores por defecto si homeData es nulo (como en el código original)
    final double creditosIndividuales = double.tryParse(
      (homeData?.gruposIndGrupos.isNotEmpty ?? false)
          ? homeData!.gruposIndGrupos.first.creditos_individuales ?? '78'
          : '78',
    ) ?? 78.0;

    final double creditosGrupales = double.tryParse(
      (homeData?.gruposIndGrupos.isNotEmpty ?? false)
          ? homeData!.gruposIndGrupos.first.creditos_grupales ?? '45'
          : '45',
    ) ?? 45.0;

    final double total = creditosIndividuales + creditosGrupales;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Distribución de Créditos",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                SizedBox(
                  height: 150,
                  width: 150,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: AppColors.statCardTeal,
                          value: creditosIndividuales,
                          title: '${(creditosIndividuales / total * 100).toStringAsFixed(0)}%',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: AppColors.statCardCreditos,
                          value: creditosGrupales,
                          title: '${(creditosGrupales / total * 100).toStringAsFixed(0)}%',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(
                        color: AppColors.statCardTeal,
                        text: 'Individuales',
                      ),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                        color: AppColors.statCardCreditos,
                        text: 'Grupales',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // El método de ayuda también se mueve aquí
  Widget _buildLegendItem({required Color color, required String text}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 14, color: colors.textSecondary)),
      ],
    );
  }
}