import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

DefaultStyles vetgoSocialQuillStyles(BuildContext context) {
  final base = DefaultStyles.getInstance(context);
  final onSurface = Theme.of(context).colorScheme.onSurface;
  final ph = base.placeHolder!;
  final para = base.paragraph!;
  return base.merge(
    DefaultStyles(
      placeHolder: ph.copyWith(
        style: ph.style.copyWith(
          color: onSurface,
          decoration: TextDecoration.none,
        ),
      ),
      paragraph: para.copyWith(
        style: para.style.copyWith(
          color: onSurface,
          decoration: TextDecoration.none,
        ),
      ),
    ),
  );
}
