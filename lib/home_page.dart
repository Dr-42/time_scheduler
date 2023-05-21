import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

import 'data_types.dart';

class HomePage extends StatelessWidget {
  final List<BlockType> blockTypes;
  final List<TimeBlock> timeBlocks;
  final String currentBlockName;
  final int currentBlockType;

  const HomePage({
    Key? key,
    required this.blockTypes,
    required this.timeBlocks,
    required this.currentBlockName,
    required this.currentBlockType,
  }) : super(key: key);

  // A list of block types
  // User can add new block types
  // User cannot delete block types
  @override
  Widget build(BuildContext context) {
    var curTime = DateTime(2023, 5, 12, 16, 9, 0);

    if (blockTypes.isEmpty) {
      return const Center(
        child: Text("No block types"),
      );
    }

    return Column(
      children: [
        Text(
          "Welcome Spandan!",
          style: Theme.of(context).textTheme.displaySmall,
        ),
        CenterTimer(
          startTime: curTime,
          blockType: blockTypes[currentBlockType],
          timeBlocks: timeBlocks,
        ),
        Card(
          child: Text(
              style: const TextStyle(fontSize: 24),
              "Currently in $currentBlockName"),
        ),
        const Divider(),
        const Text(
          "Today's Distribution",
          style: TextStyle(fontSize: 16),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PieChart(
              timeBlocks: timeBlocks,
              blockTypes: blockTypes,
              curBlockType: currentBlockType,
            ),
            PieChartLegend(
              blockTypes: blockTypes,
            ),
          ],
        ),
        const Divider(),
        const Text(
          "Until now",
          style: TextStyle(fontSize: 16),
        ),
        // Collapsible list of time blocks
        Expanded(
          child: ListView.builder(
            itemCount: timeBlocks.length,
            reverse: false,
            itemBuilder: (context, index) {
              return TimeBlockCard(
                block: timeBlocks[timeBlocks.length - 1 - index],
                blockTypes: blockTypes,
              );
            },
          ),
        ),
      ],
    );
  }
}

class TimeBlockCard extends StatelessWidget {
  final TimeBlock block;
  final List<BlockType> blockTypes;

  const TimeBlockCard({
    Key? key,
    required this.block,
    required this.blockTypes,
  }) : super(key: key);

  //final List<BlockType> blockTypes = [
  //  BlockType(name: "Sleep", color: Colors.blue[900]!, id: 0),
  //  BlockType(name: "Work", color: Colors.red[900]!, id: 1),
  //  BlockType(name: "Play", color: Colors.green[900]!, id: 2),
  //];

  @override
  Widget build(BuildContext context) {
    var cardFormattedTime =
        "${block.startTime.hour.toString().padLeft(2, '0')}:${block.startTime.minute.toString().padLeft(2, '0')} - ${block.endTime.hour.toString().padLeft(2, '0')}:${block.endTime.minute.toString().padLeft(2, '0')}";
    return Card(
      child: ListTile(
        title: Text(block.title),
        subtitle: Text(cardFormattedTime),
        tileColor: blockTypes[block.type].color,
      ),
    );
  }
}

class CenterTimer extends StatefulWidget {
  final DateTime startTime;
  final BlockType blockType;
  final List<TimeBlock> timeBlocks;

  const CenterTimer({
    Key? key,
    required this.startTime,
    required this.blockType,
    required this.timeBlocks,
  }) : super(key: key);

  @override
  State<CenterTimer> createState() => _CenterTimerState();
}

class _CenterTimerState extends State<CenterTimer> {
  late Timer timer;
  late DateTime currentTime;

  @override
  void initState() {
    super.initState();
    // Set the current time to the start time
    currentTime = DateTime.now();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        currentTime = currentTime.add(const Duration(seconds: 1));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var elapsedTime = currentTime.difference(widget.timeBlocks.last.endTime);
    String formattedTime =
        "${elapsedTime.inHours.toString().padLeft(2, '0')}:${elapsedTime.inMinutes.remainder(60).toString().padLeft(2, '0')}:${elapsedTime.inSeconds.remainder(60).toString().padLeft(2, '0').padRight(2, '0')}";

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Card(
          color: widget.blockType.color,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              // Format the elapsed time to HH:MM:SS
              formattedTime,
              style: const TextStyle(fontSize: 50),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }
}

class PieChartLegend extends StatefulWidget {
  final List<BlockType> blockTypes;
  const PieChartLegend({Key? key, required this.blockTypes}) : super(key: key);

  @override
  State<PieChartLegend> createState() => _PieChartLegendState();
}

class _PieChartLegendState extends State<PieChartLegend> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: ListView(
        children: [
          for (var blockType in widget.blockTypes)
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    color: blockType.color,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Text(blockType.name),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// A 360 degree Piechart with total length of 24 hours
class PieChart extends StatefulWidget {
  const PieChart({
    Key? key,
    required this.blockTypes,
    required this.timeBlocks,
    required this.curBlockType,
  }) : super(key: key);

  final List<BlockType> blockTypes;
  final List<TimeBlock> timeBlocks;
  final int curBlockType;

  @override
  State<PieChart> createState() => _PieChartState();
}

class _PieChartState extends State<PieChart> {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    // Start the timer to update the chart every second
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {}); // Trigger a rebuild of the widget
    });
  }

  @override
  void dispose() {
    timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the total length of all time blocks
    double total = 0;
    for (var block in widget.timeBlocks) {
      total += block.endTime.difference(block.startTime).inSeconds;
    }

    List<Tuple<BlockType, int>> data = [
      for (var block in widget.timeBlocks)
        Tuple(
          widget.blockTypes[block.type],
          block.endTime.difference(block.startTime).inSeconds,
        ),
    ];

    var curData = Tuple(
      widget.blockTypes[widget.curBlockType],
      DateTime.now().difference(widget.timeBlocks.last.endTime).inSeconds,
    );

    data.add(curData);
    total += curData.item2;

    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: SizedBox(
        width: 200,
        height: 100,
        child: CustomPaint(
          painter: PieChartPainter(data, total, widget.blockTypes),
        ),
      ),
    );
  }
}

class Tuple<X, Y> {
  final X item1;
  final Y item2;
  Tuple(this.item1, this.item2);
}

class PieChartPainter extends CustomPainter {
  final List<Tuple<BlockType, int>> data;
  final double total;
  final List<BlockType> blockTypes;

  PieChartPainter(this.data, this.total, this.blockTypes);

  @override
  void paint(Canvas canvas, Size size) {
    double radius = size.width / 2;
    double startAngle = pi;
    for (int i = 0; i < data.length; i++) {
      double sweepAngle = data[i].item2 * pi / total;
      canvas.drawArc(
          Rect.fromCircle(center: Offset(radius, radius), radius: radius),
          startAngle,
          sweepAngle,
          false,
          Paint()
            ..color = data[i].item1.color
            ..strokeWidth = 20
            ..style = PaintingStyle.stroke);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
