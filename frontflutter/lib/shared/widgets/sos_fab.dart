import 'package:flutter/material.dart';
import 'package:frontflutter/core/constants/app_constants.dart';

class SosFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const SosFAB({
    required this.onPressed,
    this.isLoading = false,
    Key? key,
  }) : super(key: key);

  @override
  State<SosFAB> createState() => _SosFABState();
}

class _SosFABState extends State<SosFAB> with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse background
        if (!widget.isLoading)
          ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.2)
                .animate(_pulseController),
            child: Container(
              width: AppConstants.sosButtonSize + 20,
              height: AppConstants.sosButtonSize + 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.2),
              ),
            ),
          ),
        // Main button
        FloatingActionButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          child: widget.isLoading
              ? SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                )
              : const Icon(
                  Icons.emergency,
                  size: 32,
                ),
        ),
      ],
    );
  }
}
