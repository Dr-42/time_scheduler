import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  // A list of block types
  // User can add new block types
  // User cannot delete block types
  final List<BlockType> blockTypes = [
    BlockType(name: "Sleep", color: Colors.blue[900]!, id: 0),
    BlockType(name: "Work", color: Colors.red[900]!, id: 1),
    BlockType(name: "Play", color: Colors.green[900]!, id: 2),
  ];

  // A list of time blocks
  // User can add new time blocks
  // User cannot delete time blocks
  final List<TimeBlock> timeBlocks = [
    TimeBlock(
        //Today 6 AM
        startTime: DateTime.now().subtract(Duration(hours: 24)),
        endTime: DateTime.now().subtract(Duration(hours: 16)),
        title: "Sleep",
        type: 0),
    TimeBlock(
        startTime: DateTime.now().subtract(Duration(hours: 16)),
        endTime: DateTime.now().subtract(Duration(hours: 8)),
        title: "Work",
        type: 1),
    TimeBlock(
        startTime: DateTime.now().subtract(Duration(hours: 8)),
        endTime: DateTime.now().subtract(Duration(hours: 6)),
        title: "Play",
        type: 2),
    TimeBlock(
      startTime: DateTime.now().subtract(Duration(hours: 6)),
      endTime: DateTime.now(),
      title: "Sleep",
      type: 0,
    )
  ];

  @override
  Widget build(BuildContext context) {
    var curTime = DateTime(2023, 5, 12, 16, 9, 0);
    return Column(
      children: [
        PieChart(
          timeBlocks: timeBlocks,
          blockTypes: blockTypes,
        ),
        CenterTimer(startTime: curTime),
        for (var block in timeBlocks)
          TimeBlockCard(
            block: block,
            blockTypes: blockTypes,
          ),
      ],
    );
  }
}

class TimeBlockCard extends StatelessWidget {
  final TimeBlock block;
  final List<BlockType> blockTypes;

  TimeBlockCard({
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
    return Card(
      child: ListTile(
        title: Text(block.title),
        subtitle: Text(
            "${block.startTime.hour}:${block.startTime.minute} - ${block.endTime.hour}:${block.endTime.minute}"),
        tileColor: blockTypes[block.type].color,
      ),
    );
  }
}

class CenterTimer extends StatefulWidget {
  final DateTime startTime;

  const CenterTimer({
    Key? key,
    required this.startTime,
  }) : super(key: key);

  @override
  _CenterTimerState createState() => _CenterTimerState();
}

class _CenterTimerState extends State<CenterTimer> {
  late Timer timer;
  late DateTime currentTime;

  @override
  void initState() {
    super.initState();
    // Set the current time to the start time
    currentTime = DateTime.now();
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        currentTime = currentTime.add(Duration(seconds: 1));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var elapsedTime = currentTime.difference(widget.startTime);
    String formattedTime =
        "${elapsedTime.inHours.toString().padLeft(2, '0')}:${elapsedTime.inMinutes.remainder(60).toString().padLeft(2, '0')}:${elapsedTime.inSeconds.remainder(60).toString().padLeft(2, '0')}";

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              // Format the elapsed time to HH:MM:SS
              formattedTime,
              style: TextStyle(fontSize: 50),
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

// A 360 degree Piechart with total length of 24 hours
class PieChart extends StatefulWidget {
  PieChart({
    Key? key,
    required this.blockTypes,
    required this.timeBlocks,
  }) : super(key: key);

  final List<BlockType> blockTypes;
  final List<TimeBlock> timeBlocks;

  @override
  State<PieChart> createState() => _PieChartState();
}

class _PieChartState extends State<PieChart> {
  late List<double> data;

  @override
  Widget build(BuildContext context) {
    var types = widget.blockTypes.length;

    data = [
      for (int i = 0; i < types; i++)
        widget.timeBlocks
            .where((element) => element.type == i)
            .map((e) => e.endTime.difference(e.startTime).inSeconds)
            .reduce((a, b) => a + b)
            .toDouble()
    ];

    double total = data.reduce((a, b) => a + b);
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: SizedBox(
        width: 200,
        height: 200,
        child: CustomPaint(
          painter: PieChartPainter(data, total, widget.blockTypes),
        ),
      ),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<double> data;
  final double total;
  final List<BlockType> blockTypes;

  PieChartPainter(this.data, this.total, this.blockTypes);

  @override
  void paint(Canvas canvas, Size size) {
    double radius = size.width / 2;
    double startAngle = 0;
    for (int i = 0; i < data.length; i++) {
      double sweepAngle = data[i] * 2 * pi / total;
      canvas.drawArc(
          Rect.fromCircle(center: Offset(radius, radius), radius: radius),
          startAngle,
          sweepAngle,
          false,
          Paint()
            ..color = blockTypes[i].color
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

// Logical class depicting a time block
// A time block has a start time, end time, and a title and a type
// The type is a num
// The endTime is mutable
class TimeBlock {
  final DateTime startTime;
  DateTime endTime;
  final String title;
  final int type;

  TimeBlock(
      {required this.startTime,
      required this.endTime,
      required this.title,
      required this.type});

  void setEndTime(DateTime newEndTime) {
    endTime = newEndTime;
  }
}

class BlockType {
  final String name;
  final Color color;
  final int id;

  BlockType({required this.name, required this.color, required this.id});
}
