// import 'package:flutter/material.dart';

// class PinInput extends StatelessWidget {
//   final int length;
//   final ValueChanged<String> onCompleted;
//   final ValueChanged<String> onChanged;

//   PinInput({
//     required this.length,
//     required this.onCompleted,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 280,
//       child: GridView.builder(
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 4,
//           childAspectRatio: 1,
//           crossAxisSpacing: 10,
//           mainAxisSpacing: 10,
//         ),
//         shrinkWrap: true,
//         itemCount: 12,
//         itemBuilder: (context, index) {
//           if (index == 9) return Container();
//           if (index == 10) index = 0;
//           if (index == 11) {
//             return IconButton(
//               icon:
//                   Icon(Icons.backspace, color: Theme.of(context).primaryColor),
//               onPressed: () => onChanged('-'),
//             );
//           }
//           return ElevatedButton(
//             child: Text(
//               '${index + 1}',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             onPressed: () => onChanged('${index + 1}'),
//             style: ElevatedButton.styleFrom(
//               foregroundColor: Theme.of(context).primaryColor,
//               backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
//               shape: CircleBorder(),
//               padding: EdgeInsets.all(20),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
