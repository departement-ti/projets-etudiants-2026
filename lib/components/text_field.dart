import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

class Text_Field extends StatefulWidget {
  const Text_Field({
    super.key,
    required this.label,
    required this.hint,
    required this.isPassword,
    required this.keyboard,
    required this.txtEditController,
    required this.focusNode,
  });

  final String label;
  final String hint;
  final bool isPassword;
  final TextInputType keyboard;
  final TextEditingController txtEditController;
  final FocusNode focusNode;

  @override
  State<Text_Field> createState() => _TextFieldState();
}

class _TextFieldState extends State<Text_Field> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: widget.focusNode,
      keyboardType: widget.keyboard,
      obscureText: _obscureText,
      controller: widget.txtEditController,
      style: GoogleFonts.roboto(
        height: 2,
        color: const Color.fromARGB(255, 16, 15, 15),
      ),
      cursorColor: const Color.fromARGB(255, 7, 82, 96),
      decoration: InputDecoration(
        hintText: widget.hint,
        filled: true,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: const Color.fromARGB(255, 7, 82, 96),
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(20),
          ),
          borderSide: BorderSide(
            color: Color.fromARGB(255, 7, 82, 96),
          ),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(20),
          ),
          borderSide: BorderSide(
            color: Colors.transparent,
          ),
        ),
        labelText: widget.label,
        labelStyle: GoogleFonts.roboto(
          color: const Color.fromARGB(255, 16, 15, 15),
        ),
      ),
    );
  }
}
