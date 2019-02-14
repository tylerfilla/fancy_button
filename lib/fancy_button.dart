/*
 * Copyright (c) 2019 Tyler Filla
 *
 * This software is provided 'as-is', without any express or implied
 * warranty. In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would
 *    be appreciated but is not required.
 *
 * 2. Altered source versions must be plainly marked as such, and must not
 *    be misrepresented as being the original software.
 *
 * 3. This notice may not be removed or altered from any source
 *    distribution.
 */

library fancy_button;

import 'package:flutter/material.dart';

/// The pose of a fancy button.
enum FancyButtonPose {
  /// The button is hidden from view.
  hidden,

  /// The button is shown, and only its icon is visible.
  shown_icon,

  /// The button is shown, and only its text label is visible.
  shown_label,

  /// The button is shown, and its icon and text label are visible.
  shown_icon_and_label,
}

/// A fancy button :)
///
/// This is a custom implementation of Material Design's floating action button
/// (FAB) with better support for its fancy animations between states than the
/// built-in [FloatingActionButton] implementation.
class FancyButton extends StatefulWidget {
  /// The background color. This is used for the button surface.
  ///
  /// By default, the inherited theme's accent color is used.
  final Color backgroundColor;

  /// The foreground color. This is used for the icon and text label.
  ///
  /// By default, the inherited theme's accent icon color is used.
  final Color foregroundColor;

  /// The child icon widget.
  ///
  /// At least one of [icon] and [label] must be non-null.
  final Widget icon;

  /// The child label widget.
  ///
  /// At least one of [icon] and [label] must be non-null.
  final Widget label;

  /// The initial pose.
  ///
  /// By default, this is [FancyButtonPose.shown_icon].
  final FancyButtonPose initialPose;

  /// The button pressed callback.
  ///
  /// This is triggered after a full touch-down/touch-up cycle. See the
  /// [onTouchDown] and [onTouchUp] callbacks for specifics on those events.
  final VoidCallback onPressed;

  /// The button touch down callback.
  ///
  /// This is triggered when the user places their finger on the button.
  final VoidCallback onTouchDown;

  /// The button touch up callback.
  ///
  /// This is triggered when the user releases their finger from the button.
  final VoidCallback onTouchUp;

  FancyButton({
    Key key,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.label,
    this.initialPose = FancyButtonPose.shown_icon,
    this.onPressed,
    this.onTouchDown,
    this.onTouchUp,
  })  : assert((icon ?? label) != null, 'one of icon and label must be non-null'),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FancyButtonState();
  }
}

/// State and control for a fancy button.
class FancyButtonState extends State<FancyButton> with SingleTickerProviderStateMixin {
  /// The pose animation controller.
  AnimationController _poseAnimation;

  /// The current pose.
  FancyButtonPose _poseCurrent;

  /// The previous pose.
  FancyButtonPose _posePrevious;

  @override
  void initState() {
    super.initState();

    // Initialize pose animation
    _poseAnimation = AnimationController(
      vsync: this,
      // TODO: Eventually, we might want to break this out
      duration: const Duration(milliseconds: 233),
    )..addListener(() => setState(() {}));

    // Initialize pose
    // TODO: This hardcodes an entrance animation (we might not want this)
    _poseCurrent = FancyButtonPose.hidden;
    pose = widget.initialPose;
  }

  @override
  void dispose() {
    _poseAnimation.dispose();
    super.dispose();
  }

  /// Get the current pose.
  get pose => _poseCurrent;

  /// Set the current pose.
  set pose(FancyButtonPose pose) {
    // If this pose is already current, do nothing
    if (pose == _poseCurrent) return;

    // Update pose state
    setState(() {
      _posePrevious = _poseCurrent;
      _poseCurrent = pose;
    });

    // Start the transition animation
    _poseAnimation.forward(from: 0);
  }

  /// Called when the highlight state of the button ink well changes. This is
  /// used to drive the touch-down and touch-up events of the fancy button.
  void _onInkWellHighlightChanged(bool value) {
    if (value) {
      if (widget.onTouchDown != null) {
        widget.onTouchDown();
      }
    } else {
      if (widget.onTouchUp != null) {
        widget.onTouchUp();
      }
    }
  }

  /// Called when the button ink well is tapped. This is used to drive the
  /// pressed event of the fancy button. Also, by supplying an internal callback
  /// for the ink well's tap event, the ink well is permanently enabled
  /// regardless of the user's choice to supply a pressed callback to the fancy
  /// button.
  void _onInkWellTap() {
    if (widget.onPressed != null) {
      widget.onPressed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bg = widget.backgroundColor ?? theme.accentColor;
    final fg = widget.foregroundColor ?? theme.accentIconTheme.color;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0, maxHeight: 48.0),
      child: Material(
        color: bg,
        elevation: 6.0,
        shape: const StadiumBorder(),
        type: MaterialType.button,
        textStyle: theme.accentTextTheme.button.copyWith(
          color: fg,
          letterSpacing: 1.2,
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onHighlightChanged: _onInkWellHighlightChanged,
          onTap: _onInkWellTap,
          child: _FancyButtonCore(
            icon: widget.icon == null
                ? null
                : IconTheme.merge(
                    data: theme.accentIconTheme.copyWith(color: fg),
                    child: widget.icon,
                  ),
            label: widget.label,
            toPose: _poseCurrent,
            fromPose: _posePrevious,
            progress: _poseAnimation.value,
          ),
        ),
      ),
    );
  }
}

