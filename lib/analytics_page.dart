import 'package:flutter/material.dart';
import 'server_io.dart';
import 'data_types.dart';

class AnalyticsPage extends StatefulWidget {
  final String serverIP;

  const AnalyticsPage({
    Key? key,
    required this.serverIP,
  }) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  List<TimeBlock> timeBlocks = [];
  List<BlockType> blockTypes = [];
  bool fetched = false;
  bool startDateSelected = false;
  bool endDateSelected = false;

  @override
  Widget build(BuildContext context) {
    if (_startDate != null && _endDate != null) {
      //Check if the start date is before the end date
      if (_startDate!.isAfter(_endDate!)) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Error: Start date is after end date!",
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                    startDateSelected = false;
                    endDateSelected = false;
                  });
                },
                child: const Text('Reset'),
              ),
            ],
          ),
        );
      }
      if (!fetched) {
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
              "Analytics for ${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}",
              style: const TextStyle(fontSize: 24),
            ),
            // Collapsible list of time blocks
            const Expanded(
              child: Column(
                children: [
                  Text(
                    "Time Distribution",
                    style: TextStyle(fontSize: 24),
                  ),
                ],
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
            "Welcome to the Analytics Page!",
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 20),
          const Text(
            "Select a date range to view analytics for:",
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_startDate != null)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                )
              else
                const Icon(
                  Icons.check_circle,
                  color: Colors.grey,
                ),
              const SizedBox(width: 20),
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
                        _startDate = selectedDate;
                        startDateSelected = true;
                      });
                    }
                  });
                },
                child: const Text('Select Start Date'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_endDate != null)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                )
              else
                const Icon(
                  Icons.check_circle,
                  color: Colors.grey,
                ),
              const SizedBox(width: 20),
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
                        _endDate = selectedDate;
                        endDateSelected = true;
                      });
                    }
                  });
                },
                child: const Text('Select End Date'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
