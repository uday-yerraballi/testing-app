import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minimal Toggle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const ToggleScreen(),
    );
  }
}

class ToggleScreen extends StatefulWidget {
  const ToggleScreen({super.key});

  @override
  State<ToggleScreen> createState() => _ToggleScreenState();
}

class _ToggleScreenState extends State<ToggleScreen>
    with SingleTickerProviderStateMixin {
  // State variables
  bool _isOn = false;
  double _dragAlignment = -1.0; // -1.0 is Left (Off), 1.0 is Right (On)
  
  // Animation controller for snapping
  late AnimationController _controller;
  late Animation<double> _animation;

  // Constants for design
  static const double _width = 300.0;
  static const double _height = 100.0;
  static const double _thumbPadding = 8.0;
  // Thumb size is height - padding * 2
  static const double _thumbSize = _height - (_thumbPadding * 2); 
  
  // Colors
  // Green accent
  static const Color _activeColor = Color(0xFF34C759); 
  // Neural gray
  static const Color _inactiveColor = Color(0xFFE5E5EA); 
  // Darker gray for inactive track to ensure contrast
  static const Color _inactiveTrackColor = Color(0xFFD1D1D6); 
  
  // Background Colors
  static const Color _activeBg = Color(0xFFF0FDF4); // Very light green
  static const Color _inactiveBg = Color(0xFFF2F2F7); // Neutral gray

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _controller.addListener(() {
      setState(() {
        _dragAlignment = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Calculate generic 0.0 to 1.0 progress based on alignment (-1.0 to 1.0)
  double get _progress => (_dragAlignment + 1.0) / 2.0;

  void _onPanDown(DragDownDetails details) {
    _controller.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      // Convert drag delta to alignment delta
      // Track width available for movement is _width - _thumbSize - (_thumbPadding * 2)
      // Actually simpler: The alignment -1 to 1 maps to the travel distance.
      // Travel distance = _width - _height (since thumb is roughly height)
      // Let's approximate for smoother feel: map width to alignment range 2.0
      
      double deltaAlignment = (details.delta.dx / (_width / 2.5)); 
      _dragAlignment += deltaAlignment;
      _dragAlignment = _dragAlignment.clamp(-1.0, 1.0);
      
      // Update state visually based on threshold during drag? 
      // User requested "snap-to-state behavior when dragged past 50% threshold"
      // We will handle the actual boolean flip in onPanEnd.
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // Snap logic
    // If we passed the middle (0.0), toggle.
    // Also consider velocity for a "flick"
    bool targetState = _isOn;
    
    // Velocity threshold to detect flick
    double velocity = details.velocity.pixelsPerSecond.dx;
    
    if (velocity > 500) {
      targetState = true;
    } else if (velocity < -500) {
      targetState = false;
    } else {
      // Positional threshold
      targetState = _dragAlignment > 0.0;
    }

    _animateToState(targetState);
  }

  void _toggle() {
    _animateToState(!_isOn);
  }

  void _animateToState(bool targetIsOn) {
    final double targetAlign = targetIsOn ? 1.0 : -1.0;
    
    if (_isOn != targetIsOn) {
      HapticFeedback.lightImpact();
    }
    
    _isOn = targetIsOn;
    
    _animation = _controller.drive(Tween<double>(
      begin: _dragAlignment,
      end: targetAlign,
    ).chain(CurveTween(curve: Curves.easeOutBack))); // subtle bounce on release

    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    
    // Interpolate colors based on drag position for smooth transitions
    final Color trackColor = Color.lerp(
      _inactiveTrackColor, 
      _activeColor, 
      _progress
    )!;

    final Color bgColor = Color.lerp(
      _inactiveBg, 
      _activeBg, 
      _progress
    )!;
    
    // Shadow intensity can also peak during interaction
    final double shadowElevation = 10.0 + (5.0 * (1.0 - _dragAlignment.abs()));

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: GestureDetector(
          onTap: _toggle,
          onHorizontalDragDown: _onPanDown,
          onHorizontalDragUpdate: _onPanUpdate,
          onHorizontalDragEnd: _onPanEnd,
          child: Container(
            width: _width,
            height: _height,
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(_height / 2),
              boxShadow: [
                BoxShadow(
                  color: trackColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // The Thumb
                Align(
                  alignment: Alignment(_dragAlignment, 0.0),
                  child: Padding(
                    padding: const EdgeInsets.all(_thumbPadding),
                    child: Container(
                      width: _thumbSize,
                      height: _thumbSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
