Para retomar (actualizado 2026-09-12):

1. Verificar en MATLAB que la nueva estructura de FPA funciona:
   - Añadir `src/` al path y comprobar que las clases de FPA (`Demodulator`, `Unwrapper`, etc.) cargan sin error.
   - Correr los tests migrados en `tests/` (los `testFPA*.m`) apuntando a `tests/fixtures/` y arreglar las rutas hardcodeadas que sigan apuntando al legacy (`ClassLib/TestFPA/...`).
   - Si todo funciona, borrar `om4mtools-matlab/ClassLib/FPA` y `ClassLib/TestFPA` del legacy (siguen intactos, solo se copiaron).
2. Repetir el mismo patrón de migración (mismo criterio de `src/`/`tests/`/`fixtures/`) para el resto de `ClassLib/` (+OM4MClassLib, StandardHW, TestOM4MClassLib, TestStandardHW) y `UtilLib/` (+Zernikes, TestZernike, CamCalToolboxWrappers, DeployPaths, FPA, FullScreen).
3. Quedan 2 decisiones pendientes (antes eran 3, la de CamCalToolboxWrappers ya se resolvió) — ver "Decisiones pendientes" en `TODO.md`:
   - Versión mínima de MATLAB objetivo.
   - `+Zernikes` al aplanar a `src/`: ¿renombrar o mantener como package `+`?
4. Resolver las 3 colisiones de nombres pendientes cuando toque migrar esas carpetas: `CamL.m`/`CamR.m`, `DMK33UX183Bin3.m`, `RunSelectedTests.m` (descartar).

Contexto completo en `DECISIONS.md` (secciones "FASE 1 bis" y "FASE 2 (primera pasada) — FPA / TestFPA") y en la memoria persistente del proyecto.
