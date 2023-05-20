import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'home_page.dart';
import 'settings_page.dart';
import 'data_types.dart';
import 'fetchers.dart';

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
  String serverIP = "localhost:8080";
  final ThemeData theme = ThemeData(
    colorScheme: const ColorScheme.dark(),
  );

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  late Future<List<BlockType>> blockTypesFuture;
  late Future<List<TimeBlock>> timeBlocksFuture;
  late String currentBlockName;
  late int currentBlockType;
  late String serverIP;

  // Path: lib\main.dart
  @override
  Widget build(BuildContext context) {
    if (widget.blockTypes.isEmpty) {
      var blockTypesFuture = fetchBlockTypes(widget.serverIP);
      blockTypesFuture.then((value) => setState(() {
            widget.blockTypes = value;
          }));
    }

    if (widget.timeBlocks.isEmpty && !widget.pingedTimeBlocks) {
      var timeBlocksFuture = fetchTimeBlocks(widget.serverIP);
      timeBlocksFuture.then((value) => setState(() {
            widget.timeBlocks = value;
          }));
      widget.pingedTimeBlocks = true;
    }

    if (widget.currentBlockName == "") {
      var currentBlockNameFuture = fetchCurrentBlockName(widget.serverIP);
      currentBlockNameFuture.then((value) => setState(() {
            widget.currentBlockName = value;
          }));
    }

    if (widget.currentBlockType == 0 && !widget.pingedcurrentBlockType) {
      var currentBlockTypeFuture = fetchCurrentBlockType(widget.serverIP);
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
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              //Show a floating window with settings
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  var nameController = TextEditingController();

                  return AlertDialog(
                    title: const Text('Settings'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Server IP',
                          ),
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
                          setState(() {
                            widget.serverIP = nameController.text;

                            var blockTypesFuture =
                                fetchBlockTypes(widget.serverIP);
                            blockTypesFuture.then((value) => setState(() {
                                  widget.blockTypes = value;
                                }));

                            var timeBlocksFuture =
                                fetchTimeBlocks(widget.serverIP);
                            timeBlocksFuture.then((value) => setState(() {
                                  widget.timeBlocks = value;
                                }));

                            var currentBlockNameFuture =
                                fetchCurrentBlockName(widget.serverIP);
                            currentBlockNameFuture.then((value) => setState(() {
                                  widget.currentBlockName = value;
                                }));

                            var currentBlockTypeFuture =
                                fetchCurrentBlockType(widget.serverIP);
                            currentBlockTypeFuture.then((value) => setState(() {
                                  widget.currentBlockType = value;
                                }));

                            widget.pingedTimeBlocks = false;
                            widget.pingedcurrentBlockType = false;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
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
              currentBlockName:
                  widget.currentBlockName.replaceAll("\"", "").trim(),
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

                              postBlockType(blockType, widget.serverIP);
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

                              postTimeBlock(newBlock, widget.serverIP);
                              postCurrentBlockType(
                                  nextBlockType, widget.serverIP);
                              postCurrentBlockName(
                                  nameController.text, widget.serverIP);

                              timeBlocksFuture =
                                  fetchTimeBlocks(widget.serverIP);
                              blockTypesFuture =
                                  fetchBlockTypes(widget.serverIP);
                              var currentNameFuture =
                                  fetchCurrentBlockName(widget.serverIP);
                              var currentTypeFuture =
                                  fetchCurrentBlockType(widget.serverIP);

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

  void postBlockType(BlockType blockType, String serverIP) {
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
        setState(() {
          var blockTypesFuture = fetchBlockTypes(widget.serverIP);
          blockTypesFuture.then((value) => setState(() {
                widget.blockTypes = value;
              }));
        });
      }
    });
  }

  void postTimeBlock(TimeBlock timeBlock, String serverIP) {
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
        setState(() {
          var timeBlocksFuture = fetchTimeBlocks(widget.serverIP);
          timeBlocksFuture.then((value) => setState(() {
                widget.timeBlocks = value;
              }));
        });
      }
    });
  }

  void postCurrentBlockName(String name, String serverIP) {
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
        setState(() {
          var currentBlockNameFuture = fetchCurrentBlockName(widget.serverIP);
          currentBlockNameFuture.then((value) => setState(() {
                widget.currentBlockName = value;
              }));
        });
      }
    });
  }

  void postCurrentBlockType(int t, String serverIP) {
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
        setState(() {
          var currentBlockTypeFuture = fetchCurrentBlockType(widget.serverIP);
          currentBlockTypeFuture.then((value) => setState(() {
                widget.currentBlockType = value;
              }));
        });
      }
    });
  }
}
