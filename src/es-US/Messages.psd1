# This file is auto-generated from YAML localization files. Do not edit manually.
ConvertFrom-StringData @'
    error_task_name_does_not_exist=La tarea {0} no existe.
    error_invalid_include_path=No se puede incluir {0}. Archivo no encontrado.
    error_no_default_task=Se requiere la tarea 'default'.
    error_no_framework_install_dir_found=No se encontró el directorio de instalación de .NET Framework en {0}.
    error_unknown_pointersize=Tamaño de puntero desconocido ({0}) devuelto por System.IntPtr.
    psake_success=psake ejecutó correctamente la tarea {0}
    error_missing_action_parameter=Debe especificarse el parámetro de acción cuando se usan los parámetros PreAction o PostAction en la tarea {0}.
    warning_missing_vsssetup_module=Advertencia: No se puede encontrar la versión {0} de las herramientas de construcción sin el módulo VSSetup. Puedes instalarlo con el comando: Install-Module VSSetup -Scope CurrentUser
    error_invalid_task_name=El nombre de la tarea no debe estar vacío ni ser nulo.
    error_corrupt_callstack=La pila de llamadas está dañada. Se esperaba {0}, pero se obtuvo {1}.
    error_circular_reference=Se detectó una referencia circular en la tarea {0}.
    warning_deprecated_framework_variable=Advertencia: Usar la variable global $framework para definir la versión de .NET Framework está obsoleto. Usa la función Framework o el archivo de configuración psake-config.ps1.
    error_loading_module=Error al cargar el módulo {0}.
    postcondition_failed=Falló la condición posterior para la tarea {0}.
    required_variable_not_set=La variable {0} debe estar definida para ejecutar la tarea {1}.
    error_shared_task_cannot_have_action='{0}' hace referencia a una tarea compartida del módulo {1} y no puede tener una acción.
    continue_on_error=Error en la tarea {0}. {1}
    error_bad_command=Error al ejecutar el comando {0}.
    error_build_file_not_found=No se pudo encontrar el archivo de construcción {0}.
    error_duplicate_task_name=La tarea {0} ya fue definida.
    error_unknown_module=No se puede encontrar el módulo [{0}].
    error_invalid_framework=Versión de .NET Framework no válida: {0}.
    precondition_was_false=La condición previa fue falsa, no se ejecutó la tarea {0}.
    error_default_task_cannot_have_action=La tarea 'default' no puede tener una acción.
    error_duplicate_alias_name=El alias {0} ya fue definido.
    error_unknown_bitnesspart=Arquitectura de .NET Framework desconocida: {0}, especificada en {1}.
    error_unknown_framework=Versión desconocida de .NET Framework: {0} especificada en {1}.
'@

