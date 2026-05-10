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
  final base = DefaultStyles.getInstance(context);
  final onSurface = Theme.of(context).colorScheme.onSurface;
  final ph = base.placeHolder!;
  final para = base.paragraph!;
  final lists = base.lists!;
  // Texto plano por defecto (sin heredar grosor medio del tema / Material 3).
  final plain = para.style.copyWith(
    color: onSurface,
    decoration: TextDecoration.none,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.normal,
  );
  return base.merge(
    DefaultStyles(
      placeHolder: ph.copyWith(
        style: ph.style.copyWith(
          color: onSurface,
          decoration: TextDecoration.none,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
          fontSize: plain.fontSize,
          height: plain.height,
        ),
      ),
      paragraph: para.copyWith(style: plain),
      lists: lists.copyWith(
        style: lists.style.copyWith(
          color: onSurface,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
      ),
    ),
  );
}
