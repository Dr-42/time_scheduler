import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'data_types.dart';

Future<String> getServerIP() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('serverIP') ?? "";
}

Future<void> setServerIP(String serverIP) async {
  //Save the server IP to shared preferences
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('serverIP', serverIP);
}

Future<String> getUserName() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('userName') ?? "";
}

Future<void> setUserName(String userName) async {
  //Save the server IP to shared preferences
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('userName', userName);
}

bool postBlockType(BlockType blockType, String serverIP) {
  var url = Uri.parse('http://$serverIP/blocktypes');
  var response = http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(blockType.toJson()),
  );

  response.then((value) {
    if (value.statusCode == 201) {
      return true;
    }
  });

  return false;
}

bool postTimeBlock(TimeBlock timeBlock, String serverIP) {
  var url = Uri.parse('http://$serverIP/timeblocks');
  var response = http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(timeBlock.toJson()),
  );

  response.then((value) {
    if (value.statusCode == 201) {
      return true;
    }
  });
  return false;
}

bool postCurrentBlockName(String name, String serverIP) {
  var url = Uri.parse('http://$serverIP/currentblockname');
  var response = http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(name),
  );

  response.then((value) {
    if (value.statusCode == 201) {
      return true;
    }
  });
  return false;
}

bool postCurrentBlockType(int t, String serverIP) {
  var url = Uri.parse('http://$serverIP/currentblocktype');
  var response = http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(t),
  );

  response.then((value) {
    if (value.statusCode == 201) {
      return false;
    }
  });
  return true;
}

Future<List<BlockType>> fetchBlockTypes(String serverIP) async {
  //Check if the server is running
  var serverRunning = false;
  while (!serverRunning) {
    if (serverIP == "") {
      return [];
    }
    try {
      var response = await http.get(Uri.parse('http://$serverIP/blocktypes'));
      if (response.statusCode == 200) {
        serverRunning = true;
      }
    } catch (e) {
      serverRunning = false;
    }
  }
  http.Response response;
  try {
    response = await http.get(Uri.parse('http://$serverIP/blocktypes'));
  } catch (e) {
    return [];
  }
  if (response.statusCode == 200) {
    final List<Map<String, dynamic>> jsonList =
        List<Map<String, dynamic>>.from(json.decode(response.body));
    return jsonList.map((json) => BlockType.fromJson(json)).toList();
  } else {
    return [];
  }
}

Future<Analysis?> fetchAnalysis(
  String serverIP,
  DateTime startTime,
  DateTime endTime,
) async {
  var query = 'http://$serverIP/analysis?'
      'startyear=${startTime.year}&startmonth=${startTime.month}&startday=${startTime.day}'
      '&endyear=${endTime.year}&endmonth=${endTime.month}&endday=${endTime.day}';

  var serverRunning = false;
  while (!serverRunning) {
    if (serverIP == "") {
      return null;
    }
    try {
      var response = await http.get(Uri.parse(query));
      if (response.statusCode == 200) {
        serverRunning = true;
      }
    } catch (e) {
      serverRunning = false;
    }
  }
  var response = await http.get(Uri.parse(query));
  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonMap = json.decode(response.body);
    return Analysis.fromJson(jsonMap);
  }
  return null;
}

Future<List<TimeBlock>> fetchTimeBlocks(String serverIP, DateTime when) async {
  //Check if the server is running
  var query =
      'http://$serverIP/timeblocks?year=${when.year}&month=${when.month}&day=${when.day}';
  var serverRunning = false;
  while (!serverRunning) {
    if (serverIP == "") {
      return [];
    }
    try {
      var response = await http.get(Uri.parse(query));
      if (response.statusCode == 200) {
        serverRunning = true;
      }
    } catch (e) {
      serverRunning = false;
    }
  }
  var response = await http.get(Uri.parse(query));
  if (response.statusCode == 200) {
    final List<Map<String, dynamic>> jsonList =
        List<Map<String, dynamic>>.from(json.decode(response.body));
    return jsonList.map((json) => TimeBlock.fromJson(json)).toList();
  } else {
    return [];
  }
}

Future<String> fetchCurrentBlockName(String serverIP) async {
  var query = 'http://$serverIP/currentblockname';
  var serverRunning = false;
  while (!serverRunning) {
    if (serverIP == "") {
      return "";
    }
    try {
      var response = await http.get(Uri.parse(query));
      if (response.statusCode == 200) {
        serverRunning = true;
      }
    } catch (e) {
      serverRunning = false;
    }
  }

  var response = await http.get(Uri.parse(query));
  if (response.statusCode == 200) {
    return response.body;
  } else {
    return "";
  }
}

Future<int> fetchCurrentBlockType(String serverIP) async {
  var query = 'http://$serverIP/currentblocktype';
  var serverRunning = false;
  while (!serverRunning) {
    if (serverIP == "") {
      return 0;
    }
    try {
      var response = await http.get(Uri.parse(query));
      if (response.statusCode == 200) {
        serverRunning = true;
      }
    } catch (e) {
      serverRunning = false;
    }
  }

  var response = await http.get(Uri.parse(query));
  if (response.statusCode == 200) {
    return int.parse(response.body);
  } else {
    return 0;
  }
}
