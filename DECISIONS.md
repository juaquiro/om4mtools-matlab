# DECISIONS.md — om4mtools-matlab

Registro de decisiones, inventario y hallazgos del proceso de modernización.
Condensado a un resumen por sección (2026-09-16) — el detalle completo de
cada entrada sigue disponible en `git log -- DECISIONS.md`.

---

## Decisiones de diseño

| Fecha | Decisión | Razón |
|-------|----------|-------|
| 2026-05 | Nombre `om4mtools-matlab` | Sin lenguaje implícito, preparado para `om4mtools-python` |
| 2026-05 | Git fuera de Dropbox | Conflictos entre Dropbox sync y objetos `.git/` |
| 2026-05 | Dropbox como fase de limpieza, Git cuando la estructura esté clara | Sin presión de commits durante la reorganización |
| 2026-05 | Datos/assets en Dropbox, descarga con `download_fixtures.sh` | Fixtures no pertenecen al repo |
| 2026-05 | Sin directorio `data/` en la estructura | Todo son fixtures de test → van a `tests/fixtures/` |
| 2026-05 | MEX binarios SÍ van al repo | 1-2 ficheros sin dependencias, facilita consumo como submodule |
| 2026-05 | MEX build via MSBuild (Opción A) | Reutiliza .sln existente. Revisar al iniciar `om4mtools-python` |
| 2026-05 | Migrar MEX a CMake junto con port Python | CMake es estándar para extensiones Python (pybind11/ctypes) |
| 2026-05 | Consumo via Git submodule congelado | Versión fija por proyecto, actualización explícita y controlada |
| 2026-05 | Estructura plana en `src/` y `tests/` | 4 subdirectorios, volumen pequeño, simplicidad > organización |
| 2026-05 | Sin namespaces `+` | Toolbox de utilidades, simplicidad > organización prematura |
| 2026-05 | MATLAB Agentic Toolkit como setup completo | Instala MCP, skills y guidelines de una vez |
| 2026-05 | Skills principales: `matlab-modernize-code`, `matlab-testing` | Directamente relevantes para Fases 3 y 4 |
| 2026-05 | Excluir libs de terceros del nuevo repo | chebfun, CameraCalibrationToolbox, DIPUM, etc. no son código OM4M |
| 2026-05 | Carpeta `ClassLib/StandardHW/legacy/` es código muerto | Contiene versiones antiguas ya reemplazadas por clases en `+OM4MClassLib` |

---

## FASE 1 — Inventario y auditoría (2026-05-22)

Auditoría completa del legacy en Dropbox (`audit_filelist.txt`, 2422 ficheros):
373 `.m` propios de OM4M (162 classdef/161 function/50 script, 155 tests) frente
a 1632 de terceros a excluir (chebfun, CameraCalibrationToolbox, DIPUM,
ImageProcessingToolbox, HDR, ExportFig, jsonlab, XML-IO-Tools). MEX principal:
`IOT2DPU/IOT2DPU.sln` (5 `.vcxproj`, binario `PUFlynMdMex.mexw64`). ~159 MB de
fixtures identificadas (`.mat`/`.jpg`/`.bmp`/etc.) para `tests/fixtures/`. De
200+ colisiones de nombre al aplanar a `src/`, solo 9 eran código OM4M propio
real (la mayoría resueltas descartando `legacy/` o duplicados). ~130 tests ya
usaban `matlab.unittest.TestCase`; ~20 scripts ad-hoc y 4 `RunSelectedTests.m`
quedaron pendientes de convertir en Fase 3.

---

## Pendiente de decisión

- **Resuelto 2026-09-12:** `CamCalToolboxWrappers` se migra a
  `estimateCameraParameters` (Computer Vision Toolbox); `CameraCalibrationToolbox`
  (188 ficheros de terceros) eliminado del repo.
- **Resuelto (sin objeto):** la decisión de namespace `+Chebyshev` quedó sin
  efecto al eliminarse `+Chebyshev` del alcance junto con `ClassLib/ML`
  (ver Fase 1 bis); solo `+Zernikes` siguió pendiente, resuelta en Fase 2.
