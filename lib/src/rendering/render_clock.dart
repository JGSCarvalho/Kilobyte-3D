import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Drives repaint notifications at a fixed frame rate.
///
/// The [RenderClock] listens to Flutter's V-Sync signal and converts continuous elapsed time into discrete frame
/// intervals.
///
/// Bound listeners are notified only when a new frame interval is reached, allowing rendering workloads to run at a
/// stable frame rate independent of the display refresh frequency.
class RenderClock extends ChangeNotifier {

  /// The target frame rate expressed in frames per second.
  final int fps;

  /// Creates a render clock.
  ///
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [fps]: The desired frame rate. Must be between 1 and 60.
  RenderClock(this.fps) : assert(fps > 0 && fps <= 60, 'FPS must be between 1 and 60!');

  /// Measures elapsed time since the clock was started.
  late final Stopwatch _stopwatch;

  /// Receives callbacks synchronized with the display refresh cycle.
  late final Ticker _ticker;

  /// The duration of a single frame in milliseconds.
  late final double _frameDuration;

  /// The last frame token dispatched to listeners.
  int _lastFrame = -1;

  /// Starts the internal timing loop.
  ///
  /// This method must be called before the clock can begin dispatching repaint notifications.
  ///
  /// ---
  ///
  /// ### Throws:
  ///
  /// - [StateError] if the clock has already been initialized.
  void initialize() {
    _frameDuration = 1000.0 / fps;

    _ticker = Ticker(_tickProcessor);
    _stopwatch = Stopwatch();

    _stopwatch.start();
    _ticker.start();
  }

  /// Processes V-Sync callbacks and dispatches repaint notifications when a new frame interval is reached.
  void _tickProcessor(Duration elapsed) {
    final frame = _token;

    if (frame != _lastFrame) {
      _lastFrame = frame;

      notifyListeners();
    }
  }

  /// A monotonically increasing frame identifier.
  ///
  /// Each frame interval maps to a unique integer token.
  ///
  /// ---
  ///
  /// ### Throws:
  ///
  /// - [LateInitializationError] if accessed before [initialize].
  int get _token => _stopwatch.elapsedMilliseconds ~/ _frameDuration;

  /// Stops the clock and releases all internal resources.
  ///
  /// ---
  ///
  /// ### Throws:
  ///
  /// - [LateInitializationError] if called before [initialize].
  @override
  void dispose() {
    _stopwatch.stop();
    _ticker.dispose();

    super.dispose();
  }
}
