import 'dart:math' as math;
import 'package:easy_table/src/internal/row_callbacks.dart';
import 'package:easy_table/src/internal/table_layout_builder.dart';
import 'package:easy_table/src/internal/table_scroll_controllers.dart';
import 'package:easy_table/src/internal/theme_metrics/theme_metrics.dart';
import 'package:easy_table/src/last_row_widget_listener.dart';
import 'package:easy_table/src/model.dart';
import 'package:easy_table/src/last_visible_row_listener.dart';
import 'package:easy_table/src/row_callback_typedefs.dart';
import 'package:easy_table/src/row_color.dart';
import 'package:easy_table/src/row_hover_listener.dart';
import 'package:easy_table/src/theme/theme.dart';
import 'package:easy_table/src/theme/theme_data.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Table view designed for a large number of data.
///
/// The type [ROW] represents the data of each row.
/// The [cellContentHeight] is mandatory due to performance.
/// The total height of the cell will be the sum of the [cellContentHeight]
/// value, divider thickness, and cell margin.
class EasyTable<ROW> extends StatefulWidget {
//TODO handle negative values
//TODO allow null and use defaults?
  const EasyTable(this.model,
      {Key? key,
      this.onHover,
      this.unpinnedHorizontalScrollController,
      this.pinnedHorizontalScrollController,
      this.verticalScrollController,
      this.onLastVisibleRow,
      this.onRowTap,
      this.onRowSecondaryTap,
      this.onRowDoubleTap,
      this.columnsFit = false,
      int? visibleRowsCount,
      this.focusable = true,
      this.multiSort = false,
      this.lastRowWidget,
      this.rowColor,
      this.onLastRowWidget})
      : _visibleRowsCount = visibleRowsCount == null || visibleRowsCount > 0
            ? visibleRowsCount
            : null,
        super(key: key);

  final EasyTableModel<ROW>? model;
  final ScrollController? unpinnedHorizontalScrollController;
  final ScrollController? pinnedHorizontalScrollController;
  final ScrollController? verticalScrollController;
  final OnRowHoverListener? onHover;
  final EasyTableRowColor<ROW>? rowColor;
  final RowDoubleTapCallback<ROW>? onRowDoubleTap;
  final RowTapCallback<ROW>? onRowTap;
  final RowTapCallback<ROW>? onRowSecondaryTap;
  final bool columnsFit;
  final int? _visibleRowsCount;
  final OnLastVisibleRowListener? onLastVisibleRow;
  final bool focusable;
  final bool multiSort;
  final Widget? lastRowWidget;
  final OnLastRowWidgetListener? onLastRowWidget;

  int? get visibleRowsCount => _visibleRowsCount;

  @override
  State<StatefulWidget> createState() => _EasyTableState<ROW>();
}

/// The [EasyTable] state.
class _EasyTableState<ROW> extends State<EasyTable<ROW>> {
  late final TableScrollControllers _scrollControllers;

  bool _scrolling = false;

  int? _hoveredRowIndex;

  bool _lastRowWidgetVisible = false;
  int _lastVisibleRow = -1;
  final FocusNode _focusNode = FocusNode(debugLabel: 'EasyTable');