- **Resuelto 2026-09-16:** versión mínima de MATLAB objetivo = **R2023a**
  (afecta a `arguments` con opciones nominales R2021a+,
  `mustBeMember`/`mustBeInteger` R2020b+, `buildtool` R2022b+). La propia
  Fase 4 que motivó la pregunta fue descartada explícitamente (ver TODO.md),
  pero la decisión queda registrada por si hace falta en el futuro.

---

## FASE 1 bis — Re-auditoría tras limpieza manual (2026-09-12)

El usuario borró manualmente gran parte del legacy antes de Fase 2 (de 2422 a
538 ficheros, 223 `.m` OM4M). Confirmó como fuera de alcance definitivo:
`ClassLib/ML`+`TestML`, `ClassLib/MSurface`+`TestMSurface`, y varios
subdirectorios de `UtilLib` (`Surfaces`, `OptimaLib`, `+Chebyshev`, `Poly2`,
`RoiPolyIOT`, `SurfProcessor`, `functionDependencies`, etc. — algunos de estos
se recuperarían más tarde, ver Fase 2). De los terceros, `ExportFig`/`jsonlab`
seguían sin revisar; el resto ya estaba eliminado. Colisiones de nombre
reales bajaron a 3 (`CamL.m`/`CamR.m`, `DMK33UX183Bin3.m`), pendientes de
Fase 2.

---

## FASE 2 (primera pasada) — FPA / TestFPA (2026-09-12)

Primera migración real a la estructura objetivo (`src/`, `tests/`,
`tests/fixtures/`): 40 clases/funciones de `ClassLib/FPA` a `src/`, 34 de 35
tests de `ClassLib/TestFPA` a `tests/`, fixtures a `tests/fixtures/` (decisión
de entonces, revertida más tarde — ver "FASE 2 (reversión)"). Verificado en
MATLAB: 11/12 tests de dos suites representativas pasan; el único fallo
(dependencia de una función `dropbox()` con ruta personal del autor) es
preexistente, no de la migración. Se corrigieron dos bugs reales encontrados
al verificar: el helper de path `testAAAddReferencesPathFPA.m` estaba roto de
origen (llamaba a una función `resetPath` inexistente), y 6 tests cargaban
fixtures con rutas relativas a subcarpeta que solo resuelven contra el
directorio de trabajo — se creó `tests/fixturesRoot.m` para resolverlas de
forma absoluta. Legacy `ClassLib/FPA`/`TestFPA` borrado tras verificar.

---

## FASE 2 (continuación) — StandardHW y resto de UtilLib sin namespace (2026-09-12)

Se pospuso (a petición del usuario) decidir qué hacer con los namespaces `+`
(`+OM4MClassLib`, `+Zernikes`) hasta ver el resto de la migración. Migrados y
verificados: `ClassLib/StandardHW`+`TestStandardHW` (20 clases, 8 tests — la
colisión `DMK33UX183Bin3.m` resultó ser un archivo genuinamente distinto,
renombrado; `testStandardHW_MockCam` 9/10 pasa, único fallo un bug preexistente
en el propio test), `UtilLib/FPA` (9 funciones + 5 scripts de demo visual sin
aserciones, migrados tal cual), y sin tests propios: `DeployPaths`,
`CamCalToolboxWrappers` (queda roto hasta reescribirse sobre
`estimateCameraParameters` en Fase 4), `GUILib/TwoCamCaptureGUI`. Legacy
correspondiente borrado tras confirmación explícita del usuario en cada tanda.

---

## FASE 2 (continuación) — `+OM4MClassLib` y `+Zernikes` (2026-09-12)

