import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:VehiLoc/core/model/response_daily.dart';

class EventWidget extends StatelessWidget {
  final List<InputLogsItem> eventData;
  final Future<List<InputLogsItem>> Function() fetchEventData;

  const EventWidget({
    Key? key,
    required this.eventData,
    required this.fetchEventData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<InputLogsItem>>(
      future: fetchEventData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Data tidak ada'));
        } else {
          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('Data Event tidak ada'));
          } else {
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: DataTable(
                    columnSpacing: 20,
                    headingTextStyle:
                        const TextStyle(fontWeight: FontWeight.bold),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Waktu',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins'),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Event',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins'),
                        ),
                      ),
                    ],
                    rows: snapshot.data!.map((item) {
                      return DataRow(cells: [
                        DataCell(Text(
                          DateFormat.Hm().format(
                              DateTime.fromMillisecondsSinceEpoch(
                                  item.dt * 1000)),
                          style: const TextStyle(
                              fontSize: 18, fontFamily: 'Poppins'),
                        )),
                        DataCell(Text(
                          '${item.sensorName} was ${item.newStateDesc}',
                          style: const TextStyle(
                              fontSize: 18, fontFamily: 'Poppins'),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            );
          }
        }
      },
    );
  }
}
