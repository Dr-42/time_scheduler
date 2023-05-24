import 'package:flutter/material.dart';

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

class Trend {
  final DateTime date;
  final Duration timeSpent;
  final int blockTypeId;

  Trend({
    required this.date,
    required this.timeSpent,
    required this.blockTypeId,
  });

  static Trend fromJson(Map<String, dynamic> json) {
    return Trend(
      date: DateTime(
        json['day']['year'],
        json['day']['month'],
        json['day']['day'],
        json['day']['hour'],
        json['day']['minute'],
        json['day']['second'],
      ),
      timeSpent: Duration(
        seconds: json['timeSpent']['seconds'],
        minutes: json['timeSpent']['minutes'],
        hours: json['timeSpent']['hours'],
      ),
      blockTypeId: json['blockTypeID'],
    );
  }
}

class Analysis {
  final List<double> percentages;
  final List<Trend> trends;

  Analysis({
    required this.percentages,
    required this.trends,
  });

  static Analysis fromJson(Map<String, dynamic> json) {
    List<double> percentages = [];
    List<Trend> trends = [];
    //Parse percentages as a list of floats
    for (dynamic value in json['percentages']) {
      if (value is int) {
        percentages.add(value.toDouble()); // Convert int to double
      } else if (value is double) {
        percentages.add(value);
      } else {
        throw FormatException('Invalid percentage value: $value');
      }
    }
    for (var trend in json['trends']) {
      trends.add(Trend.fromJson(trend));
    }
    return Analysis(
      percentages: percentages,
      trends: trends,
    );
  }
}
