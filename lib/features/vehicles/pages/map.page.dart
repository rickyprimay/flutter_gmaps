// SizedBox(
//               height: 200,
//               child: Center(
//                   child: Chart(
//                 data: [
//                   {'genre': 'Sports', 'sold': 275},
//                   {'genre': 'Strategy', 'sold': 115},
//                   {'genre': 'Action', 'sold': 120},
//                   {'genre': 'Shooter', 'sold': 350},
//                   {'genre': 'Other', 'sold': 150},
//                 ],
//                 variables: {
//                   'genre': Variable(
//                     accessor: (Map map) => map['genre'] as String,
//                   ),
//                   'sold': Variable(
//                     accessor: (Map map) => map['sold'] as num,
//                   ),
//                 },
//                 marks: [IntervalMark()],
//                 axes: [
//                   Defaults.horizontalAxis,
//                   Defaults.verticalAxis,
//                 ],
//               )),
//             ),