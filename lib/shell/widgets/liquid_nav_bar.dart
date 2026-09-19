import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'dart:ui';
import '../../../core/theme/app_colors.dart';

class LiquidNavBarItem {
  final IconData icon;
  final String label;

  LiquidNavBarItem({required this.icon, required this.label});
}

class LiquidNavBar extends StatefulWidget {
  final List<LiquidNavBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final Color backgroundColor;
  final Color activeColor;
  final Color inactiveColor;

  const LiquidNavBar({
    Key? key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.backgroundColor = Colors.white,
    this.activeColor = AppColors.pujaRed,
    this.inactiveColor = AppColors.mutedGray,
  }) : super(key: key);

  @override
  State<LiquidNavBar> createState() => _LiquidNavBarState();
}

class _LiquidNavBarState extends State<LiquidNavBar> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.selectedIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: _previousIndex.toDouble(), end: widget.selectedIndex.toDouble())
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));
  }

  @override
  void didUpdateWidget(LiquidNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex;
      _startAnimation();
    }
  }

  void _startAnimation() {
    _animation = Tween<double>(begin: _previousIndex.toDouble(), end: widget.selectedIndex.toDouble())
        .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack, // A bouncy curve
    ));
    _animationController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: widget.backgroundColor.withOpacity(0.85),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The animated liquid background
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _LiquidPainter(
                      progress: _animation.value,
                      itemCount: widget.items.length,
                      color: widget.activeColor,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
              // The icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(widget.items.length, (index) {
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (widget.selectedIndex != index) {
                          widget.onItemSelected(index);
                        }
                      },
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          // Calculate how close the current animated position is to this icon's index
                          double distance = (_animation.value - index).abs();
                          double activeFactor = (1 - distance).clamp(0.0, 1.0);
                          
                          // Animate color based on distance
                          Color iconColor = Color.lerp(widget.inactiveColor, Colors.white, activeFactor)!;
                          
                          // Animate Y position (dip down when active)
                          double yOffset = activeFactor * 10.0;
                          
                          return Transform.translate(
                            offset: Offset(0, yOffset),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget.items[index].icon,
                                  color: iconColor,
                                  size: 24,
                                ),
                                if (activeFactor < 0.5) // Only show text when not fully active to save space
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      widget.items[index].label,
                                      style: TextStyle(
                                        color: iconColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final double progress;
  final int itemCount;
  final Color color;

  _LiquidPainter({
    required this.progress,
    required this.itemCount,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Width of each item segment
    final segmentWidth = size.width / itemCount;
    
    // The exact center X coordinate of the current active progress
    final centerX = (progress * segmentWidth) + (segmentWidth / 2);

    final path = Path();
    
    // Start at top left
    path.moveTo(0, 0);
    
    // Define the drop dimensions
    final dropWidth = segmentWidth * 0.8;
    final dropDepth = 55.0; // How deep the drop goes

    // Draw top edge until the drop
    path.lineTo(centerX - dropWidth, 0);

    // Draw the cubic bezier for the left side of the drop
    path.cubicTo(
      centerX - (dropWidth * 0.5), 0, // Control point 1
      centerX - (dropWidth * 0.4), dropDepth, // Control point 2
      centerX, dropDepth, // End point (bottom center of drop)
    );

    // Draw the cubic bezier for the right side of the drop
    path.cubicTo(
      centerX + (dropWidth * 0.4), dropDepth, // Control point 1
      centerX + (dropWidth * 0.5), 0, // Control point 2
      centerX + dropWidth, 0, // End point
    );

    // Draw top edge to the end
    path.lineTo(size.width, 0);
    
    // Draw the rest of the rectangle
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // The logic above draws a "dip" from the top. We want the drop to be a solid shape that comes from the top?
    // Wait, if it's a liquid navbar, usually the *active* indicator is a shape that bubbles UP, or the background has a dip.
    // Let's invert the path so the background is mostly transparent, and we just draw the "bubble".
    // Alternatively, just draw a drop shape.
    
    // Let's do a bubble that hangs down from the top edge.
    // Actually, drawing just the bubble shape is easier:
    final bubblePath = Path();
    bubblePath.moveTo(centerX - dropWidth, 0);
    bubblePath.cubicTo(
      centerX - (dropWidth * 0.4), 0,
      centerX - (dropWidth * 0.4), dropDepth * 0.9,
      centerX, dropDepth * 0.9,
    );
    bubblePath.cubicTo(
      centerX + (dropWidth * 0.4), dropDepth * 0.9,
      centerX + (dropWidth * 0.4), 0,
      centerX + dropWidth, 0,
    );
    bubblePath.close();

    canvas.drawPath(bubblePath, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.itemCount != itemCount ||
           oldDelegate.color != color;
  }
}
