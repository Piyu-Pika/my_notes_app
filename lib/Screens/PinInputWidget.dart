// void _showNoteOptions(
//     BuildContext context, String noteId, Map<String, dynamic> noteData) {
//   showModalBottomSheet(
//     context: context,
//     builder: (BuildContext context) {
//       return SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: <Widget>[
//             if (_currentView == 'notes') ...[
//               ListTile(
//                 leading: Icon(Icons.edit),
//                 title: Text('Edit'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _editNote(context, noteId, noteData);
//                 },
//               ),
//               ListTile(
//                 leading: Icon(noteData['pinned'] ?? false
//                     ? Icons.push_pin
//                     : Icons.push_pin_outlined),
//                 title: Text(noteData['pinned'] ?? false ? 'Unpin' : 'Pin'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _togglePinNote(noteId, noteData['pinned'] ?? false);
//                 },
//               ),
//               ListTile(
//                 leading: Icon(Icons.lock),
//                 title: Text('Lock Note'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _lockNote(noteId, noteData);
//                 },
//               ),
//               ListTile(
//                 leading: Icon(Icons.archive),
//                 title: Text('Archive'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _archiveNote(noteId);
//                 },
//               ),
//               ListTile(
//                 leading: Icon(Icons.delete),
//                 title: Text('Move to Trash'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _moveToTrash(noteId);
//                 },
//               ),
//             ] else if (_currentView == 'archive') ...[
//               // ... (keep existing archive options)
//             ] else if (_currentView == 'trash') ...[
//               // ... (keep existing trash options)
//             ],
//           ],
//         ),
//       );
//     },
//   );
// }

// void _lockNote(String noteId, Map<String, dynamic> noteData) async {
//   final user = FirebaseAuth.instance.currentUser!;

//   // First, verify the PIN
//   String? enteredPin = await _promptForPin('Enter PIN to lock note');
//   if (enteredPin == null) return; // User cancelled

//   try {
//     // Verify the entered PIN
//     DocumentSnapshot doc = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(user.uid)
//         .get();

//     if (doc.exists) {
//       String? storedPin =
//           (doc.data() as Map<String, dynamic>)['lockedNotesPin'];
//       if (storedPin != enteredPin) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Incorrect PIN')),
//         );
//         return;
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('User data not found')),
//       );
//       return;
//     }

//     // PIN is correct, proceed to lock the note
//     await FirebaseFirestore.instance
//         .collection('users')
//         .doc(user.uid)
//         .collection('notes')
//         .doc(noteId)
//         .update({
//       'isLocked': true,
//       'archived': false,
//       'inTrash': false,
//       'pinned': false,
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Note has been locked')),
//     );

//     // Refresh the screen
//     setState(() {});
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Failed to lock note: $e')),
//     );
//   }
// }
