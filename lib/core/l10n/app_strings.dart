/// UI strings with Unicode escapes where needed so corrupt source encoding cannot break glyphs on device.
abstract final class AppStrings {
  // --- Client dashboard (legacy ClientStrings) ---
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

  static const simularCitaEnCamino = 'Simular cita en camino';

  static const conectando = 'Conectando\u2026';

  static const demoVetNombre = 'Dra. Hern\u00E1ndez';

  static const demoEta = 'Llegada estimada: 14 min';

  // --- Vet dashboard / shell ---
  static String holaDoctor(String name) {
    final n = name.trim().isEmpty ? 'Doctor(a)' : name.trim();
    return 'Hola, Dr. $n';
  }

  static const vetNavInicio = 'Inicio';

  static const vetNavAgenda = 'Agenda';

  static const vetResumenHoy = 'Resumen de hoy';

  static const vetCitasPendientes = 'Citas pendientes';

  static const vetGananciasMxn = 'Ganancias (MXN)';

  static const vetProximasVisitas = 'Pr\u00F3ximas visitas';

  static const vetDeslizaMas = 'Desliza para ver m\u00E1s';

  static const vetSinVisitasHoy = 'No hay visitas asignadas para hoy.';

  static const vetDireccionPendiente = 'Direcci\u00F3n pendiente';

  static const vetMascota = 'Mascota';

  static const vetRutaEmergencia = 'Ruta de emergencia';

  static const vetSesionRutaSinId = 'Sesi\u00F3n de ruta sin id.';

  // --- Store ---
  static const storeTitle = 'Tienda Vetgo';

  static const storeBuscarHint = 'Buscar productos\u2026';

  static const storeBuscarTooltip = 'Buscar';

  static const storeCategoriaTodos = 'Todos';

  static const storeErrorCatalogo = 'No se pudo cargar el cat\u00E1logo.';

  static const storeSinResultados = 'No hay productos con estos filtros.';

  static String storeCarritoDemo(String productName) =>
      '$productName a\u00F1adido al carrito (demo).';

  static const storeProductoFallback = 'Producto';

  // --- Emergency SOS ---
  static const emergencyTitulo = 'Emergencia';

  static const emergencySubtitulo = 'Respuesta prioritaria 24/7';

  static const emergencyEnviandoAlerta = 'Enviando alerta a veterinarios cercanos';

  static const emergencySolicitarAyuda = 'Solicitar ayuda\nurgente';

  static const emergencyDetalleRapido = 'Detalle r\u00E1pido (opcional)';

  static const emergencySinMascotas =
      'No hay mascotas en tu cuenta. A\u00F1ade una desde la app o espera la sincronizaci\u00F3n.';

  static const emergencyLabelMascota = 'Mascota';

  static const emergencyLabelSintomas = 'S\u00EDntomas';

  static const emergencyHintSintomas = 'Describe lo que observas';

  static const emergencyEnviarSos = 'Enviar datos al equipo SOS';

  static const emergencyEnviando = 'Enviando\u2026';

  static const emergencyNecesitaUbicacion =
      'Se necesita ubicaci\u00F3n para alertar al equipo veterinario.';

  static const emergencyRegistraMascota =
      'Primero registra una mascota en tu cuenta.';

  static String emergencyRegistradaRef(String id) =>
      'Emergencia registrada (ref. $id). Te contactamos en segundos.';

  static const emergencyRegistrada = 'Emergencia registrada. Te contactamos en segundos.';

  static const emergencyDefaultSosBoton = 'Emergencia SOS \u2014 bot\u00F3n principal';

  static const emergencyDefaultSosForm = 'Emergencia SOS \u2014 formulario';

  // --- Schedule flow ---
  static const scheduleSolicitudDemo = 'Solicitud registrada (demo).';

  // --- Login / auth (visible errors) ---
  static const loginSinToken =
      'No se recibi\u00F3 un token. Intenta de nuevo o contacta soporte.';

  static const loginDebesVerificar = 'Debes verificar tu correo.';

  static const loginFalloGenerico = 'No se pudo iniciar sesi\u00F3n.';

  // --- Hub / client quick access (keep escapes) ---
  static const hubElige = 'Elige qu\u00E9 necesitas';

  static const hubTeGuiamos = 'Te guiamos paso a paso en cada flujo.';

  static const hubServiciosTitle = 'Servicios';
}
