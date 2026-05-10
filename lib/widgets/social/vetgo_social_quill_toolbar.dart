import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Barra compacta para compositores sociales (negrita con estado visual corregido).
QuillSimpleToolbarConfig vetgoSocialToolbarConfig(ThemeData theme) {
  final scheme = theme.colorScheme;
  final onSurface = scheme.onSurface;
  final boldIconTheme = QuillIconTheme(
    iconButtonUnselectedData: IconButtonData(color: onSurface),
    iconButtonSelectedData: IconButtonData(
      color: onSurface,
      style: IconButton.styleFrom(
        foregroundColor: onSurface,
        backgroundColor: scheme.surfaceContainerHighest,
      ),
    ),
  );

  return QuillSimpleToolbarConfig(
    multiRowsDisplay: false,
    color: scheme.surface,
    showFontFamily: false,
    showFontSize: false,
    showBoldButton: true,
    showItalicButton: true,
    showUnderLineButton: false,
    showStrikeThrough: false,
    showInlineCode: false,
    showSmallButton: false,
    showColorButton: false,
    showBackgroundColorButton: false,
    showClearFormat: true,
    showHeaderStyle: false,
    showListNumbers: true,
    showListBullets: true,
    showListCheck: false,
    showCodeBlock: false,
    showQuote: false,
    showIndent: false,
    showLink: false,
    showUndo: true,
    showRedo: true,
    showSearchButton: false,
    showSubscript: false,
    showSuperscript: false,
    showAlignmentButtons: false,
    showLineHeightButton: false,
    showDirection: false,
    axis: Axis.horizontal,
    buttonOptions: QuillSimpleToolbarButtonOptions(
      base: QuillToolbarBaseButtonOptions(
        iconTheme: boldIconTheme,
      ),
      bold: QuillToolbarToggleStyleButtonOptions(
        iconTheme: boldIconTheme,
        // firma (dynamic, dynamic): el typedef interno de flutter_quill no coincide
        // en runtime con parámetros tipados y provoca _TypeError.
        childBuilder: ((dynamic options, dynamic extra) {
          final o = options as QuillToolbarToggleStyleButtonOptions;
          final e = extra as QuillToolbarToggleStyleButtonExtraOptions;
          final ctx = e.context;
          final tooltip = o.tooltip ??
              FlutterQuillLocalizations.of(ctx)?.bold ??
              'Negrita';
          final iconSize = (o.iconSize ?? kDefaultIconSize) *
              (o.iconButtonFactor ?? kDefaultIconButtonFactor);
          return Tooltip(
            message: tooltip,
            child: QuillToolbarIconButton(
              icon: Icon(
                o.iconData ?? Icons.format_bold,
                size: iconSize,
              ),
              isSelected: !e.isToggled,
              onPressed: e.onPressed,
              afterPressed: o.afterButtonPressed,
              iconTheme: o.iconTheme ?? boldIconTheme,
            ),
          );
        }) as QuillToolbarButtonOptionsChildBuilder<
            QuillToolbarToggleStyleButtonOptions,
            QuillToolbarToggleStyleButtonExtraOptions>,
      ),
    ),
  );
}
