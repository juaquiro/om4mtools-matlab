# om4mtools-matlab — TODO

> **Objetivo del proyecto (reconfirmado 2026-09-15):** limpiar la migración
> desde `om4mmatlabutils`, dejarla ordenada en Git y volver a tener la suite
> de tests corriendo. Nada más. Este repo es estrictamente personal, no va a
> evolucionar mucho más allá de esto — no hay plan de empaquetarlo/distribuirlo
> como toolbox o módulo MATLAB, ni de refactorizar el código existente. Ver
> "Descartado explícitamente" más abajo.
>
> Historial completo de las fases ya cerradas (auditoría, reorganización de
> estructura, migración de tests, creación del repo Git, CI) está en
> `DECISIONS.md` y en el historial de git de este mismo fichero
> (`git log -- TODO.md`) — no se repite aquí.

## Completado (resumen)

- Estructura reorganizada: `src/` y `tests/` planos (salvo `+OM4MClassLib` y
  `+Zernikes`), `mex/src/` + `mex/bin/` para el proyecto Visual Studio de
  `IOT2DPU`.
- Migración de tests legacy (`mtest` → `matlab.unittest.TestCase`),
  `tests/setupPath.m`/`resetPath.m` como único punto de entrada de path.
- Repo Git creado, publicado en `github.com/juaquiro/om4mtools-matlab`, con
  branching model (`develop`/`main`) y gate de CI estático
  (`structure-check.yml`/`release.yml`).
- Gran parte de la suite puesta en verde (fixtures de Coursera, `svmtrain` →
  `fitcsvm`, bugs de índice/gradiente, tests script-based mal detectados,
  etc. — detalle completo en DECISIONS.md).

## Pendiente

