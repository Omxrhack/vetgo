import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

QuillEditorConfig vetgoSocialQuillEditorConfig(
  BuildContext context, {
  required String placeholder,
}) {
  return QuillEditorConfig(
    expands: true,
    padding: EdgeInsets.zero,
    placeholder: placeholder,
    customStyles: vetgoSocialQuillStyles(context),
    textCapitalization: TextCapitalization.none,
  );
}

DefaultStyles vetgoSocialQuillStyles(BuildContext context) {
  final theme = Theme.of(context);
  final base = DefaultStyles.getInstance(context);
  final scheme = theme.colorScheme;
  final onSurface = scheme.onSurface;
  final ph = base.placeHolder!;
  final para = base.paragraph!;
  final lists = base.lists!;
  // Misma densidad que el cuerpo del post en feed (Threads / X).
  final plain = (theme.textTheme.bodyLarge ?? para.style).copyWith(
    fontSize: 15.5,
    height: 1.42,
    letterSpacing: -0.15,
    color: onSurface.withValues(alpha: 0.92),
    decoration: TextDecoration.none,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.normal,
  );
  final placeholderMuted = onSurface.withValues(alpha: 0.42);
  return base.merge(
    DefaultStyles(
      placeHolder: ph.copyWith(
        style: ph.style.merge(TextStyle(
          color: placeholderMuted,
          decoration: TextDecoration.none,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
          fontSize: plain.fontSize,
          height: plain.height,
          letterSpacing: plain.letterSpacing,
        )),
      ),
      paragraph: para.copyWith(style: plain),
      lists: lists.copyWith(
        style: lists.style.copyWith(
          color: plain.color,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
          fontSize: plain.fontSize,
          height: plain.height,
          letterSpacing: plain.letterSpacing,
        ),
      ),
    ),
  );
}