**Decisión confirmada:** mantener ambos como package `+` dentro de `src/`
(excepción explícita a la regla "sin namespaces" de CLAUDE.md). Migrados:
`+OM4MClassLib` (15 ficheros) y `+Zernikes` (6). `TestOM4MClassLib` (13 tests,
solo `testCQueue` era `matlab.unittest` real, el resto `mtest` antiguo o demos
sin aserciones); `test_HW_Passive3DCam.m` resultó estar ya roto de origen —
usa la clase `Passive3DCam`, borrada sin registrar en la limpieza manual de
Fase 1 bis (hueco que persiguió Fase 3, ver más abajo). `TestZernike`: se
encontró que 3 de sus 6 funciones dependían de `UtilLib/Poly2`/`ClassLib/ML`,
ya descartados — el usuario decidió **recuperar ambos** (restaurados desde la
papelera de reciclaje), quedando solo `Polyval2` como hueco real e
irrecuperable (resuelto meses después, ver Fase 3 baseline). `ClassLib/TestML`
se migró filtrado (16 tests propios de OM4M, descartando material de curso
Coursera y duplicados `mtest`); de 84 tests, 41 pasaban, el resto por 3 causas
esperadas (datos de Coursera excluidos, `svmtrain` eliminado de MATLAB
moderno, `covmatrix` de DIPUM). `UtilLib/jsonlab` recuperado y migrado (uso
real confirmado en otro proyecto del usuario) y sus `examples/` transformados
en tests unitarios reales (`testJsonlabRoundTrip`, `testJsonlabBasicTypes`),
descubriendo limitaciones reales de jsonlab con arrays de strings planas
(resuelto como bug real en 2026-09-16, ver más abajo) y con arrays vacíos/2D
(documentadas con tolerancia, no bugs). Legacy `ClassLib/`+`UtilLib/jsonlab`
borrados tras cada verificación — con esto Fase 2 queda completa salvo
`IOT2DPU` (MEX, pista aparte).

---

## TODO Fase 3 (registrado 2026-09-12, a petición del usuario): `pathdef` no es `resetPath`

Durante Fase 2, los `matlabpath(resetPath)` rotos (función inexistente) se
habían sustituido por `matlabpath(pathdef)` — el usuario señaló que no es
equivalente: `pathdef` tira el path propio del usuario (otros proyectos,
toolboxes), no solo el añadido por los tests. **Implementado 2026-09-13:**
`tests/resetPath.m`, con `persistent capturedPath` que captura el path real al
primer uso en la sesión y lo restaura tal cual, aplicado en 47 ficheros. De
paso: `testThorlabsPM100PowerMeter.m` se etiquetó `Hardware` (se había
escapado del etiquetado por patrón de nombre) y se corrigió un bug real en
`testTFM_VdH.m` (su `TearDown` estaba declarado como test normal, nunca se
ejecutaba como teardown).

## Eliminado del alcance: subsistema motores/fuentes de luz/potenciómetros (2026-09-13)

A petición explícita del usuario, eliminados por completo (sin sustituto) 16
ficheros de `src/` ya migrados y funcionando (`HWCM700Servo`, `HWCNCXProV2`,
`HWLep`, `HWLightSourcePS`, `HWSerial`, `HWVelleman`, interfaces `I*`,
factories, `ThorlabsPM100*PowerMeter`, etc.), sus 5 tests y 1 fixture huérfana
— el usuario decidió que este subsistema ya no hace falta en absoluto.
Verificado con `grep` que nada más en el repo los referenciaba.

### `UtilLib/ExportFig` → recuperado al alcance y migrado (2026-09-12)

El usuario confirmó uso real de `export_fig` (preferido sobre el exportador
nativo de MATLAB) — migrados los 15 `.m` + `pdftops.exe` a `src/`, verificado
PNG/EPS en MATLAB R2024b, legacy borrado. `jsonlab` quedó pendiente de la
misma revisión (resuelto poco después, ver Fase 2 arriba).

---

## FASE 3 — Convención de tests de hardware (2026-09-13)

`run_all_tests.m` (`TestSuite.fromFolder`) solo descubre `classdef TestCase`
— los tests de hardware en `mtest` legacy quedaban excluidos por accidente de
formato, no por diseño, y empezarían a ejecutarse (y fallar sin hardware
conectado) en cuanto Fase 3 los reescribiera como `classdef`. Decisión:
etiquetar explícitamente `methods (Test, TestTags = {'Hardware'})`,
`run_all_tests.m` los excluye por defecto y `run_hardware_tests.m` (nuevo) los
ejecuta a propósito. Excepción pedida por el usuario: los tests contra
`MockCam` (software puro) nunca se etiquetan.

