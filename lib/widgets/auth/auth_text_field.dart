import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final String label;
  final IconData prefixIcon;
  final bool isPassword;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool enabled;

  const AuthTextField({
    super.key,
    required this.label,
    required this.prefixIcon,
    required this.controller,
    this.isPassword = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return _AuthTextFieldImpl(
      label: label,
      prefixIcon: prefixIcon,
      isPassword: isPassword,
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      enabled: enabled,
    );
  }
}

class _AuthTextFieldImpl extends StatefulWidget {
  final String label;
  final IconData prefixIcon;
  final bool isPassword;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool enabled;

  const _AuthTextFieldImpl({
    required this.label,
    required this.prefixIcon,
    this.isPassword = false,
    required this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
  });

  @override
  State<_AuthTextFieldImpl> createState() => _AuthTextFieldImplState();
}

class _AuthTextFieldImplState extends State<_AuthTextFieldImpl> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      keyboardType: widget.keyboardType,
      enabled: widget.enabled,
      validator: widget.validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: widget.label,
        alignLabelWithHint: true,
        prefixIcon: Icon(widget.prefixIcon, size: 20),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
      ),
    );
  }
}
