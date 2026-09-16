# om4mtools-matlab

Toolbox de utilidades MATLAB del grupo OM4M (Optical Methods for Measuring).
Modernización de om4mmatlabutils.

## Contexto
- Objetivo del proyecto (reconfirmado 2026-09-15): dejar la migración desde
  `om4mmatlabutils` ordenada en Git y la suite de tests corriendo de nuevo —
  cumplido y liberado como v1.0.0 (2026-09-16). Proyecto estrictamente
  personal, sin plan de empaquetarlo/distribuirlo como toolbox o módulo
  MATLAB. **Excepciones puntuales (2026-09-16):** unificar la validación de
  parámetros con bloques `arguments` (name-value) en todo `src/`, y unificar
  docstrings (convención estándar de MATLAB, incluida una breve por test)
  sí están en alcance ahora — ver TODO.md para el detalle y lo demás que
  sigue descartado explícitamente.
- Directorio de trabajo: `C:\user\AQ_SCC\GitHub\om4mtools-matlab` — repo Git, migrado
  desde `Dropbox\AQ_EXP\75 om4mtools-matlab\` el 2026-09-14 (esa copia de Dropbox se
  conserva solo como backup, ver `README_IMPORTANTE_14SEP26.md` ahí — no es el sitio
  de trabajo activo)
- Proyecto estrictamente personal por ahora: siempre se ejecuta en máquinas donde
  existe el propio Dropbox del usuario en una ubicación conocida (ver `src/dropbox.m`)
  — el código vive en Git, pero las fixtures de test siguen viviendo en Dropbox
- Fixtures de test en: `<dropbox root>\AQ_EXP\DataSetsForTesting\om4mtools-matlab`
  (NO en `tests/fixtures/`, que se mantiene vacío a propósito — ver
  `tests/fixtures/README.md` y `fixturesRoot()`)

## Recursos de referencia
- MATLAB Agentic Toolkit:    https://github.com/matlab/matlab-agentic-toolkit
  (servidor MCP — ver sección "MATLAB MCP" en README.md para instalación y
  verificación)
- MATLAB Coding Guidelines:  https://github.com/mathworks/MATLAB-Coding-Guidelines
  (copia local en `MATLAB-Coding-Guidelines.pdf`, raíz del repo)
- Prompts de referencia:     https://github.com/matlab/prompts/tree/main/prompts/programming

## Estructura
- `src/`     — todo plano, sin subdirectorios ni namespaces, **salvo `+OM4MClassLib` y
  `+Zernikes`**: se mantienen como package `+` (decisión explícita del usuario,
  ver DECISIONS.md — aplanarlos habría obligado a reescribir ~25+ call sites)
- `tests/`   — todo plano, un TestXxx.m por función
- `mex/src/` — código C/C++ + proyecto Visual Studio (.sln)
- `mex/bin/` — binarios precompilados (SÍ van al repo)
- `dll/src/<Nombre>/` — código C/C++ de dependencias `loadlibrary()` (no MEX),
  un subdirectorio por DLL, con su `.vcxproj` (sin `.sln` propio salvo que
  haga falta)
- `dll/bin/` — `.dll` + `.h` (headers, incluidos los que el propio header
  incluya, p.ej. `shrhelp.h`) que `loadlibrary()` necesita en tiempo de
  ejecución (SÍ van al repo, mismo criterio que `mex/bin/`)

## Convenciones de código
- Bloques `arguments` para toda validación de entrada (no inputParser)
- Nunca usar `i`, `j` como variables de bucle
- Seguir MATLAB-Coding-Guidelines en todo momento (`MATLAB-Coding-Guidelines.pdf`)
- Sin refactor ni modernización masiva de `src/` existente, **salvo la
  unificación de validación de parámetros con `arguments` (name-value) y
  la unificación de docstrings** (excepciones explícitas añadidas
  2026-09-16, ver TODO.md). Fuera de eso, aplicar estas convenciones solo
  a código nuevo o que ya se esté tocando por otro motivo

## MEX
- Código fuente en mex/src/ — proyecto Visual Studio (.sln)
- Binarios precompilados en mex/bin/ (SÍ van al repo)
- Recompilar con: run('mex/build.m') — usa MSBuild sobre el .sln
- Intermedios de compilación (Debug/, Release/, .obj, .pdb) NO van al repo

## Tests
- Framework: matlab.unittest.TestCase exclusivamente
- Ejecutar suite completa (sin hardware): run('tests/run_all_tests.m')
- Ejecutar solo tests de hardware (a pie de mesa, con el equipo conectado): run('tests/run_hardware_tests.m')
- Tests que requieren hardware real (cámaras, motores, fuentes) van etiquetados
  `methods (Test, TestTags = {'Hardware'})` — excluidos de run_all_tests.m automáticamente.
  Excepción: los tests contra `MockCam` (software, sin hardware real) NO se etiquetan.
- `tests/setupPath.m` en cada `TestMethodSetup` (`setupPath();`) añade src/,
  tests/fixtures/ y `mex/bin/` (usado por `UnwrapperTypes.FlynMd`) —
  único punto de entrada, sustituye a los antiguos helpers por dominio
  (`testAAAddReferencesPath*.m`, `testAddReferemcesML_hg.m`, ya eliminados). También lo
  llaman `run_all_tests.m`/`run_hardware_tests.m`, así que cada test sigue siendo
  ejecutable en solitario (`run(testXxx)`) sin correr la suite completa antes.
- Restaurar el path en TestMethodTeardown con `matlabpath(resetPath); %#ok<RESETPATH>`
  (`tests/resetPath.m`), NUNCA `matlabpath(pathdef)` — `pathdef` resetea al path de
  fábrica de MATLAB y tira el path propio del usuario (otros proyectos, toolboxes).
- Fixtures: `tests/fixtures/` está vacío a propósito. Los datos viven en
  `<dropbox root>\AQ_EXP\DataSetsForTesting\om4mtools-matlab`, resueltos vía
  `fixturesRoot()` (que envuelve `src/dropbox.m`) — no hace falta descargar nada, el
  proyecto es personal y siempre corre en una máquina con ese Dropbox montado. Ver
  `tests/fixtures/README.md`.

## Commits
- Atómicos: un cambio lógico por commit
- No mezclar refactor con nueva funcionalidad

## Lo que NO tocar sin confirmación explícita
- [Añadir aquí según vaya surgiendo]
