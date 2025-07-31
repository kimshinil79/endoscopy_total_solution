import 'package:flutter/material.dart';
class _TextFormInExamRoom extends StatefulWidget {
  final String title;
  final TextInputType keyboardType;
  final TextEditingController controller;
  final Function(String?) onSaved;

  _TextFormInExamRoom({
    required this.title,
    required this.keyboardType,
    required this.controller,
    required this.onSaved,
  });

  @override
  __TextFormInExamRoomState createState() => __TextFormInExamRoomState();
}

class __TextFormInExamRoomState extends State<_TextFormInExamRoom> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
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
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.indigoAccent, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.indigoAccent, width: 2),
              ),
            ),
            onSaved: widget.onSaved,
          ),
          if (!_isFocused && widget.controller.text.isEmpty)
            Center(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.indigoAccent.withOpacity(0.5),
                ),
              ),
            ),
          if (_isFocused || widget.controller.text.isNotEmpty)
            Positioned(
              left: 10,
              top: -8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4),
                color: Colors.grey[50],
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.indigoAccent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}