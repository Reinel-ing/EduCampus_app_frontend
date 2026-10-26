# EduCampus — Documentación del Proyecto

**Fuente primaria:** `EduCampus_app (14).zip` (frontend Flutter + backend FastAPI + PostgreSQL/Neon).  
**Plantilla de estructura:** `Plantilla proyecto final.doc`.  
**Contexto inicial:** `presentacion vieja.pdf`, usada para problema, público objetivo y Scrum propuesto.

> Criterio: cuando el código actual y una fuente histórica difieren, prevalece el código actual. Las cifras de medición se calculan del repositorio. Las estimaciones de esfuerzo son referenciales y llevan sus supuestos explícitos.

---
# PRIMERA PARTE
## I. DESCRIPCION DEL SISTEMA
## 1.1. IDENTIFICACION DEL PROBLEMA

El Colegio Manantial de Sabiduría (COLMAS), institución orientada a la educación preescolar y primaria, ha identificado que una parte importante de sus procesos administrativos, académicos y de registro se realiza de forma física y manual. La presentación inicial del proyecto describe esta situación como poco eficiente, poco estandarizada y difícil de mantener de forma constante, lo que afecta la gestión de la información necesaria para el acompañamiento de los estudiantes. El proyecto surge para centralizar esos procesos en una solución digital que permita a docentes, personal administrativo y acudientes consultar y registrar información desde un único sistema. El alcance funcional actual comprende estudiantes, cursos, actividades, asistencia, evaluación, convivencia, alertas, materiales, horarios, calendario, notificaciones, boletines y reportes. Los módulos financieros de pagos, pensiones y contabilidad no forman parte del alcance activo documentado.

## 1.2. DESCRIPCIÓN DETALLADA DEL SISTEMA O APLICACIÓN

EduCampus es una solución de gestión educativa implementada con un frontend Flutter Web/PWA y un backend REST desarrollado con FastAPI. El backend utiliza SQLAlchemy 2.0 para persistencia en PostgreSQL administrado en Neon, Alembic para migraciones y Pydantic para validación. El frontend utiliza el paquete http para consumir la API, shared_preferences para persistir localmente el estado elegido de la sesión, y clases singleton que extienden ChangeNotifier para manejar el estado de los módulos. La aplicación expone tres perfiles principales: Administrador, Docente y Acudiente. El flujo de acceso actual es correo y contraseña; el requisito previo de acceso mediante código de carnet del estudiante no está implementado en el código revisado y por tanto no se describe como funcionalidad actual.

El Administrador gestiona personas, grados, firmas, evaluación, asistencia, convivencia, alertas, calendario, horarios, formularios, reportes y configuración. El Docente gestiona estudiantes de sus cursos, asistencia, calificaciones o logros, materiales, actividades, entregas, convivencia, horario y avisos de recogida. El Acudiente consulta el progreso del estudiante a su cargo, asistencia, actividades, materiales, horario, calendario, notificaciones y boletines. La API contiene además funcionalidades de matrícula y comunicación, pero la documentación técnica indica que algunas no son consumidas por pantallas activas.

La presentación inicial del proyecto definió Scrum como metodología propuesta, justificada por el desarrollo incremental de módulos como estudiantes, actividades, asistencia, evaluación, seguimiento y comunicación. La implementación técnica actual evidencia integración continua directa sobre la rama principal, despliegue automático y separación en frontend/backend, pero no aporta evidencia suficiente para afirmar que todos los eventos y artefactos de Scrum hayan sido formalmente ejecutados. En este documento Scrum se registra como metodología declarada en la propuesta inicial, no como evidencia de cumplimiento total.

## 1.3. MODELO DE REQUERIMIENTOS
### 1.3.1. Descripción Requisitos funcionales

| ID | Módulo | Requisito | Actor/capa | Estado |
|---|---|---|---|---|
| RF01 | Autenticación | Iniciar sesión con correo y contraseña mediante /auth/login/. | Administrador, Docente, Acudiente | Implementado |
| RF02 | Sesión | Restaurar la sesión local mediante /auth/session/. | Todos | Implementado |
| RF03 | Usuarios | Registrar estudiantes, docentes y acudientes mediante /auth/registro/. | Administrador | Implementado |
| RF04 | Usuarios | Consultar estudiantes, docentes y acudientes. | Administrador | Implementado |
| RF05 | Grados | Crear, editar y eliminar grados. | Administrador | Implementado |
| RF06 | Firmas | Consultar/cargar firmas digitales de docentes y administrador. | Administrador | Implementado |
| RF07 | Evaluación | Registrar calificaciones numéricas de 0 a 5. | Docente, Administrador | Implementado |
| RF08 | Evaluación | Registrar logros/observaciones de preescolar por periodo. | Docente, Administrador | Implementado |
| RF09 | Boletines | Generar y descargar boletines PDF por estudiante y periodo. | Acudiente, Administrador | Implementado |
| RF10 | Asistencia | Registrar y consultar asistencia de estudiantes. | Docente, Administrador | Implementado |
| RF11 | Asistencia docente | Registrar y consultar asistencia de profesores. | Administrador | Implementado |
| RF12 | Convivencia | Registrar, consultar, actualizar seguimiento y eliminar situaciones. | Docente, Administrador | Implementado |
| RF13 | Alertas | Crear y atender alertas con respuesta administrativa. | Docente, Administrador | Implementado |
| RF14 | Recogida | Registrar finalización de clase y avisar a acudientes. | Docente | Implementado |
| RF15 | Notificaciones | Consultar notificaciones y marcarlas como leídas. | Docente, Acudiente | Implementado |
| RF16 | Materiales | Publicar, listar y eliminar material didáctico. | Docente, Administrador | Implementado |
| RF17 | Actividades | Crear y listar tareas con fecha límite y opción de video. | Docente, Acudiente | Implementado |
| RF18 | Entregas | Subir entregas multipart, descargar archivos y calificarlas. | Acudiente, Docente | Implementado |
| RF19 | Reglas de entrega | Rechazar entregas fuera de plazo, formatos no permitidos, video no autorizado y archivos >200 MiB. | Backend | Implementado |
| RF20 | Horario | Crear, listar y eliminar bloques de horario. | Administrador, Docente, Acudiente | Implementado |
| RF21 | Calendario | Crear, consultar y eliminar eventos. | Administrador, Todos consulta | Implementado |
| RF22 | Comunicación | Crear comunicados institucionales. | Administrador | Endpoint existe; frontend activo no persiste |
| RF23 | Formularios | Crear plantillas, campos y diligenciar formularios. | Administrador, usuarios según formulario | Parcial |
| RF24 | Campos personalizados | Definir campos adicionales en la ficha del estudiante. | Administrador | Implementado en frontend/modelo |
| RF25 | Reportes | Generar reporte diario y estadísticas institucionales. | Administrador | Implementado |
| RF26 | PWA | Instalar la aplicación web como PWA. | Todos | Implementado |
| RF27 | Salud | Verificar API y conexión a PostgreSQL mediante / y /health. | Operación | Implementado |
| RF28 | Matrícula | Crear matrícula mediante /matriculas/. | Administrador | Endpoint disponible; no hay interfaz activa |

