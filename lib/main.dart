import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';
import 'settings_page.dart';
import 'data_types.dart';
import 'fetchers.dart';

Future<String> getServerIP() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('serverIP') ?? "";
}

Future<void> setServerIP(String serverIP) async {
  //Save the server IP to shared preferences
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('serverIP', serverIP);
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
  final ThemeData theme = ThemeData(
    colorScheme: const ColorScheme.dark(),
  );

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;
  var noServer = true;

  late List<BlockType> blockTypes = [];
  late List<TimeBlock> timeBlocks = [];
  late String currentBlockName = "";
  late int currentBlockType = 0;
  late String serverIP = "";

  @override
  void initState() {
    super.initState();
    var serverIPFuture = getServerIP();
    serverIPFuture.then((value) => setState(() {
          serverIP = value;
        }));

    if (serverIP == "") {
      setState(() {
        noServer = true;
      });
    } else {
      setState(() {
        noServer = false;
      });
    }

    var blockTypesFuture = fetchBlockTypes(serverIP);
    blockTypesFuture.then((value) => setState(() {
          blockTypes = value;
        }));

    var timeBlocksFuture = fetchTimeBlocks(serverIP);
    timeBlocksFuture.then((value) => setState(() {
          timeBlocks = value;
        }));

    var currentBlockNameFuture = fetchCurrentBlockName(serverIP);
    currentBlockNameFuture.then((value) => setState(() {
          currentBlockName = value;
        }));

    var currentBlockTypeFuture = fetchCurrentBlockType(serverIP);
    currentBlockTypeFuture.then((value) => setState(() {
          currentBlockType = value;
        }));
  }

  @override
  Widget build(BuildContext context) {
    if (noServer) {
      var serverIPFuture = getServerIP();
      serverIPFuture.then((value) => setState(() {
            serverIP = value;
          }));
      if (serverIP != "") {
        setState(() {
          noServer = false;

          var blockTypesFuture = fetchBlockTypes(serverIP);
          blockTypesFuture.then((value) => setState(() {
                blockTypes = value;
              }));

          var timeBlocksFuture = fetchTimeBlocks(serverIP);
          timeBlocksFuture.then((value) => setState(() {
                timeBlocks = value;
              }));

          var currentBlockNameFuture = fetchCurrentBlockName(serverIP);
          currentBlockNameFuture.then((value) => setState(() {
                currentBlockName = value;
              }));

          var currentBlockTypeFuture = fetchCurrentBlockType(serverIP);
          currentBlockTypeFuture.then((value) => setState(() {
                currentBlockType = value;
              }));
        });
      }
      return Scaffold(
        //Text showing no serverIP is set
        //Text field to set serverIP
        //Button to set serverIP

        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("No server IP set"),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Server IP',
                ),
                onChanged: (text) {
                  serverIP = text;
                },
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    setServerIP(serverIP);
                    noServer = false;
                    var blockTypesFuture = fetchBlockTypes(serverIP);
                    blockTypesFuture.then((value) => setState(() {
                          blockTypes = value;
                        }));

                    var timeBlocksFuture = fetchTimeBlocks(serverIP);
                    timeBlocksFuture.then((value) => setState(() {
                          timeBlocks = value;
                        }));

                    var currentBlockNameFuture =
                        fetchCurrentBlockName(serverIP);
                    currentBlockNameFuture.then((value) => setState(() {
                          currentBlockName = value;
                        }));

                    var currentBlockTypeFuture =
                        fetchCurrentBlockType(serverIP);
                    currentBlockTypeFuture.then((value) => setState(() {
                          currentBlockType = value;
                        }));
                  });
                },
                child: const Text("Set Server IP"),
              ),
            ],
          ),
        ),
      );
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
            icon: const Icon(Icons.settings),
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
                            serverIP = nameController.text;
                            setServerIP(serverIP);

                            var blockTypesFuture = fetchBlockTypes(serverIP);
                            blockTypesFuture.then((value) => setState(() {
                                  blockTypes = value;
                                }));

                            var timeBlocksFuture = fetchTimeBlocks(serverIP);
                            timeBlocksFuture.then((value) => setState(() {
                                  timeBlocks = value;
                                }));

                            var currentBlockNameFuture =
                                fetchCurrentBlockName(serverIP);
                            currentBlockNameFuture.then((value) => setState(() {
                                  currentBlockName = value;
                                }));

                            var currentBlockTypeFuture =
                                fetchCurrentBlockType(serverIP);
                            currentBlockTypeFuture.then((value) => setState(() {
                                  currentBlockType = value;
                                }));
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
      body: selectedIndex == 0 && timeBlocks.isNotEmpty
          ? HomePage(
              timeBlocks: timeBlocks,
              blockTypes: blockTypes,
              currentBlockName: currentBlockName.replaceAll("\"", "").trim(),
              currentBlockType: currentBlockType,
            )
          : selectedIndex == 0 && timeBlocks.isEmpty
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
                            const Text("Block Color"),
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

                              postBlockType(blockType, serverIP);
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
                                for (var blockType in blockTypes)
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
                              if (timeBlocks.isNotEmpty) {
                                startTime = timeBlocks.last.endTime;
                              }
                              var endTime = DateTime.now();
                              var blockName = currentBlockName;
                              var blockType = currentBlockType;

                              var newBlock = TimeBlock(
                                title: blockName,
                                type: blockType,
                                startTime: startTime,
                                endTime: endTime,
                              );

                              postTimeBlock(newBlock, serverIP);
                              postCurrentBlockType(nextBlockType, serverIP);
                              postCurrentBlockName(
                                  nameController.text, serverIP);

                              var timeBlocksFuture = fetchTimeBlocks(serverIP);
                              var blockTypesFuture = fetchBlockTypes(serverIP);
                              var currentNameFuture =
                                  fetchCurrentBlockName(serverIP);
                              var currentTypeFuture =
                                  fetchCurrentBlockType(serverIP);

                              timeBlocksFuture.then((value) {
                                setState(() {
                                  timeBlocks = value;
                                });
                              });

                              blockTypesFuture.then((value) {
                                setState(() {
                                  blockTypes = value;
                                });
                              });

                              currentNameFuture.then((value) {
                                setState(() {
                                  currentBlockName = value;
                                });
                              });

                              currentTypeFuture.then((value) {
                                setState(() {
                                  currentBlockType = value;
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
          var blockTypesFuture = fetchBlockTypes(serverIP);
          blockTypesFuture.then((value) => setState(() {
                blockTypes = value;
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
          var timeBlocksFuture = fetchTimeBlocks(serverIP);
          timeBlocksFuture.then((value) => setState(() {
                timeBlocks = value;
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
          var currentBlockNameFuture = fetchCurrentBlockName(serverIP);
          currentBlockNameFuture.then((value) => setState(() {
                currentBlockName = value;
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
          var currentBlockTypeFuture = fetchCurrentBlockType(serverIP);
          currentBlockTypeFuture.then((value) => setState(() {
                currentBlockType = value;
              }));
        });
      }
    });
  }
}
