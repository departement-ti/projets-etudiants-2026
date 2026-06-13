import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class CognitiveChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  final String title;
  final Color lineColor;

  const CognitiveChart({
    super.key,
    required this.data,
    required this.title,
    this.lineColor = const Color.fromRGBO(7, 82, 96, 1),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color.fromRGBO(7, 82, 96, 1),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  labelStyle: GoogleFonts.roboto(fontSize: 11, color: Colors.grey),
                ),
                primaryYAxis: NumericAxis(
                  minimum: 0, maximum: 100,
                  labelFormat: '{value}%',
                  labelStyle: GoogleFonts.roboto(fontSize: 11, color: Colors.grey),
                  majorGridLines: MajorGridLines(
                    color: Colors.grey.withAlpha(40),
                    width: 1,
                  ),
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries>[
                  SplineSeries<ChartDataPoint, String>(
                    dataSource: data,
                    xValueMapper: (d, _) => d.label,
                    yValueMapper: (d, _) => d.value,
                    color: lineColor,
                    width: 3,
                    markerSettings: const MarkerSettings(isVisible: true),
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      textStyle: GoogleFonts.roboto(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartDataPoint {
  final String label;
  final double value;
  ChartDataPoint(this.label, this.value);
}