- [ ] **Cerrar la suite de tests.** Baseline documentado en DECISIONS.md
  ("Fase 3 — primera pasada de estandarización y baseline"). Quedan, entre
  otros:
  - **Computer Vision Toolbox SÍ está instalada en esta máquina** (24.2,
    R2024b) — la nota anterior de "no instalada" era errónea, corregida
    2026-09-15 tras verificarlo con el MCP server de MATLAB
    (`detect_matlab_toolboxes`). Identificados 14 tests que llaman
    directamente a APIs de CVT (grep de `estimateCameraParameters`,
    `detectCheckerboardPoints`, `cameraParameters`, `undistortImage`, etc. en
    `testFPA_UtilFunFPAClassVer.m` y `testFPA_UtilFunMapperMeasureClassVer.m`,
    no solo por patrón de nombre). Baseline inicial: 4/14 pasan, 10/14
    fallan — ninguno de los 10 fallos era limitación de entorno, eran 3 bugs
    reales de compatibilidad de API (nombre de toolbox obsoleto en un
    chequeo, tipo de retorno de `undistortImage` cambiado, validación de
    tipos más estricta en `cameraParameters`). **Arreglados los 3 (2026-09-15)
    — 14/14 pasan ahora:**
    1. `testHomographyCalcWithComputerVisionToolbox`: comprobaba
       `any(strcmp({ver.Name}, 'Computer Vision System Toolbox'))` (nombre
       pre-R2016b de la toolbox) y lanzaba `error('...NOT installed')` si no
       casaba — en R2024b el nombre es `'Computer Vision Toolbox'` (sin
       "System"). Corregido el string comparado (mismo patrón que ya usaban
       correctamente los tests `testUndistortImagesCVTbx_*` del mismo
       fichero).
    2. `testUndistortImagesCVTbx_5MAY20`/`_29JUN20`/`_15DIC20`: `assertEqual`
       esperaba que el 2º valor devuelto por `undistortImage` fuera el
       `double [0,0]` (`newOrigin`, comportamiento pre-R2024b); en R2024b ese
       2º valor es un objeto `cameraIntrinsics` (`camIntrinsics`, ver `help
       undistortImage`). Verificado empíricamente que con
       `'OutputView','same'` ese `cameraIntrinsics` devuelto es idéntico al
       de entrada (mismo `PrincipalPoint`/`FocalLength`/`ImageSize`) — no hay
       cambio de origen, igual que antes. Test corregido para comparar
       `camIntrinsicsOut.PrincipalPoint` contra `params.PrincipalPoint` (con
       tolerancia) en vez de comparar contra `[0,0]`; el resto del test
       (cálculo de `undistortedPoints` restando `newOrigin(1)`/`(2)`) se deja
       intacto fijando `newOrigin = [0,0]` explícitamente tras la
       comprobación, ya que sigue siendo cierto que no hay desplazamiento.
    3. `testMejoraCaluloDPMUsingLMMClass_APR20_GeomCal`,
       `testCaluloDPMUsingLMMClass_15DIC20`, `testDPMPowerRangeCalc`,
       `testLMM_Calibration_5MAY20`, `testLMM_Calibracion_1OCT20`,
       `testLMM_Calibracion_15DIC20`: error
       `MATLAB:fisheyeParameters:invalidType` — el campo
       `DetectedKeypoints` del struct de calibración cargado con `loadjson`
       es `double` (JSON no distingue logical/double), pero
       `cameraParameters(params_struct)` en R2024b exige `logical`. El propio
       código ya hacía este mismo cast para `EstimateTangentialDistortion` y
       `EstimateSkew` (comentario `%for loading we need to cast two values to
       logical`) — se añadió el mismo cast para `DetectedKeypoints`.
  - ~9 tests de `LensMapperMeasurement`/`CameraCalibration*` sin investigar.
  - `testFPADisplayProjectorC` (falla en `loadlibrary`, probablemente una
    librería C externa no instalada — sin confirmar). `DisplayProjectorPsych`
    y su test se eliminaron directamente (2026-09-15, a petición del
    usuario) en vez de investigar el fallo de Psychtoolbox.
  - ~15-20 tests restantes sin categorizar del todo.
  - `testQC_FeatureTest` (dependía de helpers y de `..\TestDB\`, ninguno de
    los dos presentes en este repo) se eliminó directamente (2026-09-15, a
    petición del usuario) en vez de esperar a recuperar esas dependencias.
  - No se espera necesariamente un 100% Passed en esta máquina — el objetivo
    es que cada fallo quede documentado (bug real vs. limitación de entorno
    vs. dependencia irrecuperable), no forzosamente resuelto.

- [x] **`Passive3DCam.m` + `Passive3DCamData.m`** (`ClassLib/+OM4MClassLib/+HW/`,
  detectado como hueco silencioso frente a `om4mmatlabutils`) — **decisión
  del usuario (2026-09-15): se quedan fuera para siempre, no se recuperan.**
  Ver FASE 7 en DECISIONS.md para el contexto completo de por qué se
  descartaron originalmente (2026-09-13).

- [ ] **Revisar si hay más huecos silenciosos frente a `om4mmatlabutils`**
  (`C:\user\AQ_SCC\GitHub\om4mmatlabutils`, repo original más completo que la
  copia de Dropbox usada en la migración) además de `Passive3DCam`/
  `Passive3DCamData` de arriba (ya resuelto: no se recuperan).

- [ ] **Revisar si faltan fixtures de test** (datos/assets, no código) en
  `om4mmatlabutils` que `tests/fixtures/` (vía `fixturesRoot()`) debería
  tener y que no llegaron a migrarse — por ejemplo por tests rotos por
  dependencias ausentes (`Passive3DCam`, etc.) o por el recorte de alcance de
  la Fase 1.

## Descartado explícitamente (2026-09-15)

A petición del usuario, se descarta cualquier objetivo relacionado con:

- **Refactorización de código**, incluida la exploración de `dynamicprops`
  para `Demodulator`/`Classifier`/`Unwrapper`/`aFeature`/`imaqCam` — la lista
  dinámica de propiedades actual (`PropsEnumList`) se queda tal cual está.
- **Modernización de código** más allá de lo ya hecho (bloques `arguments`
  generalizados, `checkcode` sobre todo `src/`, eliminar `i`/`j` donde
  queden, etc.).
- **Documentación uniforme**: formato de docstring estándar OM4M en todo
  `src/`, `Contents.m`, `help om4mtools`.
- **Empaquetado/distribución como toolbox o módulo MATLAB**: modelo de
  consumo como Git submodule congelado, `setup.m`, tags semánticos de
  versión (`v1.0.0`), transferencia a una organización GitHub del grupo
  (`om4mlab`).
- **Compilar MEX para otras plataformas** (`glnxa64`/`maci64`) o migrar el
  build de MSBuild a CMake.
- **Migración a Python** (`om4mtools-python`).

Si alguno de estos puntos vuelve a hacer falta en el futuro, el detalle
completo de cada uno (motivación, estado, decisiones ya tomadas) sigue
disponible en el historial de git de este fichero.
