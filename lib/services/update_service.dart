// Este archivo actúa como un puente.
// El resto de tu app solo importará este archivo.

export 'update_service_io.dart' // Exporta la versión para IO (móvil, escritorio) por defecto
    if (dart.library.html) 'update_service_web.dart'; // Y si detecta que es web, exporta la versión web.