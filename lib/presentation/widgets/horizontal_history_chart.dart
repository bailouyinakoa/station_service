import 'package:flutter/material.dart';

class HorizontalHistoryChart extends StatefulWidget {
  const HorizontalHistoryChart({
    super.key,
    required this.height,
    required this.contentWidth,
    required this.child,
  });

  final double height;
  final double contentWidth;
  final Widget child;

  @override
  State<HorizontalHistoryChart> createState() => _HorizontalHistoryChartState();
}

class _HorizontalHistoryChartState extends State<HorizontalHistoryChart> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftFade = false;
  bool _showRightFade = false;
  bool _autoScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateFades);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoScrollToLatest();
      _updateFades();
    });
  }

  @override
  void didUpdateWidget(covariant HorizontalHistoryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contentWidth != widget.contentWidth) {
      _autoScrolled = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoScrollToLatest();
        _updateFades();
      });
    }
  }

  void _autoScrollToLatest() {
    if (!_scrollController.hasClients || _autoScrolled) {
      return;
    }
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent <= 0) {
      return;
    }
    _autoScrolled = true;
    _scrollController.jumpTo(maxExtent);
  }

  void _updateFades() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    final showLeft = position.pixels > 2;
    final showRight = position.pixels < (position.maxScrollExtent - 2);
    if (showLeft != _showLeftFade || showRight != _showRightFade) {
      setState(() {
        _showLeftFade = showLeft;
        _showRightFade = showRight;
      });
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateFades)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.swipe_left_alt_rounded,
              size: 16,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              'Glissez horizontalement pour voir l\'historique',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                  scrollbars: false,
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(width: widget.contentWidth, child: widget.child),
                ),
              ),
              if (_showLeftFade)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      width: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Theme.of(context).colorScheme.surface,
                            Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (_showRightFade)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      width: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            Theme.of(context).colorScheme.surface,
                            Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
