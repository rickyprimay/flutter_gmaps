// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:vehiloc/features/vehicles/Api/api_provider.dart';


// class VehicleView extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (context) => ApiProvider(),
//       child: MaterialApp(
//         title: 'API Testing',
//         home: VehiclePage(),
//       ),
//     );
//   }
// }

// class VehiclePage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final apiProvider = Provider.of<ApiProvider>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('API Testing'),
//       ),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () {
//             apiProvider.testApi();
//           },
//           child: Text('Test API'),
//         ),
//       ),
//     );
//   }
// }