/// The core of a fancy button.
///
/// This widget combines the icon and label of a Material Design-style floating
/// action button (FAB) into a single "core" evaluated at an instant in time.
/// Transitions involving complex icon-label interactions for different combos
/// of leading/lagging poses are processed by this widget using a collection of
/// independent tweens solved at a single, given progress value.
///
/// When creating this widget, pass in the from (lagging) and to (leading) poses
/// in the current transition, if applicable, as well as the progress (from zero
/// to one, inclusive) of the transition. If no transition is in progress, pass
/// in a progress of zero and ignore the from (lagging) pose. Consequently, the
/// from (lagging) pose is optional. The core widget will solve for the given
/// progress between the two given poses (or, degenerately, the one given pose).
///
/// The core has two user-facing children:
///   - Icon widget
///   - Label widget
///
/// These are both widgets supplied to the core constructor.
///
/// The core layout thus has five abstract regions that influence its visuals:
///   - Padding
///   - Icon widget
///   - Padding
///   - Label widget
///   - Padding
///
/// These three regions of padding are not represented by physical widgets, but
/// they are animated during pose transitions all the same.
///
/// For implementation's sake, the center padding is split into six concrete
/// elements yielding the following layout:
///   - Padding A
///   - Icon widget
///   - Padding B
///   - Padding C
///   - Label widget
///   - Padding D
///
/// This differentiation between paddings B and C is hopefully not perceptible
/// for the end user (although, with a nonlinear motion curve, there *is* a
/// difference...but it's small :). Anyway, it helps us make another logical
/// leap to further divide and conquer the animation problem...
///
/// These six concrete elements of the layout are then split into two groups:
///   - Group 1
///     - Padding A
///     - Icon widget
///     - Padding B
///   - Group 2
///     - Padding C
///     - Label widget
///     - Padding D
///
/// This split establishes a semantic boundary between the icon, its padding,
/// the label, and the label's padding. This makes animating in/out either the
/// icon or the widget, with its respective padding, pretty easy.
class _FancyButtonCore extends StatelessWidget {
  /// The button icon.
  ///
  /// At least one of [icon] and [label] must be non-null.
  final Widget icon;

  /// The button label.
  ///
  /// At least one of [icon] and [label] must be non-null.
  final Widget label;

  /// The leading pose in the current transition.
  final FancyButtonPose toPose;

  /// The lagging pose in the current transition.
  ///
  /// This is ignored if, and only if, progress is zero.
  final FancyButtonPose fromPose;

  /// The progress of the current transition.
  final double progress;

  _FancyButtonCore({
    Key key,
    this.icon,
    this.label,
    @required this.toPose,
    this.fromPose,
    @required this.progress,
  })  : // Assert one of icon and/or label non-null
        assert((icon ?? label) != null),
        // Assert fromPose non-null when progress > 0
        assert((progress == 0 ? progress : fromPose) != null),
        super(key: key);

  /// Compute the width factor of group 1.
  double _computeWidthFactor1() {
    return 1.0;
  }

  /// Compute the width factor of group 2.
  double _computeWidthFactor2() {
    return 1.0;
  }

  /// Compute the opacity of group 1.
  double _computeOpacity1() {
    return 1.0;
  }

  /// Compute the opacity of group 2.
  double _computeOpacity2() {
    return 1.0;
  }

  /// Compute padding A.
  double _computePaddingA() {
    return 12.0;
  }

  /// Compute padding B.
  double _computePaddingB() {
    return 6.0;
  }

  /// Compute padding C.
  double _computePaddingC() {
    return 6.0;
  }

  /// Compute padding D.
  double _computePaddingD() {
    return 20.0;
  }

  /// Build the group 1 widget.
  Widget _buildGroup1() {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      widthFactor: _computeWidthFactor1(),
      child: Container(
        padding: EdgeInsets.only(
          left: _computePaddingA(),
          right: _computePaddingB(),
        ),
        child: Opacity(
          opacity: _computeOpacity1(),
          child: icon,
        ),
      ),
    );
  }

  /// Build the group 2 widget.
  Widget _buildGroup2() {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: _computeWidthFactor2(),
      child: Container(
        padding: EdgeInsets.only(
          left: _computePaddingC(),
          right: _computePaddingD(),
        ),
        child: Opacity(
          opacity: _computeOpacity2(),
          child: label,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildGroup1(),
        _buildGroup2(),
      ],
    );
  }
}
