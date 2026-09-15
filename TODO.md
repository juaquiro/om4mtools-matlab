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
  - ~15 tests que dependen de Computer Vision Toolbox (no instalada en esta
    máquina) — limitación de entorno, no bug.
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
