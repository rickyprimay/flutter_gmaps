import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:vehiloc/features/vehicles/api/api_service.dart';

class LoggerTest extends StatefulWidget {
  @override
  _LoggerTestState createState() => _LoggerTestState();
}

class _LoggerTestState extends State<LoggerTest> {
  final Logger logger = Logger();
  final ApiService apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fetch Daily Vehicle Data Logger'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final int vehicleId = 912;
            final int startEpoch = 1706654259;

            final dailyData = await apiService.fetchDailyHistory(
              vehicleId,
              startEpoch,
            );

            logger.i('Fetch Daily Vehicle Data Result: $dailyData');
          },
          child: Text('Fetch Daily Vehicle Data'),
        ),
      ),
    );
  }
}
