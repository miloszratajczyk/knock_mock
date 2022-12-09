import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Knock mock',
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    gyroscopeEvents.listen((GyroscopeEvent event) {
      // Adds sensor reading to records if not feeezed
      if (_freezed) return;
      records.add(event.x);
      // Removes records that cannot fit on the screen
      final screenHeight = MediaQuery.of(context).size.height.toInt();
      if (records.length > screenHeight) {
        records = records.sublist(records.length - screenHeight);
      }
      setState(() {});
    });
    super.initState();
  }

  bool detect() {
    // Segements the records based on the sign
    List<List<double>> segmentedRecords = records.fold(
      [
        [0.0]
      ],
      (previousValue, element) {
        if (previousValue.last.last * element >= 0) {
          previousValue.last.add(element);
        } else {
          previousValue.add([element]);
        }
        return previousValue;
      },
    );
    // Checks if segments meet the criteria
    for (int i = 0; i < segmentedRecords.length; i++) {
      if (segmentedRecords.length - i > 4 &&
          segmentedRecords[i].isHorizontal &&
          !segmentedRecords[i + 1].isHorizontal &&
          segmentedRecords[i + 2].isHorizontal &&
          !segmentedRecords[i + 3].isHorizontal) {
        return true;
      }
    }
    return false;
  }

  List<double> records = [];
  bool _freezed = false;

  @override
  Widget build(BuildContext context) {
    final detected = detect();
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Column(
              children: [
                for (var r in records)
                  Container(
                    color: r < 0 ? Colors.amber : Colors.orange,
                    height: 1,
                    width: r.abs() * valueMultiplier,
                  )
              ],
            ),
          ),
          Center(
            child: Text(
              detected ? "DETECTED" : "",
              style: Theme.of(context).textTheme.displaySmall,
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.severe_cold),
        onPressed: () => setState(() {
          _freezed = !_freezed;
        }),
      ),
    );
  }
}

// Value used to scale sensor outputs for easier visualization and detection
const double valueMultiplier = 16;

extension DoubleListExtension on List<double> {
  // Returns the max of abstract values
  double get maxAbs => fold(double.negativeInfinity,
      (previousValue, element) => max(previousValue, element.abs()));
  // Checks if records segment is wider than higher
  bool get isHorizontal => maxAbs * valueMultiplier > length;
}
