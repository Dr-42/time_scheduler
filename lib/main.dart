import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'home_page.dart';
import 'settings_page.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<BlockType>> fetchBlockTypes() async {
  //Check if the server is running
  var serverRunning = false;
  while (!serverRunning) {
    try {
      var response =
          await http.get(Uri.parse('http://localhost:8080/blocktypes'));
      if (response.statusCode == 200) {
        serverRunning = true;
      }
    } catch (e) {
      serverRunning = false;
    }
  }
  var response = await http.get(Uri.parse('http://localhost:8080/blocktypes'));
  if (response.statusCode == 200) {
    final List<Map<String, dynamic>> jsonList =
        List<Map<String, dynamic>>.from(json.decode(response.body));
    return jsonList.map((json) => BlockType.fromJson(json)).toList();
  } else {
    return [];
  }
}

Future<List<TimeBlock>> fetchTimeBlocks() async {
  //Check if the server is running
  var query =
      'http://localhost:8080/timeblocks?year=${DateTime.now().year}&month=${DateTime.now().month}&day=${DateTime.now().day}';
  var queryPrev =
      'http://localhost:8080/timeblocks?year=${DateTime.now().year}&month=${DateTime.now().month}&day=${DateTime.now().day - 1}';
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
        var prevTitleFuture = fetchCurrentBlockName();
        var prevTypeFuture = fetchCurrentBlockType();

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
          query = 'http://localhost:8080/timeblocks';
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

            query = 'http://localhost:8080/timeblocks';
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

Future<String> fetchCurrentBlockName() async {
  var query = 'http://localhost:8080/currentblockname';
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

Future<int> fetchCurrentBlockType() async {
  var query = 'http://localhost:8080/currentblocktype';
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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Scheduler',
      home: MyHomePage(title: 'Time Scheduler'),
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;
  List<BlockType> blockTypes = [];
  List<TimeBlock> timeBlocks = [];
  String currentBlockName = "";
  int currentBlockType = 0;
  bool pingedTimeBlocks = false;
  bool pingedcurrentBlockType = false;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  late Future<List<BlockType>> blockTypesFuture;
  late Future<List<TimeBlock>> timeBlocksFuture;
  late String currentBlockName;
  late int currentBlockType;

  // Path: lib\main.dart
  @override
  Widget build(BuildContext context) {
    if (widget.blockTypes.isEmpty) {
      var blockTypesFuture = fetchBlockTypes();
      blockTypesFuture.then((value) => setState(() {
            widget.blockTypes = value;
          }));
    }

    if (widget.timeBlocks.isEmpty && !widget.pingedTimeBlocks) {
      var timeBlocksFuture = fetchTimeBlocks();
      timeBlocksFuture.then((value) => setState(() {
            widget.timeBlocks = value;
          }));
      widget.pingedTimeBlocks = true;
    }

    if (widget.currentBlockName == "") {
      var currentBlockNameFuture = fetchCurrentBlockName();
      currentBlockNameFuture.then((value) => setState(() {
            widget.currentBlockName = value;
          }));
    }

    if (widget.currentBlockType == 0 && !widget.pingedcurrentBlockType) {
      var currentBlockTypeFuture = fetchCurrentBlockType();
      currentBlockTypeFuture.then((value) => setState(() {
            widget.currentBlockType = value;
          }));
      widget.pingedcurrentBlockType = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Row(
                children: [
                  Text(
                    'Time Scheduler',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('Home'),
              leading: const Icon(Icons.home),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  selectedIndex = 0;
                });
              },
            ),
            ListTile(
              title: const Text('Settings'),
              leading: const Icon(Icons.settings),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  selectedIndex = 1;
                });
              },
            ),
            Expanded(
              child: Container(),
            ),
            const AboutListTile(
              icon: Icon(Icons.info),
              applicationName: 'Time Scheduler',
              applicationVersion: '0.0.1',
              applicationLegalese: '© 2023',
            ),
          ],
        ),
      ),
      body: selectedIndex == 0 && widget.timeBlocks.isNotEmpty
          ? HomePage(
              timeBlocks: widget.timeBlocks,
              blockTypes: widget.blockTypes,
              currentBlockName: widget.currentBlockName,
              currentBlockType: widget.currentBlockType,
            )
          : selectedIndex == 0 && widget.timeBlocks.isEmpty
              ? const Center(
                  child: Text("Please add a time block"),
                )
              : selectedIndex == 1
                  ? const SettingsPage()
                  : throw Exception('Invalid index'),
      //Different floating action buttons for different pages
      floatingActionButton: switch (selectedIndex) {
        0 => Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                tooltip: "Add a block type",
                child: const Icon(Icons.add_box),
                onPressed: () {
                  //New popup window to add a new blocktype
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      var nameController = TextEditingController();
                      Color col = Colors.blue;

                      return AlertDialog(
                        title: const Text('New Block Type'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Block Type Name',
                              ),
                            ),
                            Text("Block Color"),
                            ColorPicker(
                              onColorChanged: (color) {
                                col = color;
                              },
                              pickerColor: Colors.blue,
                              enableAlpha: false,
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              //Post new block type to server
                              var blockType = BlockType(
                                name: nameController.text,
                                color: col,
                                id: 0,
                              );

                              postBlockType(blockType);
                              Navigator.pop(context);
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                onPressed: () {
                  //New popup window to add a new block
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      var nameController = TextEditingController();
                      int nextBlockType = 0;
                      var startTime = DateTime.now().subtract(
                        const Duration(seconds: 2),
                      );
                      return AlertDialog(
                        title: const Text('Next Task'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Task Name',
                              ),
                            ),
                            DropdownButtonFormField(
                              decoration: const InputDecoration(
                                labelText: 'Task Type',
                              ),
                              items: [
                                for (var blockType in widget.blockTypes)
                                  DropdownMenuItem(
                                    value: blockType,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          color: blockType.color,
                                        ),
                                        Text(" ${blockType.name}"),
                                      ],
                                    ),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value != null) nextBlockType = value.id;
                              },
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              if (widget.timeBlocks.isNotEmpty) {
                                startTime = widget.timeBlocks.last.endTime;
                              }
                              var endTime = DateTime.now();
                              var blockName = widget.currentBlockName;
                              var blockType = widget.currentBlockType;

                              var newBlock = TimeBlock(
                                title: blockName,
                                type: blockType,
                                startTime: startTime,
                                endTime: endTime,
                              );

                              postTimeBlock(newBlock);
                              postCurrentBlockType(nextBlockType);
                              postCurrentBlockName(nameController.text);

                              timeBlocksFuture = fetchTimeBlocks();
                              blockTypesFuture = fetchBlockTypes();
                              var currentNameFuture = fetchCurrentBlockName();
                              var currentTypeFuture = fetchCurrentBlockType();

                              timeBlocksFuture.then((value) {
                                setState(() {
                                  widget.timeBlocks = value;
                                });
                              });

                              blockTypesFuture.then((value) {
                                setState(() {
                                  widget.blockTypes = value;
                                });
                              });

                              currentNameFuture.then((value) {
                                setState(() {
                                  widget.currentBlockName = value;
                                });
                              });

                              currentTypeFuture.then((value) {
                                setState(() {
                                  widget.currentBlockType = value;
                                });
                              });

                              Navigator.pop(context);
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      );
                    },
                  );
                },
                tooltip: 'Next Block',
                child: const Icon(Icons.next_plan),
              ),
            ],
          ),
        1 => FloatingActionButton(
            onPressed: () {},
            tooltip: 'Add',
            child: const Icon(Icons.add),
          ),
        _ => throw Exception('Invalid index'),
      },
    );
  }

  void postBlockType(BlockType blockType) {
    var url = Uri.parse('http://localhost:8080/blocktypes');
    var response = http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(blockType.toJson()),
    );

    response.then((value) {
      if (value.statusCode == 201) {
        setState(() {
          var blockTypesFuture = fetchBlockTypes();
          blockTypesFuture.then((value) => setState(() {
                widget.blockTypes = value;
              }));
        });
      }
    });
  }

  void postTimeBlock(TimeBlock timeBlock) {
    var url = Uri.parse('http://localhost:8080/timeblocks');
    var response = http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(timeBlock.toJson()),
    );

    response.then((value) {
      if (value.statusCode == 201) {
        setState(() {
          var timeBlocksFuture = fetchTimeBlocks();
          timeBlocksFuture.then((value) => setState(() {
                widget.timeBlocks = value;
              }));
        });
      }
    });
  }

  void postCurrentBlockName(String name) {
    var url = Uri.parse('http://localhost:8080/currentblockname');
    var response = http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(name),
    );

    response.then((value) {
      if (value.statusCode == 201) {
        setState(() {
          var currentBlockNameFuture = fetchCurrentBlockName();
          currentBlockNameFuture.then((value) => setState(() {
                widget.currentBlockName = value;
              }));
        });
      }
    });
  }

  void postCurrentBlockType(int t) {
    var url = Uri.parse('http://localhost:8080/currentblocktype');
    var response = http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(t),
    );

    response.then((value) {
      if (value.statusCode == 201) {
        setState(() {
          var currentBlockTypeFuture = fetchCurrentBlockType();
          currentBlockTypeFuture.then((value) => setState(() {
                widget.currentBlockType = value;
              }));
        });
      }
    });
  }
}
