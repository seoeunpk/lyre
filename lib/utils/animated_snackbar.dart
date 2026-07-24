import 'package:flutter/material.dart';
import 'app_colors.dart';

void showAnimatedSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _AnimatedSnackBar(
      message: message,
      isError: isError,
      onDismiss: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _AnimatedSnackBar extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _AnimatedSnackBar({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_AnimatedSnackBar> createState() => _AnimatedSnackBarState();
}

class _AnimatedSnackBarState extends State<_AnimatedSnackBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1500), () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 32,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: widget.isError ? AppColors.red : const Color(0xFF4A7B5A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