### 1.3.2. Descripción Requisitos no funcionales

| ID | Categoría | Requisito | Estado |
|---|---|---|---|
| RNF01 | Seguridad | Contraseñas verificadas con bcrypt; existe además cifrado reversible para consulta administrativa. | Implementado; riesgo residual por reversibilidad |
| RNF02 | Sesiones | Sesiones del backend se mantienen en memoria y se invalidan al reiniciar. | Limitación actual |
| RNF03 | Disponibilidad | Backend desplegado en Render gratuito, con suspensión por inactividad. | Limitación actual |
| RNF04 | Persistencia | PostgreSQL gestionado en Neon. | Implementado |
| RNF05 | Archivos | Entregas en filesystem de Render; el plan gratuito usa almacenamiento efímero. | Limitación actual |
| RNF06 | Validación | Pydantic valida dominios de correo, contraseña, rol, nota, periodo y otros payloads. | Implementado |
| RNF07 | API | Comunicación REST en JSON y multipart/form-data. | Implementado |
| RNF08 | Portabilidad | Flutter Web/PWA; prueba responsive para 320x568, 390x844, 768x1024 y 1366x768. | Implementado en código/pruebas |
| RNF09 | Mantenibilidad | Separación frontend por models/services/screens/widgets/core y backend en main/models/schemas/database. | Implementado |
| RNF10 | Integridad | FK, UNIQUE y políticas ondelete definidas en SQLAlchemy. | Implementado |
| RNF11 | CORS | allow_origins=["*"] en el backend. | Implementado; configuración permisiva |
| RNF12 | Rendimiento | Cliente usa timeout de 45 s en operaciones HTTP relevantes. No existe SLA formal. | Parcial |
| RNF13 | Calidad visual | La suite responsive abre paneles y opciones en cuatro resoluciones y comprueba ausencia de excepciones. | Implementado en pruebas |

## 1.4. MODELO DE CASOS DE USO
### 1.4.1. Diagramas de caso de uso

```mermaid

digraph G { graph [rankdir=LR,bgcolor="transparent",splines=ortho,nodesep=0.35,ranksep=0.65]; node[shape=ellipse,style=filled,fillcolor="#F5F8FC",color="#5E759D",fontname="Arial",fontsize=9]; edge[color="#647A9B",arrowsize=0.7];
admin[shape=box,label="Administrador",fillcolor="#E8F1FB"]; teacher[shape=box,label="Docente",fillcolor="#E8F8E2"]; parent[shape=box,label="Acudiente",fillcolor="#FFF6DD"];
login[label="Autenticar usuario"]; users[label="Gestionar estudiantes y docentes"]; grades[label="Gestionar grados"]; academic[label="Gestionar evaluación / logros"]; attend[label="Registrar asistencia"]; tasks[label="Gestionar actividades y entregas"]; conv[label="Gestionar convivencia y alertas"]; bulletin[label="Generar boletín PDF"]; collect[label="Avisar recogida"]; content[label="Gestionar materiales / horario / calendario"]; notif[label="Consultar notificaciones"]; reports[label="Consultar reportes"];
admin->login; teacher->login; parent->login; admin->users; admin->grades; admin->academic; admin->attend; admin->conv; admin->bulletin; admin->content; admin->reports; teacher->academic; teacher->attend; teacher->tasks; teacher->conv; teacher->collect; teacher->content; teacher->notif; parent->tasks; parent->bulletin; parent->content; parent->notif;
}
```

### 1.4.2. Descripción de caso de uso

| ID | Nombre | Actor | Prerrequisitos | Flujo | Excepciones |
|---|---|---|---|---|---|
| CU01 | Autenticar usuario | Administrador/Docente/Acudiente | Cuenta registrada y API disponible. | 1) Ingresar correo y contraseña. 2) Validar UI. 3) POST /auth/login/. 4) Buscar cuenta. 5) Verificar bcrypt. 6) Crear sesión. 7) Dirigir al panel. | 401 por credenciales; error de conexión; rol sin destino. |
| CU02 | Restaurar sesión | Todos | Token local existente. | 1) Leer SharedPreferences. 2) GET /auth/session/. 3) Si es válida, reconstruir SesionUsuario. 4) Navegar al destino. | Token inválido o servidor reiniciado: limpiar sesión y volver a login. |
| CU03 | Gestionar estudiante | Administrador | Sesión de admin. | Consultar, registrar y revisar estudiantes. | La edición existente no persiste actualmente según documentación técnica. |
| CU04 | Gestionar evaluación | Docente/Administrador | Estudiante y curso válidos. | Registrar calificación 0..5 o logro/observación según grado y consultar. | Payload inválido: 422; periodo fuera de I-IV: 422. |
| CU05 | Registrar asistencia | Docente/Administrador | Estudiante/curso existentes. | Registrar estado para fecha no futura. | Fecha futura: 400. |
| CU06 | Gestionar actividad | Docente | Curso existente. | Crear tarea, descripción, fecha límite y permiso de video. | Datos faltantes: 422; curso inexistente: 404. |
| CU07 | Entregar actividad | Acudiente | Actividad vigente; estudiante y acudiente válidos. | Multipart: archivo + comentario; validar plazo/tipo/tamaño; guardar; notificar docente. | 400 por plazo/formato/video/tamaño; 404 por IDs; duplicado por UNIQUE. |
| CU08 | Calificar entrega | Docente | Entrega existente. | Registrar nota y retroalimentación. | 404 si no existe; 422 por nota fuera de rango. |
| CU09 | Gestionar convivencia | Docente/Administrador | Estudiante existente. | Crear situación, consultar, actualizar seguimiento o eliminar. | 404 si id inexistente. |
| CU10 | Atender alerta | Administrador | Alerta existente. | Marcar atendida y guardar respuesta. | 404 si no existe; 401/403 según sesión. |
| CU11 | Avisar recogida | Docente | Curso existente. | Registrar clase finalizada, crear notificaciones a acudientes y preparar WhatsApp. | Curso inexistente; estudiante/acudiente sin relación. |
| CU12 | Generar boletín | Administrador/Acudiente | Estudiante y firmas requeridas. | GET /estudiantes/{id}/boletin/; backend construye PDF con ReportLab. | No generar si falta firma requerida. |
| CU13 | Gestionar materiales | Docente/Administrador/Acudiente | Curso existente. | Subir/listar/eliminar o consultar material. | Formato/tamaño de archivo según endpoint. |
| CU14 | Gestionar horario | Administrador/Docente/Acudiente | Curso existente. | Crear/listar/eliminar bloque por día y hora. | Duplicidades o datos inválidos. |
| CU15 | Gestionar calendario | Administrador/usuarios consulta | Sesión. | Crear/listar/eliminar eventos. | Id inexistente. |
| CU16 | Consultar reportes | Administrador | Sesión de administrador. | Consultar estadísticas y reporte diario de asistencia. | Error de BD / filtros inválidos. |

