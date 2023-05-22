import 'package:flutter/material.dart';
import 'data_types.dart';
import 'server_io.dart';
import 'home_page.dart';

class HistoryPage extends StatefulWidget {
  final String serverIP;

  const HistoryPage({
    Key? key,
    required this.serverIP,
  }) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTime? _selectedDate;
  List<TimeBlock> timeBlocks = [];
  List<BlockType> blockTypes = [];
  bool fetched = false;

  @override
  Widget build(BuildContext context) {
    if (_selectedDate != null) {
      if (!fetched) {
        var timeBlocksFuture = fetchTimeBlocks(
          widget.serverIP,
          _selectedDate!,
        );
        timeBlocksFuture.then((value) {
          setState(() {
            timeBlocks = value;
          });
        });

        var blockTypesFuture = fetchBlockTypes(widget.serverIP);
        blockTypesFuture.then((value) {
          setState(() {
            blockTypes = value;
          });
        });
        fetched = true;
      } else {
        return Center(
          child: Column(children: [
            Text(
              "History for ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
              style: const TextStyle(fontSize: 24),
            ),
            // Collapsible list of time blocks
            Expanded(
              child: ListView.builder(
                itemCount: timeBlocks.length,
                reverse: false,
                itemBuilder: (context, index) {
                  return TimeBlockCard(
                    block: timeBlocks[timeBlocks.length - 1 - index],
                    blockTypes: blockTypes,
                  );
                },
              ),
            ),
          ]),
        );
      }
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Welcome to the History Page!',
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 20),
          const Text(
            'Please select a date to view the history for:',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2021),
                lastDate: DateTime.now(),
              ).then((selectedDate) {
                if (selectedDate != null) {
                  setState(() {
                    _selectedDate = selectedDate;
                  });
                }
              });
            },
            child: const Text('Select Date'),
          ),
        ],
      ),
    );
  }
}
