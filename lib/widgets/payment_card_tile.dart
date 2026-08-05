import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/payment_card.dart';
import '../models/venezuelan_bank.dart';

class PaymentCardTile extends StatelessWidget {
  const PaymentCardTile({
    super.key,
    required this.item,
    required this.usageCount,
    required this.onPress,
    required this.onEdit,
    required this.onDelete,
  });

  final PaymentCard item;
  final int usageCount;
  final void Function(PaymentCard item) onPress;
  final void Function(PaymentCard item) onEdit;
  final void Function(PaymentCard item) onDelete;

  @override
  Widget build(BuildContext context) {
    final bank = VenezuelanBank.fromBankName(item.bank);
    final facePath = bank?.cardFaceAssetPath;
    final usageLabel =
        usageCount == 1 ? '1 compra registrada' : '$usageCount compras registradas';

    if (facePath != null && bank != null) {
      return _BrandedCardTile(
        item: item,
        faceAssetPath: facePath,
        aspectRatio: bank.cardFaceAspectRatio,
        quarterTurns: bank.cardFaceQuarterTurns,
        usageLabel: usageLabel,
        onPress: onPress,
        onEdit: onEdit,
        onDelete: onDelete,
      );
    }

    return _LegacyGradientTile(
      item: item,
      usageLabel: usageLabel,
      onPress: onPress,
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }
}

class _BrandedCardTile extends StatefulWidget {
  const _BrandedCardTile({
    required this.item,
    required this.faceAssetPath,
    required this.aspectRatio,
    required this.quarterTurns,
    required this.usageLabel,
    required this.onPress,
    required this.onEdit,
    required this.onDelete,
  });

  final PaymentCard item;
  final String faceAssetPath;
  final double aspectRatio;
  final int quarterTurns;
  final String usageLabel;
  final void Function(PaymentCard item) onPress;
  final void Function(PaymentCard item) onEdit;
  final void Function(PaymentCard item) onDelete;