## 1.5. MODELO DE DISEÑO DEL SISTEMA
### 1.5.1. Diagrama de clases detallado

```mermaid

digraph G { graph [rankdir=LR,bgcolor="transparent",splines=ortho]; node [shape=record,style="rounded,filled",fillcolor="#F5F8FC",color="#5E759D",fontname="Arial",fontsize=10]; edge[color="#647A9B",arrowsize=0.7];
auth[label="{AuthService|+ iniciarSesion(correo,password)\l+ cerrarSesion()\l+ restaurarSesion()\l+ recordarSesion()\l}"]; student[label="{Estudiante|+ id\l+ nombre\l+ correo\l+ grado\l+ acudiente\l}"]; teacher[label="{Teacher|+ id\l+ nombre\l+ correo\l+ especialidad\l+ gradosAsignados\l}"]; academic[label="{RegistroAcademico|+ id\l+ estudianteId\l+ materia\l+ tipo\l+ titulo\l+ descripcion\l+ calificacion\l}"]; activity[label="{Actividad|+ id\l+ cursoId\l+ titulo\l+ descripcion\l+ fechaEntrega\l+ permiteVideo\l}"]; delivery[label="{Entrega|+ id\l+ actividadId\l+ estudianteId\l+ estado\l+ archivoUrl\l+ nota\l+ retroalimentacion\l}"]; conviv[label="{SituacionConvivencia|+ id\l+ estudianteId\l+ tipo\l+ titulo\l+ seguimientoRealizado\l}"]; alert[label="{AlertaAlumno|+ id\l+ estudianteId\l+ severidad\l+ atendida\l+ respuestaAdmin\l}"]; material[label="{MaterialDidactico|+ id\l+ titulo\l+ grado\l+ materia\l+ enlace\l}"]; notif[label="{Notificacion|+ id\l+ rol\l+ destinatarioId\l+ titulo\l+ mensaje\l+ leida\l}"];
auth->student[label="sesión"]; teacher->activity[label="crea"]; activity->delivery[label="recibe"]; student->delivery[label="entrega"]; student->academic[label="tiene"]; student->conviv[label="tiene"]; student->alert[label="recibe"]; teacher->material[label="publica"]; delivery->notif[label="genera"]; }
```

### 1.5.2. Diagramas de secuencias

**Login**
```mermaid

digraph G { graph [rankdir=TB,bgcolor="transparent"]; node[shape=box,style="rounded,filled",fillcolor="#F5F8FC",color="#5E759D",fontname="Arial",fontsize=10]; edge[color="#647A9B"];
U[label="Usuario"]; UI[label="LoginScreen"]; A[label="AuthService.iniciarSesion"]; API[label="POST /auth/login/"]; DB[label="buscar_cuenta_por_correo + bcrypt"]; S[label="sesiones[access_token]"];
U->UI[label="correo + contraseña"]; UI->A[label="validar + invocar"]; A->API[label="HTTP POST / timeout 45s"]; API->DB[label="consultar / verify_password"]; DB->S[label="crear sesión si válido"]; S->API[label="access_token + rol + datos"]; API->A[label="JSON"]; A->UI[label="SesionUsuario / error"]; UI->U[label="panel o mensaje"];
}
```

**Entrega**
```mermaid

digraph G { graph [rankdir=TB,bgcolor="transparent"]; node[shape=box,style="rounded,filled",fillcolor="#FFF9EA",color="#B38D2E",fontname="Arial",fontsize=10]; edge[color="#7B6B43"]; P[label="Acudiente"]; UI[label="Pantalla actividad"]; API[label="POST /tareas/{id}/entregas/"]; R[label="Validar plazo / tarea"]; V[label="Validar estudiante y acudiente"]; F[label="Validar extensión / video / 200 MB"]; S[label="Guardar archivo"]; DB[label="INSERT tareas_entregas"]; N[label="Crear notificación al docente"]; P->UI->API->R->V->F->S->DB->N; }
```

### 1.5.3. Diagrama entidad relación

