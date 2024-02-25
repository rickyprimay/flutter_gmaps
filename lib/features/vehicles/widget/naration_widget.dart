import 'package:flutter/material.dart';
import 'package:VehiLoc/core/model/response_daily.dart';
import 'package:VehiLoc/core/utils/naration_func.dart';
import 'package:VehiLoc/core/Api/api_service.dart';
import 'package:logger/logger.dart';

class NarationWidget extends StatefulWidget {
  final Logger logger = Logger();
  final ApiService apiService = ApiService();
  final List<JdetailsItem> narationData;
  final Future<List<JdetailsItem>> Function() fetchNarationData;

  NarationWidget({
    Key? key,
    required this.narationData,
    required this.fetchNarationData,
  }) : super(key: key);

  @override
  _NarationWidgetState createState() => _NarationWidgetState();
}

class _NarationWidgetState extends State<NarationWidget> {
  Map<int, String> addresses = {};
  final Map<int, bool> buttonPressedMap = {};
  bool isFetchingAddress = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: DataTable(
            columnSpacing: 20,
            headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
            dataRowMinHeight: 100,
            dataRowMaxHeight: 100,
            columns: const [
              DataColumn(
                label: Text('Waktu',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins')),
              ),
              DataColumn(
                label: Text('Narasi',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins')),
              ),
            ],
            rows: widget.narationData.map((item) {
              final buttonPressed = buttonPressedMap[item.startdt] ?? false;
              final address = addresses[item.startdt] ?? '';

              return DataRow(cells: [
                DataCell(
                  Text(
                    '${formatTime(item.startdt)} - ${formatTime(item.enddt)}             ',
                    style: const TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatNaration(item),
                              style: const TextStyle(
                                  fontSize: 18, fontFamily: 'Poppins'),
                            ),
                            if (item.type == 1)
                              buttonPressed
                                  ? Text(
                                      address,
                                      style: const TextStyle(
                                          fontSize: 18, fontFamily: 'Poppins'),
                                    )
                                  : TextButton(
                                      onPressed: () async {
                                        if (addresses[item.startdt] == null) {
                                          final _address = await fetchGeocode(
                                              item.lat, item.lon);
                                          setState(() {
                                            buttonPressedMap[item.startdt] =
                                                true;
                                            addresses[item.startdt] = _address;
                                          });
                                          widget.logger.i('Alamat: $_address');
                                        }
                                      },
                                      child: const Text(
                                        'Show',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontFamily: 'Poppins',
                                            color: Colors.blue),
                                      ),
                                    ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<String> fetchGeocode(double lat, double lon) async {
    try {
      final _address = await widget.apiService.fetchAddress(lat, lon);
      return _address;
    } catch (e) {
      widget.logger.e("Error fetching address: $e");
      return "";
    }
  }
}