## Inventario y conversión de `mtest` legacy (2026-09-13)

19 ficheros `mtest` inventariados (todos "muertos" para el runner actual): 2
eliminados por cobertura 100% duplicada en su equivalente `classdef`, 1
consolidado dentro de `testFPA_UtilFunFPAClassVer.m` (que pasó a 67 tests/~5000
líneas, el fichero de test más grande del repo), 16 reescritos 1:1 como
`classdef` (patrón estándar: helper de path por dominio + `matlabpath(resetPath)`
+ `assertX` sueltos convertidos a `testCase.assertX`). De los reescritos, 2
quedaron bloqueados por huecos ya conocidos (`testSVM_Toolbox`: `svmtrain`
eliminado de MATLAB; `testQC_FeatureTest`: helpers y `..\TestDB\` inexistentes)
y 4 (`test_HW_Passive3DCam`, `test_HW_Passive3DCamData`,
`test_Facades_TwoCamCapAppInterface`, `test_DataStructs_MeasureList_P3DData`)
se eliminaron horas después junto con el hueco de `Passive3DCam` — el usuario
decidió no esperar a que Fase 7 lo recuperase. Esto arrastró la eliminación en
cascada de `TwoCamCapAppInterface.m`, `MeasureList_P3DData.m`,
`TwoCamCaptureGUI.m/.fig` y `CamL.m`/`CamR.m`/`.mat` (todo el subsistema de
captura de dos cámaras), confirmando con `grep` en cada paso que nada más los
usaba. Resultado final: 12 `classdef` nuevos quedan en el repo, `grep
initTestSuite tests/` da cero resultados.

## `tests/setupPath.m` sustituye a los 4 helpers de path por dominio (2026-09-13)

El pedido inicial de eliminar sin más los 4 helpers de path (asumiendo que
`run_all_tests.m` ya cubría todo) no era correcto: 2 de ellos también añadían
`IOT2DPU/deploy` al path (necesario para el MEX `PUFlynMdMex.mexw64`).
Solución: un único `tests/setupPath.m` que hace todos los `addpath`
necesarios (`tests/`, `src/`, fixtures, MEX), llamado desde `TestMethodSetup`
de cada test — preserva poder ejecutar cualquier test en solitario sin correr
la suite completa antes. Los 4 helpers viejos borrados. Hallazgos de paso: una
llamada con espaciado distinto que el `grep` inicial no detectó, y un carácter
"1" suelto que había corrompido `run_all_tests.m` (`end1` en vez de `end`),
ambos corregidos.

## Datos de Grupo 1 copiados a fixtures + tests actualizados; tests de Grupo 2 eliminados (2026-09-13)

Continuación de hallazgos de rutas hardcodeadas a datos externos. Eliminados
los tests irrecuperables (dependían de datos en una NAS o carpetas nunca
migradas a Dropbox: partes de `testFPADemodulatorFTTempAnalysis.m` y
`testTempAnalysisRetarExposure.m`). El resto de tests con rutas a datos ya
copiados se actualizó a `fixturesRoot()` en vez de `dropbox()` (~80 sitios,
patrón opaco, ningún test tuvo que cambiar su lógica). Única excepción dejada
sin tocar: `test_SetParamsForCalculateLensPower` (dataset de 6.9 GB, se saltó
a propósito) — **cerrado 2026-09-14** tras acotar que solo hacía falta un
subdirectorio de 34 ficheros, copiado y test actualizado. Grupo 1 quedó así
cerrado al 100%, cero referencias a `dropbox()` restantes en tests.

---

## FASE 2 (reversión) — `tests/fixtures/` vacío, vuelta a `dropbox()` vía `fixturesRoot()` (2026-09-14)

**Decisión revertida:** todo el trabajo de "Grupo 1" (copiar ~11 GB de
fixtures a `tests/fixtures/`) se deshace. El proyecto es estrictamente
personal — siempre corre en una máquina con el Dropbox del usuario montado,
duplicar los datos dentro del repo no aporta nada. Cambio mínimo: solo
`src/dropbox.m` y `tests/fixturesRoot.m` (que ahora devuelve
`dropbox('AQ_EXP','DataSetsForTesting','om4mtools-matlab')`) — cero tests
tocados, porque todos ya trataban `fixturesRoot()` como una raíz opaca.
Verificado con `diff` que el mirror de Dropbox era superset exacto de
`tests/fixtures/` antes de borrar sus ~11 GB (sustituidos por un
`tests/fixtures/README.md` explicando la decisión).

## Grupo 2 hardcoded refs (`testTFM_VdH.m`) — CERRADO (2026-09-14)

Datos del TFM de Víctor del Hierro localizados en Dropbox y copiados
(aplanados) a `DataSetsForTesting/.../Datos_LinearzationGV_TFM_20-21-VdHG/`.
De los 9 tests: 3 sin hardware quedaron totalmente funcionales, 4 con
cámara/proyector real se etiquetaron `Hardware`, y 2 se marcaron con
`assumeFail` por dependencias irrecuperables (clase `figDemodulator` nunca
localizada; ficheros de medida LMM de lentes nunca localizados — resueltos
como eliminación definitiva el 2026-09-16, ver más abajo).
`tests/testTFM_VdH.m` se integró en `testFPA_UtilFunFPAClassVer.m` y se
eliminó como fichero aparte.

---

## FASE 6 — Migración de Dropbox a repo Git (2026-09-14)

Proyecto movido de `Dropbox\AQ_EXP\75 om4mtools-matlab\` a
`C:\user\AQ_SCC\GitHub\om4mtools-matlab` (repo Git independiente) — la copia
de Dropbox se conserva intacta como backup (`README_IMPORTANTE_14SEP26.md`).
`.gitignore` ajustado tras inspeccionar el árbol real (excepción para el MEX
legacy `.mexw64` que aún no se había movido a `mex/bin/`, exclusión de
ficheros específicos de esta máquina). 383 ficheros comprometidos en el primer
commit. Crear el repo remoto, hacer push y el primer tag quedaron pendientes
de que el usuario lo pidiera explícitamente (hecho poco después, ver
secciones siguientes; release v1.0.0 real en 2026-09-16, ver TODO.md).

---

## FASE 2 — Migración de `IOT2DPU` a `mex/src/`/`mex/bin/` (2026-09-14)

Último ítem pendiente de Fase 2. El árbol completo de `IOT2DPU` (5 `.vcxproj`
+ `.sln` + `src/`) se movió tal cual a `mex/src/` sin aplanar (los `.vcxproj`
referencian su fuente con rutas relativas fijas — aplanar habría roto ~40
referencias sin poder recompilar aquí para verificar). El material de prueba
del propio proyecto VS (`IOT2DPU/tests/`, datos binarios y `.bat`) fue a
`mex/src/tests/`, no a `tests/` (no es la suite `matlab.unittest`). Binarios
(`PUFlynMdMex.mexw64`, `PUMexLib.dll/.h`) a `mex/bin/`. `tests/setupPath.m`
actualizado para apuntar ahí.

---

## `mex/build.m` (2026-09-14)

Wrapper sobre MSBuild (localizado vía `vswhere.exe`) que compila
`IOT2DPU.sln` en `Release|x64` y copia el resultado desde
`mex/src/deploy/` (destino de un post-build event heredado) a `mex/bin/`.
`.gitignore` ampliado para cubrir los intermedios reales de MSBuild
(`mex/src/**/x64/`, `.vs/`, etc.). Bloqueante real encontrado al intentar
compilar de verdad: los `.vcxproj` pedían `PlatformToolset v120` (VS2013), no
instalado — se decidió no reapuntar (`retarget`) todavía sin poder verificar
que el binario recompilado da los mismos resultados numéricos (sin harness
automático de comparación); queda para cuando se aborde esa tarea (resuelta
poco después, ver siguiente sección).

---

## Tag `mex_dll_working` + retarget a `v143` (2026-09-14)

Verificado `run(testFPAUnwrapper)` (5/5 Passed) con el MEX existente
compilado `v120`, tagueado ese estado como punto de rollback (`mex_dll_working`,
commit `2afc49c`) antes de tocar nada. Retarget de los 5 `.vcxproj` a `v143`
(VS2022). Dos problemas nuevos al compilar con el toolset nuevo (preexistentes,
no causados por el retarget en sí): falta la variable `$(MATLAB)` (resuelto
pasando `/p:MATLAB=<matlabroot>` explícito) y el post-build event fallaba si
`mex/src/deploy/` no existía (resuelto creándolo antes de invocar MSBuild).
Tras el retarget, build limpio y `run(testFPAUnwrapper)` de nuevo 5/5 Passed
— mismo resultado que con `v120` (aviso honesto: estos tests no comparan
salida numérica del unwrapper, solo confirman que carga y ejecuta sin
excepción).

---

## Fase 3 — primera pasada de estandarización y baseline (2026-09-14)

6 ficheros de test (relacionados con `+Zernikes`/`Poly2` y jsonlab) no tenían
`TestMethodSetup`/`TestMethodTeardown` — dependían silenciosamente de que otro
test los hubiera puesto ya en el path; corregido, uniformando el patrón del
resto del repo. **Primera ejecución real completa de `run_all_tests.m`:** 461
tests, 34 Hardware excluidos → 325 Passed, 120 Failed, 136 Incomplete.
Categorizados por causa raíz: ~43 por datos de Coursera excluidos a propósito
(esperado), 18→10 arreglados convirtiendo `testCellArrayList.m` (en realidad
un script de demo, no un test real) a `classdef` de verdad, ~15 por Computer
Vision Toolbox no instalada (entonces), 2 arreglados (`testPolyval2` — método
`Polyval2` renombrado a estático de `ProcessMeasure`), 5 arreglados
(`assertEqual`/`assertAlmostEqual` sueltos del framework `xunit` legacy que se
habían escapado de una limpieza anterior), y el resto ya documentado
(`svmtrain`, `testQC_FeatureTest`, `loadlibrary` de proyector,
`testJsonlabRoundTrip`) o sin categorizar todavía (resuelto en la sesión de
cierre de 2026-09-15/16, ver más abajo). De paso, se corrigió un bug propio en
`check-conventions.sh` (lintaba el fichero completo en vez de solo el diff,
lo que habría hecho fallar `smoke` en cualquier edición futura a código
legacy con `i`/`j` preexistentes sin tocar).

---

## Fase 3 — fixtures de Coursera (2026-09-14)

Localizados y copiados a `DataSetsForTesting/.../CourseraMLData/` los 9
ficheros de datos de Machine Learning (Andrew Ng/Coursera) que sí usan 10
clases de test reales (no todo el curso). ~46 sitios de código actualizados a
`fixturesRoot()`. De 40 tests bloqueados, 39 quedaron arreglados solo con la
copia de datos; el 40º reveló un bug propio distinto (resuelto en una sesión
aparte, ver más abajo). Se descubrieron 3 bloqueantes nuevos, no corregidos
en esa sesión: funciones auxiliares de Coursera (`mapFeature`/`plotData`/
`polyFeatures`) nunca migradas (resuelto reimplementándolas, ver siguiente
sección), `svmtrain` (ya documentado), y `bayesgauss` de DIPUM (resuelto poco
después, ver más abajo).

---

## Reimplementación de `mapFeature`/`plotData`/`polyFeatures` (2026-09-14)

Las 3 funciones auxiliares de Coursera reimplementadas desde cero (no
copiadas) como `src/mapFeature.m`, `src/plotData.m`, `src/polyFeatures.m` —
mismo nombre/firma, con bloques `arguments` y sin `i`/`j`. De 14 tests
bloqueados, 13 quedaron arreglados (varias clases al 100%). El 14º
(`testML_UtilFunML_CostFunctionLR`) reveló un bug propio y preexistente —
resuelto en la sesión siguiente, ver abajo.

---

## `bayesgauss`/`covmatrix` añadidos por el usuario + `svmtrain` → `fitcsvm` (2026-09-14)

El usuario añadió `bayesgauss.m`/`covmatrix.m` (DIPUM, terceros) directamente;
se localizó y añadió también la variante correcta de 2 salidas (más
`mahalanobis.m`, dependencia suya) desde el repo original `om4mmatlabutils`,
arreglando `testKMeansToolbox/test5`. **`svmtrain`/`svmclassify` → `fitcsvm`/
`predict`** en `src/ClassifierSVM.m` y `tests/testSVM_Toolbox.m` (9+ sitios):
incluyó cambiar `SVMstruct` de array a cell array (`ClassificationSVM` no
admite crecer en un array plano) y recalcular 4 valores de referencia
hardcodeados que cambiaron ligeramente por el nuevo solver (SMO vs QP legacy,
tolerancias ensanchadas para absorber esa deriva). Resultado: de 70 a 73
Passed de 74, con un único fallo restante ya documentado (resuelto en la
sección siguiente).

---

## `testML_UtilFunML_CostFunctionLR` — el desfase de `ag` resuelto (2026-09-14)

El valor de referencia hardcodeado `ag` (28 elementos) no correspondía a
`theta(1:28)` sino a `theta(2:29)` — `CostFunctionLR` añade su propia columna
de sesgo por encima de la que ya trae `mapFeature`, así que `g(1)` no tiene
equivalente en `ag`. Corregido a comparar `g(2:29)-ag`. Con esto, las 10
clases de test de ML/Coursera de la sesión quedan 74/74 Passed.

---

## `CProjector` (CHighPerform) recuperado — nueva convención `dll/` (2026-09-15)

`testFPADisplayProjectorC` fallaba porque ni el `.dll` ni el `.h` de
`CProjector` existían en el repo. Localizado en el legacy `om4mmatlabutils/
CHighPerform/` (3 DLLs) — recuperado solo `CProjector` (los otros dos no los
usa nada aquí). Nueva convención `dll/src/CProjector/` (fuente + `.vcxproj`,
sin `.sln` propio) y `dll/bin/` (binario + headers, mismo criterio que
`mex/bin/`). Hueco real encontrado de paso: `shrhelp.h` también hay que
copiarlo junto a `CProjector.h` para que `loadlibrary` no falle. Las 4 pruebas
de `testFPADisplayProjectorC` pasan ahora, verificado con proyección real en
un segundo monitor.

## `test_GetSethImage` arreglado + 5 scripts de demo de `UtilLib/FPA` renombrados fuera del descubrimiento de tests (2026-09-16)

Inicio de la categorización final de los 9 Failed / ~20 Incomplete del
baseline. `testStandardHW_MockCam/test_GetSethImage`: bug ya diagnosticado en
Fase 2 pero nunca arreglado (firma `test_GetSethImage(~)` descartaba el
argumento `testCase` que el cuerpo sí usaba) — corregido. Los 5 scripts de
demo de `UtilLib/FPA` (nunca fueron tests reales) se enganchaban al
descubrimiento de `TestSuite.fromFolder` solo por su nombre de fichero —
renombrados a `demo*.m` para dejar de aparecer en `run_all_tests.m`.

## Resto de los 9 Failed arreglados (2026-09-16)

Todos bugs reales pequeños o aserciones obsoletas, ninguno limitación de
entorno: un `case` de `switch` que faltaba en `testFPADemodulatorSpatialFT`,
coordenadas de sidelobe obsoletas en `test_LocateSidelobes_ReferenciaRotlex`,
tolerancia inalcanzable (`eps`) y un flip de signo erróneo en
`test_phaseGradient1` (renombrado `test_phaseGradientDirect`),
`testDecodeFromRGBTable` eliminado (fixtures de un paper legacy nunca
migradas), y el valor esperado desactualizado de `testWhoCalledMe` (el nombre
devuelto ahora viene cualificado con la clase). Con esto, 9/9 Failed del
baseline quedan resueltos.

## `testFFVCalibration/testPolinomicalCalibrationFromLMMs` arreglado: opción `noRefMethod` en `LensMapperMeasurement.CalculateLensPower` (2026-09-16)

El fixture PSI/Massig de estos tests tiene `zx`/`zy` pero nunca produce
`zrx`/`zry` por diseño (no un hueco de fixture, como asumía el `assumeFail`
original). Añadida una opción `noRefMethod (1,1) logical = false` a
`CalculateLensPower` (`src/LensMapperMeasurement.m`): cuando está activa,
copia `zx`/`zy` en `zrx`/`zry` en vez de exigirlos ya calculados. Aplicado y
verificado en los 4 tests de `testFFVCalibration` (`testPolinomicalCalibrationFromLMMs`,
`...V2`, `testCalibration2TimesAndRecal`, `testCalibration2Times` — este
último con un valor nominal esperado corregido de paso), dejando el fichero
completo en verde.

## `testCalculateHomographyAndTransform` extraído a demo (2026-09-16)

Ya llevaba su propio `assumeFail` (usa `ginput(4)`, no automatizable). Se
extrajo del `classdef` de `testFPA_UtilFunFPAClassVer` a
`tests/demoCalculateHomographyAndTransform.m` (script aparte con su propio
`setupPath()`), dejando de aparecer en `run_all_tests.m`.

## `testFigFFTLinGV` eliminado: dependencia irrecuperable (2026-09-16)

Necesitaba una clase helper `figDemodulator` (funciones de figuras del TFM de
Víctor del Hierro) nunca localizada en ningún repo o copia de Dropbox
conocida — eliminado en vez de dejarlo con `assumeFail` indefinidamente.

## `testCalculatePowerWithCorrectionFromLMMfile` eliminado: dependencia irrecuperable (2026-09-16)

Mismo patrón: necesitaba ficheros de medida LMM de lentes nunca localizados.
El método (~520 líneas, casi todo rutas comentadas de selección manual) se
eliminó entero.

## `jsonlab` (`loadjson`/`savejson`) arreglado para MATLAB actual: bug real de compatibilidad (2026-09-16)

El único de los ~29 Incomplete originales que resultó ser un bug de
compatibilidad real. `loadjson`'s `parse_array` hace `eval()` directo sobre
texto de array JSON como atajo de rendimiento — para arrays de strings planas
(`["GML","XML"]`), ese texto es sintaxis válida de `string` de MATLAB desde
R2017a, así que el `eval()` que antes fallaba (y caía a un parser manual
correcto) ahora tiene éxito y devuelve un array `string` que rompe `savejson`
aguas abajo. Fix: `cellstr()` justo después del `eval()` si el resultado es
`string`. Verificado sin regresiones (`testJsonlabBasicTypes` 26/26,
`testUbjsonRoundTrip` 4/4). El caso restante (`testJsonRoundTrip/example4.json`)
no es el mismo bug — es una ambigüedad inherente del formato JSON plano
(no distingue "varios arrays" de "una matriz") que ningún cambio de
compatibilidad puede arreglar; documentado con un `assumeFail` específico y
preciso en vez de tocar `savejson` globalmente.

## "Cerrar la suite de tests" — completado, baseline final confirmado (2026-09-16)

Baseline final confirmado por el usuario tras `run('tests/run_all_tests.m')`
real: **405 passed, 0 failed, 10 incomplete (of 415), 34 Hardware excluidos**
— las 10 Incomplete, todas documentadas (9 `assumeFail` de trabajo inacabado
del autor original en `testFPA_UtilFunMapperMeasureClassVer`, resueltas en
una sesión posterior — ver TODO.md/memoria; 1 ambigüedad de formato JSON ya
descrita arriba). Con esto, el objetivo del proyecto queda cumplido. (Nota
posterior: los 9 `assumeFail` de `LensMapperMeasureClassVer` se resolvieron
el mismo día vía la opción `noRefMethod`, y el proyecto se liberó como
v1.0.0 — ver TODO.md.)