```mermaid

digraph G { graph [rankdir=LR,bgcolor="transparent",splines=ortho,nodesep=0.22,ranksep=0.48,ratio=compress]; node[shape=plain,fontname="Arial"]; edge[color="#60759b",penwidth=1.1,arrowsize=0.65];
admin[label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" BGCOLOR="#EAF2F8"><TR><TD><B>administradores</B></TD></TR><TR><TD ALIGN="LEFT">PK id</TD></TR><TR><TD ALIGN="LEFT">correo UNIQUE</TD></TR><TR><TD ALIGN="LEFT">password_hash</TD></TR></TABLE>>];
prof[label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" BGCOLOR="#EAF2F8"><TR><TD><B>profesores</B></TD></TR><TR><TD ALIGN="LEFT">PK id</TD></TR><TR><TD ALIGN="LEFT">correo UNIQUE</TD></TR><TR><TD ALIGN="LEFT">especialidad</TD></TR></TABLE>>];
acud[label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" BGCOLOR="#EAF2F8"><TR><TD><B>acudientes</B></TD></TR><TR><TD ALIGN="LEFT">PK id</TD></TR><TR><TD ALIGN="LEFT">correo UNIQUE</TD></TR><TR><TD ALIGN="LEFT">telefono</TD></TR></TABLE>>];
est[label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" BGCOLOR="#E8F8F5"><TR><TD><B>estudiantes</B></TD></TR><TR><TD ALIGN="LEFT">PK id</TD></TR><TR><TD ALIGN="LEFT">grado_id FK</TD></TR><TR><TD ALIGN="LEFT">acudiente_id FK</TD></TR></TABLE>>];
gr[label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" BGCOLOR="#E8F8F5"><TR><TD><B>grados</B></TD></TR><TR><TD ALIGN="LEFT">PK id</TD></TR><TR><TD ALIGN="LEFT">nombre UNIQUE</TD></TR></TABLE>>];
curso[label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" BGCOLOR="#E8F8F5"><TR><TD><B>cursos</B></TD></TR><TR><TD ALIGN="LEFT">PK id</TD></TR><TR><TD ALIGN="LEFT">instructor_id FK</TD></TR><TR><TD ALIGN="LEFT">grado_id FK</TD></TR></TABLE>>];
matr[label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" BGCOLOR="#E8F8F5"><TR><TD><B>matriculas</B></TD></TR><TR><TD ALIGN="LEFT">PK id</TD></TR><TR><TD ALIGN="LEFT">student_id FK</TD></TR><TR><TD ALIGN="LEFT">course_id FK</TD></TR></TABLE>>];
cal[label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" BGCOLOR="#E8F8F5"><TR><TD><B>calificaciones</B></TD></TR><TR><TD ALIGN="LEFT">PK id</TD></TR><TR><TD ALIGN="LEFT">student_id FK</TD></TR><TR><TD ALIGN="LEFT">course_id FK</TD></TR><TR><TD ALIGN="LEFT">periodo, score</TD></TR></TABLE>>];
asi[label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" BGCOLOR="#FCECEF"><TR><TD><B>asistencias</B></TD></TR><TR><TD ALIGN="LEFT">PK id</TD></TR><TR><TD ALIGN="LEFT">student_id FK</TD></TR><TR><TD ALIGN="LEFT">course_id FK</TD></TR><TR><TD ALIGN="LEFT">fecha, status</TD></TR></TABLE>>];
conv[label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" BGCOLOR="#FCECEF"><TR><TD><B>convivencia</B></TD></TR><TR><TD ALIGN="LEFT">PK id</TD></TR><TR><TD ALIGN="LEFT">student_id FK</TD></TR><TR><TD ALIGN="LEFT">seguimiento</TD></TR></TABLE>>];
alert[label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" BGCOLOR="#FCECEF"><TR><TD><B>alertas_alumnos</B></TD></TR><TR><TD ALIGN="LEFT">PK id</TD></TR><TR><TD ALIGN="LEFT">student_id FK</TD></TR><TR><TD ALIGN="LEFT">atendida</TD></TR></TABLE>>];
tarea[label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" BGCOLOR="#FFF6DD"><TR><TD><B>tareas</B></TD></TR><TR><TD ALIGN="LEFT">PK id</TD></TR><TR><TD ALIGN="LEFT">curso_id FK</TD></TR><TR><TD ALIGN="LEFT">fecha_entrega</TD></TR></TABLE>>];
ent[label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" BGCOLOR="#FFF6DD"><TR><TD><B>tareas_entregas</B></TD></TR><TR><TD ALIGN="LEFT">PK id</TD></TR><TR><TD ALIGN="LEFT">tarea_id FK</TD></TR><TR><TD ALIGN="LEFT">student_id FK</TD></TR><TR><TD ALIGN="LEFT">nota</TD></TR></TABLE>>];
mat[label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" BGCOLOR="#FFF6DD"><TR><TD><B>materiales_didacticos</B></TD></TR><TR><TD ALIGN="LEFT">PK id</TD></TR><TR><TD ALIGN="LEFT">curso_id FK</TD></TR><TR><TD ALIGN="LEFT">archivo/enlace</TD></TR></TABLE>>];
hor[label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" BGCOLOR="#EAF2F8"><TR><TD><B>horarios</B></TD></TR><TR><TD ALIGN="LEFT">PK id</TD></TR><TR><TD ALIGN="LEFT">curso_id FK</TD></TR><TR><TD ALIGN="LEFT">dia/hora</TD></TR></TABLE>>];
notif[label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" BGCOLOR="#EAF2F8"><TR><TD><B>notificaciones</B></TD></TR><TR><TD ALIGN="LEFT">PK id</TD></TR><TR><TD ALIGN="LEFT">destinatario FK?</TD></TR><TR><TD ALIGN="LEFT">leida</TD></TR></TABLE>>];
event[label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" BGCOLOR="#EAF2F8"><TR><TD><B>eventos_calendario</B></TD></TR><TR><TD ALIGN="LEFT">PK id</TD></TR><TR><TD ALIGN="LEFT">titulo, fecha</TD></TR></TABLE>>];
admin->event[style=dashed,label="creador"]; prof->curso[label="1:N"]; gr->curso[label="1:N"]; gr->est[label="1:N"]; acud->est[label="1:N"]; est->matr[label="1:N"]; curso->matr[label="1:N"]; est->cal[label="1:N"]; curso->cal[label="1:N"]; est->asi[label="1:N"]; curso->asi[label="1:N"]; est->conv[label="1:N"]; est->alert[label="1:N"]; curso->tarea[label="1:N"]; tarea->ent[label="1:N"]; est->ent[label="1:N"]; acud->ent[style=dashed,label="0:N"]; curso->mat[label="1:N"]; curso->hor[label="1:N"]; acud->notif[label="1:N"]; prof->notif[label="1:N"]; est->notif[label="0:N"];
}
```

### 1.5.4. Diagrama de componentes

```mermaid

digraph G { graph [rankdir=LR,bgcolor="transparent",splines=ortho]; node[shape=box,style="rounded,filled",fontname="Arial",color="#5E759D"]; edge[color="#647A9B",arrowsize=0.7];
flutter[label="Flutter Web / PWA\nDart + Material + http\nshared_preferences"]; services[label="Frontend services\nAuth, Actividades, Evaluación,\nAsistencia, Materiales, etc."]; api[label="FastAPI\nmain.py\nREST JSON + multipart"]; schemas[label="Pydantic\nschemas.py"]; orm[label="SQLAlchemy 2.0\nmodels.py"]; db[label="PostgreSQL\nNeon"]; files[label="Render filesystem\nuploads/entregas/\nactual: efímero"]; pdf[label="ReportLab\nBoletines PDF"]; wa[label="WhatsApp / wa.me\nurl_launcher"]; alembic[label="Alembic\n13 revisiones"];
flutter->services; services->api[label="HTTP"]; api->schemas[label="validación"]; api->orm[label="ORM"]; orm->db; alembic->db[label="migraciones"]; api->files[label="archivos"]; api->pdf[label="generación"]; flutter->wa[label="enlace"];
}
```

