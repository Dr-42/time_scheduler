import 'package:flutter/material.dart';
import 'package:time_scheduler/home_page.dart';
import 'server_io.dart';
import 'data_types.dart';
import 'dart:math';

class AnalyticsPage extends StatefulWidget {
  final String serverIP;

  const AnalyticsPage({
    Key? key,
    required this.serverIP,
  }) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  List<TimeBlock> timeBlocks = [];
  List<BlockType> blockTypes = [];
  bool fetched = false;
  bool startDateSelected = false;
  bool endDateSelected = false;
  Analysis? analysis;

  @override
  Widget build(BuildContext context) {
    if (_startDate != null && _endDate != null) {
      //Check if the start date is before the end date
      if (_startDate!.isAfter(_endDate!)) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Error: Start date is after end date!",
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                    startDateSelected = false;
                    endDateSelected = false;
                  });
                },
                child: const Text('Reset'),
              ),
            ],
          ),
        );
      }
      if (!fetched) {
        var blockTypesFuture = fetchBlockTypes(widget.serverIP);
        blockTypesFuture.then((value) {
          setState(() {
            blockTypes = value;
          });
        });

        var analysisFuture = fetchAnalysis(
          widget.serverIP,
          _startDate!,
          _endDate!,
        );

        analysisFuture.then((value) {
          setState(() {
            analysis = value;
          });
        });
        fetched = true;
      } else {
        if (analysis == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return Center(
          child: Column(children: [
            Text(
              "Analytics for ${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}",
              style: const TextStyle(fontSize: 24),
            ),
            Divider(),
            // Collapsible list of time blocks
            Expanded(
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatChartWidget(
                        floats: analysis!.percentages,
                        blockTypes: blockTypes,
                        height: 250,
                      ),
                      SizedBox(width: 20),
                      PieChartLegend(
                        blockTypes: blockTypes,
                        height: 200,
                      ),
                    ],
                  ),
                  AreaCurveWidget(
                    trends: analysis!.trends,
                    selectedBlockTypeIds: [2, 3, 10],
                    blockTypes: blockTypes,
                  ),
                ],
              ),
            ),
          ]),
        );
      }
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Welcome to the Analytics Page!",
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 20),
          const Text(
            "Select a date range to view analytics for:",
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_startDate != null)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                )
              else
                const Icon(
                  Icons.check_circle,
                  color: Colors.grey,
                ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                  showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2021),
                    lastDate: DateTime.now(),
                  ).then((selectedDate) {
                    if (selectedDate != null) {
                      setState(() {
                        _startDate = selectedDate;
                        startDateSelected = true;
                      });
                    }
                  });
                },
                child: const Text('Select Start Date'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_endDate != null)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                )
              else
                const Icon(
                  Icons.check_circle,
                  color: Colors.grey,
                ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                  showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2021),
                    lastDate: DateTime.now(),
                  ).then((selectedDate) {
                    if (selectedDate != null) {
                      setState(() {
                        _endDate = selectedDate;
                        endDateSelected = true;
                      });
                    }
                  });
                },
                child: const Text('Select End Date'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FloatChartWidget extends StatelessWidget {
  final List<double> floats;
  final List<BlockType> blockTypes;
  final double height;

  FloatChartWidget({
    required this.floats,
    required this.blockTypes,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200, // Adjust the width of the chart
      height: height,
      child: CustomPaint(
        painter: ChartPainter(floats: floats, blockTypes: blockTypes),
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<double> floats;
  final List<BlockType> blockTypes;

  ChartPainter({required this.floats, required this.blockTypes});

  @override
  void paint(Canvas canvas, Size size) {
    final double barWidth = size.width / floats.length;
    final double chartHeight = size.height * 0.8;
    final double chartBottom = size.height * 0.9;
    double lineSpacing = chartHeight / 10;
    final double maxFloat = floats.reduce(max);

    // Draw background lines at every 10% interval
    //Determine the max floats in the floats array
    var maximum = 0.0;
    for (int i = 0; i < floats.length; i++) {
      if (floats[i] > maximum) {
        maximum = floats[i];
      }
    }

    lineSpacing = chartHeight / (maximum / 10);
    //Round the max float up to the nearest 10
    maximum = (maximum / 10).ceil() * 10;

    for (int i = 0; i <= maximum / 10; i++) {
      double lineY = chartBottom - (lineSpacing * i);

      Paint linePaint = Paint()
        ..color = Colors.grey.withOpacity(0.5)
        ..strokeWidth = 1;

      canvas.drawLine(
        Offset(0, lineY),
        Offset(size.width, lineY),
        linePaint,
      );
    }

    for (int i = 0; i < floats.length; i++) {
      double value = floats[i];
      BlockType blockType = blockTypes[i];
      double barHeight = chartHeight * (value / maxFloat);
      double barTop = chartBottom - barHeight;

      Rect barRect = Rect.fromLTRB(
        i * barWidth,
        barTop,
        (i + 1) * barWidth,
        chartBottom,
      );

      Paint barPaint = Paint()..color = blockType.color;
      canvas.drawRect(barRect, barPaint);
    }
  }

  @override
  bool shouldRepaint(ChartPainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(ChartPainter oldDelegate) => false;
}

class AreaCurveWidget extends StatelessWidget {
  final List<Trend> trends;
  final List<int> selectedBlockTypeIds;
  final List<BlockType> blockTypes;

  AreaCurveWidget({
    required this.trends,
    required this.selectedBlockTypeIds,
    required this.blockTypes,
  });

  @override
  Widget build(BuildContext context) {
    List<Trend> filteredTrends = trends
        .where((trend) => selectedBlockTypeIds.contains(trend.blockTypeId))
        .toList();

    // Extract the unique days from filteredTrends
    Set<int> uniqueDays = filteredTrends.map((trend) => trend.date.day).toSet();
    List<int> sortedDays = uniqueDays.toList()..sort();

    return SizedBox(
      height: 300, // adjust the height as needed
      width: 400,
      child: CustomPaint(
        painter: AreaCurvePainter(
          filteredTrends,
          sortedDays,
          blockTypes,
          selectedBlockTypeIds,
        ),
      ),
    );
  }
}

class AreaCurvePainter extends CustomPainter {
  final List<Trend> trends;
  final List<int> sortedDays;
  final List<BlockType> blockTypes;
  final List<int> selectedIDs;

  AreaCurvePainter(
    this.trends,
    this.sortedDays,
    this.blockTypes,
    this.selectedIDs,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final double padding = 26.0;
    final double curveWidth = size.width - padding * 2;
    final double curveHeight = size.height - padding * 2;
    final double maxTimeSpent = trends
            .fold(
              0,
              (maxValue, trend) => maxValue > trend.timeSpent.inHours
                  ? maxValue
                  : trend.timeSpent.inHours,
            )
            .toDouble() +
        1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int selectedID in selectedIDs) {
      final filteredTrends =
          trends.where((trend) => trend.blockTypeId == selectedID).toList();

      final curvePath = Path();
      final curvePaint = Paint()
        ..style = PaintingStyle.fill
        ..color = blockTypes[selectedID]
            .color
            .withOpacity(0.5); // Adjust the color and opacity as desired

      for (int i = 0; i < filteredTrends.length; i++) {
        final trend = filteredTrends[i];
        final int day = trend.date.day;
        final int dayIndex = sortedDays.indexOf(day);

        if (dayIndex != -1) {
          final double x =
              padding + dayIndex * curveWidth / (sortedDays.length - 1);
          final double y = padding +
              (1 - trend.timeSpent.inMinutes / (60 * maxTimeSpent)) *
                  curveHeight;

          if (i == 0 && trend.blockTypeId == selectedID) {
            curvePath.moveTo(x, size.height - padding);
            curvePath.lineTo(x, y);
          } else {
            final prevTrend = filteredTrends[i - 1];
            final int prevDay = prevTrend.date.day;
            final int prevDayIndex = sortedDays.indexOf(prevDay);

            if (prevDayIndex != -1 && prevTrend.blockTypeId == selectedID) {
              curvePath.lineTo(x, y);
            }
          }

          // Draw circles at data points
          final circleRadius = 4.0;
          final circleCenter = Offset(x, y);
          final circlePaint = Paint();

          circlePaint.color = blockTypes[selectedID].color.withOpacity(1.0);
          canvas.drawCircle(circleCenter, circleRadius, circlePaint);
        }
      }

      curvePath.lineTo(size.width - padding, size.height - padding);
      curvePath.close();

      canvas.drawPath(curvePath, curvePaint);

      final textStyle = TextStyle(
        color: Colors.white, // Adjust the label color as desired
        fontSize: 12, // Adjust the label font size as desired
      );

      // Draw day labels
      for (int i = 0; i < sortedDays.length; i++) {
        final dayLabel = sortedDays[i].toString();
        final labelOffset = padding + i * curveWidth / (sortedDays.length - 1);
        textPainter.text = TextSpan(text: dayLabel, style: textStyle);
        textPainter.layout();
        textPainter.paint(
            canvas, Offset(labelOffset, size.height - padding + 4));
      }

      // Draw hour labels
      final List<double> hourLabels = [
        0,
        (maxTimeSpent ~/ 2.0).toDouble(),
        maxTimeSpent
      ];
      for (double hour in hourLabels) {
        final hourLabel = hour.toString();
        final labelOffset = padding - 24;
        final y = padding + (1 - hour / maxTimeSpent) * curveHeight;
        textPainter.text = TextSpan(text: hourLabel, style: textStyle);
        textPainter.layout();
        textPainter.paint(canvas, Offset(labelOffset, y - 8));
      }
    }
  }

  @override
  bool shouldRepaint(AreaCurvePainter oldDelegate) {
    return oldDelegate.trends != trends ||
        oldDelegate.sortedDays != sortedDays ||
        oldDelegate.selectedIDs != selectedIDs;
  }
}