  void _setHoveredRowIndex(int? rowIndex) {
    if (widget.model != null && _hoveredRowIndex != rowIndex) {
      _hoveredRowIndex = rowIndex;
      if (widget.onHover != null) {
        widget.onHover!(_hoveredRowIndex);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollControllers = TableScrollControllers(
        vertical: widget.verticalScrollController,
        unpinnedHorizontal: widget.unpinnedHorizontalScrollController,
        leftPinnedHorizontal: widget.pinnedHorizontalScrollController);
    widget.model?.addListener(_rebuild);
    _scrollControllers.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.model?.dispose();
    _focusNode.dispose();
    _scrollControllers.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EasyTable<ROW> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model?.removeListener(_rebuild);
      widget.model?.addListener(_rebuild);
    }
    if (widget.verticalScrollController != null) {
      _scrollControllers.setVerticalScrollController(
          scrollController: widget.verticalScrollController!,
          listener: _rebuild);
    }
    if (widget.unpinnedHorizontalScrollController != null) {
      _scrollControllers.setUnpinnedScrollController(
          scrollController: widget.unpinnedHorizontalScrollController!,
          listener: _rebuild);
    }
    if (widget.pinnedHorizontalScrollController != null) {
      _scrollControllers.setLeftPinnedScrollController(
          scrollController: widget.pinnedHorizontalScrollController!,
          listener: _rebuild);
    }
  }

  void _onLastRowWidget(bool visible) {
    if (widget.onLastRowWidget != null) {
      if (_lastRowWidgetVisible != visible) {
        _lastRowWidgetVisible = visible;
        Future.microtask(() => widget.onLastRowWidget!(_lastRowWidgetVisible));
      }
    }
  }

  void _onLastVisibleRowListener(int lastVisibleRowIndex) {
    if (widget.onLastVisibleRow != null) {
      if (_lastVisibleRow != lastVisibleRowIndex) {
        _lastVisibleRow = lastVisibleRowIndex;
        Future.microtask(() => widget.onLastVisibleRow!(lastVisibleRowIndex));
      }
    }
  }

  void _rebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final EasyTableThemeData theme = EasyTableTheme.of(context);

    final TableThemeMetrics themeMetrics = TableThemeMetrics(theme);

    Widget table = ClipRect(
        child: TableLayoutBuilder(
            onHover: widget.onHover != null ? _setHoveredRowIndex : null,
            multiSort: widget.multiSort,
            scrollControllers: _scrollControllers,
            columnsFit: widget.columnsFit,
            themeMetrics: themeMetrics,
            visibleRowsLength: widget.visibleRowsCount,
            onLastRowWidget:
                widget.onLastRowWidget != null ? _onLastRowWidget : null,
            onLastVisibleRow: widget.onLastVisibleRow != null
                ? _onLastVisibleRowListener
                : null,
            model: widget.model,
            scrolling: _scrolling,
            rowColor: widget.rowColor,
            lastRowWidget: widget.lastRowWidget,
            rowCallbacks: RowCallbacks(
                onRowTap: widget.onRowTap,
                onRowSecondaryTap: widget.onRowSecondaryTap,
                onRowDoubleTap: widget.onRowDoubleTap),
            onDragScroll: _onDragScroll));

    if (widget.model != null) {
      if (theme.row.hoverBackground != null ||
          theme.row.hoverForeground != null) {
        table = MouseRegion(
            onExit: (event) => _setHoveredRowIndex(null), child: table);
      }

      table = Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (pointer) {
          if (widget.focusable) {
            _focusNode.requestFocus();
          }
        },
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            _onScroll(pointerSignal.scrollDelta.dy, themeMetrics.row.height);
          }
        },
        onPointerPanZoomUpdate: (PointerPanZoomUpdateEvent event) {
          _onScroll(event.delta.dy, themeMetrics.row.height);
        },
        child: table,
      );

      if (widget.focusable) {
        table = Focus(
            focusNode: _focusNode,
            onKey: (node, event) =>
                _handleKeyPress(node, event, themeMetrics.row.height),
            child: table);
      }
    }

    if (theme.decoration != null) {
      table = Container(decoration: theme.decoration, child: table);
    }
    return table;
  }

  void _onScroll(double deltaY, double rowHeight) {
    if (deltaY > 0) {
      if (_scrollControllers.vertical.hasClients) {
        double target = math.min(
            _scrollControllers.vertical.position.pixels + rowHeight,
            _scrollControllers.vertical.position.maxScrollExtent);
        _scrollControllers.vertical.animateTo(target,
            duration: const Duration(milliseconds: 30), curve: Curves.ease);
      }
    } else if (deltaY < 0) {
      if (_scrollControllers.vertical.hasClients) {
        double target = math.max(
            _scrollControllers.vertical.position.pixels - rowHeight, 0);
        _scrollControllers.vertical.animateTo(target,
            duration: const Duration(milliseconds: 30), curve: Curves.ease);
      }
    }
  }

  KeyEventResult _handleKeyPress(
      FocusNode node, RawKeyEvent event, double rowHeight) {
    if (event is RawKeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (_scrollControllers.vertical.hasClients) {
          double target = math.min(
              _scrollControllers.vertical.position.pixels + rowHeight,
              _scrollControllers.vertical.position.maxScrollExtent);
          _scrollControllers.vertical.animateTo(target,
              duration: const Duration(milliseconds: 30), curve: Curves.ease);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (_scrollControllers.vertical.hasClients) {
          double target = math.max(
              _scrollControllers.vertical.position.pixels - rowHeight, 0);
          _scrollControllers.vertical.animateTo(target,
              duration: const Duration(milliseconds: 30), curve: Curves.ease);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
        if (_scrollControllers.vertical.hasClients) {
          double target = math.min(
              _scrollControllers.vertical.position.pixels +
                  _scrollControllers.vertical.position.viewportDimension,
              _scrollControllers.vertical.position.maxScrollExtent);
          _scrollControllers.vertical.animateTo(target,
              duration: const Duration(milliseconds: 30), curve: Curves.ease);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
        if (_scrollControllers.vertical.hasClients) {
          double target = math.max(
              _scrollControllers.vertical.position.pixels -
                  _scrollControllers.vertical.position.viewportDimension,
              0);
          _scrollControllers.vertical.animateTo(target,
              duration: const Duration(milliseconds: 30), curve: Curves.ease);
        }
      }
    }
    return KeyEventResult.ignored;
  }

  void _onDragScroll(bool start) {
    setState(() => _scrolling = start);
  }
}
