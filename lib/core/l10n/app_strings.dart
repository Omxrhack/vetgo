/// UI strings with Unicode escapes where needed so corrupt source encoding cannot break glyphs on device.
abstract final class AppStrings {
  // --- Client dashboard (legacy ClientStrings) ---
  static String holaNombre(String name) => '\u00A1Hola, $name!';

  static const recordatoriosTitulo = 'Recordatorios';

  static const recordatoriosCuerpo =
      'Aqu\u00ED aparecer\u00E1n vacunas y citas cuando est\u00E9n registradas en tu cuenta.';

  static const accesosRapidos = 'Accesos r\u00E1pidos';

  static const dashboardClienteTagline =
      'Servicios, mascotas y urgencias cuando los necesites.';

  static const clienteDashboardSubtitle =
      'Tu perfil, tus mascotas y su salud en un solo lugar.';

  static const clientePerfilTitulo = 'Resumen de mi perfil';

  static const clientePerfilSubtitulo =
      'Consulta r\u00E1pido tu cuenta y el estado general de tus mascotas.';

  static const clienteSaludTitulo = 'Recordatorios de salud';

  static const clienteActividadTitulo = 'Actividad reciente';

  static const clienteActividadVacia =
      'A\u00FAn no hay actividad reciente en tu cuenta.';

  static const clienteRecordatorioSinMascotas =
      'Registra tu primera mascota para activar recordatorios personalizados.';

  static const clienteRecordatorioSinCitas =
      'No tienes citas futuras registradas. Agenda una revisi\u00F3n preventiva.';

  static String clienteRecordatorioConCita(String fechaHora) =>
      'Pr\u00F3xima atenci\u00F3n programada para $fechaHora.';

  static const dashboardClienteSeccionAcciones = 'Acciones';

  static const quickActionServiciosLabel = 'Servicios';

  static const cerrarSesionTooltip = 'Cerrar sesi\u00F3n';

  static const quickActionEmergenciaLabel = 'Emergencia';

  static const quickActionTrackingLabel = 'Visita';

  static const quickActionTiendaLabel = 'Tienda';

  static const mascotasErrorParcial =
      'No se pudieron cargar tus mascotas. Mostramos datos temporales si est\u00E1n disponibles.';

  static const accesosHubTitulo = 'Servicios paso a paso';

  static const accesosHubSubtitulo =
      'Urgencia, citas, mascotas y tienda en pantallas guiadas.';

  static const tusMascotas = 'Tus mascotas';

  static const verExpediente = 'Ver expediente';

  static const carouselSinMascotas =
      'A\u00F1ade una mascota para verla aqu\u00ED.';

  static const clienteProximasCitas = 'Pr\u00F3ximas citas';

  static const clienteSinCitasProgramadas =
      'No tienes citas programadas con fecha de hoy en adelante.';

  static const clienteCitasErrorCarga =
      'No se pudieron cargar tus citas. Intenta de nuevo m\u00E1s tarde.';

  static const clienteCitaVeterinarioPendiente = 'Veterinario por confirmar';

  static String clienteVisitaProgramadaPara(String fechaHora) =>
      'Visita programada: $fechaHora';

  static String clienteCitaLineaVeterinario(String nombre) =>
      'Veterinario: $nombre';

  static const simularCitaEnCamino = 'Visita en camino';

  static const conectando = 'Conectando\u2026';

  static const demoVetNombre = 'Dra. Hern\u00E1ndez';

  static const demoEta = 'Llegada estimada: 14 min';

  static const trackingTitulo = 'Tu visita en camino';

  static const trackingLlamadaDemo = 'Iniciando llamada\u2026';

  static const trackingChatDemo = 'Abriendo chat\u2026';

  // --- Vet dashboard / shell ---
  static String holaDoctor(String name) {
    final n = name.trim().isEmpty ? 'Doctor(a)' : name.trim();
    return 'Hola, Dr. $n';
  }