## 1.6. PRODUCTO DEL SOFTWARE

La documentación técnica aportada registra el frontend de producción en `https://edu-campus-app-frontend.vercel.app` y el backend en `https://educampus-backend-rwz6.onrender.com`. La presentación vieja contiene mockups iniciales; se consideran material histórico y no evidencia de que el diseño final sea idéntico.

---
# SEGUNDA PARTE
## II. PRUEBAS DEL SOFTWARE
### 2.1. INTRODUCCIÓN

La unidad de pruebas busca verificar el comportamiento de EduCampus por niveles: unitario, integración, sistema y aceptación. El diseño se concentra en caminos críticos: autenticación, evaluación, asistencia, actividades/entregas, boletines, convivencia, alertas y notificaciones. Las pruebas existentes en el repositorio son una prueba de arranque y una batería responsive; el resto de casos de este documento quedan diseñados para ejecución en un ambiente controlado.

### 2.2. PLANIFICACIÓN DE LAS PRUEBAS
#### 2.2.1. Objetivos de las pruebas

**Objetivo general:** verificar la corrección funcional e integración del sistema EduCampus y detectar fallas en las reglas de negocio críticas antes de aceptación.

**Objetivos específicos:** verificar autenticación y sesiones; validar límites y dominios de datos; comprobar reglas de asistencia y entregas; validar generación de boletines; comprobar navegación responsive; verificar integración frontend-backend y persistencia PostgreSQL; identificar riesgos de seguridad, disponibilidad y almacenamiento.

#### 2.2.2. Alcance

| Módulo | Objetivos |
|---|---|
| Autenticación | Login, sesión, logout, restauración y recuperación. |
| Usuarios | Registro, consulta y permisos. |
| Evaluación | Nota 0..5 y observaciones por periodo. |
| Asistencia | Estudiantes y docentes; fechas futuras. |
| Actividades/entregas | Plazo, formato, video, tamaño, duplicidad y calificación. |
| Boletines | Reglas de firma y generación PDF. |
| Convivencia/alertas | Creación, seguimiento y atención. |
| Notificaciones/recogida | Creación y consulta. |
| Horario/calendario | CRUD y consulta. |
| PWA/responsive | 4 tamaños definidos por pruebas automáticas. |

#### 2.2.3. Estrategias de pruebas

| Nivel | Técnicas | Estrategia | Herramientas |
|---|---|---|---|
| Unitarias | Equivalencia, límites, caja blanca | Métodos y validadores críticos | flutter_test, pytest/manual según entorno |
| Integración | Incremental ascendente/descendente, pruebas basadas en hilos | Frontend ↔ API ↔ BD; API ↔ Storage | Flutter test, http client, Postman/cURL |
| Sistemas | Seguridad, rendimiento, usabilidad, portabilidad, fiabilidad, mantenibilidad | Validación end-to-end de módulos | OWASP ZAP, Apache JMeter, navegador, SonarQube |
| Aceptación | Escenarios de negocio | Flujos de rol completos | Selenium/Katalon o ejecución guiada |

#### 2.2.4. Ambiente de pruebas

**Hardware:** no se define un equipo concreto en las fuentes; para ejecución reproducible deberá registrarse el computador usado por el equipo.  
**Software observado en el proyecto:** Dart/Flutter SDK requerido por `pubspec.yaml` (Dart `^3.13.2`), FastAPI 0.141.1, SQLAlchemy 2.0.54, PostgreSQL, Alembic 1.20.0, Pydantic 2.13.5, ReportLab 5.0.1, Pillow 12.3.0.

### 2.3. PRUEBAS UNITARIAS
#### Análisis de las pruebas

El repositorio ya contiene `widget_test.dart` (arranque) y `responsive_test.dart` (paneles/menú en cuatro resoluciones). Se añaden casos de validación derivados del código de `servicio_auth.dart` y `schemas.py`.

#### Diseño de casos de pruebas — clases de equivalencia

| Condición | Clase válida | Clase no válida | Casos |
|---|---|---|---|
| Correo | Email válido y @gmail.com | Formato inválido o dominio distinto | CP-002/CP-003 |
| Password | 6..100 + mayúscula+número+especial | fuera de rango o sin requisito | CP-001/CP-002 |
| Nota | 0..5 | <0 o >5 | CP-007..009 |
| Periodo | I..IV | otro valor | CP-008..010 |
| Fecha asistencia | hoy o pasado | futuro | CP-011..012 |
| Archivo | permitido <=200 MiB | extensión no válida / >200 MiB | CP-013..017 |
| Video | permite_video=true | video cuando false | CP-015 |

#### Diseño por valores límites

| Variable | Inferior | Exacto | Superior | Resultado esperado |
|---|---|---|---|---|
| Contraseña | 5 | 6 | 7 | 5 falla; 6 pasa. |
| Contraseña | 99 | 100 | 101 | 100 pasa; 101 falla. |
| Calificación | -0.01 | 0 | 0.01 | 0 pasa; negativo falla. |
| Calificación | 4.99 | 5 | 5.01 | 5 pasa; 5.01 falla. |
| Archivo | 199 MiB | 200 MiB | 200 MiB+1 | 200 pasa; +1 falla. |
| Fecha asistencia | ayer | hoy | mañana | hoy pasa; mañana falla. |
| Periodo | III | I o IV | V | I y IV pasan; V falla. |
| Responsive width | 899 | 900 | 901 | 899 usa menú móvil; 900 no. |

#### Ejecución y evaluación

Los casos que requieren servidor, base de datos o herramienta externa se marcan como **Pendiente de ejecución** para no presentar como ejecutados resultados que no se observaron en este entorno.

### 2.4. PRUEBAS DE INTEGRACIÓN
#### 2.4.1. Estrategia de Pruebas incrementales

