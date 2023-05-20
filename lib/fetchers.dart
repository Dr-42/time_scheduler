import 'dart:convert';
import 'package:http/http.dart' as http;

import 'data_types.dart';

Future<List<BlockType>> fetchBlockTypes(String serverIP) async {
  //Check if the server is running
  var serverRunning = false;
  while (!serverRunning) {
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

Future<List<TimeBlock>> fetchTimeBlocks(String serverIP) async {
  //Check if the server is running
  var query =
      'http://$serverIP/timeblocks?year=${DateTime.now().year}&month=${DateTime.now().month}&day=${DateTime.now().day}';
  var queryPrev =
      'http://$serverIP/timeblocks?year=${DateTime.now().year}&month=${DateTime.now().month}&day=${DateTime.now().day - 1}';
  var serverRunning = false;
  while (!serverRunning) {
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
    if (response.body == "[]") {
      var responsePrev = await http.get(Uri.parse(queryPrev));
      if (responsePrev.statusCode == 200) {
        final List<Map<String, dynamic>> jsonList =
            List<Map<String, dynamic>>.from(json.decode(responsePrev.body));
        var prevList =
            jsonList.map((json) => TimeBlock.fromJson(json)).toList();

        var prevBlock = prevList.last;
        var prevTitleFuture = fetchCurrentBlockName(serverIP);
        var prevTypeFuture = fetchCurrentBlockType(serverIP);

        var prevTitle = await prevTitleFuture;
        var prevType = await prevTypeFuture;

        var prevLastBlock = TimeBlock(
          startTime: prevBlock.endTime,
          //Endtime is yesterday's 23:59:59
          endTime: DateTime(prevBlock.endTime.year, prevBlock.endTime.month,
              prevBlock.endTime.day, 23, 59, 59),
          title: prevTitle,
          type: prevType,
        );
        if (prevLastBlock.title != "") {
          //Add the last block of yesterday
          query = 'http://$serverIP/timeblocks';
          var serverAccepted = false;
          while (!serverAccepted) {
            try {
              var response = await http.post(Uri.parse(query),
                  headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                  },
                  body: jsonEncode(prevLastBlock.toJson()));
              if (response.statusCode == 200) {
                serverAccepted = true;
              }
            } catch (e) {
              serverAccepted = false;
            }
          }

          if (serverAccepted) {
            //Add the first block of today
            var firstBlock = TimeBlock(
              startTime: DateTime(DateTime.now().year, DateTime.now().month,
                  DateTime.now().day, 0, 0, 0),
              endTime: DateTime(DateTime.now().year, DateTime.now().month,
                  DateTime.now().day, 0, 0, 1),
              title: "New Day",
              type: 0,
            );

            query = 'http://$serverIP/timeblocks';
            var serverRunning = false;
            while (!serverRunning) {
              try {
                var response = await http.post(Uri.parse(query),
                    headers: <String, String>{
                      'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: jsonEncode(firstBlock.toJson()));
                if (response.statusCode == 200) {
                  serverRunning = true;
                }
              } catch (e) {
                serverRunning = false;
              }
            }
            if (serverRunning) {
              return [firstBlock];
            } else {
              return [];
            }
          }
        }
      } else {
        return [];
      }
    }

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