  static const vetNavInicio = 'Inicio';

  static const vetNavAgenda = 'Agenda';

  /// Agenda del veterinario (pantalla de citas).
  static const vetScheduleTitulo = 'Agenda y ruta';

  static const vetScheduleSinCitas =
      'Sin citas para este d\u00EDa. Las solicitudes pendientes sin veterinario asignado tambi\u00E9n aparecen aqu\u00ED.';

  static const vetScheduleLineaDelDia = 'L\u00EDnea del d\u00EDa';

  static const vetScheduleVerExpediente = 'Ver expediente';

  static const vetScheduleIniciarRuta = 'Iniciar ruta';

  static const vetScheduleCitaSinAsignar = 'Sin asignar';

  static const vetScheduleRutaRequiereAsignacion =
      'La ruta en vivo estar\u00E1 disponible cuando la cita te est\u00E9 asignada.';

  static const vetScheduleTomarCita = 'Asignarme esta cita';

  static const vetScheduleCitaAsignadaOk =
      'Listo: la cita qued\u00F3 asignada a ti.';

  static const vetBookAppointmentTitulo = 'Programar visita';

  static const vetBookAppointmentEnviar = 'Registrar en agenda';

  static const vetBookAppointmentGuardada = 'Visita registrada en tu agenda.';

  static const vetBookAppointmentCuandoTitulo = 'Fecha y hora de la visita';

  static const hubTileAgendarVisitaTitulo = 'Agendar visita';

  static const hubTileAgendarVisitaSubtitulo =
      'Varios pasos: mascota, fecha sugerida y confirmaci\u00F3n.';

  static const vetScheduleSinColonia = 'Sin direcci\u00F3n registrada';

  static String vetScheduleEstado(String estado) => 'Estado: $estado';

  static const vetScheduleVeterinarioTitulo = 'Veterinario asignado';

  static const vetProximaVisitaSinVeterinario =
      'Sin veterinario asignado a\u00FAn';

  static const vetResumenHoy = 'Resumen de hoy';

  static const vetCitasPendientes = 'Citas pendientes';

  static const vetGananciasMxn = 'Ganancias (MXN)';

  static const vetProximasVisitas = 'Pr\u00F3ximas visitas';

  static const vetDeslizaMas = 'Desliza para ver m\u00E1s';

  static const vetSinVisitasHoy = 'No hay visitas asignadas para hoy.';

  static const vetDireccionPendiente = 'Direcci\u00F3n pendiente';

  static const vetMascota = 'Mascota';

  static const vetPacienteEspecie = 'Paciente';

  static const vetDutyOffTitle = 'Fuera de turno';

  static const vetDutyOnTitle = 'Disponible para urgencias';

  static const vetDutyOffSubtitle = 'No recibir\u00E1s alertas de emergencia.';

  static const vetDutyOnSubtitle = 'Podr\u00E1s recibir asignaciones urgentes.';

  static const vetDisponibilidadSection = 'Disponibilidad';

  static const vetDashboardErrorTitulo = 'No se pudo cargar el panel';

  static const vetRutaEmergencia = 'Ruta de emergencia';

  static const vetSesionRutaSinId = 'Sesi\u00F3n de ruta sin id.';

  static const vetRouteErrorCargaSesion =
      'No se pudo cargar la sesi\u00F3n de seguimiento.';

  static const vetRouteSinCoordenadasDestino =
      'Sin coordenadas del destino en tu cuenta; solo se muestra tu posici\u00F3n hasta que el tutor las registre.';

  static String vetRouteDistanciaKm(double km) =>
      'Distancia aprox.: ${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';

  static String vetRouteEtaAproxMinutos(int min) =>
      'Tiempo estimado (orientativo): ~$min min';

  static String vetRouteEtaServidorMinutos(int min) =>
      'ETA en servidor: $min min';

