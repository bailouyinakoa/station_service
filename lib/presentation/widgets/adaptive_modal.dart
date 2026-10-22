import 'package:flutter/material.dart';

Future<T?> showAdaptiveModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
}) {
  final isPhone = MediaQuery.of(context).size.width < 600;
  if (!isPhone) {
    return showDialog<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      anchorPoint: anchorPoint,
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    isDismissible: barrierDismissible,
    backgroundColor: Theme.of(context).colorScheme.surface,
    showDragHandle: true,
    builder: (sheetContext) {
      final dialogLike = builder(sheetContext);
      final padding = MediaQuery.of(sheetContext).viewInsets;

      if (dialogLike is AlertDialog) {
        return Padding(
          padding: EdgeInsets.only(bottom: padding.bottom),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            minChildSize: 0.35,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dialogLike.title != null) ...[
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.titleLarge ??
                            const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                        child: dialogLike.title!,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (dialogLike.content != null) dialogLike.content!,
                    if (dialogLike.actions != null &&
                        dialogLike.actions!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: dialogLike.actions!,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      }

      return Padding(
        padding: EdgeInsets.only(bottom: padding.bottom),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.35,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: dialogLike,
            );
          },
        )
      );
    },
  );
}
