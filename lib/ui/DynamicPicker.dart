import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinite_listview/infinite_listview.dart';

// Copied from NumberPicker
typedef TextMapper<T> = String Function(T value);
class DynamicPicker<T> extends StatefulWidget {

  final List<T> values;
  
  /// Currently selected value
  final T value;

  /// Called when selected value changes
  final ValueChanged<T> onChanged;

  /// Specifies how many items should be shown - defaults to 3
  final int itemCount;

  /// height of single item in pixels
  final double itemHeight;

  /// width of single item in pixels
  final double itemWidth;

  /// Direction of scrolling
  final Axis axis;

  /// Style of non-selected numbers. If null, it uses Theme's bodyText2
  final TextStyle? textStyle;

  /// Style of non-selected numbers. If null, it uses Theme's headline5 with accentColor
  final TextStyle? selectedTextStyle;

  /// Whether to trigger haptic pulses or not
  final bool haptics;

  /// Build the text of each item on the picker
  final TextMapper textMapper;

  /// Decoration to apply to central box where the selected value is placed
  final Decoration? decoration;

  final bool infiniteLoop;

  const DynamicPicker({
    Key? key,
    required this.values,
    required this.value,
    required this.onChanged,
    required this.textMapper,
    this.itemCount = 3,
    this.itemHeight = 50,
    this.itemWidth = 100,
    this.axis = Axis.vertical,
    this.textStyle,
    this.selectedTextStyle,
    this.haptics = false,
    this.decoration,
    this.infiniteLoop = false,
  })  :super(key: key);

  @override
  _DynamicPickerState<T> createState() => _DynamicPickerState<T>(this.onChanged);
}

class _DynamicPickerState<T> extends State<DynamicPicker> {
  late ScrollController _scrollController;
  final ValueChanged<T> onChanged; // needed, otherwise T is erased

  _DynamicPickerState(this.onChanged) {}

  @override
  void initState() {
    super.initState();
    final idx = widget.values.indexOf(widget.value);
    final initialOffset = idx * itemExtent;
    if (widget.infiniteLoop) {
      _scrollController =
          InfiniteScrollController(initialScrollOffset: initialOffset);
    } else {
      _scrollController = ScrollController(initialScrollOffset: initialOffset);
    }
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    var indexOfMiddleElement = (_scrollController.offset / itemExtent).round();
    if (widget.infiniteLoop) {
      indexOfMiddleElement %= itemCount;
    } else {
      indexOfMiddleElement = indexOfMiddleElement.clamp(0, itemCount - 1);
    }
    final valueInTheMiddle =
        _getValueFromIndex(indexOfMiddleElement + additionalItemsOnEachSide);

    debugPrint("valueInTheMiddle=$valueInTheMiddle");
    if (widget.value != valueInTheMiddle) {
      onChanged(valueInTheMiddle);
      if (widget.haptics) {
        HapticFeedback.selectionClick();
      }
    }
    Future.delayed(
      Duration(milliseconds: 100),
      () => _maybeCenterValue(),
    );
  }

  @override
  void didUpdateWidget(DynamicPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _maybeCenterValue();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get isScrolling => _scrollController.position.isScrollingNotifier.value;

  double get itemExtent =>
      widget.axis == Axis.vertical ? widget.itemHeight : widget.itemWidth;

  int get itemCount => widget.values.length;

  int get listItemsCount => itemCount + 2 * additionalItemsOnEachSide;

  int get additionalItemsOnEachSide => (widget.itemCount - 1) ~/ 2;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.axis == Axis.vertical
          ? widget.itemWidth
          : widget.itemCount * widget.itemWidth,
      height: widget.axis == Axis.vertical
          ? widget.itemCount * widget.itemHeight
          : widget.itemHeight,
      child: NotificationListener<ScrollEndNotification>(
        onNotification: (not) {
          if (not.dragDetails?.primaryVelocity == 0) {
            Future.microtask(() => _maybeCenterValue());
          }
          return true;
        },
        child: Stack(
          children: [
            if (widget.infiniteLoop)
              InfiniteListView.builder(
                scrollDirection: widget.axis,
                controller: _scrollController as InfiniteScrollController,
                itemExtent: itemExtent,
                itemBuilder: _itemBuilder,
                padding: EdgeInsets.zero,
              )
            else
              ListView.builder(
                itemCount: listItemsCount,
                scrollDirection: widget.axis,
                controller: _scrollController,
                itemExtent: itemExtent,
                itemBuilder: _itemBuilder,
                padding: EdgeInsets.zero,
              ),
            _NumberPickerSelectedItemDecoration(
              axis: widget.axis,
              itemExtent: itemExtent,
              decoration: widget.decoration,
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemBuilder(BuildContext context, int index) {
    final themeData = Theme.of(context);
    final defaultStyle = widget.textStyle ?? themeData.textTheme.bodyText2;
    final selectedStyle = widget.selectedTextStyle ??
        themeData.textTheme.headline5?.copyWith(color: themeData.accentColor);

    final value = _getValueFromIndex(index % itemCount);
    final isExtra = !widget.infiniteLoop &&
        (index < additionalItemsOnEachSide ||
            index >= listItemsCount - additionalItemsOnEachSide);
    final itemStyle = value == widget.value ? selectedStyle : defaultStyle;

    final child = isExtra
        ? SizedBox.shrink()
        : Text(widget.textMapper(value),
            style: itemStyle,
          );

    return Container(
      width: widget.itemWidth,
      height: widget.itemHeight,
      alignment: Alignment.center,
      child: child,
    );
  }

  T _getValueFromIndex(int index) {
    index -= additionalItemsOnEachSide;
    index %= itemCount;
    debugPrint("index=$index");
    return widget.values.elementAt(index);
  }

  void _maybeCenterValue() {
    if (_scrollController.hasClients && !isScrolling) {
      int index = widget.values.indexOf(widget.value);
      if (widget.infiniteLoop) {
        final offset = _scrollController.offset + 0.5 * itemExtent;
        final cycles = (offset / (itemCount * itemExtent)).floor();
        index += cycles * itemCount;
      }
      _scrollController.animateTo(
        index * itemExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }
}

class _NumberPickerSelectedItemDecoration extends StatelessWidget {
  final Axis axis;
  final double itemExtent;
  final Decoration? decoration;

  const _NumberPickerSelectedItemDecoration({
    Key? key,
    required this.axis,
    required this.itemExtent,
    required this.decoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IgnorePointer(
        child: Container(
          width: isVertical ? double.infinity : itemExtent,
          height: isVertical ? itemExtent : double.infinity,
          decoration: decoration,
        ),
      ),
    );
  }

  bool get isVertical => axis == Axis.vertical;
}