  @override
  State<_BrandedCardTile> createState() => _BrandedCardTileState();
}

class _BrandedCardTileState extends State<_BrandedCardTile>
    with SingleTickerProviderStateMixin {
  static const _maxTilt = 0.16; // ~9°
  static const _perspective = 0.0012;

  late final AnimationController _resetController;
  Animation<double> _resetX = const AlwaysStoppedAnimation(0);
  Animation<double> _resetY = const AlwaysStoppedAnimation(0);

  double _rx = 0;
  double _ry = 0;
  Offset? _downGlobal;
  bool _tilting = false;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..addListener(() {
        setState(() {
          _rx = _resetX.value;
          _ry = _resetY.value;
        });
      });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _applyTilt(Offset local, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final nx = ((local.dx / size.width) * 2) - 1;
    final ny = ((local.dy / size.height) * 2) - 1;
    setState(() {
      _ry = (nx * _maxTilt).clamp(-_maxTilt, _maxTilt);
      _rx = (-ny * _maxTilt).clamp(-_maxTilt, _maxTilt);
      _tilting = true;
    });
  }

  void _springBack() {
    if (_rx == 0 && _ry == 0 && !_tilting) return;
    _resetX = Tween<double>(begin: _rx, end: 0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    );
    _resetY = Tween<double>(begin: _ry, end: 0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    );
    _tilting = false;
    _downGlobal = null;
    _resetController.forward(from: 0);
  }

  Matrix4 get _transform {
    return Matrix4.identity()
      ..setEntry(3, 2, _perspective)
      ..rotateX(_rx)
      ..rotateY(_ry);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final subtitle = item.lastFour == null || item.lastFour!.isEmpty
        ? item.subtitle
        : '${item.subtitle} · •••• ${item.lastFour}';

    final shadowDx = _ry * 28;
    final shadowDy = 10 + (-_rx * 28);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final aspectRatio = widget.aspectRatio;
          final size = Size(
            constraints.maxWidth,
            constraints.maxWidth / aspectRatio,
          );

          return Listener(
            onPointerDown: (event) {
              _resetController.stop();
              _downGlobal = event.position;
              _applyTilt(event.localPosition, size);
            },
            onPointerMove: (event) {
              if (_downGlobal == null) return;
              final delta = event.position - _downGlobal!;
              // Let the list scroll vertically without fighting the tilt.
              if (delta.dy.abs() > 28 &&
                  delta.dy.abs() > delta.dx.abs() * 1.35) {
                _springBack();
                return;
              }
              _applyTilt(event.localPosition, size);
            },
            onPointerUp: (_) => _springBack(),
            onPointerCancel: (_) => _springBack(),
            child: Transform(
              alignment: Alignment.center,
              transform: _transform,
              filterQuality: FilterQuality.medium,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0A1F4D).withValues(
                        alpha: _tilting ? 0.38 : 0.28,
                      ),
                      blurRadius: _tilting ? 28 : 20,
                      offset: Offset(shadowDx, shadowDy),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _CardFaceImage(
                          assetPath: widget.faceAssetPath,
                          quarterTurns: widget.quarterTurns,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF0A1F4D),
                            alignment: Alignment.center,
                            child: const Text(
                              'BNC',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 28,
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: ShaderMask(
                              blendMode: BlendMode.dstIn,
                              shaderCallback: (bounds) {
                                return const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x00000000),
                                    Color(0x00000000),
                                    Color(0x66FFFFFF),
                                    Color(0xCCFFFFFF),
                                    Color(0xFFFFFFFF),
                                  ],
                                  stops: [0.0, 0.75, 0.84, 0.93, 1.0],
                                ).createShader(bounds);
                              },
                              child: ImageFiltered(
                                imageFilter: ImageFilter.blur(
                                  sigmaX: 14,
                                  sigmaY: 14,
                                  tileMode: TileMode.clamp,
                                ),
                                child: _CardFaceImage(
                                  assetPath: widget.faceAssetPath,
                                  quarterTurns: widget.quarterTurns,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: ShaderMask(
                              blendMode: BlendMode.dstIn,
                              shaderCallback: (bounds) {
                                return const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x00000000),
                                    Color(0x00000000),
                                    Color(0x55FFFFFF),
                                    Color(0xFFFFFFFF),
                                  ],
                                  stops: [0.0, 0.80, 0.90, 1.0],
                                ).createShader(bounds);
                              },
                              child: ImageFiltered(
                                imageFilter: ImageFilter.blur(
                                  sigmaX: 28,
                                  sigmaY: 28,
                                  tileMode: TileMode.clamp,
                                ),
                                child: _CardFaceImage(
                                  assetPath: widget.faceAssetPath,
                                  quarterTurns: widget.quarterTurns,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x0006112E),
                                Color(0x0006112E),
                                Color(0x4006112E),
                                Color(0x9906112E),
                                Color(0xE006112E),
                              ],
                              stops: [0.0, 0.75, 0.84, 0.93, 1.0],
                            ),
                          ),
                        ),
                        // Specular highlight that follows the tilt.
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(
                                  -0.8 + (_ry / _maxTilt) * 0.6,
                                  -1.0 + (_rx / _maxTilt) * 0.4,
                                ),
                                end: Alignment(
                                  0.6 + (_ry / _maxTilt) * 0.4,
                                  0.8,
                                ),
                                colors: [
                                  Colors.white.withValues(
                                    alpha: 0.16 + (_tilting ? 0.06 : 0),
                                  ),
                                  Colors.transparent,
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.35, 1.0],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 10, 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    _Pill(item.kind.label.toUpperCase()),
                                    const SizedBox(width: 6),
                                    _Pill(item.currencyMode.shortLabel),
                                    const Spacer(),
                                    _CardActionButton(
                                      tooltip: 'Ver movimientos',
                                      icon: Icons.receipt_long_outlined,
                                      onPressed: () => widget.onPress(item),
                                    ),
                                    _CardActionButton(
                                      tooltip: 'Editar',
                                      icon: Icons.edit_outlined,
                                      onPressed: () => widget.onEdit(item),
                                    ),
                                    _CardActionButton(
                                      tooltip: 'Eliminar',
                                      icon: Icons.delete_outline,
                                      opacity: 0.85,
                                      onPressed: () => widget.onDelete(item),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.82),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.usageLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.58),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CardFaceImage extends StatelessWidget {
  const _CardFaceImage({
    required this.assetPath,
    required this.quarterTurns,
    this.errorBuilder,
  });

  final String assetPath;
  final int quarterTurns;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      assetPath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: errorBuilder,
    );
    if (quarterTurns == 0) return image;
    return RotatedBox(quarterTurns: quarterTurns, child: image);
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.opacity = 0.95,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.12),
      ),
      icon: Icon(
        icon,
        size: 18,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _LegacyGradientTile extends StatelessWidget {
  const _LegacyGradientTile({
    required this.item,
    required this.usageLabel,
    required this.onPress,
    required this.onEdit,
    required this.onDelete,
  });

  final PaymentCard item;
  final String usageLabel;
  final void Function(PaymentCard item) onPress;
  final void Function(PaymentCard item) onEdit;
  final void Function(PaymentCard item) onDelete;

  @override
  Widget build(BuildContext context) {
    final color = Color(
      int.parse(item.colorHex.replaceFirst('#', 'FF'), radix: 16),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            Color.lerp(color, Colors.black, 0.35)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Pill(item.kind.label.toUpperCase()),
                      const SizedBox(width: 8),
                      _Pill(item.currencyMode.shortLabel),
                      const Spacer(),
                      const SizedBox(width: 120),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.lastFour == null || item.lastFour!.isEmpty
                        ? item.subtitle
                        : '${item.subtitle} · •••• ${item.lastFour}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    usageLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => onPress(item),
                    tooltip: 'Ver movimientos',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.receipt_long_outlined,
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onEdit(item),
                    tooltip: 'Editar',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onDelete(item),
                    tooltip: 'Eliminar',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
