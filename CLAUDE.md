# om4mtools-matlab

Toolbox de utilidades MATLAB del grupo OM4M (Optical Methods for Measuring).
Modernización de om4mmatlabutils.

## Contexto
- Fase actual: Fase 1
- Directorio de trabajo: Dropbox/om4mtools-matlab/ (sin Git todavía)
- Proyecto estrictamente personal por ahora: siempre se ejecuta en máquinas donde
  existe el propio Dropbox del usuario en una ubicación conocida (ver `src/dropbox.m`)
- Fixtures de test en: `<dropbox root>\AQ_EXP\DataSetsForTesting\om4mtools-matlab`
  (NO en `tests/fixtures/`, que se mantiene vacío a propósito — ver
  `tests/fixtures/README.md` y `fixturesRoot()`)

## Recursos de referencia
- MATLAB Agentic Toolkit:    https://github.com/matlab/matlab-agentic-toolkit
- MATLAB Coding Guidelines:  https://github.com/mathworks/MATLAB-Coding-Guidelines
- Toolbox best practices:    https://github.com/mathworks/toolboxdesign
- Prompts de referencia:     https://github.com/matlab/prompts/tree/main/prompts/programming

## Modelo de consumo
Se usa como Git submodule congelado en proyectos consumidores.
Ver FASE 0.5 en TODO.md para detalles y comandos.

## Estructura
- `src/`     — todo plano, sin subdirectorios ni namespaces, **salvo `+OM4MClassLib` y
  `+Zernikes`**: se mantienen como package `+` (decisión explícita del usuario,
  ver DECISIONS.md — aplanarlos habría obligado a reescribir ~25+ call sites)
- `tests/`   — todo plano, un TestXxx.m por función
- `mex/src/` — código C/C++ + proyecto Visual Studio (.sln)
- `mex/bin/` — binarios precompilados (SÍ van al repo)

## Convenciones de código
- Bloques `arguments` para toda validación de entrada (no inputParser)
- Nunca usar `i`, `j` como variables de bucle
- Docstrings en formato estándar OM4M (ver FASE 5 en TODO.md)
- Seguir MATLAB-Coding-Guidelines en todo momento

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
  tests/fixtures/ y el MEX legacy `IOT2DPU/deploy` (usado por `UnwrapperTypes.FlynMd`) —
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
