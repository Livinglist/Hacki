// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hacki/cubits/cubits.dart';
//
// class ReplyScreen extends StatefulWidget {
//   ReplyScreen({
//     Key? key,
//     this.splitViewEnabled = false,
//     required this.focusNode,
//     required this.textEditingController,
//     required this.onSendTapped,
//     required this.onCloseTapped,
//     required this.onChanged,
//   }) : super(key: key);
//
//   final bool splitViewEnabled;
//   final FocusNode focusNode;
//   final TextEditingController textEditingController;
//   final VoidCallback onSendTapped;
//   final VoidCallback onCloseTapped;
//   final ValueChanged<String> onChanged;
//
//   @override
//   State<ReplyScreen> createState() => _ReplyScreenState();
// }
//
// class _ReplyScreenState extends State<ReplyScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<EditCubit, EditState>(
//       buildWhen: (previous, current) =>
//           previous.showReplyBox != current.showReplyBox,
//       builder: (context, editState) {
//         return Scaffold(
//           body: Column(
//             children: [
//               if (context.read<SplitViewCubit>().state.enabled)
//                 const Divider(
//                   height: 0,
//                 ),
//               const SizedBox(height: 36),
//               Row(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 8,
//                     ),
//                     child: Text(
//                       editState.replyingTo == null
//                           ? 'Editing'
//                           : 'Replying '
//                               '${editState.replyingTo?.by}',
//                       style: const TextStyle(color: Colors.grey),
//                     ),
//                   ),
//                   const Spacer(),
//                   if (!isLoading) ...[
//                     ...[
//                       if (replyingTo != null)
//                         AnimatedOpacity(
//                           opacity: expanded ? 1 : 0,
//                           duration: const Duration(milliseconds: 300),
//                           child: IconButton(
//                             key: const Key('quote'),
//                             icon: const Icon(
//                               FeatherIcons.code,
//                               color: Colors.orange,
//                               size: 18,
//                             ),
//                             onPressed: expanded ? showTextPopup : null,
//                           ),
//                         ),
//                       IconButton(
//                         key: const Key('expand'),
//                         icon: Icon(
//                           expanded
//                               ? FeatherIcons.minimize2
//                               : FeatherIcons.maximize2,
//                           color: Colors.orange,
//                           size: 18,
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             expanded = !expanded;
//                           });
//                         },
//                       ),
//                     ],
//                     IconButton(
//                       key: const Key('close'),
//                       icon: const Icon(
//                         Icons.close,
//                         color: Colors.orange,
//                       ),
//                       onPressed: () {
//                         widget.onCloseTapped();
//                         expanded = false;
//                       },
//                     ),
//                   ],
//                   if (isLoading)
//                     const Padding(
//                       padding: EdgeInsets.symmetric(
//                         vertical: 12,
//                         horizontal: 16,
//                       ),
//                       child: SizedBox(
//                         height: 24,
//                         width: 24,
//                         child: CircularProgressIndicator(
//                           color: Colors.orange,
//                           strokeWidth: 2,
//                         ),
//                       ),
//                     )
//                   else
//                     IconButton(
//                       key: const Key('send'),
//                       icon: const Icon(
//                         Icons.send,
//                         color: Colors.orange,
//                       ),
//                       onPressed: () {
//                         widget.onSendTapped();
//                         expanded = false;
//                       },
//                     ),
//                 ],
//               ),
//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   child: TextField(
//                     focusNode: widget.focusNode,
//                     controller: widget.textEditingController,
//                     maxLines: 100,
//                     decoration: const InputDecoration(
//                       alignLabelWithHint: true,
//                       contentPadding: EdgeInsets.zero,
//                       hintText: '...',
//                       hintStyle: TextStyle(
//                         color: Colors.grey,
//                       ),
//                       focusedBorder: InputBorder.none,
//                       border: InputBorder.none,
//                     ),
//                     keyboardType: TextInputType.multiline,
//                     textInputAction: TextInputAction.newline,
//                     onChanged: widget.onChanged,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   void showTextPopup() {
//     final replyingTo = context.read<EditCubit>().state.replyingTo;
//
//     showDialog<void>(
//       context: context,
//       barrierDismissible: true,
//       builder: (_) {
//         return AlertDialog(
//             insetPadding: const EdgeInsets.symmetric(
//               horizontal: 12,
//               vertical: 24,
//             ),
//             contentPadding: EdgeInsets.zero,
//             content: ConstrainedBox(
//               constraints: const BoxConstraints(
//                 maxWidth: 500,
//                 maxHeight: 500,
//               ),
//               child: Column(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.only(
//                       left: 12,
//                       top: 6,
//                     ),
//                     child: Row(
//                       children: [
//                         Text(
//                           replyingTo?.by ?? '',
//                           style: const TextStyle(color: Colors.grey),
//                         ),
//                         const Spacer(),
//                         TextButton(
//                           child: const Text('Copy All'),
//                           onPressed: () => FlutterClipboard.copy(
//                             replyingTo?.text ?? '',
//                           ).then((_) => HapticFeedback.selectionClick()),
//                         ),
//                         IconButton(
//                           icon: const Icon(
//                             Icons.close,
//                             color: Colors.orange,
//                             size: 18,
//                           ),
//                           onPressed: () => Navigator.pop(context),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Expanded(
//                     child: Scrollbar(
//                       isAlwaysShown: true,
//                       child: Padding(
//                         padding: const EdgeInsets.only(
//                           left: 12,
//                           right: 6,
//                           top: 6,
//                         ),
//                         child: SingleChildScrollView(
//                           child: SelectableLinkify(
//                             scrollPhysics: const NeverScrollableScrollPhysics(),
//                             linkStyle: TextStyle(
//                               fontSize:
//                                   MediaQuery.of(context).textScaleFactor * 15,
//                               color: Colors.orange,
//                             ),
//                             onOpen: (link) => LinkUtil.launchUrl(link.url),
//                             text: replyingTo?.text ?? '',
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ));
//       },
//     );
//   }
// }
