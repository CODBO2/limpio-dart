import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class CurvedNavItem {
  const CurvedNavItem({
    required this.icon,
    required this.label,
    this.key,
  });

  final IconData icon;
  final String label;
  final Key? key;
}

/// Barra inferior con notch animado y círculo flotante en el ítem activo.
class CurvedBottomNavBar extends StatefulWidget {
  const CurvedBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<CurvedNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  State<CurvedBottomNavBar> createState() => _CurvedBottomNavBarState();
}

class _CurvedBottomNavBarState extends State<CurvedBottomNavBar>
    with SingleTickerProviderStateMixin {
  static const _barHeight = 64.0;
  static const _circleSize = 52.0;
  static const _circleGap = 6.0;
  static const _sideInset = 12.0;
  static const _bottomInset = 8.0;
  static const _topOverflow = 28.0;
  static const _edgePad = 28.0;
  static const _inactiveIconSize = 20.0;

  /// Centro del ícono inactivo dentro del slot (referencia de diseño).
  static const _inactiveIconCenterY = 28.0;

  /// Centro de la esfera flotante (relativo al borde superior de la barra).
  static const _bubbleCenterY = 0.0;

  late final AnimationController _controller;
  Animation<double> _indexAnimation = const AlwaysStoppedAnimation(0);
  double _fromIndex = 0;
  double _toIndex = 0;
  int _previousIndex = 0;

  static const _animDuration = Duration(milliseconds: 520);
  static const _liftCurve = Curves.easeInOutQuart;

  double get _hostRadius => _circleSize / 2 + _circleGap;

  @override
  void initState() {
    super.initState();
    _syncIndexState(widget.currentIndex);
    _controller = AnimationController(
      vsync: this,
      duration: _animDuration,
      value: 1,
    );
    _indexAnimation = AlwaysStoppedAnimation(_toIndex);
    _controller.addStatusListener(_onLiftAnimationStatus);
  }

  @override
  void reassemble() {
    super.reassemble();
    // Hot reload: evita campos sin inicializar.
    _syncIndexState(widget.currentIndex);
  }

  void _syncIndexState(int index) {
    _previousIndex = index;
    _fromIndex = index.toDouble();
    _toIndex = _fromIndex;
  }

  @override
  void didUpdateWidget(covariant CurvedBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _fromIndex = _indexAnimation.value;
      _toIndex = widget.currentIndex.toDouble();
      _indexAnimation = Tween<double>(begin: _fromIndex, end: _toIndex).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOutCubicEmphasized,
          reverseCurve: Curves.easeInOutCubicEmphasized,
        ),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  void _onLiftAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _previousIndex = widget.currentIndex;
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onLiftAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  double _centerX(double width, double index) {
    final count = widget.items.length;
    final usable = math.max(width - 2 * _edgePad, count * 48.0);
    final slot = usable / count;
    final start = (width - usable) / 2;
    return start + (index + 0.5) * slot;
  }

  /// Progreso 0 = ícono en reposo; 1 = ícono en la esfera.
  double _liftProgress(int index, double t) {
    final current = widget.currentIndex;
    if (_previousIndex == current) {
      return index == current ? 1.0 : 0.0;
    }
    if (index == _previousIndex) return 1.0 - t;
    if (index == current) return t;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final totalHeight = _topOverflow + _barHeight + _bottomInset + bottomSafe;

    return SizedBox(
      height: totalHeight,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final animIndex = _indexAnimation.value;
          final liftT = _liftCurve.transform(_controller.value);

          return Padding(
            padding: EdgeInsets.fromLTRB(
              _sideInset,
              _topOverflow,
              _sideInset,
              _bottomInset + bottomSafe,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final count = widget.items.length;
                final notchX = _centerX(width, animIndex);
                final host = _hostRadius;

                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    PhysicalShape(
                      elevation: 10,
                      color: AppColors.surface,
                      shadowColor: Colors.black.withValues(alpha: 0.18),
                      clipper: _NavBarNotchClipper(
                        notchCenterX: notchX,
                        hostRadius: host,
                      ),
                      child: SizedBox(
                        height: _barHeight,
                        width: width,
                        child: Stack(
                          children: [
                            for (var i = 0; i < count; i++)
                              Positioned(
                                left: _centerX(width, i.toDouble()) - 36,
                                width: 72,
                                top: 0,
                                bottom: 0,
                                child: _NavSlot(
                                  key: widget.items[i].key,
                                  item: widget.items[i],
                                  selected: widget.currentIndex == i,
                                  lift: _liftProgress(i, liftT),
                                  onTap: () => widget.onTap(i),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    for (var i = 0; i < count; i++)
                      if (_liftProgress(i, liftT) > 0.001)
                        _buildFlyingIcon(
                          width: width,
                          index: i,
                          lift: _liftProgress(i, liftT),
                        ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFlyingIcon({
    required double width,
    required int index,
    required double lift,
  }) {
    final motion = _smoothStep(lift);
    final grow = Curves.easeOutCubic.transform(lift);
    final centerY =
        _inactiveIconCenterY + (_bubbleCenterY - _inactiveIconCenterY) * motion;
    final size = 20.0 + (_circleSize - 20.0) * grow;

    return Positioned(
      left: _centerX(width, index.toDouble()) - size / 2,
      top: centerY - size / 2,
      child: IgnorePointer(
        child: _FlyingIconBubble(
          icon: widget.items[index].icon,
          size: size,
          lift: lift,
        ),
      ),
    );
  }

  /// Interpolación suave sin saltos en los extremos.
  static double _smoothStep(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }
}

class _FlyingIconBubble extends StatelessWidget {
  const _FlyingIconBubble({
    required this.icon,
    required this.size,
    required this.lift,
  });

  final IconData icon;
  final double size;
  final double lift;

  @override
  Widget build(BuildContext context) {
    final shellT = _CurvedBottomNavBarState._smoothStep(
      Curves.easeOutCubic.transform(lift),
    );
    final innerT = _CurvedBottomNavBarState._smoothStep(
      Curves.easeInOutCubic.transform(lift),
    );
    final shellOpacity = shellT;
    final innerSize = math.max(0.0, (size - 10) * innerT);
    final iconColor = Color.lerp(
      AppColors.textMuted,
      Colors.white,
      _CurvedBottomNavBarState._smoothStep(lift),
    )!;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (shellOpacity > 0)
            Opacity(
              opacity: shellOpacity,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12 * shellOpacity),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          if (innerSize > 8)
            Container(
              width: innerSize,
              height: innerSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ink,
              ),
            ),
          Icon(icon, size: 22, color: iconColor),
        ],
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    super.key,
    required this.item,
    required this.selected,
    required this.lift,
    required this.onTap,
  });

  final CurvedNavItem item;
  final bool selected;
  final double lift;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.ink : AppColors.textMuted;
    final inactiveIconOpacity = (1 - lift).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: _CurvedBottomNavBarState._barHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Opacity(
              opacity: inactiveIconOpacity,
              child: Icon(
                item.icon,
                size: _CurvedBottomNavBarState._inactiveIconSize,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              style: TextStyle(
                fontSize: 9.5,
                height: 1.1,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: 0.1,
              ),
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

/// Recorte en U suave; el path nunca se autointersecta en los bordes.
class _NavBarNotchClipper extends CustomClipper<Path> {
  _NavBarNotchClipper({
    required this.notchCenterX,
    required this.hostRadius,
  });

  final double notchCenterX;
  final double hostRadius;

  static const _corner = 20.0;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final r = hostRadius;
    final cx = notchCenterX.clamp(r + 8.0, w - r - 8.0);

    const shoulder = 14.0;

    final leftShoulderX = math.max(_corner, cx - r - shoulder);
    final rightShoulderX = math.min(w - _corner, cx + r + shoulder);
    final c1x = math.max(_corner, cx - r - shoulder / 2);
    final c2x = math.min(w - _corner, cx + r + shoulder / 2);

    final path = Path()
      ..moveTo(0, _corner)
      ..quadraticBezierTo(0, 0, _corner, 0);

    if (leftShoulderX > _corner) {
      path.lineTo(leftShoulderX, 0);
    }

    path
      ..cubicTo(
        c1x,
        0,
        cx - r,
        0,
        cx - r,
        r * 0.2,
      )
      ..arcToPoint(
        Offset(cx + r, r * 0.2),
        radius: Radius.circular(r),
        clockwise: false,
        largeArc: false,
      )
      ..cubicTo(
        cx + r,
        0,
        c2x,
        0,
        rightShoulderX,
        0,
      );

    if (rightShoulderX < w - _corner) {
      path.lineTo(w - _corner, 0);
    }

    path
      ..quadraticBezierTo(w, 0, w, _corner)
      ..lineTo(w, h - _corner)
      ..quadraticBezierTo(w, h, w - _corner, h)
      ..lineTo(_corner, h)
      ..quadraticBezierTo(0, h, 0, h - _corner)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant _NavBarNotchClipper oldClipper) {
    return oldClipper.notchCenterX != notchCenterX ||
        oldClipper.hostRadius != hostRadius;
  }
}
