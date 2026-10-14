import 'package:flutter/material.dart';

/// Builds [builder] only when the slot is on screen or about to scroll in.
///
/// Banner and native requests stay tied to this moment. Full-screen ads are
/// preloaded separately and must not use this slot.
class LazyAdSlot extends StatefulWidget {
  const LazyAdSlot({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  State<LazyAdSlot> createState() => _LazyAdSlotState();
}

class _LazyAdSlotState extends State<LazyAdSlot> {
  static const _lead = 320.0;

  bool _near = false;
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (!identical(next, _position)) {
      _position?.removeListener(_check);
      _position = next;
      _position?.addListener(_check);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    super.dispose();
  }

  void _check() {
    if (_near || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    late final Offset origin;
    try {
      origin = box.localToGlobal(Offset.zero);
    } catch (_) {
      return;
    }
    final screen = MediaQuery.sizeOf(context);
    final near = origin.dx > -_lead &&
        origin.dx < screen.width + _lead &&
        origin.dy > -_lead &&
        origin.dy < screen.height + _lead;
    if (!near) return;
    setState(() => _near = true);
    _position?.removeListener(_check);
    _position = null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_near) return const SizedBox(width: double.infinity, height: 0);
    return widget.builder(context);
  }
}