| ID | Integración | Estrategia | Caso | Resultado esperado |
|---|---|---|---|---|
| I01 | AuthService ↔ /auth/login/ | Ascendente | Login válido/401 | SesionUsuario correcta o error controlado. |
| I02 | API auth ↔ PostgreSQL | Descendente | Cuenta existente/inexistente | Rol y credenciales resueltos correctamente. |
| I03 | Tarea ↔ Entrega ↔ archivo ↔ notificación | Por hilo | Entrega válida/vencida | Persistencia, regla de plazo y notificación coordinadas. |
| I04 | Calificaciones ↔ boletín ↔ firmas | Por hilo | Boletín completo/incompleto | PDF generado solo con condiciones satisfechas. |

#### 2.4.2. Estrategia de Pruebas basadas en hilos

**Hilo Autenticación:** Login → búsqueda por rol → bcrypt → sesión → panel.  
**Hilo Entrega:** consulta tarea → multipart → reglas de plazo/formato/tamaño → archivo → BD → notificación.  
**Hilo Boletín:** consulta periodo → calificaciones/observaciones → firmas → ReportLab → PDF.

#### 2.4.3. Diseño casos de pruebas de integración

Usar I01-I04 como casos base y combinarlos con los casos CP-001..CP-022. Ejecución: pendiente.

### 2.5. PRUEBAS DE SISTEMAS

#### 2.5.1. Pruebas de seguridad

**Tipo:** Seguridad.  
**Nombre:** Protección de autenticación.  
**Descripción:** Comprobar que contraseñas incorrectas no generan sesión y que endpoints protegidos rechazan tokens inválidos..  
**Ambiente:** API levantada + PostgreSQL de pruebas; cuentas ficticias..  
**Herramientas/metodología:** Pruebas API + revisión estática; OWASP ZAP como herramienta propuesta por la plantilla..  
**Diseño:** Diseño listo; ejecución externa requerida..  
**Resultado:** No ejecutado en este entorno..

#### 2.5.2. Pruebas de rendimiento

**Tipo:** Rendimiento.  
**Nombre:** Respuesta de operaciones críticas.  
**Descripción:** Medir latencia de login, listado de tareas, carga de entrega y boletín bajo carga controlada..  
**Ambiente:** Ambiente staging; datos representativos..  
**Herramientas/metodología:** Apache JMeter según plantilla..  
**Diseño:** Diseño listo; ejecución externa requerida..  
**Resultado:** No ejecutado; no se inventan tiempos..

#### 2.5.3. Pruebas de usabilidad

**Tipo:** Usabilidad.  
**Nombre:** Navegación por rol.  
**Descripción:** Comprobar que los tres paneles abren opciones sin excepciones y que formularios muestran validaciones comprensibles..  
**Ambiente:** Chrome/Edge; resoluciones definidas en responsive_test.dart..  
**Herramientas/metodología:** Flutter widget tests + inspección manual..  
**Diseño:** Hay prueba automática de desbordes..  
**Resultado:** Pendiente de ejecución completa..

#### 2.5.4. Pruebas de portabilidad

**Tipo:** Portabilidad.  
**Nombre:** PWA y tamaños.  
**Descripción:** Verificar que la interfaz funciona en teléfono, tablet y escritorio; la suite actual cubre cuatro tamaños..  
**Ambiente:** 320x568, 390x844, 768x1024, 1366x768..  
**Herramientas/metodología:** flutter_test + navegador..  
**Diseño:** Hay prueba automática de cuatro tamaños..  
**Resultado:** Ejecución no realizada aquí..

#### 2.5.5. Pruebas de fiabilidad

**Tipo:** Fiabilidad.  
**Nombre:** Restauración de sesión y BD.  
**Descripción:** Comprobar recuperación cuando el backend reinicia y cuando la BD pierde conectividad temporalmente..  
**Ambiente:** Backend staging + PostgreSQL..  
**Herramientas/metodología:** Pruebas de integración/API..  
**Diseño:** Diseño de casos..  
**Resultado:** Pendiente..

#### 2.5.6. Pruebas de mantenibilidad

**Tipo:** Mantenibilidad.  
**Nombre:** Migraciones y estructura.  
**Descripción:** Verificar que Alembic actualiza esquema y que los servicios del frontend pueden modificarse sin romper pantallas no relacionadas..  
**Ambiente:** Repositorio completo..  
**Herramientas/metodología:** Revisión estática + ejecución de migraciones..  
**Diseño:** 13 revisiones Alembic presentes..  
**Resultado:** Pendiente de pipeline automatizado..

### 2.6. PRUEBAS DE ACEPTACIÓN
#### 2.6.1. Diseño de caso de pruebas

| ID | Requisito asociado | Escenario de negocio | Datos | Pasos | Resultado esperado | Resultado obtenido |
|---|---|---|---|---|---|---|
| CA001 | RF01 | Ingreso exitoso | correo/contraseña válidos | Abrir app → ingresar → validar | Acceso al panel | Pendiente |
| CA002 | RF07 | Docente registra nota válida | score=4.5, periodo=II | Abrir evaluación → guardar | Nota visible/persistida | Pendiente |
| CA003 | RF12 | Registrar convivencia | situación positiva | Abrir convivencia → registrar | Situación visible y seguimiento disponible | Pendiente |
| CA004 | RF18/RF19 | Acudiente entrega tarea en plazo | PDF <=200 MiB | Abrir tarea → adjuntar → enviar | Entrega creada | Pendiente |
| CA005 | RF09 | Descargar boletín | student_id + firmas | Abrir boletín → descargar | PDF generado | Pendiente |
| CA006 | RF14 | Aviso recogida | curso con acudientes | Finalizar clase → avisar | Notificaciones creadas | Pendiente |

#### 2.6.2. Ejecución y evaluación de la prueba

La plantilla solicita ejecución con una herramienta como Selenium/Katalon y evidencias. En esta entrega se deja el diseño completo y el resultado como Pendiente de ejecución, porque no se observó una corrida real de Selenium/Katalon en las fuentes.

### 2.7. CONCLUSIONES UNIDAD DE PRUEBAS

Las pruebas unitarias y de caja blanca permiten cubrir validadores y ramas críticas; las pruebas de integración deben priorizar autenticación, entregas y boletines; las pruebas de sistema deben concentrarse en seguridad, disponibilidad, archivos y responsive; y la aceptación debe confirmar los flujos completos por rol. El principal criterio QA es distinguir entre lo que ya está automatizado en el repositorio y lo que todavía requiere ejecución en ambiente.

---
# TERCERA PARTE
## III. MEDICION DEL SOFTWARE
### 3.1. INTRODUCCION

