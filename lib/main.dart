import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'home_page.dart';
import 'analytics_page.dart';
import 'history_page.dart';
import 'data_types.dart';
import 'server_io.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  var selectedIndex = 0;
  var noServer = true;

  late List<BlockType> blockTypes = [];
  late List<TimeBlock> timeBlocks = [];
  late String currentBlockName = "";
  late int currentBlockType = 0;
  late String serverIP = "";
  late String userName = "";
  TextEditingController serverIPController = TextEditingController();
  TextEditingController userNameController = TextEditingController();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncServer();
    }
  }

  @override
  void initState() {
    super.initState();
    var serverIPFuture = getServerIP();
    var userNameFuture = getUserName();
    serverIPFuture.then((value) => setState(() {
          serverIP = value;
        }));

    userNameFuture.then((value) => setState(() {
          userName = value;
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
    syncServer();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addObserver(this);
    if (noServer) {
      var serverIPFuture = getServerIP();
      serverIPFuture.then((value) => setState(() {
            serverIP = value;
          }));
      if (serverIP != "") {
        setState(() {
          noServer = false;
          syncServer();
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
                controller: serverIPController,
                decoration: const InputDecoration(
                  labelText: 'Server IP',
                ),
              ),
              TextField(
                controller: userNameController,
                decoration: const InputDecoration(
                  labelText: 'User Name',
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    serverIP = serverIPController.text;
                    userName = userNameController.text;
                    setServerIP(serverIP);
                    setUserName(userName);
                    noServer = false;
                    syncServer();
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
                  var ipController = TextEditingController();
                  var nameController = TextEditingController();

                  return AlertDialog(
                    title: const Text('Settings'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: ipController,
                          decoration: const InputDecoration(
                            labelText: 'Server IP',
                          ),
                        ),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'User Name',
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
                            if (ipController.text != "") {
                              serverIP = ipController.text;
                              setServerIP(serverIP);
                            }

                            if (nameController.text != "") {
                              userName = nameController.text;
                              setUserName(userName);
                            }

                            syncServer();
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
              title: const Text('History'),
              leading: const Icon(Icons.history),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  selectedIndex = 1;
                });
              },
            ),
            ListTile(
              title: const Text('Analytics'),
              leading: const Icon(Icons.analytics),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  selectedIndex = 2;
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
      body: selectedIndex == 0 && currentBlockName != ""
          ? HomePage(
              userName: userName,
              timeBlocks: timeBlocks,
              blockTypes: blockTypes,
              currentBlockName: currentBlockName.replaceAll("\"", "").trim(),
              currentBlockType: currentBlockType,
            )
          : selectedIndex == 0 && timeBlocks.isEmpty
              ? const Center(
                  child: Text("No time blocks added or no server connection"),
                )
              : selectedIndex == 1
                  ? HistoryPage(
                      serverIP: serverIP,
                    )
                  : selectedIndex == 2
                      ? AnalyticsPage(
                          serverIP: serverIP,
                        )
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
                  syncServer();
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
                              if (nameController.text == "") {
                                return;
                              }
                              var blockType = BlockType(
                                name: nameController.text,
                                color: col,
                                id: 0,
                              );

                              if (postBlockType(blockType, serverIP)) {
                                syncServer();
                              }
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
                  syncServer();
                  //New popup window to add a new block
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      var nameController = TextEditingController();
                      int nextBlockType = 0;
                      var startTime = DateTime(1945, 1, 1, 1, 1, 1);
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
                              if (nameController.text == "") {
                                return;
                              }
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

                              var success = false;
                              if (postTimeBlock(newBlock, serverIP)) {
                                success = true;
                              }
                              if (postCurrentBlockType(
                                  nextBlockType, serverIP)) {
                                success = true;
                              }
                              if (postCurrentBlockName(
                                  nameController.text, serverIP)) {
                                success = true;
                              }

                              if (success) {
                                syncServer();
                              }

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
        1 => Container(),
        2 => Container(),
        _ => throw Exception('Invalid index'),
      },
    );
  }

  void syncServer() {
    var timeBlocksFuture = fetchTimeBlocks(serverIP, DateTime.now());
    var blockTypesFuture = fetchBlockTypes(serverIP);
    var currentNameFuture = fetchCurrentBlockName(serverIP);
    var currentTypeFuture = fetchCurrentBlockType(serverIP);

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
  }
}
