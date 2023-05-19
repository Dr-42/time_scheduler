import 'package:flutter/material.dart';

import 'home_page.dart';
import 'settings_page.dart';

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

  final List<BlockType> blockTypes = [
    BlockType(
      name: "Sleep",
      color: Color.fromARGB(255, 102, 58, 5),
      id: 0,
    ),
    BlockType(
      name: "Work",
      color: Colors.purple[800]!,
      id: 1,
    ),
    BlockType(
      name: "Play",
      color: Colors.amber[800]!,
      id: 2,
    ),
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
      endTime: DateTime.now().subtract(Duration(hours: 4)),
      title: "Evening Sleep",
      type: 0,
    ),
    TimeBlock(
      startTime: DateTime.now().subtract(Duration(hours: 4)),
      endTime: DateTime.now().subtract(Duration(hours: 1)),
      title: "Evening Work",
      type: 1,
    ),
    TimeBlock(
        startTime: DateTime.now().subtract(Duration(hours: 1)),
        endTime: DateTime.now(),
        title: "Evening Play",
        type: 2),
  ];

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  // Path: lib\main.dart
  @override
  Widget build(BuildContext context) {
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
      body: Center(
        child: switch (selectedIndex) {
          0 => HomePage(
              timeBlocks: widget.timeBlocks,
              blockTypes: widget.blockTypes,
            ),
          1 => const SettingsPage(),
          _ => throw Exception('Invalid index'),
        },
      ),
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
                      return AlertDialog(
                        title: const Text('New Block Type'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              decoration: const InputDecoration(
                                labelText: 'Block Type Name',
                              ),
                            ),
                            /*ColorPicker(
                              onColorChanged: (color) {},
                              color: Colors.blue,
                              heading: Text('Task Color'),
                            ),*/
                          ],
                          /*ColorPicker(
                            onColorChanged: (color) {},
                            color: Colors.blue,
                            heading: Text('Task Color'),
                          ),*/
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
                      return AlertDialog(
                        title: const Text('Next Task'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
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
                              onChanged: (value) {},
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
}
