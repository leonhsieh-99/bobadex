import 'package:flutter/material.dart';

class CompactTextRow extends StatefulWidget {
  final TextEditingController textController;
  final String? labelText;
  final String? hintText; 
  final ValueChanged<String>? onSearchChanged;
  final int maxLength;
  final int maxLines;
  final Widget child;
  final int leftFlexStart;
  final int leftFlexEnd;
  final int rightFlex;
  final double height;
  const CompactTextRow({
    super.key,
    required this.textController,
    this.onSearchChanged,
    this.labelText,
    this.hintText,
    this.maxLength = 20,
    this.maxLines = 1,
    required this.child,
    this.leftFlexStart = 3,
    this.leftFlexEnd = 6,
    this.rightFlex = 2,
    this.height = 48.0,
  });

  @override
  State<CompactTextRow> createState() => _CompactTextRowState();
}

class _CompactTextRowState extends State<CompactTextRow> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
  constraints: BoxConstraints(minHeight: widget.height),
  child: Row(
    children: [
      Expanded(
        flex: _focused ? widget.leftFlexEnd : widget.leftFlexStart,
        child: AnimatedSize(
          duration: Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn,
          child: TextField(
            focusNode: _focusNode,
            controller: widget.textController,
            onChanged: widget.onSearchChanged,
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              counterText: "",
            ),
            maxLength: widget.maxLength,
            maxLines: widget.maxLines,
          ),
        ),
      ),
      SizedBox(width: 10),
      Expanded(
        flex: widget.rightFlex,
        child: SizedBox(
          height: widget.height,
          child: Center(child: widget.child),
        ),
      ),
    ],
  ),
);
  }
}
