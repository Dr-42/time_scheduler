import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

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
      return Center(
        child: Text("No block types"),
      );
    }

    return Column(
      children: [
        Container(
          child: Text(
            "Welcome Spandan!",
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
        CenterTimer(
          startTime: curTime,
          blockType: blockTypes[currentBlockType],
          timeBlocks: timeBlocks,
        ),
        Card(
          child: Text(
              style: TextStyle(fontSize: 24), "Currently in $currentBlockName"),
        ),
        Divider(),
        Text(
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
        Divider(),
        Text(
          "Until now",
          style: TextStyle(fontSize: 16),
        ),
        // Collapsible list of time blocks
        Expanded(
          child: ListView.builder(
            itemCount: timeBlocks.length,
            itemBuilder: (context, index) {
              return TimeBlockCard(
                block: timeBlocks[index],
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

class PieChartLegend extends StatefulWidget {
  final List<BlockType> blockTypes;
  PieChartLegend({Key? key, required this.blockTypes}) : super(key: key);

  @override
  _PieChartLegendState createState() => _PieChartLegendState();
}

class _PieChartLegendState extends State<PieChartLegend> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (var blockType in widget.blockTypes)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  color: blockType.color,
                ),
                SizedBox(
                  width: 10,
                ),
                Text(blockType.name),
              ],
            ),
          ),
      ],
    );
  }
}

// A 360 degree Piechart with total length of 24 hours
class PieChart extends StatefulWidget {
  PieChart({
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
    timer = Timer.periodic(Duration(seconds: 1), (_) {
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

    var cur_data = Tuple(
      widget.blockTypes[widget.curBlockType],
      DateTime.now().difference(widget.timeBlocks.last.endTime).inSeconds,
    );

    data.add(cur_data);
    total += cur_data.item2;

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
  late DateTime endTime;
  final String title;
  final int type;

  // Constructor
  TimeBlock({
    required this.startTime,
    endTime,
    required this.title,
    required this.type,
  }) {
    this.endTime = endTime ?? startTime;
  }

  void setEndTime(DateTime newEndTime) {
    endTime = newEndTime;
  }

  // Convert to json
  Map<String, dynamic> toJson() {
    return {
      'startTime': {
        'year': startTime.year,
        'month': startTime.month,
        'day': startTime.day,
        'hour': startTime.hour,
        'minute': startTime.minute,
        'second': startTime.second,
      },
      'endTime': {
        'year': endTime.year,
        'month': endTime.month,
        'day': endTime.day,
        'hour': endTime.hour,
        'minute': endTime.minute,
        'second': endTime.second,
      },
      'title': title,
      'blockTypeId': type,
    };
  }

  // Convert from json
  static TimeBlock fromJson(Map<String, dynamic> json) {
    return TimeBlock(
      startTime: DateTime(
        json['startTime']['year'],
        json['startTime']['month'],
        json['startTime']['day'],
        json['startTime']['hour'],
        json['startTime']['minute'],
        json['startTime']['second'],
      ),
      endTime: DateTime(
        json['endTime']['year'],
        json['endTime']['month'],
        json['endTime']['day'],
        json['endTime']['hour'],
        json['endTime']['minute'],
        json['endTime']['second'],
      ),
      title: json['title'].toString().replaceAll("\"", ""),
      type: json['blockTypeId'],
    );
  }
}

class BlockType {
  final String name;
  final Color color;
  final int id;

  BlockType({
    required this.name,
    required this.color,
    required this.id,
  });

  static BlockType fromJson(Map<String, dynamic> json) {
    //Color in json is stored as color : {r: 255, g: 255, b: 255, a: 255}
    //We need to convert it to Color.fromARGB(255, r, g, b)
    Map<String, dynamic> colorJson = json['color'];
    return BlockType(
      name: json['name'],
      color: Color.fromARGB(
        255,
        colorJson['r'],
        colorJson['g'],
        colorJson['b'],
      ),
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': {
        'r': color.red,
        'g': color.green,
        'b': color.blue,
      },
      'id': id,
    };
  }
}