La medición se usa para obtener indicadores reproducibles sobre tamaño, estructura y atributos de calidad. En este proyecto se combinan conteos directos del repositorio con indicadores derivados de la arquitectura y pruebas existentes. La plantilla solicita además calidad según ISO/IEC 25010; para esta edición se usa como referencia la versión publicada ISO/IEC 25010:2023.

### 3.1.1. Objetivos

Obtener una línea base cuantitativa del software; identificar áreas de complejidad o acoplamiento; medir cobertura estructural de calidad; y proporcionar una base para comparar futuras versiones.

### 3.1.2. Alcance

Frontend `frontend/lib`, backend Python excluyendo `venv`, pruebas Flutter y modelos ORM. No se cuentan artefactos de dependencias generados.

### 3.1.3. Tipos y herramientas de métricas

Conteos con scripts Python/Unix; análisis AST de Python; conteo de pantallas/servicios; análisis de endpoints; y matriz de calidad. SonarQube y herramientas comerciales quedan como herramientas propuestas por la plantilla, pero no se reportan como ejecutadas.

### 3.2. MEDICION DEL SOFTWARE - ATRIBUTOS INTERNOS
#### 3.2.1. Métricas de tamaño del código fuente

| Métrica | Método | Resultado | Interpretación |
|---|---|---:|---|
| LOC frontend Dart (sin blanco) | Cuenta no blanca de frontend/lib | 14.611 | Volumen de código cliente medido directamente. |
| LOC backend Python (sin blanco) | Cuenta no blanca excluyendo backend/venv | 4.446 | Volumen de código servidor medido directamente. |
| LOC total fuente (sin blanco) | Dart + Python | 19.057 | Tamaño combinado de las capas principales. |
| Archivos Dart productivos | find frontend/lib/**/*.dart | 92 | Fragmentación del frontend. |
| Pantallas Flutter | find frontend/lib/screens/**/*.dart | 38 | Cobertura de UI por módulo. |
| Servicios Flutter | find frontend/lib/services/**/*.dart | 27 | Componentización del acceso a datos/estado. |
| Modelos Dart | find frontend/lib/models/**/*.dart | 16 | Modelado del dominio cliente. |
| Widgets reutilizables | find frontend/lib/widgets/**/*.dart | 7 | Reutilización de UI. |
| Clases ORM SQLAlchemy | models.py AST | 21 | Entidades persistentes activas en código actual. |
| Endpoints FastAPI | main.py AST | 62 | Superficie funcional de API. |
| Revisiones Alembic | alembic/versions/*.py | 13 | Evolución del esquema. |
| Pruebas Flutter | frontend/test/*.dart | 2 | Pruebas automatizadas presentes. |

**Nota sobre LOC:** el conteo no blanco es un indicador reproducible de tamaño, no una equivalencia directa con calidad. No se presenta como una medición SonarQube.

#### 3.2.2. Métricas de tamaño orientadas a clases

En el backend ORM, DIT=1 para las clases que heredan directamente de `Base`. WMC se aproxima por métodos explícitos definidos en cada clase; CBO se calcula como el número de referencias a otras entidades detectadas en `relationship()` y `ForeignKey()`.

| Clase | WMC | DIT | CBO aproximado | Cohesión cualitativa |
|---|---:|---:|---:|---|
| Administrador | 0 | 1 | 0 | Alta |
| Grado | 0 | 1 | 2 | Alta |
| Acudiente | 0 | 1 | 0 | Alta |
| Estudiante | 0 | 1 | 2 | Alta |
| Profesor | 0 | 1 | 0 | Alta |
| Curso | 0 | 1 | 2 | Alta |
| Matricula | 0 | 1 | 2 | Alta |
| Calificacion | 0 | 1 | 2 | Alta |
| Observacion | 0 | 1 | 2 | Alta |
| Asistencia | 0 | 1 | 2 | Alta |
| AsistenciaDocente | 0 | 1 | 2 | Alta |
| Convivencia | 0 | 1 | 1 | Alta |
| AlertaAlumno | 0 | 1 | 1 | Alta |
| Notificacion | 0 | 1 | 5 | Media |
| MaterialDidactico | 0 | 1 | 1 | Alta |
| Tarea | 0 | 1 | 1 | Alta |
| TareaEntrega | 0 | 1 | 5 | Media |
| Horario | 0 | 1 | 1 | Alta |
| Comunicado | 0 | 1 | 0 | Alta |
| EventoCalendario | 0 | 1 | 1 | Alta |
| ClaseFinalizada | 0 | 1 | 2 | Alta |

### 3.3. MEDICION DE LA CALIDAD DEL SOFTWARE - ATRIBUTOS EXTERNOS

La plantilla pide usabilidad, seguridad, portabilidad, mantenibilidad, rendimiento, fiabilidad, compatibilidad y adecuación funcional. La siguiente tabla usa indicadores observables del repositorio. ISO/IEC 25010:2023 define el modelo de calidad de producto para este tipo de evaluación.

| Característica | Métrica | Fórmula/criterio | Resultado | Análisis |
|---|---|---|---|---|
| Usabilidad | Cobertura responsive | 4 resoluciones verificadas en código de pruebas / 4 previstas | 100% del conjunto definido en responsive_test.dart | La suite recorre Login y los paneles por rol. |
| Portabilidad | Resoluciones cubiertas | 4 | 4 | 320x568; 390x844; 768x1024; 1366x768. |
| Seguridad | Validaciones de entrada | Correo, contraseña, rol, score, periodo y archivos | Cobertura definida en schemas.py/main.py | La cobertura debe complementarse con pruebas negativas y escaneo. |
| Fiabilidad | Rutas de salud | 2 endpoints: / y /health | 2/2 documentados | /health consulta SELECT 1 en PostgreSQL. |
| Compatibilidad | Capas cliente-servidor | Flutter + HTTP REST + FastAPI + JSON/multipart | 1 integración principal | No usa acceso directo del cliente a PostgreSQL. |
| Adecuación funcional | Requisitos funcionales documentados | 28 | 28 trazados al código/endpoints o limitaciones | RF22, RF23 y RF28 tienen estado parcial/no activo de frontend. |

### 3.4. CONCLUSIONES

El producto presenta una arquitectura modular y separada en cliente/servidor, con una base cuantificable de 15,009 líneas no blancas de Dart en frontend, 4,445 de Python en backend, 21 clases ORM, 62 endpoints y 13 revisiones Alembic. El principal riesgo no es la falta de componentes, sino algunas decisiones de operación y seguridad documentadas: sesiones en memoria, almacenamiento efímero de entregas en Render gratuito, CORS comodín y cifrado reversible adicional de contraseñas. Las métricas futuras deberían comparar estas mismas magnitudes para evidenciar tendencia y no solo valores aislados.

---
# CUARTA PARTE
## IV. ESTIMACION DEL SOFTWARE
### 4.1. Estimación por punto de función (PF)

Se presenta una estimación académica preliminar basada en el número de endpoints, entidades y operaciones observadas. Para evitar presentar el resultado como un conteo IFPUG certificado, se usan pesos medios y se declara el supuesto.

**Supuestos:** 28 entradas externas EI, 27 consultas EQ, 7 salidas externas EO y 21 archivos lógicos internos ILF; 0 archivos de interfaz externa. Con pesos medios 4/4/5/10: **UFP = 490 puntos de función sin ajuste**. Con una productividad referencial de 10 h/PF únicamente para comparar órdenes de magnitud: 4,900 h, aproximadamente 30.6 persona-mes a 160 h/mes. Esto no representa el esfuerzo real del equipo; requiere calibración de productividad.

### 4.2. Estimación por punto de caso de uso

Se consideran 3 actores humanos complejos y 16 casos de uso principales. Con el esquema didáctico de 3 puntos por actor complejo y 10 puntos por caso de uso medio: UAW=9, UUCW=160, UUCP=169. Con 20 h/PCU como productividad referencial: 3,380 h, aproximadamente 21.1 persona-mes. El cálculo es académico y no sustituye el conteo formal de transacciones por caso.

### 4.3. Estimación por puntos de objetos

Se contabilizan 38 pantallas, 27 servicios y 16 modelos Dart. Con pesos referenciales de 2 puntos por pantalla, 1 por servicio y 2 por modelo: **PO = 119**. Con 8 h/PO: 952 h, 5.95 persona-mes. Es una aproximación comparativa.

### 4.4. Estimación por puntos de Historias

| Épica/módulo | Story Points |
|---|---:|
| Autenticación y sesión | 13 |
| Gestión usuarios/grados | 13 |
| Evaluación/boletines | 18 |
| Asistencia | 11 |
| Convivencia/alertas | 13 |
| Actividades/entregas | 18 |
| Materiales | 8 |
| Horario/calendario | 8 |
| Notificaciones/recogida | 13 |
| Formularios/campos | 13 |
| Reportes/configuración | 8 |
| PWA/portabilidad | 6 |
| QA/integración | 10 |

**Total:** 152 SP. Con una velocidad hipotética de 24 SP por sprint, la carga equivale a aproximadamente 7 sprints. La velocidad no está medida en el repositorio, por lo que esto es una hipótesis de planificación.

### 4.5. Estimación con una herramienta

La plantilla solicita una herramienta digital. En las fuentes no aparece una corrida de una herramienta concreta de estimación. Para no inventar un resultado, se deja la siguiente especificación de ejecución: cargar backlog/módulos y registrar tamaño, velocidad, esfuerzo, duración y costo; después comparar contra PF/PCU/PO.

### 4.6. Análisis de los resultados

Los cuatro modelos no deben compararse por el número bruto sin normalizar: cada método mide una unidad diferente. PF y PCU producen órdenes de magnitud altos porque utilizan productividades referenciales que no están calibradas con este equipo académico; los puntos de objeto dan una cifra menor porque solo modelan componentes UI/servicio; los story points son especialmente útiles para planificación incremental si se dispone de velocidad observada. Por ausencia de datos históricos de productividad y costo por hora del equipo, no se presenta un costo monetario como si fuera real.

| Modelo | Tamaño | Esfuerzo referencial | Tiempo referencial | Personas implícitas a 1 año académico |
|---|---:|---:|---:|---:|
| PF | 490 UFP | 4,900 h | 30.6 PM | 2.55 personas promedio/12 meses |
| PCU | 169 UUCP | 3,380 h | 21.1 PM | 1.76 personas promedio/12 meses |
| PO | 119 PO | 952 h | 5.95 PM | 0.50 personas promedio/12 meses |
| Historias | 144 SP | depende de velocidad real | ~6 sprints a 24 SP/sprint | depende de duración sprint |

### 4.7. Conclusiones

La estimación más defendible para seguimiento del proyecto es la basada en historias, siempre que el equipo registre velocidad real por sprint. Las cifras de PF, PCU y PO deben conservarse como referencias académicas y recalibrarse con datos reales de esfuerzo. La ausencia de historial de horas/costo impide afirmar un presupuesto monetario real.

# CONCLUSIONES GENERALES

EduCampus presenta un sistema funcional con frontend Flutter Web/PWA, backend FastAPI y persistencia PostgreSQL, con cobertura de los procesos académicos y de seguimiento definidos para la institución. El código ya implementa autenticación, usuarios, grados, evaluación, asistencia, convivencia, alertas, actividades, entregas, materiales, horario, calendario, notificaciones y generación de boletines.

La revisión de calidad muestra que el proyecto cuenta con una base de pruebas automatizadas de arranque y responsive, pero necesita complementar la evidencia con ejecución formal de pruebas de integración, seguridad, rendimiento y aceptación. Asimismo, algunos riesgos técnicos ya identificados deben ser tratados antes de una operación institucional estable: sesiones en memoria, almacenamiento efímero de entregas, CORS amplio, mecanismo reversible de contraseñas y funciones de edición/comunicación no persistentes.

La documentación final se basa en el código actual y conserva las diferencias entre implementación, documentación histórica y propuesta inicial. Esto permite que el documento sea trazable y evita presentar como implementada una funcionalidad que todavía sea parcial o futura.

# REFERENCIAS - BIBLIOGRAFICAS

1. Equipo EduCampus. *EduCampus_app (14).zip*. Código fuente del frontend Flutter y backend FastAPI, septiembre de 2026.
2. *Plantilla proyecto final.doc*. Documento guía suministrado para la estructura del proyecto y pruebas.
3. Equipo EduCampus. *presentacion vieja.pdf*. Presentación inicial del proyecto; fuente contextual para problemática, objetivos y metodología Scrum propuesta.
4. ISO. *ISO/IEC 25010:2023 — Systems and software engineering — Systems and software Quality Requirements and Evaluation (SQuaRE) — Product quality model*. Edición 2, 2023.
