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
  /// The child icon widget.
  ///
  /// At least one of [icon] and [label] must be non-null.
  final Widget icon;

  /// The child label widget.
  ///
  /// At least one of [icon] and [label] must be non-null.
  final Widget label;

  FancyButton({
    Key key,
    this.icon,
    this.label,
  })  : assert((icon ?? label) != null, 'one of icon and label must be non-null'),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _FancyButtonState();
  }
}

/// State for a fancy button.
class _FancyButtonState extends State<FancyButton> {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(width: 56.0, height: 56.0),
      child: Material(
        color: Colors.white,
        elevation: 6.0,
        shape: const CircleBorder(),
        type: MaterialType.button,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(child: widget.icon),
            Container(child: widget.label),
          ],
        ),
      ),
    );
  }
}
