import 'package:badges/badges.dart' as bdg;
import 'package:flutter/material.dart';
import 'package:easy_sidemenu/src/side_menu_display_mode.dart';
import 'global/global.dart';
import 'package:easy_sidemenu/src/side_menu_controller.dart';

typedef SideMenuItemBuilder = Widget Function(
    BuildContext context, SideMenuDisplayMode displayMode);

class SideMenuItemList {
  late List<dynamic> items;
}

class SideMenuItemWithGlobal extends StatefulWidget {
  /// #### Side Menu Item
  ///
  /// This is a widget for use in [SideMenu] as items, with text and icon(s).
  ///
  /// - If **activeIcon** and **inactiveIcon** are provided, they will be used
  ///   to represent the selected and non-selected states, respectively.
  /// - If you only provide one of them, the other will remain `null` and will not be shown.
  /// - If both are null, but you have an [iconWidget], that widget will be shown.
  /// - If you want complete customization, use [builder].
  const SideMenuItemWithGlobal({
    Key? key,
    required this.global,
    this.onTap,
    this.title,
    this.activeIcon,
    this.inactiveIcon,
    this.iconWidget,
    this.badgeContent,
    this.badgeColor,
    this.tooltipContent,
    this.trailing,
    this.builder,
  })  : assert(
  title != null || activeIcon != null || inactiveIcon != null || builder != null,
  'At least a title, or some icon (activeIcon/inactiveIcon), or a builder is required',
  ),
        super(key: key);

  /// A function called when the user taps on the [SideMenuItemWithGlobal]
  final void Function(int index, SideMenuController sideMenuController)? onTap;

  /// [SideMenu]'s global object
  final Global global;

  /// Title text
  final String? title;

  /// Icon to display when this item is selected/active
  final Icon? activeIcon;

  /// Icon to display when this item is non-selected/inactive
  final Icon? inactiveIcon;

  /// If you need to display a completely custom icon,
  /// provide this [Widget]. If [activeIcon] and [inactiveIcon] are null,
  /// `iconWidget` will be displayed.
  final Widget? iconWidget;

  /// Text shown as a “badge” next to the icon (e.g., notification count)
  final Widget? badgeContent;

  /// Background color for the badge
  final Color? badgeColor;

  /// The tooltip text (shown when in “compact” mode and
  /// [showTooltipOverItemsName] is `true`).
  final String? tooltipContent;

  /// A widget displayed after the item's title (e.g., a chevron).
  final Widget? trailing;

  /// To create a completely custom item, use this builder, which
  /// takes `(BuildContext context, SideMenuDisplayMode displayMode)`.
  final SideMenuItemBuilder? builder;

  @override
  State<SideMenuItemWithGlobal> createState() => _SideMenuItemState();
}

class _SideMenuItemState extends State<SideMenuItemWithGlobal> {
  late int currentPage = widget.global.controller.currentPage;
  bool isHovered = false;
  bool isDisposed = false;

  @override
  void initState() {
    super.initState();
    _nonNullableWrap(WidgetsBinding.instance)!
        .addPostFrameCallback((timeStamp) {
      // Set initialPage only if the widget is still mounted
      if (mounted) {
        currentPage = widget.global.controller.currentPage;
      }
      if (!isDisposed) {
        // Bind controller callback
        widget.global.controller.addListener(_handleChange);
      }
    });
    widget.global.itemsUpdate.add(update);
  }

  void update() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    isDisposed = true;
    widget.global.controller.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange(int page) {
    safeSetState(() {
      currentPage = page;
    });
  }

  /// Ensure setState is only called if the widget is still mounted
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  bool isSameWidget(SideMenuItemWithGlobal other) {
    return (other.inactiveIcon == widget.inactiveIcon &&
        other.activeIcon == widget.activeIcon &&
        other.title == widget.title &&
        other.builder == widget.builder &&
        other.trailing == widget.trailing);
  }

  T? _nonNullableWrap<T>(T? value) => value;

  int _getIndexOfCurrentSideMenuItemWidget() {
    int index = 0;
    int n = widget.global.items.length;
    for (int i = 0; i < n; i++) {
      if (widget.global.items[i] is SideMenuItemWithGlobal) {
        if (isSameWidget(widget.global.items[i])) {
          return index;
        } else {
          index = index + 1;
        }
      } else {
        int m = widget.global.items[i].children.length;
        for (int j = 0; j < m; j++) {
          if (isSameWidget(widget.global.items[i].children[j])) {
            return index;
          } else {
            index = index + 1;
          }
        }
      }
    }
    return -1;
  }

