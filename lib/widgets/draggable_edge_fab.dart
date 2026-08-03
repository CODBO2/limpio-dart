import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// A FAB that can be dragged and snaps to the nearest screen edge.
class DraggableEdgeFab extends StatefulWidget {
  const DraggableEdgeFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.size = 56,
    this.edgePadding = 20,
    this.bottomSafePadding = 24,
    this.topSafePadding = 48,
    this.buttonKey,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final double size;
  final double edgePadding;
  final double bottomSafePadding;
  final double topSafePadding;
  final Key? buttonKey;

  @override
  State<DraggableEdgeFab> createState() => _DraggableEdgeFabState();
}

class _DraggableEdgeFabState extends State<DraggableEdgeFab> {
  Offset? _position;
  Offset? _dragStart;
  Offset? _positionAtDragStart;
  bool _moved = false;

  Offset _defaultPosition(Size area) {
    return Offset(
      area.width - widget.size - widget.edgePadding,
      area.height - widget.size - widget.bottomSafePadding,
    );
  }

  Offset _clamp(Offset pos, Size area) {
    final maxX = (area.width - widget.size - widget.edgePadding).clamp(0.0, double.infinity);
    final maxY = (area.height - widget.size - widget.bottomSafePadding).clamp(0.0, double.infinity);
    final minY = widget.topSafePadding;
    return Offset(
      pos.dx.clamp(widget.edgePadding, maxX),
      pos.dy.clamp(minY, maxY),
    );
  }

  Offset _snapToEdge(Offset pos, Size area) {
    final centerX = pos.dx + widget.size / 2;
    final left = widget.edgePadding;
    final right = area.width - widget.size - widget.edgePadding;
    final snappedX = centerX < area.width / 2 ? left : right;
    return _clamp(Offset(snappedX, pos.dy), area);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final area = Size(constraints.maxWidth, constraints.maxHeight);
        final position = _clamp(_position ?? _defaultPosition(area), area);

        return Stack(
          children: [
            Positioned(
              left: position.dx,
              top: position.dy,
              child: GestureDetector(
                onPanStart: (details) {
                  _dragStart = details.globalPosition;
                  _positionAtDragStart = position;
                  _moved = false;
                },
                onPanUpdate: (details) {
                  if (_dragStart == null || _positionAtDragStart == null) return;
                  final delta = details.globalPosition - _dragStart!;
                  if (delta.distance > 6) _moved = true;
                  setState(() {
                    _position = _clamp(_positionAtDragStart! + delta, area);
                  });
                },
                onPanEnd: (_) {
                  setState(() {
                    _position = _snapToEdge(_position ?? position, area);
                  });
                  _dragStart = null;
                  _positionAtDragStart = null;
                },
                onTap: () {
                  if (!_moved) widget.onPressed();
                },
                child: Material(
                  key: widget.buttonKey,
                  color: AppColors.fab,
                  elevation: 4,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: Icon(widget.icon, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
