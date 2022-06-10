import 'package:easy_table/src/experimental/content_area_id.dart';
import 'package:easy_table/src/experimental/table_layout_parent_data_exp.dart';
import 'package:easy_table/src/experimental/table_layout_settings.dart';
import 'package:flutter/material.dart';

class ContentArea {
  ContentArea(
      {required this.id,
      required this.headerAreaDebugColor,
      required this.scrollbarAreaDebugColor});

  final ContentAreaId id;
  final Color headerAreaDebugColor;
  final Color scrollbarAreaDebugColor;

  final List<RenderBox> children = [];
  RenderBox? scrollbar;

  Rect bounds = Rect.zero;

  void clear() {
    children.clear();
    scrollbar = null;
  }

  void performLayout({required TableLayoutSettings layoutSettings}) {
    double y = 0;
    for (RenderBox renderBox in children) {
      final TableLayoutParentDataExp parentData = renderBox._parentData();
      renderBox.layout(
          BoxConstraints.tightFor(
              width: 100, height: layoutSettings.cellHeight),
          parentUsesSize: true);
      parentData.offset = Offset(0, y);
      y += layoutSettings.cellHeight;
    }
    if (scrollbar != null) {
      scrollbar!.layout(
          BoxConstraints.tightFor(
              width: bounds.width, height: layoutSettings.scrollbarSize),
          parentUsesSize: true);
      scrollbar!._parentData().offset =
          Offset(bounds.left, bounds.bottom - layoutSettings.scrollbarSize);
    }
  }

  void paintDebugAreas(
      {required Canvas canvas,
      required Offset offset,
      required TableLayoutSettings layoutSettings}) {
    if (layoutSettings.hasHeader) {
      Paint paint = Paint()
        ..style = PaintingStyle.fill
        ..color = headerAreaDebugColor;
      canvas.drawRect(
          Rect.fromLTWH(offset.dx + bounds.left, offset.dy + bounds.top,
              bounds.width, layoutSettings.headerHeight),
          paint);
    }

    if (layoutSettings.hasVerticalScrollbar) {
      Paint paint = Paint()
        ..style = PaintingStyle.fill
        ..color = scrollbarAreaDebugColor;
      canvas.drawRect(
          Rect.fromLTWH(
              offset.dx + bounds.left,
              offset.dy + bounds.bottom - layoutSettings.scrollbarSize,
              bounds.width,
              layoutSettings.scrollbarSize),
          paint);
    }
  }

  void paintChildren({required Canvas canvas, required Offset offset}) {}
}

/// Utility extension to facilitate obtaining parent data.
extension _TableLayoutParentDataGetter on RenderObject {
  TableLayoutParentDataExp _parentData() {
    return parentData as TableLayoutParentDataExp;
  }
}