  /// Return the background color of the [SideMenuItemWithGlobal]
  Color _setColor() {
    if (_getIndexOfCurrentSideMenuItemWidget() == currentPage) {
      // Selected item
      if (isHovered) {
        return widget.global.style.selectedHoverColor ??
            widget.global.style.selectedColor ??
            Theme.of(context).highlightColor;
      } else {
        return widget.global.style.selectedColor ??
            Theme.of(context).highlightColor;
      }
    } else if (isHovered) {
      // Hover, but not selected
      return widget.global.style.hoverColor ?? Colors.transparent;
    } else {
      return Colors.transparent;
    }
  }

  /// Generates the icon according to [mainIcon] or [iconWidget].
  /// If mainIcon is `null`, it returns [iconWidget] or an empty SizedBox.
  /// If [badgeContent] is provided, wraps the icon with a Badge widget.
  Widget _generateIcon(Icon? mainIcon, Widget? iconWidget) {
    if (mainIcon == null) {
      return iconWidget ?? const SizedBox();
    }

    // Determine icon color and size depending on whether it's selected
    final Color iconColor = _isCurrentSideMenuItemSelected()
        ? widget.global.style.selectedIconColor ?? Colors.black
        : widget.global.style.unselectedIconColor ?? Colors.black54;
    final double iconSize = widget.global.style.iconSize ?? 24;

    final Icon icon = Icon(
      mainIcon.icon,
      color: iconColor,
      size: iconSize,
    );

    // If there is badgeContent, show the icon inside a Badge
    if (widget.badgeContent != null) {
      return bdg.Badge(
        badgeContent: widget.badgeContent!,
        badgeStyle: bdg.BadgeStyle(
          badgeColor: widget.badgeColor ?? Colors.red,
        ),
        position: bdg.BadgePosition.topEnd(top: -13, end: -7),
        child: icon,
      );
    } else {
      return icon;
    }
  }

  bool _isCurrentSideMenuItemSelected() {
    return _getIndexOfCurrentSideMenuItemWidget() == currentPage;
  }

  @override
  Widget build(BuildContext context) {
    // If a custom builder is provided, skip the default build
    if (widget.builder != null) {
      return ValueListenableBuilder(
        valueListenable: widget.global.displayModeState,
        builder: (context, value, child) {
          return widget.builder!(context, value as SideMenuDisplayMode);
        },
      );
    }

    return InkWell(
      onTap: () => widget.onTap?.call(
        _getIndexOfCurrentSideMenuItemWidget(),
        widget.global.controller,
      ),
      onHover: (value) {
        safeSetState(() {
          isHovered = value;
        });
      },
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Padding(
        padding: widget.global.style.itemOuterPadding,
        child: Container(
          height: widget.global.style.itemHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _setColor(),
            borderRadius: widget.global.style.itemBorderRadius,
          ),
          child: ValueListenableBuilder(
            valueListenable: widget.global.displayModeState,
            builder: (context, value, child) {
              final displayMode = value as SideMenuDisplayMode;

              return Tooltip(
                message: (displayMode == SideMenuDisplayMode.compact &&
                    widget.global.style.showTooltip)
                    ? widget.tooltipContent ?? widget.title ?? ""
                    : "",
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: widget.global.style.itemInnerSpacing,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: widget.global.style.itemInnerSpacing * 2,
                      ),

                      /// Here we define which icon to display:
                      /// activeIcon if the item is selected, otherwise inactiveIcon.
                      _generateIcon(
                        _isCurrentSideMenuItemSelected()
                            ? widget.activeIcon
                            : widget.inactiveIcon,
                        widget.iconWidget,
                      ),

                      SizedBox(width: widget.global.style.itemInnerSpacing),

                      if (displayMode == SideMenuDisplayMode.open) ...[
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.title ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: _isCurrentSideMenuItemSelected()
                                  ? const TextStyle(
                                  fontSize: 17, color: Colors.black)
                                  .merge(widget
                                  .global.style.selectedTitleTextStyle)
                                  : const TextStyle(
                                  fontSize: 17, color: Colors.black54)
                                  .merge(widget.global.style
                                  .unselectedTitleTextStyle),
                            ),
                          ),
                        ),
                        const SizedBox.shrink(),
                        if (widget.trailing != null &&
                            widget.global.showTrailing) ...[
                          Flexible(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: widget.trailing!,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