  static const vetRouteActualizarUbicacion =
      'Actualizar mi ubicaci\u00F3n ahora';

  static const vetRouteUbicacionEnviada = 'Ubicaci\u00F3n enviada.';

  static const vetRoutePermisoUbicacion =
      'Activa el permiso de ubicaci\u00F3n para compartir tu posici\u00F3n en vivo.';

  static const vetRouteEnviandoUbicacion = 'Enviando ubicaci\u00F3n\u2026';

  static const vetRouteContextoDesconocido = 'Ruta en curso';

  // --- Store ---
  static const storeTitle = 'Tienda';

  static const storeSubtitle =
      'Alimento, higiene y accesorios para tu compa\u00F1ero.';

  static const storeBuscarHint = 'Buscar productos\u2026';

  static const storeBuscarTooltip = 'Buscar';

  static const storeCategoriaTodos = 'Todos';

  static const storeErrorCatalogo = 'No se pudo cargar el cat\u00E1logo.';

  static const storeSinResultados = 'No hay productos con estos filtros.';

  static String storeCarritoDemo(String productName) =>
      '$productName a\u00F1adido al carrito.';

  static const storeProductoFallback = 'Producto';

  // --- Emergency SOS ---
  static const emergencyTitulo = 'Emergencia';

  static const emergencySubtitulo = 'Respuesta prioritaria 24/7';

  static const emergencyEnviandoAlerta =
      'Enviando alerta a veterinarios cercanos';

  static const emergencySolicitarAyuda = 'Solicitar ayuda\nurgente';

  /// CTA principal (una línea; pantalla SOS rediseñada).
  static const emergencyCtaPrincipal = 'Solicitar ayuda urgente';

  /// Ayuda bajo el botón SOS (ubicación).
  static const emergencyUbicacionNota =
      'Se usar\u00E1 tu ubicaci\u00F3n para alertar al equipo veterinario.';

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

  static const emergencyRegistrada =
      'Emergencia registrada. Te contactamos en segundos.';

  static const emergencyDefaultSosBoton =
      'Emergencia SOS \u2014 bot\u00F3n principal';

  // --- Schedule flow ---
  static const scheduleSolicitudDemo = 'Solicitud registrada (demo).';

  static const scheduleIntroBody =
      'Eliges la mascota, fecha y hora de la visita y un mapa con la ubicaci\u00F3n '
      'aproximada (tu GPS si lo permites). La solicitud se env\u00EDa al servidor; '
      'si tienes veterinario preferido en Servicios, la cita puede asign\u00E1rsele cuando sea posible.';

  static String schedulePasoNDeM(int n, int total) => 'Paso $n de $total';

  static const scheduleAgendarVisitaTitulo = 'Agendar visita a domicilio';

  static const scheduleAtras = 'Atr\u00E1s';

  static const scheduleContinuar = 'Continuar';

  static const scheduleSiguiente = 'Siguiente';

  static const scheduleSinMascotas =
      'No hay mascotas registradas. Vuelve cuando sincronicemos tus datos.';

  static const schedulePasoMascotaTitulo =
      '\u00BFQu\u00E9 mascota necesita la visita?';

  static const scheduleCuandoUbicacionTitulo = 'Fecha, hora y ubicaci\u00F3n';

  static const scheduleMapaHint =
      'El marcador muestra tu ubicaci\u00F3n aproximada si activas el GPS; '
      'si no, usamos una zona de referencia.';

  static const scheduleNotasOpcional = 'Notas para el veterinario (opcional)';

  static const scheduleConfirmacionTitulo = 'Confirmaci\u00F3n';

  static const scheduleResumenMascota = 'Mascota:';

  static const scheduleResumenCuando = 'Cu\u00E1ndo:';

  static const scheduleResumenNotas = 'Notas:';

  static const scheduleEnviarSolicitud = 'Enviar solicitud';

  static const scheduleEnviando = 'Enviando\u2026';

