import 'package:flutter/material.dart';

/// A Material 3 split button with a primary action and a menu of additional options.
///
/// Follows M3 Expressive design guidelines for split buttons.
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
      duration: const Duration(milliseconds: 150),
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
    final horizontalPadding = _getHorizontalPadding();
    final labelStyle = _getLabelStyle(textTheme);

    return MenuAnchor(
      onOpen: () {
        _menuController.forward();
      },
      onClose: () {
        _menuController.reverse();
      },
      alignmentOffset: const Offset(0, 4),
      menuChildren: widget.menuItems
          .map(
            (item) => MenuItemButton(
              leadingIcon: item.icon != null ? Icon(item.icon) : null,
              onPressed: item.onPressed,
              child: Text(item.label),
            ),
          )
          .toList(),
      builder: (context, controller, child) {
        return Container(
          height: buttonHeight,
          decoration: BoxDecoration(
            color: widget.enabled
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Leading button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.enabled ? widget.onPressed : null,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: widget.enabled
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface.withValues(alpha: 0.38),
                            size: _getIconSize(),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: labelStyle.copyWith(
                            color: widget.enabled
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface.withValues(alpha: 0.38),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Divider
              Container(
                width: 1,
                height: buttonHeight * 0.6,
                color: widget.enabled
                    ? colorScheme.onPrimary.withValues(alpha: 0.3)
                    : colorScheme.onSurface.withValues(alpha: 0.12),
              ),
              // Trailing button (menu)
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
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding * 0.7,
                      vertical: 12,
                    ),
                    child: RotationTransition(
                      turns: Tween<double>(begin: 0, end: 0.5).animate(
                        CurvedAnimation(
                          parent: _menuController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Icon(
                        Icons.expand_more,
                        color: widget.enabled
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface.withValues(alpha: 0.38),
                        size: _getIconSize(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
        return 12;
      case SplitButtonSize.small:
        return 16;
      case SplitButtonSize.medium:
        return 20;
      case SplitButtonSize.large:
        return 24;
      case SplitButtonSize.extraLarge:
        return 28;
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
