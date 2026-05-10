import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Barra compacta para compositores sociales.
QuillSimpleToolbarConfig vetgoSocialToolbarConfig(ThemeData theme) {
  final scheme = theme.colorScheme;
  final onSurface = scheme.onSurface;
  final iconTheme = QuillIconTheme(
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
        iconTheme: iconTheme,
      ),
    ),
  );
}