  static const scheduleFechaPasada =
      'Elige una fecha y hora posteriores a ahora.';

  static const mapaOsmAtribucion = '\u00A9 OpenStreetMap contributors';

  // --- Login / auth (visible errors) ---
  static const loginSinToken =
      'No se recibi\u00F3 un token. Intenta de nuevo o contacta soporte.';

  static const loginDebesVerificar = 'Debes verificar tu correo.';

  static const loginFalloGenerico = 'No se pudo iniciar sesi\u00F3n.';

  // --- Hub / client quick access (keep escapes) ---
  static const hubElige = 'Elige qu\u00E9 necesitas';

  static const hubTeGuiamos = 'Te guiamos paso a paso en cada flujo.';

  static const hubServiciosTitle = 'Servicios';

  // --- Elegir veterinario (cliente) ---
  static const vetElegirTitulo = 'Tu veterinario';

  static const vetElegirSubtitulo =
      'Eleg\u00ED uno para priorizarlo en emergencias y en citas a domicilio. Si no eliges, usamos asignaci\u00F3n autom\u00E1tica.';

  static const vetReintentar = 'Reintentar';

  static const vetListaVacia =
      'A\u00FAn no hay veterinarios disponibles en el cat\u00E1logo.';

  static const vetQuitarPreferido = 'Usar asignaci\u00F3n autom\u00E1tica';

  static String vetPreferidoGuardado(String name) =>
      'Guardado: $name ser\u00E1 tu veterinario preferido.';

  static const vetPreferidoQuitarOk =
      'Listo: volveremos a asignar autom\u00E1ticamente.';

  static const hubTileVetTitulo = 'Mi veterinario';

  static const hubTileVetSubtitulo =
      'Elige qui\u00E9n atiende tus urgencias y visitas.';

  static const emergencyVetLineAuto =
      'Sin preferencia: asignamos al veterinario disponible m\u00E1s cercano.';

  static String emergencyVetLinePref(String name) =>
      'Preferencia activa: $name';

  static const emergencyVetElegir = 'Elegir o cambiar';

  static const scheduleVetLineAuto = 'Sin veterinario fijo (autom\u00E1tico)';

  static String scheduleVetLinePref(String name) => 'Veterinario: $name';

  static const scheduleVetElegir = 'Elegir veterinario';

  static String scheduleCitaRegistrada(String id) =>
      'Cita registrada (ref. $id).';

  static const scheduleCitaOkSinRef = 'Cita registrada.';

  static const scheduleCitaError = 'No se pudo registrar la cita.';

  /// Foto de perfil (Storage Supabase + dashboard).
  static const profilePhotoCambiarTooltip = 'Cambiar foto de perfil';

  /// Onboarding: selector de galería en lugar de URL manual.
  static const onboardingFotoPerfilTitulo = 'Foto de perfil';

  static const onboardingFotoPerfilSubtitulo =
      'Toca para elegir una imagen en la galer\u00EDa.';

  static const onboardingFotoPerfilSubtituloOpcional =
      'Opcional. Toca para elegir en la galer\u00EDa.';

  static const onboardingFotoPerfilQuitar = 'Quitar foto';

  static const onboardingVetFotoRequerida =
      'Sube una foto de perfil desde la galer\u00EDa para continuar.';

  static const onboardingUsarUbicacion = 'Usar mi ubicaci\u00F3n actual';

  static const onboardingUbicacionAplicada =
      'Direcci\u00F3n rellenada con tu ubicaci\u00F3n.';

  static const onboardingVetBaseDireccionLabel = 'Direcci\u00F3n o zona base';

  static const onboardingVetBaseDireccionHint =
      'Opcional. Tambi\u00E9n guardamos coordenadas para cobertura y emergencias.';

  static const petPhotoCambiarTooltip = 'Cambiar foto de la mascota';

  static const petPhotoActualizada = 'Foto de la mascota actualizada.';
}
