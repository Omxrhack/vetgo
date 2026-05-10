import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Barra compacta para compositores sociales: negrita, cursiva, listas, deshacer.
QuillSimpleToolbarConfig vetgoSocialToolbarConfig() {
  return const QuillSimpleToolbarConfig(
    multiRowsDisplay: true,
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
  );
}
