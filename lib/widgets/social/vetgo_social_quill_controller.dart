// ignore_for_file: experimental_member_use

import 'package:flutter_quill/flutter_quill.dart';

/// Controlador para compositores sociales: documento vacío y, por defecto,
/// pegado desde otras apps solo como texto plano (sin HTML/rich del portapapeles).
QuillController vetgoSocialQuillController() {
  return QuillController.basic(
    config: const QuillControllerConfig(
      clipboardConfig: QuillClipboardConfig(
        enableExternalRichPaste: false,
      ),
    ),
  );
}
