import 'package:flutter/material.dart';

import '../theme/motion_scheme.dart';
/// A Material 3 split button with a primary action and a dropdown menu.
///
/// Uses proper Material 3 styling with rounded shape, tonal elevation,
/// and proper ripple effects instead of manual Container + InkWell layering.
class SplitButton extends StatefulWidget {
  const SplitButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.menuItems,
    this.icon,
    this.enabled = true,
    this.size = SplitButtonSize.small,
  });

  final String label;
  final VoidCallback? onPressed;
  final List<SplitButtonMenuItem> menuItems;
  final IconData? icon;
  final bool enabled;
  final SplitButtonSize size;

  @override
  State<SplitButton> createState() => _SplitButtonState();
}

class _SplitButtonState extends State<SplitButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _menuController;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final buttonHeight = _getHeight();
    final labelStyle = _getLabelStyle(textTheme);
    final iconSize = _getIconSize();
    final horizontalPad = _getHorizontalPadding();

    final foreground = widget.enabled
        ? colorScheme.onPrimary
        : colorScheme.onSurface.withOpacity(0.38);
    final background = widget.enabled
        ? colorScheme.primary
        : colorScheme.onSurface.withOpacity(0.12);

    return MenuAnchor(
      onOpen: () => _menuController.forward(),
      onClose: () => _menuController.reverse(),
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevation: const WidgetStatePropertyAll(3),
      ),
      menuChildren: widget.menuItems
          .map(
            (item) => MenuItemButton(
              leadingIcon: item.icon != null
                  ? Icon(item.icon, size: 20)
                  : null,
              style: MenuItemButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: item.onPressed,
              child: Text(item.label),
            ),
          )
          .toList(),
      builder: (context, controller, child) {
        return Material(
          color: background,
          borderRadius: BorderRadius.circular(buttonHeight / 2),
          elevation: widget.enabled ? 1 : 0,
          shadowColor: colorScheme.shadow.withOpacity(0.3),
          child: InkWell(
            onTap: widget.enabled ? widget.onPressed : null,
            borderRadius: BorderRadius.circular(buttonHeight / 2),
            splashColor: colorScheme.onPrimary.withOpacity(0.12),
            highlightColor: colorScheme.onPrimary.withOpacity(0.08),
            child: SizedBox(
              height: buttonHeight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Primary action area ──
                  Padding(
                    padding: EdgeInsets.only(
                      left: horizontalPad,
                      right: horizontalPad * 0.6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: foreground, size: iconSize),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: labelStyle.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Divider ──
                  Container(
                    width: 1,
                    height: buttonHeight * 0.5,
                    decoration: BoxDecoration(
                      color: foreground.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(0.5),
                    ),
                  ),

                  // ── Menu toggle ──
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.enabled
                          ? () {
                              if (controller.isOpen) {
                                controller.close();
                              } else {
                                controller.open();
                              }
                            }
                          : null,
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(buttonHeight / 2),
                      ),
                      splashColor: colorScheme.onPrimary.withOpacity(0.12),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPad * 0.6,
                        ),
                        child: SizedBox(
                          height: buttonHeight,
                          child: Center(
                            child: RotationTransition(
                              turns: Tween<double>(begin: 0, end: 0.5).animate(
                                CurvedAnimation(
                                  parent: _menuController,
                                  curve: MotionScheme.spatialFast,
                                ),
                              ),
                              child: Icon(
                                Icons.arrow_drop_down,
                                color: foreground,
                                size: iconSize + 4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _getHeight() {
    switch (widget.size) {
      case SplitButtonSize.extraSmall:
        return 32;
      case SplitButtonSize.small:
        return 40;
      case SplitButtonSize.medium:
        return 48;
      case SplitButtonSize.large:
        return 56;
      case SplitButtonSize.extraLarge:
        return 64;
    }
  }

  double _getHorizontalPadding() {
    switch (widget.size) {
      case SplitButtonSize.extraSmall:
        return 14;
      case SplitButtonSize.small:
        return 18;
      case SplitButtonSize.medium:
        return 22;
      case SplitButtonSize.large:
        return 26;
      case SplitButtonSize.extraLarge:
        return 30;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case SplitButtonSize.extraSmall:
        return 16;
      case SplitButtonSize.small:
        return 18;
      case SplitButtonSize.medium:
        return 20;
      case SplitButtonSize.large:
        return 22;
      case SplitButtonSize.extraLarge:
        return 24;
    }
  }

  TextStyle _getLabelStyle(TextTheme textTheme) {
    switch (widget.size) {
      case SplitButtonSize.extraSmall:
        return textTheme.labelSmall!;
      case SplitButtonSize.small:
        return textTheme.labelLarge!;
      case SplitButtonSize.medium:
        return textTheme.labelLarge!;
      case SplitButtonSize.large:
        return textTheme.titleSmall!;
      case SplitButtonSize.extraLarge:
        return textTheme.titleMedium!;
    }
  }
}

class SplitButtonMenuItem {
  const SplitButtonMenuItem({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
}

enum SplitButtonSize { extraSmall, small, medium, large, extraLarge }
