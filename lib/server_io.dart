import 'dart:convert';
import 'package:crypto/crypto.dart';
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

Future<String> getUserPassword() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('userPassword') ?? "";
}

Future<void> setUserPassword(String password) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  var passwordHash = sha256.convert(utf8.encode(password));
  prefs.setString('userPassword', passwordHash.toString());
}

Future<bool> postBlockType(BlockType blockType, String serverIP) async {
  var url = Uri.parse('http://$serverIP/blocktypes');
  var passwordHash = await getUserPassword();
  var response = http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $passwordHash',
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

Future<bool> postTimeBlock(TimeBlock timeBlock, String serverIP) async {
  var url = Uri.parse('http://$serverIP/timeblocks');
  var passwordHash = await getUserPassword();
  var response = http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $passwordHash',
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

Future<bool> postCurrentBlockName(String name, String serverIP) async {
  var url = Uri.parse('http://$serverIP/currentblockname');
  var passwordHash = await getUserPassword();
  var response = http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $passwordHash',
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

Future<bool> postCurrentBlockType(int t, String serverIP) async {
  var url = Uri.parse('http://$serverIP/currentblocktype');
  var passwordHash = await getUserPassword();
  var response = http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $passwordHash',
    },
    body: jsonEncode(t.toString()),
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
  var passwordHash = await getUserPassword();
  var url = Uri.parse('http://$serverIP/blocktypes');
  while (!serverRunning) {
    if (serverIP == "") {
      return [];
    }
    try {
      var response = await http.get(url, headers: <String, String>{
        'Authorization': 'Bearer $passwordHash',
      });
      if (response.statusCode == 200) {
        serverRunning = true;
        final List<Map<String, dynamic>> jsonList =
            List<Map<String, dynamic>>.from(json.decode(response.body));
        return jsonList.map((json) => BlockType.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        return [];
      }
    } catch (e) {
      serverRunning = false;
    }
  }
  return [];
}

Future<Analysis?> fetchAnalysis(
  String serverIP,
  DateTime startTime,
  DateTime endTime,
) async {
  var query = 'http://$serverIP/analysis?'
      'startyear=${startTime.year}&startmonth=${startTime.month}&startday=${startTime.day}'
      '&endyear=${endTime.year}&endmonth=${endTime.month}&endday=${endTime.day}';
  var passwordHash = await getUserPassword();

  var serverRunning = false;
  while (!serverRunning) {
    if (serverIP == "") {
      return null;
    }
    try {
      var response = await http.get(Uri.parse(query), headers: <String, String>{
        'Authorization': 'Bearer $passwordHash',
      });
      if (response.statusCode == 200) {
        serverRunning = true;
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        return Analysis.fromJson(jsonMap);
      }
    } catch (e) {
      serverRunning = false;
    }
  }
  return null;
}

Future<List<TimeBlock>> fetchTimeBlocks(String serverIP, DateTime when) async {
  //Check if the server is running
  var query =
      'http://$serverIP/timeblocks?year=${when.year}&month=${when.month}&day=${when.day}';
  var serverRunning = false;
  var passwordHash = await getUserPassword();
  while (!serverRunning) {
    if (serverIP == "") {
      return [];
    }
    try {
      var response = await http.get(Uri.parse(query), headers: {
        'Authorization': 'Bearer $passwordHash',
      });
      if (response.statusCode == 200) {
        serverRunning = true;
        final List<Map<String, dynamic>> jsonList =
            List<Map<String, dynamic>>.from(json.decode(response.body));
        return jsonList.map((json) => TimeBlock.fromJson(json)).toList();
      }
    } catch (e) {
      serverRunning = false;
    }
  }
  return [];
}

Future<String> fetchCurrentBlockName(String serverIP) async {
  var query = 'http://$serverIP/currentblockname';
  var serverRunning = false;
  var passwordHash = await getUserPassword();
  while (!serverRunning) {
    if (serverIP == "") {
      return "";
    }
    try {
      var response = await http.get(Uri.parse(query), headers: {
        'Authorization': 'Bearer $passwordHash',
      });
      if (response.statusCode == 200) {
        serverRunning = true;
        return response.body;
      }
    } catch (e) {
      serverRunning = false;
    }
  }
  return "";
}

Future<int> fetchCurrentBlockType(String serverIP) async {
  var query = 'http://$serverIP/currentblocktype';
  var serverRunning = false;
  var passwordHash = await getUserPassword();
  while (!serverRunning) {
    if (serverIP == "") {
      return 0;
    }
    try {
      var response = await http.get(Uri.parse(query), headers: {
        'Authorization': 'Bearer $passwordHash',
      });
      if (response.statusCode == 200) {
        serverRunning = true;
        return int.parse(response.body);
      }
    } catch (e) {
      serverRunning = false;
    }
  }
  return 0;
}
