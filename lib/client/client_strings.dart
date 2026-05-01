/// Spanish UI strings using \\u escapes so source file encoding cannot break glyphs on device.
abstract final class ClientStrings {
  static String holaNombre(String name) => '\u00A1Hola, $name!';

  static const recordatoriosTitulo = 'Recordatorios';

  static const recordatoriosCuerpo =
      'Aqu\u00ED aparecer\u00E1n vacunas y citas cuando est\u00E9n registradas en tu cuenta.';

  static const accesosRapidos = 'Accesos r\u00E1pidos';

  static const cerrarSesionTooltip = 'Cerrar sesi\u00F3n';

  static const mascotasErrorParcial =
      'No se pudieron cargar tus mascotas. Mostramos datos temporales si est\u00E1n disponibles.';

  static const accesosHubTitulo = 'Servicios paso a paso';

  static const accesosHubSubtitulo =
      'Urgencia, citas, mascotas y tienda en pantallas guiadas.';

  static const tusMascotas = 'Tus mascotas';

  static const verExpediente = 'Ver expediente';

  static const carouselSinMascotas =
      'A\u00F1ade una mascota para verla aqu\u00ED.';

  static const snackSinMascotasRegistradas =
      'A\u00FAn no tienes mascotas registradas. Si acabas de iniciar sesi\u00F3n, espera la sincronizaci\u00F3n o crea una desde expediente.';

  static const simularCitaEnCamino = 'Simular cita en camino';

  static const conectando = 'Conectando\u2026';

  static const demoVetNombre = 'Dra. Hern\u00E1ndez';

  static const demoEta = 'Llegada estimada: 14 min';
}
