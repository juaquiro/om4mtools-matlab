# DECISIONS.md — om4mtools-matlab

Registro de decisiones, inventario y hallazgos del proceso de modernización.

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

> Fuente: `om4mtools-matlab/` (legacy repo en Dropbox)  
> Auditoría completa: `audit_filelist.txt` (2422 ficheros)

### Estructura legacy

| Directorio | Archivos .m | Descripción |
|---|---|---|
| `ClassLib/` | 258 | Clases OM4M: FPA, ML, StandardHW, MSurface, OM4MClassLib |
| `GUILib/` | 3 | GUI de captura (TwoCamCaptureGUI) |
| `IOT2DPU/` | 5 | Procesado de fase 2D (wrapping/unwrapping) |
| `UtilLib/` | 1739 | Utilidades + **1532 de terceros** (chebfun, DIPUM, etc.) |

### Código OM4M vs terceros

| Categoría | Archivos .m |
|---|---|
| **OM4M propio** | **373** |
| Terceros (UtilLib) | 1632 |
| **Total legacy** | **2005** |

#### Desglose OM4M propio (373 .m)

| Tipo | Cantidad |
|---|---|
| `classdef` | 162 |
| `function` | 161 |
| `script` | 50 |

| Categoría | Cantidad |
|---|---|
| Tests (Test*, test_*, en carpetas Test*/) | 155 |
| Código fuente | 218 |

#### Subdirectorios OM4M en UtilLib

| Dir | .m | Descripción |
|---|---|---|
| `Surfaces/` | 29 | Funciones de superficies ópticas |
| `OptimaLib/` | 19 | Optimización |
| `FPA/` | 14 | Funciones auxiliares FPA (Fringe Pattern Analysis) |
| `Other functions/` | 9 | Miscelánea |
| `+Zernikes/` | 6 | Polinomios de Zernike (namespace `+`) |
| `TestZernike/` | 6 | Tests para Zernikes |
| `functionDependencies/` | 6 | Herramienta de análisis de dependencias |
| `Poly2/` | 3 | Polinomios 2D |
| `RoiPolyIOT/` | 3 | ROI polinomial para IOT |
| `SurfProcessor/` | 3 | Procesado de superficies |
| `FullScreen/` | 2 | Utilidad pantalla completa |
| `DeployPaths/` | 2 | Gestión de paths para deploy |
| `CamCalToolboxWrappers/` | 2 | Wrappers de CameraCalibrationToolbox |
| `+Chebyshev/` | 2 | Polinomios de Chebyshev (namespace `+`) |
| `image2clipboard/` | 1 | Copiar imagen al portapapeles |

#### Librerías de terceros en UtilLib (a excluir del nuevo repo)

| Dir | .m | Biblioteca |
|---|---|---|
| `chebfun/` | 1204 | Chebfun (chebfun.org) — funciones de Chebyshev |
| `CameraCalibrationToolbox/` | 182 | Bouguet Camera Calibration Toolbox |
| `DIPUM/` | 129 | Digital Image Processing Using MATLAB |
| `ImageProcessingToolbox/` | 65 | Copias antiguas de funciones del IPT (2012, 2013) |
| `HDR/` | 17 | HDR imaging toolbox |
| `ExportFig/` | 16 | export_fig (O. Woodford) |
| `jsonlab/` | 12 | JSONLab |
| `XML-IO-Tools/` | 7 | xml_read / xml_write |

> **Decisión pendiente:** CamCalToolboxWrappers depende de CameraCalibrationToolbox.
> Evaluar si mantener wrappers o reimplementar sobre la toolbox de MATLAB (R2020b+).

### MEX — Proyecto Visual Studio

**Proyecto principal:** `IOT2DPU/IOT2DPU.sln`

| Proyecto .vcxproj | Descripción |
|---|---|
| `PUFlynMdMex.vcxproj` | MEX principal (phase unwrapping Flynn-Madsen) |
| `PUMexLib.vcxproj` | Librería auxiliar MEX |
| `flynmd.vcxproj` | Algoritmo Flynn-Madsen |
| `fmg.vcxproj` | Algoritmo FMG (Full Multigrid) |
| `goldbc.vcxproj` | Algoritmo Gold boundary-cut |

**Binario principal:** `PUFlynMdMex.mexw64`  
**Ruta en legacy:** `IOT2DPU/deploy/PUFlynMdMex.mexw64`

**Otros binarios en legacy (terceros o legacy, NO migrar):**
- `UtilLib/DIPUM/unravel.*` — cross-platform (mexa64, mexglx, mexmaci, mexs64, mexw32, mexw64) — de DIPUM
- `UtilLib/ImageProcessingToolbox/**/*.mexw64` — copias antiguas del IPT (2012/2013)

### Datos y assets (fixtures de test)

**Total:** 159.1 MB distribuidos en carpetas Test* y UtilLib

| Tipo | Cantidad | Destino |
|---|---|---|
| `.mat` | 57 | `tests/fixtures/` |
| `.jpg` | 66 | `tests/fixtures/` (incluye HDR pics) |
| `.bmp` | 25 | `tests/fixtures/` |
| `.tif` | 16 | `tests/fixtures/` |
| `.png` | 15 | `tests/fixtures/` (incluye doc de functionDependencies) |
| `.csv` | 3 | `tests/fixtures/` |
| `.xlsx` / `.xls` | 5 | `tests/fixtures/` |
| Ficheros ópticos (`.aq`, `.surf`, `.phase`, `.corr`, `.mask`, `.qual`) | 16 | `tests/fixtures/` |
| `.PMF` | 3 | `tests/fixtures/` |

> **Nota:** `TestFPA` concentra la mayor parte del peso (~120 MB en `.mat` y `.bmp`).

### Colisiones de nombres al aplanar a `src/` plano

Las 200+ colisiones detectadas son **todas de librerías de terceros** (principalmente chebfun).

En el código OM4M propio hay 9 colisiones reales que requieren decisión en Fase 2:

| Fichero | Ocurrencias | Situación |
|---|---|---|
| `RunSelectedTests.m` | 4 | Script legacy de test runner (no-unittest). **Descartar** — reemplazado por `run_all_tests.m` |
| `CamL.m` | 2 | TestOM4MClassLib + GUILib/TwoCamCaptureGUI. Evaluar si son idénticos |
| `CamR.m` | 2 | Ídem |
| `DMK33UX183Bin3.m` | 2 | TestFPA + TestStandardHW — script de config de cámara compartido |
| `GVPCCam.m` | 2 | TestFPA + TestStandardHW — ídem |
| `EvaluateTerms.m` | 2 | `+Chebyshev` + `+Zernikes` — en packages, sin conflicto real |
| `PolyEquivalent.m` | 2 | Ídem |
| `Passive3DCam.m` | 2 | `+OM4MClassLib/+HW/` (classdef actual) + `legacy/` (antiguo). **Descartar legacy** |
| `test_HW_Passive3DCam.m` | 2 | `TestOM4MClassLib/` (actual) + `legacy/` (antiguo). **Descartar legacy** |

> **Conclusión:** Con las librerías de terceros excluidas y `legacy/` descartado, quedan solo
> 4 colisiones reales que resolver en Fase 2: `CamL.m`, `CamR.m`, `DMK33UX183Bin3.m`, `GVPCCam.m`.
> Los ficheros de namespace `+` (`EvaluateTerms.m`, `PolyEquivalent.m`) requieren decisión
> sobre si renombrar con prefijo (`ZernikeEvaluateTerms.m`, `ChebyshevEvaluateTerms.m`) o usar
> otro mecanismo.

### Tests legacy — tipo de framework

| Framework | Archivos | Notas |
|---|---|---|
| `matlab.unittest.TestCase` | ~130 | Clases `classdef Test* < matlab.unittest.TestCase` |
| scripts legacy (`RunSelectedTests`) | 4 | En cada carpeta Test*, estilo antiguo. Descartar |
| tests ad-hoc (scripts `test_*.m`) | ~20 | Sin framework, ejecutan assertions manualmente |

> **Acción Fase 3:** Los ~20 scripts `test_*.m` ad-hoc y los 4 `RunSelectedTests.m` deben
> convertirse a `matlab.unittest.TestCase`.

---

## Pendiente de decisión

- [x] ~~**CamCalToolboxWrappers:** ¿mantener dependencia de CameraCalibrationToolbox o
  migrar a `estimateCameraParameters`?~~ **Resuelto 2026-09-12:** se migra a
  `estimateCameraParameters` (MATLAB Computer Vision Toolbox, R2014b+).
  `UtilLib/CameraCalibrationToolbox/` (dependencia externa, 188 ficheros) eliminado del
  repo. `CamCalToolboxWrappers/RectifyStereoPair.m` y `UndistortImage.m` deberán
  reescribirse sobre la toolbox de MATLAB en Fase 4.
- [x] ~~**+Chebyshev / +Zernikes:** ¿renombrar con prefijo o mantener como packages `+`?~~
  **Sin objeto:** `UtilLib/+Chebyshev/` fue eliminado del alcance junto con `ClassLib/ML`
  (ver Fase 1 bis). Solo queda `UtilLib/+Zernikes/` — decisión de namespace pospuesta a
  Fase 2, pero con un único caso a resolver en vez de dos.
- [ ] **Versión mínima de MATLAB objetivo** (Fase 4): ¿R2022b? ¿R2023a? Afecta a:
  - `arguments` con opciones nominales → R2021a+
  - `mustBeMember`, `mustBeInteger`, etc. → R2020b+
  - `buildtool` → R2022b+

---

## FASE 1 bis — Re-auditoría tras limpieza manual (2026-09-12)

> El usuario borró manualmente un gran número de ficheros del repo legacy en
> `om4mtools-matlab/` antes de arrancar Fase 2. Se ha re-escaneado el directorio y
> regenerado `audit_filelist.txt`.

### Cifras

| | Fase 1 (2026-05-22) | Fase 1 bis (2026-09-12) |
|---|---|---|
| Ficheros totales (legacy) | 2422 | 538 |
| Tamaño | — | 147 MB |
| `.m` OM4M | 373 | 223 (113 classdef, 85 function, 25 script) |

### Confirmado por el usuario: reducción de alcance intencional

Además de lo ya decidido en Fase 1 (excluir terceros, descartar `StandardHW/legacy/`),
el usuario confirmó que **queda fuera de alcance de `om4mtools-matlab`** el siguiente
código OM4M propio (no estaba marcado para descarte en la auditoría original):

- `ClassLib/ML/` + `ClassLib/TestML/` — clasificadores y utilidades de Machine Learning
- `ClassLib/MSurface/` + `ClassLib/TestMSurface/` — superficies (`EllipSurface`, `SphSurface`, `SplineSurface`, ...)
- `UtilLib/Surfaces/`, `UtilLib/OptimaLib/`, `UtilLib/+Chebyshev/`, `UtilLib/Poly2/`,
  `UtilLib/RoiPolyIOT/`, `UtilLib/SurfProcessor/`, `UtilLib/functionDependencies/`,
  `UtilLib/Other functions/`, `UtilLib/image2clipboard/`

Ficheros de metadatos del repo legacy (`.gitcredentials`, `.gitignore`,
`bitbucket-pipelines.yml`, `DoxyfilePipe`, `OM4MDoxyfile`, `Om4mMatlabUtils.dox`,
`ClassLib.dox`) también se han eliminado — no aplican a `om4mtools-matlab` (nuevo repo,
nuevo pipeline).

### Terceros: estado tras limpieza

| Librería | Fase 1 | Fase 1 bis | Estado |
|---|---|---|---|
| `chebfun` | 1204 | 0 | ✅ eliminado (según lo decidido) |
| `CameraCalibrationToolbox` | 182 | 0 | ✅ eliminado 2026-09-12 (resuelve decisión pendiente #1) |
| `DIPUM` | 129 | 0 | ✅ eliminado (según lo decidido) |
| `ImageProcessingToolbox` | 65 | 0 | ✅ eliminado (según lo decidido) |
| `HDR` | 17 | 0 | ✅ eliminado (según lo decidido) |
| `ExportFig` | 16 | 18 | ⚠️ se mantiene — pendiente revisar si algo de OM4M lo usa |
| `jsonlab` | 12 | 22 | ⚠️ se mantiene — pendiente revisar si algo de OM4M lo usa |
| `XML-IO-Tools` | 7 | 0 | ✅ eliminado (según lo decidido) |

> **Nota:** los recuentos de `ExportFig`/`jsonlab` suben ligeramente respecto a Fase 1
> porque aquella cifra excluía subcarpetas (`examples/`); el contenido no ha cambiado.

### Colisiones de nombres — actualización

Con `GVPCCam.m` resuelto (solo queda una copia en `TestFPA/`), quedan **3 colisiones
reales** para Fase 2 (antes 4):

| Fichero | Ocurrencias | Situación |
|---|---|---|
| `CamL.m` / `CamR.m` | 2 cada uno | `TestOM4MClassLib/` + `GUILib/TwoCamCaptureGUI/` |
| `DMK33UX183Bin3.m` | 2 | `TestFPA/` + `TestStandardHW/` |
| `RunSelectedTests.m` | 2 | Script legacy de test runner (no-unittest) en 2 carpetas — **descartar**, reemplazado por `run_all_tests.m` |

### Estructura actual del legacy tras la limpieza

```
om4mtools-matlab/
├── ClassLib/
│   ├── +OM4MClassLib/   (DataStructs, Facades, Util)
│   ├── FPA/
│   ├── StandardHW/      (legacy/ ya eliminado)
│   ├── TestFPA/
│   ├── TestOM4MClassLib/
│   └── TestStandardHW/
├── GUILib/TwoCamCaptureGUI/
├── IOT2DPU/             (MEX, sin cambios)
└── UtilLib/
    ├── +Zernikes/ + TestZernike/
    ├── CamCalToolboxWrappers/
    ├── DeployPaths/
    ├── ExportFig/       (tercero, pendiente revisión)
    ├── FPA/
    ├── FullScreen/
    └── jsonlab/         (tercero, pendiente revisión)
```

---

## FASE 2 (primera pasada) — FPA / TestFPA (2026-09-12)

> A petición del usuario: `ClassLib/FPA` y `ClassLib/TestFPA` son la prioridad. Se crea
> por primera vez la estructura objetivo (`src/`, `tests/`, `tests/fixtures/`) como
> hermana de `CLAUDE.md` en `75 om4mtools-matlab/`, y se migra (copiando, sin borrar el
> legacy todavía) solo este subsistema.

- **`src/`** (nuevo): 40 clases/funciones de `ClassLib/FPA/*.m`, aplanadas, sin cambios de contenido.
- **`tests/`** (nuevo): 34 de los 35 `.m` de `ClassLib/TestFPA/`, aplanados, sin cambios de contenido ni de framework (la conversión a `matlab.unittest.TestCase` es Fase 3, no se ha hecho aquí).
  - **Excluido:** `Untitled.m` — fragmento de script suelto (`[XX,YY]=meshgrid(...)`), sin `function`/`classdef`, no ejecutable de forma independiente. No se migra; queda solo en el legacy.
  - Incluidos tal cual (no son tests unitarios, son scripts/config usados por los tests): `DMK33UX183Bin3.m`, `GVPCCam.m` (config de cámara auto-generada), `GenerateProgressive.m`, `PSAsinc5.m`.
- **`tests/fixtures/`** (nuevo), decisión del usuario: fixtures dentro del propio proyecto por ahora (no en una carpeta Dropbox separada; revisar más adelante si conviene moverlas):
  - 4 subcarpetas preservadas tal cual estaban: `AnilloPolariscopio/` (6), `AnilloRGBFluo/` (6), `DiscoPolariscopio/` (6), `DiscoRGBFluo/` (7).
  - ~60 ficheros sueltos de datos (`.mat`, `.bmp`, `.tif`, `.jpg`, `.PMF`, `.json`, `.txt`) que estaban directamente en `TestFPA/` (no en las 4 subcarpetas) van sueltos en la raíz de `fixtures/`, sin agrupar bajo un subdirectorio `TestFPA/`.
- **Legacy sin tocar:** `om4mtools-matlab/ClassLib/FPA` y `ClassLib/TestFPA` se mantienen intactos (se ha copiado, no movido) hasta verificar que la nueva estructura funciona.

**Pendiente de esta pasada:**
- Repetir el mismo proceso para el resto de `ClassLib/` y `UtilLib/` (Fase 2 completa).

### Verificación en MATLAB (2026-09-12) — completada

Se ejecutaron en MATLAB R2025a (`-batch`) dos suites classdef representativas:
`testFPADecoderRGB` (7 tests, la que más usa fixtures y el ciclo SetUp/TearDown) y
`testFPAUnwrapper` (5 tests). Resultado: **11/12 pasan**. El único fallo
(`testUnwrapperFlynMdWithDeflecMeas`) es un problema preexistente no relacionado con la
migración: llama a una función `dropbox()` que no existe en ningún punto del repo
(legacy ni nuevo) y apunta a una ruta personal del autor original
(`\AQ_SYNC\AQ\KIROS\...`) — nunca fue portable fuera de esa máquina. Mismo patrón que
`testTFM_VdH.m` y `testTempAnalysisRetarExposure.m` (rutas absolutas tipo
`D:\User\Victor\...` / `\PerseusMedidas\...`), que tampoco son ejecutables fuera de los
equipos originales. No se han tocado estos 3 ficheros.

Para que la verificación pasara hubo que corregir dos problemas reales en la copia (no
solo relocalización de paths):

1. **`tests/testAAAddReferencesPathFPA.m` estaba roto de origen:** llamaba a
   `matlabpath(resetPath)` con una función `resetPath` que no existe en ningún sitio del
   repo (ni legacy ni nuevo) — habría fallado igual en el legacy si se hubiera ejecutado
   recientemente. Reescrito para resolver rutas desde `mfilename('fullpath')` (no desde
   `cwd`, que ya no coincide con la ubicación del test) y apuntar a lo que sigue
   existiendo: `src/`, `tests/fixtures/`, y el `ClassLib`/`UtilLib` legacy pendiente de
   migrar (`OM4MClassLib`, `StandardHW`, `UtilLib`, `FullScreen`, `jsonlab`,
   `IOT2DPU/deploy`) — se quitaron referencias a carpetas que ya no existen
   (`UtilLib\MTest`, `ClassLib\ML`, `UtilLib\Poly2`, `UtilLib\Other functions`,
   `CHighPerform`, `IOTQC`).
2. **6 tests cargaban fixtures con rutas relativas a subcarpeta**
   (`baseDir='.\DiscoRGBFluo'` etc. en `testFPADecoderRGB`,
   `testFPADemodulatorPS6StepFotoel`, `testFPADemodulatorPSFotoel`,
   `testPolarMeasurement`) — eso solo resuelve contra el directorio de trabajo actual, no
   contra `addpath` (a diferencia de los nombres de fichero sueltos, que sí resuelven vía
   `addpath`). Se creó `tests/fixturesRoot.m` (devuelve la ruta absoluta a
   `tests/fixtures/`) y se cambiaron esas líneas a
   `baseDir=fullfile(fixturesRoot(),'DiscoRGBFluo')`.

**Hallazgo adicional (no bloqueante, para Fase 3):** de los 34 ficheros migrados, 3 usan
el framework `mtest` antiguo en vez de `matlab.unittest` (`TestProcessMeasure.m`,
`testFPA_UtilFunFPA.m`, `testFPA_UtilFunMapperMeasure.m`). El propio autor original ya
dejó documentado en `testFPA_UtilFunFPAClassVer.m` que `mtest` no funciona desde R2016a.
Dos de los tres ya tienen versión `matlab.unittest` equivalente (sufijo `ClassVer`);
`TestProcessMeasure.m` no tiene sustituto — candidato a reescribir en Fase 3, no a
descartar sin más.

**Legacy borrado 2026-09-12:** `ClassLib/FPA` y `ClassLib/TestFPA` eliminados del árbol
legacy tras la verificación anterior.

---

## FASE 2 (continuación) — StandardHW y resto de UtilLib sin namespace (2026-09-12)

### Decisión: posponer `+OM4MClassLib` y `+Zernikes`

Antes de tocar `ClassLib/+OM4MClassLib` (namespace usado por ~25/40 ficheros de FPA vía
`import OM4MClassLib.Util.*`) se preguntó explícitamente al usuario cómo tratarlo
(mantener como package `+` en `src/`, aplanarlo ya, o posponer la decisión).
**Respuesta: posponer** — se deja `+OM4MClassLib`/`TestOM4MClassLib` y, por el mismo
motivo (es otro namespace `+`), `UtilLib/+Zernikes`/`TestZernike` para el final, cuando se
vea el impacto completo en todo lo demás ya migrado. **No aplanar ni mantener como
package sin volver a preguntar.**

### `ClassLib/StandardHW` + `TestStandardHW` → migrado y verificado

- **`src/`:** 20 clases (no 19 como se estimó en la auditoría — se recontó al migrar).
- **`tests/`:** 8 tests classdef (`testHWCNCXProV2`, `testHWLightSourcePS`, `testHWSerial`
  *[mtest antiguo, sin equivalente moderno]*, `testHWVelleman`, `testStandardHW_ImaqCam`
  *[mtest antiguo]*, `testStandardHW_ImaqCam_ClassVer`, `testStandardHW_MockCam`,
  `testThorlabsPM100PowerMeter`) + 15 scripts de configuración de cámara usados por los
  tests (`DFGPro_*`, `DFK*`, `DMx41BU02`, `DMK33UX183Bin3*`, `UVCHDWebCam`,
  `setDMK33UX183SrcProps`) + el helper de paths.
- **Colisión `DMK33UX183Bin3.m` resuelta:** el de `TestFPA` (ya en `tests/`) y el de
  `TestStandardHW` **no son idénticos** (variable `vidObj` vs `vidObj1`, uno llama a
  `setDMK33UX183SrcProps` y el otro no) — confirmado con `diff`, no era un duplicado
  inofensivo como sugería la nota de Fase 1. El de `TestStandardHW` se renombró a
  `DMK33UX183Bin3StandardHW.m` y se actualizaron sus 2 llamadores
  (`testStandardHW_ImaqCam.m`, `testStandardHW_ImaqCam_ClassVer.m`, ~26 referencias
  `@DMK33UX183Bin3` → `@DMK33UX183Bin3StandardHW`).
- **`testAAAddReferencesPathStandardHW.m` tenía el mismo bug que el de FPA**
  (`matlabpath(resetPath)` con función inexistente) — reescrito con el mismo patrón
  (`mfilename('fullpath')`, sin referencias a carpetas ya borradas como
  `CameraCalibrationToolbox`, `UtilLib\HDR`, `UtilLib\MTest`, `ClassLib\ML`,
  `CHighPerform`). Dos tests más (`testStandardHW_ImaqCam_ClassVer.m`,
  `testStandardHW_MockCam.m`) tenían el mismo `matlabpath(resetPath)` en su propio
  `TearDown` — cambiado a `matlabpath(pathdef)`.
- **Verificación en MATLAB:** las 20 clases de `src/` cargan. `testStandardHW_MockCam`
  (único test que no depende de hardware real) corrido completo: 9/10 pasan; el único
  fallo (`test_GetSethImage`) es un bug preexistente del propio test (llama a
  `assertEqual` como función suelta de xUnit en vez de `testCase.assertEqual`, dentro de
  una classdef `matlab.unittest.TestCase` — nunca pudo haber funcionado así). El resto de
  tests de `TestStandardHW` requieren hardware real conectado (motores, poder, cámaras
  serie/GigE) y no son verificables en este entorno — se migran igualmente, sin
  verificación de ejecución real.

### `UtilLib/FPA` → migrado y verificado (no confundir con `ClassLib/FPA` ya migrado)

Es una utilidad distinta (transformada de vórtice/normalización 2D), con fuente y
"tests" mezclados en la misma carpeta plana (sin split Src/Test como en `ClassLib`).

- **`src/`** (9): `FFTPU`, `IgramNorm`, `OrMinDer`, `OrientationVortex`, `SPHT`, `Vortex`,
  `VortexTransformDemodDiskNa`, `VortexTransformDemodMiract`, `calcDirection`. Sin
  dependencia de `OM4MClassLib`.
- **`tests/`** (5): `TestNormalizationVortex`, `TestOrientationVortex`, `TestSPHT`,
  `TestVortex`, `testFFTPU` — **no son tests con framework**, son scripts de demostración
  visual (`%%` cell mode, sin ninguna aserción, solo `figure`/`imagesc` para inspección
  manual). Se migran tal cual (mismo criterio que los scripts de config de cámara).
- **Fixtures:** `Delta7DisNa.tif`, `delta7DisNaMask.jpg`, `miract_crop.jpg`,
  `miract_cropMask.tif` ya existían en `tests/fixtures/` (idénticos, verificado con
  `cmp`) porque también los usaba `ClassLib/TestFPA` — no se duplican.
- **Verificación:** las 9 funciones cargan; los 5 scripts se ejecutaron con `run()`
  (aislados en una función para que el `clear all`/`clc` interno de cada script no borre
  el estado del arnés de verificación) sin errores de MATLAB.

### `UtilLib/DeployPaths`, `UtilLib/CamCalToolboxWrappers`, `UtilLib/FullScreen`, `GUILib/TwoCamCaptureGUI`

Sin tests propios — solo `src/`.

- **`DeployPaths.m`** (herramienta de diagnóstico interactiva, usa `msgbox`) necesita
  `myfile.txt` sin comprobar que exista — se decidió que **los ficheros no-`.m`
  necesarios para que el código funcione (no solo usados por tests) van a `src/`**, no a
  `tests/fixtures/`, porque `tests/fixtures/` no se añade al path en proyectos
  consumidores (ver FASE 0.5 — `setup.m` solo hace `addpath(src)` + `mex/bin`). Con este
  criterio, `myfile.txt` va en `src/` junto a `DeployPaths.m`.
- **`CamCalToolboxWrappers`** (`RectifyStereoPair.m`, `UndistortImage.m`): dependen de la
  toolbox de terceros `CameraCalibrationToolbox` ya eliminada del repo — **no funcionan
  hasta que se reescriban sobre `estimateCameraParameters` en Fase 4** (decisión ya
  tomada, ver más arriba). Se migran tal cual, sin arreglar ahora.
- **`GUILib/TwoCamCaptureGUI`** (GUI antiguo estilo GUIDE, candidato a modernizar a
  App Designer en Fase 4): `TwoCamCaptureGUI.m`+`.fig` y `CamL.m`/`CamL.mat`,
  `CamR.m`/`CamR.mat` van a `src/` (son necesarios para que el código funcione, mismo
  criterio que `myfile.txt`). `TwoCamCapConfig.xml` + 4 imágenes de ejemplo
  (`imageL1/2.jpg`, `imageR1/2.jpg`) van a `tests/fixtures/` (datos de ejemplo, no
  requeridos por el código para cargar). **Colisión `CamL`/`CamR` con
  `TestOM4MClassLib` no surge todavía** porque `TestOM4MClassLib` está pospuesto — se
  resolverá al migrar esa carpeta.
- **Verificación:** las 6 funciones/GUI cargan (`exist(...)==2/3`); no se lanzó la GUI ni
  se probaron `CamL`/`CamR` con cámaras reales (requieren hardware).

### Legacy borrado 2026-09-12 (segunda tanda, tras confirmación explícita del usuario)

`ClassLib/StandardHW`, `ClassLib/TestStandardHW`, `UtilLib/FPA`, `UtilLib/DeployPaths`,
`UtilLib/CamCalToolboxWrappers`, `UtilLib/FullScreen`, `GUILib/` (carpeta completa, ya
vacía) eliminados del legacy. El primer intento de borrado en bloque lo bloqueó el
clasificador de auto-mode de Claude Code ("Irreversible Local Destruction" — no hay Git
en este repo, solo Dropbox); se confirmó explícitamente con el usuario antes de borrar
(a diferencia de FPA/TestFPA, donde el borrado ya venía autorizado en el mensaje
original). **Para el resto de piezas que falten, volver a confirmar antes de borrar, no
asumir autorización indefinida.**

Legacy restante tras esta tanda: `ClassLib/+OM4MClassLib` + `TestOM4MClassLib`,
`UtilLib/+Zernikes` + `TestZernike` (namespaces, pospuestos a petición del usuario),
`UtilLib/ExportFig` + `jsonlab` (terceros, pendiente de revisión), `IOT2DPU` (proyecto
MEX, pista aparte).

---

## FASE 2 (continuación) — `+OM4MClassLib` y `+Zernikes` (2026-09-12)

### Decisión confirmada: mantener ambos como package `+` en `src/`

Tras posponer la decisión (ver más arriba), se volvió a preguntar al usuario
explícitamente y se confirmó: **mantener `+OM4MClassLib` y `+Zernikes` como packages `+`
dentro de `src/`**, en vez de aplanarlos. Es una excepción explícita a la regla "sin
namespaces" de CLAUDE.md — documentar ahí si se retoma esa regla más adelante.

- **`src/+OM4MClassLib/`**: copiado tal cual (`+DataStructs` 9, `+Facades` 1, `+Util` 5 =
  15 ficheros).
- **`src/+Zernikes/`**: copiado tal cual (6 ficheros).
- Como ambos quedan como package en `src/`, y `src/` ya está en el path de cualquier
  consumidor (`addpath(src)` en `setup.m`, ver FASE 0.5), **ya no hace falta** que los
  helpers de paths de `tests/` sigan apuntando al `ClassLib` legacy para esto — se
  simplificarán cuando se retoque cada helper.

### `TestOM4MClassLib` → migrado (verificación parcial, ver hallazgos)

- **`tests/`**: 13 tests (`testCQueue`, `testCellArrayList`, `testCellEnumList`,
  `testPropsEnumList`, `test_DataStructs_MeasureList_P3DData`,
  `test_Facades_TwoCamCapAppInterface`, `test_HW_Passive3DCam`,
  `test_HW_Passive3DCamData`, `test_UtilTime`, `test_Util_CSVUtils`, `test_Util_Logging`,
  `test_Util_Validation`, `test_Util_XLSUtils`) + 4 clases/enums de apoyo usadas solo por
  tests (`ClassWithProps`, `EnumAQ1`, `EnumAQ2`, `EnumPropsTypes`) + helper de paths
  (`testAAAddReferencesPath.m`, sin el bug de `resetPath` esta vez — ya usaba
  `matlabpath(pathdef)` correctamente, solo hubo que actualizar las rutas relativas).
- **Solo `testCQueue.m` es un test `matlab.unittest` real y funciona** (2/2 pasa,
  verificado). **12 de los 13 restantes son `mtest` antiguo** (`test_suite=...;
  initTestSuite;`) — no ejecutables desde R2016a, y `testCellArrayList.m`/
  `testCellEnumList.m` (bien mirado) son en realidad scripts de demo `%%` sin ninguna
  aserción, ni siquiera con el framework mtest de verdad — se migran igual, tal cual, sin
  arreglar (Fase 3).
- **Colisión `CamL.m`/`CamR.m` resuelta**: comprobado con `diff` — **no eran idénticos**
  al `CamL`/`CamR` de `GUILib` ya migrado (distinto `deviceID`, distinto
  `ReturnedColorSpace`, ruta hardcodeada de MAT-file distinta). Renombrados a
  `CamLTestOM4MClassLib.m`/`.mat` y `CamRTestOM4MClassLib.m`/`.mat`; actualizado su único
  llamador (`test_HW_Passive3DCam.m`, 11 apariciones `@CamL,@CamR` →
  `@CamLTestOM4MClassLib,@CamRTestOM4MClassLib`). **Nota:** ambas rutas hardcodeadas
  dentro de `CamL.m`/`CamR.m` (`load('C:\user\AQ_SCC\Hg\...')`) son de la máquina
  original del autor y no funcionan en ningún sitio — no es cosa de esta migración, no se
  toca.
- **`test_HW_Passive3DCam.m` ya estaba roto de origen** (independientemente de la
  migración): usa la clase `Passive3DCam`, que **ya no existe en ningún sitio del repo**
  (debió borrarse en la limpieza manual de Fase 1 bis sin que quedara registrado). No se
  puede arreglar sin traer esa clase de vuelta — se deja migrado tal cual, sabiendo que no
  puede ejecutarse.
- **`test_Util_XLSUtils.m`** (mtest antiguo, no ejecutable de todas formas) tenía 6 usos
  de `'.\testFile.xls'`/`'.\testFile.xlsx'` — mismo bug de ruta relativa a subcarpeta que
  en FPA (`.\algo` tampoco resuelve vía `addpath`, solo vía `cwd`, confirmado de nuevo
  empíricamente). Corregido a `fullfile(fixturesRoot(),'testFile.xls')` por consistencia,
  aunque el test no pueda correr por el framework muerto.
- **`tests/fixtures/`**: `documentsDB8bpqrcopystAll.csv`, `test.mat`, `testFile.xls`,
  `testFile.xlsx`, `testFileHighIndex.csv`, `testFilePolycarbonate.csv`, `testL1/2.jpg`,
  `testR1/2.jpg`, y 40 `imageL1-20.jpg`/`imageR1-20.jpg` con prefijo
  `TestOM4MClassLib_` (para no chocar con los `imageL1/2.jpg`/`imageR1/2.jpg`,
  **distintos**, ya copiados desde `GUILib` — comprobado con `cmp`, no son la misma
  foto). `TwoCamCapConfig.xml` no se duplicó (idéntico al de `GUILib`, comprobado con
  `cmp`). **Descartado** `RunSelectedTests.m` (decisión ya tomada, script legacy sin
  `matlab.unittest`).

### `TestZernike` → migrado y verificado — HALLAZGO IMPORTANTE: dependencias ya borradas

- **`tests/`**: 4 tests `matlab.unittest` reales (`testAdjustSurface`,
  `testEvaluateTerms`, `testPolyEquivalent`, `testPolyval2`) + `zernfun.m` (implementación
  de referencia de terceros, usada por `testEvaluateTerms` para comparar resultados).
  Descartado `RunSelectedTests.m`.
- **Verificación real (aislando cada test, ver nota técnica abajo):**
  - `testPolyEquivalent`: **2/2 pasa**. `PolyEquivalent` funciona bien.
  - `testEvaluateTerms`: **falla** — `Zernikes.EvaluateTerms` llama a `Poly2.Evaluate`,
    y **`UtilLib/Poly2` ya no existe en el repo** (se borró en la limpieza manual de
    Fase 1 bis, marcado como "fuera de alcance" — pero nadie se dio cuenta entonces de
    que `+Zernikes` dependía de él).
  - `testPolyval2`: **falla** — llama a `Polyval2` (sin cualificar con `Zernikes.`,
    vía `import Zernikes.*`), y **no existe ningún `Polyval2.m` en `+Zernikes` ni en
    ningún otro sitio del repo actual** — ya faltaba antes de esta migración, no se sabe
    si vivía dentro del propio `Poly2` borrado o en otro sitio.
  - `testAdjustSurface`: **falla** — `AdjustSurface.m` llama a
    `ClassifierFactory.Create(ClassifierTypes.LinReg)`, de **`ClassLib/ML`, también
    fuera de alcance y ya borrado** (confirmado como exclusión intencional en Fase 1
    bis, pero tampoco se sabía que `+Zernikes` dependía de él).
  - **Conclusión: 3 de las 6 funciones de `+Zernikes` (`EvaluateTerms`,
    `CalculateCurvatureDer` —mismo `Poly2.Derive`—, `AdjustSurface`) están rotas por
    dependencias que el propio usuario ya había decidido excluir del alcance
    (`UtilLib/Poly2`, `ClassLib/ML`), sin saber en su momento que `Zernikes` las
    necesitaba.** Las otras 3 (`GetScaling`, `PolyEquivalent`, `RegresionByNormalEqn`)
    funcionan bien. **No es un bug de esta migración — ya estaba así en el legacy antes
    de tocar nada.** Pendiente de decisión del usuario: ¿recuperar `Poly2`/`ClassLib/ML`
    al alcance, o aceptar `+Zernikes` con esas 3 funciones rotas?

**Nota técnica de verificación:** al correr varios ficheros de test distintos en la misma
llamada a `runtests({...})`, el `TearDown` de un test (`matlabpath(pathdef)`, que
resetea el path a su valor de fábrica) puede dejar sin `addpath` los packages `+` que
necesita el SIGUIENTE test del lote si ese test no tiene su propio `SetUp` que los
vuelva a añadir (a diferencia de las classdef normales, que MATLAB cachea en memoria y
siguen resolviéndose aunque se resetee el path, **las funciones dentro de un package
`+` si necesitan que su carpeta padre siga en el path en el momento de la llamada**). Los
4 tests de Zernike no tienen `SetUp` propio (asumen que `src/` ya está en el path desde
fuera) — por eso se verificaron uno a uno con `addpath` fresco antes de cada
`runtests()`, no en lote.

### Poly2 / ClassLib.ML recuperados y Zernikes arreglado (2026-09-12)

Tras el hallazgo anterior, se preguntó al usuario cómo proceder con las 3 funciones
rotas de `+Zernikes`. **Decisión: recuperar tanto `UtilLib/Poly2` como `ClassLib/ML`** al
alcance del proyecto (revierte parcialmente la reducción de alcance de Fase 1 bis).

- Ninguno de los dos lo borré yo en esta sesión — los borró el usuario antes de empezar
  Fase 2. **El usuario los restauró manualmente** desde la papelera de reciclaje de
  Windows (yo había empezado a mirar ahí para localizarlos, pero el usuario terminó la
  restauración él mismo tras un aviso de permisos al intentar listar la papelera).
- **`ClassLib/ML` restaurado:** 28 ficheros (`Classifier`, `ClassifierFactory`,
  `ClassifierChebyshev/KmeansCluster/LinReg/LR/NN/NN1/SVM/Zernikes`, `ClassifierProps`,
  `ClassifierTypes`, `aFeature*`, `Enum*`, `TrainingDataLoader`, `UtilFunML`, etc.) →
  migrados tal cual a `src/` (plano, sin namespace — no era `+ML`, ya era una carpeta
  plana). Sin colisiones de nombre con lo ya migrado.
- **`UtilLib/Poly2` restaurado:** `Poly2.m` (classdef con métodos estáticos `Evaluate`,
  `Derive`, `Laplacian` — de ahí que `Poly2.Evaluate(...)` funcione sin necesitar
  package `+`, es una llamada a método estático normal) + `derivest.m` (tercero, John
  D'Errico, File Exchange — diferenciación numérica, usado solo por el test) →
  `Poly2.m`+`derivest.m` a `src/`, `testPoly2.m` a `tests/` (test real
  `matlab.unittest`, 5/5 pasa).
- **Verificación tras la restauración:** `testEvaluateTerms` 2/2 pasa (antes roto),
  `testAdjustSurface` 1/1 pasa (antes roto), `Zernikes.CalculateCurvatureDer` verificado
  directamente (antes roto, ahora funciona). **`testPolyval2` sigue fallando** — la
  función `Polyval2` (sin cualificar, se esperaba vía `import Zernikes.*`) **no existe en
  ningún sitio del repo actual, ni en `Poly2` ni en `ML` ni en ningún otro sitio**
  (búsqueda exhaustiva `function.*Polyval2` en todo el legacy, cero resultados) — hueco
  real y aparte, no recuperable desde este repo. Se documenta como limitación conocida,
  no bloquea nada más.
### `ClassLib/TestML` → migración filtrada (2026-09-12), solo tests propios de OM4M

`ClassLib/TestML` (64 ficheros) mezclaba tests propios de los clasificadores OM4M con
ficheros de un curso de ML (Coursera/Andrew Ng) y duplicados por renombrado histórico. El
usuario eligió migrar **solo los tests propios de OM4M**, descartando el resto.

**Criterio para los duplicados** (mismo test con y sin guion bajo, p.ej.
`testMLClassifierLinReg.m` vs `testML_ClassifierLinReg.m`): comprobado con `head` en
todos los pares — el patrón es sistemático, **la versión sin guion bajo (camelCase) es
siempre la classdef `matlab.unittest.TestCase` moderna**, y la versión con guion bajo es
siempre el `mtest` antiguo (`test_suite=...;initTestSuite;`), a veces referenciando un
namespace `QCClassLib.*` incluso más antiguo que `OM4MClassLib`. Se quedó con la versión
moderna en todos los casos.

**Migrado a `tests/`** (16 tests):
- 12 classdef modernas: `testKMeansToolbox`, `testMLClassifierLinReg`,
  `testMLUtilFunML`, `testUtilTrainingDataLoader`, `testMLClassifierKmeansCluster`,
  `testMLClassifierLR`, `testMLClassifierNN`, `testMLClassifierNN1`,
  `testMLClassifierSVM`, `testMLfeatureNormalizer`, `testMLLabelManager`,
  `testMLPolynomicFeatureMapper`.
- 4 `mtest` antiguo sin equivalente moderno pero claramente código propio de OM4M (no
  descartados, mismo criterio que `TestProcessMeasure.m` en FPA): `testML_ClassifierZernikes.m`
  (prueba `ClassifierZernikes`, ya migrado), `testNN_Toolbox.m`, `testSVM_Toolbox.m`,
  `testQC_FeatureTest.m` (prueba `aFeatureFactory`/`aFeatureTypes`, código OM4M real).
- Soporte necesario: `svmdecisionIOTQC.m` (función privada de Stats Toolbox renombrada,
  usada solo por `testSVM_Toolbox.m`, no por el código de `src/`) y el helper de paths
  **`testAddReferemcesML_hg.m`** — ⚠️ **importante:** este subsistema usa un patrón de
  helper distinto a todos los demás (FPA/StandardHW/OM4MClassLib): las 12 tests
  modernas invocan el helper como `run(testAddReferemcesML_hg, 'addRefs')` (una classdef
  `matlab.unittest.TestCase` con un método `Test` llamado `addRefs`), NO como una función
  plana `testAAAddReferencesPathML_hg()`. Existían ambos ficheros en el legacy — el
  plano no lo llama ningún test migrado, así que se descartó y solo se migró y arregló
  el classdef. **Antes de asumir el patrón de función plana en un futuro subsistema,
  comprobar con `grep` cuál invoca realmente cada `SetUp`.**
- Fixtures: `QCStatsReport2Clases.xlsx`, `QCStatsReport3Clases.xlsx`, `bugMapperGo.mat`,
  `actual_theta.mat`, `Youn200225202.mat`.

**Descartado** (decisión del usuario, "solo tests propios de OM4M"):
- Material de curso (Coursera/Andrew Ng), no es código OM4M: `bayesgauss.m`,
  `covmatrix.m`, `mahalanobis.m`, `sigmoid.m`, `mapFeature.m`, `plotData.m`,
  `polyFeatures.m`, `visualizeBoundary.m`, `checkStats_Toolbox.m`, `ex1-7data*.{txt,mat}`,
  `ex4weights.mat`, `bird_small.png`.
- Duplicados `mtest` antiguos superados por su versión classdef moderna (13):
  `testKMeans_Toolbox.m`, `testML_ClassifierLinReg.m`, `testML_UtilFunML.m`,
  `testUtil_TrainingDataLoader.m`, `testML_ClassifierKmeansCluster.m`,
  `testML_ClassifierLR.m`, `testML_ClassifierLR_ClassTest.m`, `testML_ClassifierNN.m`,
  `testML_ClassifierNN1.m`, `testML_ClassifierSVM.m`, `testML_featureNormalizer.m`,
  `testML_labelManager.m`, `testML_polynomicFeatureMapper.m`.
- `testML_ClassifierChebyshev.m` — `+Chebyshev` ya está fuera de alcance desde Fase 1
  bis, coherente descartar también su test.
- `testML_ClassifierZernikes.m.orig` — backup de editor, cruft.
- `runAllUnitTests.m`, `RunSelectedTests.m` — scripts de test-runner legacy, mismo
  criterio que el resto del proyecto (superados por el futuro `tests/run_all_tests.m`).
  `testAAAddReferencesPathML_hg.m` (función plana, sin usar por ningún test migrado, ver
  nota arriba).
- Sin usar por nada, ni siquiera por lo descartado (comprobado con `grep` en todo
  `TestML`): `xmlTagSlashError.m`, `testAQ.mat`, `QCStatsReportAnomalous.xlsx`.

### Verificación en MATLAB de las 12 tests classdef modernas — completada

**84 tests, 41 pasan.** Los 43 fallos se agrupan en exactamente 3 categorías, todas
esperadas/preexistentes, ninguna es un bug de la migración:

1. **Datos de Coursera/Andrew Ng excluidos a propósito** (`ex1data2.txt`…`ex7data2.mat`)
   — la mayoría de los fallos. Consecuencia directa y esperada de la decisión de "solo
   tests propios de OM4M".
2. **`svmtrain` ya no existe en MATLAB moderno** (eliminada, no solo deprecada, desde
   ~R2016b; estamos en R2024b) — afecta a `ClassifierSVM.CalculateTheta` y a todo lo que
   lo usa por debajo (`ClassifierKmeansCluster`, `UtilFunML.learningCurve`/`NICDCurve`).
   **No es un bug de esta migración ni recuperable restaurando ficheros** — es
   modernización de código real (Fase 4; `matlab-modernize-code` ya lista `svmtrain`
   como función a reemplazar por `fitcsvm`).
3. **`covmatrix.m`** (`testKMeansToolbox/test5`) — es de DIPUM (Gonzalez/Woods/Eddins),
   tercero **ya excluido intencionalmente en Fase 1 bis** ("DIPUM ✅ eliminado"). Coherente
   con esa decisión previa, no se recupera. `testKMeansToolbox/test5` queda roto a
   propósito.

**Corrección de una clasificación propia:** `checkStats_Toolbox.m` lo había descartado
como "material de curso" solo por el patrón del nombre (`*_Toolbox.m`, como
`testNN_Toolbox`/`testSVM_Toolbox`) — pero es solo un guard genérico
(`ver('stats')`+`verLessThan`) que comprueba que el Statistics Toolbox esté instalado,
necesario para que `testKMeansToolbox` cargue. Corregido: migrado a `tests/`.

**Todo lo que SÍ depende de código/datos propios de OM4M pasa**, incluyendo los tests que
usan datos reales de lentes (`testLearningCurveLensesIOT`, `testValidationCurveIOTLenses`,
`testTrainIOT`, `testLCurveIOT*`, todos los de `LabelManager`/`PolynomicFeatureMapper`/
`UtilFunML` que no dependen de datos de Coursera) — buena señal de que los clasificadores
migrados funcionan correctamente sobre datos OM4M reales.

### Legacy borrado 2026-09-12 (tercera y última tanda de Fase 2)

Confirmado explícitamente por el usuario. Borrado: `ClassLib/+OM4MClassLib`,
`ClassLib/TestOM4MClassLib`, `ClassLib/ML`, `ClassLib/TestML`, `UtilLib/+Zernikes`,
`UtilLib/TestZernike`, `UtilLib/Poly2`. La carpeta `ClassLib/` quedó vacía tras esto y se
eliminó también.

**Fase 2 completa.** Legacy restante: `IOT2DPU` (proyecto MEX, pista aparte — mover a
`mex/src/` es tarea separada, no sigue el patrón src/tests).

### `UtilLib/jsonlab` → recuperado al alcance y migrado (2026-09-12)

El usuario confirmó que usa `loadjson`/`savejson` para generar y leer JSON, señalando un
uso real fuera de este repo (`lensmappermatlab/src/AppInt/TransDeflAppInterface.m`,
líneas 86 y 305: `loadjson(this.configFile)` / `savejson('',this.configAppInt,...)`).

- **`src/`**: 8 `.m` (`jsonopt`, `loadjson`, `loadubjson`, `mergestruct`, `savejson`,
  `saveubjson`, `struct2jdata`, `varargin2struct` — tercero, Qianqian Fang, jsonlab) +
  `AUTHORS.txt`, `ChangeLog.txt`, `LICENSE_BSD.txt`. **No se copió `examples/`** (scripts
  de demo del propio jsonlab, no hacen falta para que la librería funcione, y habría
  roto la estructura plana sin subdirectorios).
- **Colisión de `README.txt`** con el de `ExportFig` (ambos terceros traen su propio
  README) → renombrados `README_ExportFig.txt` y `README_jsonlab.txt`.
- **Verificado en MATLAB (R2024b):** `savejson`+`loadjson` con una estructura de prueba
  (número, string, vector) — round-trip correcto.
- **Legacy `UtilLib/jsonlab` borrado** tras la verificación (confirmado con el usuario).

Con esto, `UtilLib/` queda vacío del legacy — solo queda `IOT2DPU` (MEX) en todo el
árbol legacy original.

### `jsonlab/examples/` → recuperados y transformados en tests unitarios reales (2026-09-12)

`UtilLib/jsonlab/examples/` (`demo_jsonlab_basic.m`, `demo_ubjson_basic.m`,
`jsonlab_selftest.m`, `jsonlab_speedtest.m`, `example1-4.json`, y dos transcripciones de
consola `.matlab` de una sesión de MATLAB R2010b) no se había copiado al migrar jsonlab
(no hacía falta para que la librería funcionara, y `examples/` habría roto la estructura
plana de `src/`). El usuario los recuperó de la papelera de reciclaje él mismo y pidió
explícitamente **transformarlos en tests unitarios** — a diferencia del resto de Fase 2
("sin cambios de contenido"), aquí sí se ha escrito código de test nuevo a petición
explícita.

- **`tests/testJsonlabRoundTrip.m`** (nuevo): round-trip JSON y UBJSON de los 4
  `example*.json` reales (adaptado de `jsonlab_selftest.m`, que solo imprimía, sin
  ninguna aserción).
- **`tests/testJsonlabBasicTypes.m`** (nuevo): round-trip parametrizado (JSON/UBJSON) de
  cada tipo de dato demostrado en `demo_jsonlab_basic.m`/`demo_ubjson_basic.m` (escalar,
  complejo, matriz compleja, `NaN`/`Inf`, disperso real/complejo, matrices vacías,
  struct, array de structs, array de structs 2D, cell array) con aserciones de verdad.
- **`tests/jsonlab_speedtest.m`**: migrado tal cual (script de benchmark, no de
  corrección — no tiene sentido como test con aserciones).
- **Fixtures**: `example1-4.json` → `tests/fixtures/`.
- **No migrados** (superados por los tests nuevos, sin valor añadido):
  `demo_jsonlab_basic.m`, `demo_ubjson_basic.m`, `jsonlab_selftest.m` (contenido ya
  incorporado a los tests nuevos) y las dos transcripciones `.matlab` (solo texto de una
  sesión de consola antigua, no código).

**Hallazgos reales sobre jsonlab en MATLAB moderno** (descubiertos al escribir
aserciones de verdad en vez de solo imprimir, que es justo el valor de convertirlos en
tests unitarios):
- `savejson` serializa `double` con ~10 dígitos significativos por defecto → los
  round-trips de JSON (texto) pierden precisión más allá de eso. Los tests usan
  tolerancia (`AbsTol`) en vez de igualdad exacta para valores de coma flotante.
- UBJSON (binario) guarda `double`s con valor entero en el tipo entero más compacto que
  quepa (`int8`/`int16`/...) — comportamiento real y esperado del formato, no un bug. Los
  tests normalizan a `double` antes de comparar en vez de comparar clases.
- Un array UBJSON totalmente vacío (`zeros(0,3)`) no preserva de forma fiable su
  dimensión no nula tras el round-trip — se comprueba solo `isempty()`, no el tamaño
  exacto.
- El array de structs 2D no conserva su forma/orden de indexado lineal original al
  recargarlo (el propio demo antiguo de jsonlab ya mostraba una re-anidación distinta) —
  se comprueba que sobreviven todos los valores `idx`, no la forma exacta.
- **Límite real confirmado, no arreglado:** `example2.json` y `example4.json` (los que
  contienen arrays JSON de strings planos, p.ej. `["GML","XML"]`) hacen que
  `savejson`/`saveubjson` fallen dentro de su rama `matlabobject2json`/`2ubjson`
  (`Error using properties... Argument must be a text scalar`) en esta versión de
  MATLAB. No es algo a arreglar en el propio jsonlab (código de terceros) — los tests
  correspondientes usan `assumeFail` para marcarlo como limitación conocida (aparecen
  como "Filtered", no como fallo) en vez de forzar que pase.

**Verificado en MATLAB (R2024b):** 30 tests pasan, 4 correctamente filtrados por la
limitación de arrays de strings planos.

---

## TODO Fase 3 (registrado 2026-09-12, a petición del usuario): `pathdef` no es `resetPath`

Durante toda la Fase 2, cada vez que un `TestMethodTeardown`/helper de path usaba
`matlabpath(resetPath)` con la función `resetPath` inexistente, se sustituyó por
`matlabpath(pathdef)` (o, en los helpers `testAAAddReferencesPath*.m`, simplemente se
quitó el reset y se dejaron solo los `addpath` aditivos). **El usuario señaló que esto
no es equivalente**: `pathdef` resetea el path al valor de fábrica de MATLAB, tirando
cualquier cosa que el usuario tuviera en su propio path antes de arrancar los tests
(otros proyectos, toolboxes propias) — un `resetPath` de verdad debería capturar el path
tal como estaba al empezar el test y restaurar exactamente eso, no el de fábrica.

**Ficheros que ya usaban `matlabpath(pathdef)` en el legacy original** (no es algo que
yo introdujera, ya estaba así antes de tocar nada — 45 ficheros, la inmensa mayoría de
FPA, StandardHW, OM4MClassLib y ML):
`testAddReferemcesML_hg`, `testMLPolynomicFeatureMapper`, `testMLLabelManager`,
`testMLfeatureNormalizer`, `testMLClassifierSVM`, `testMLClassifierNN1`,
`testMLClassifierNN`, `testMLClassifierLR`, `testMLClassifierKmeansCluster`,
`testUtilTrainingDataLoader`, `testMLUtilFunML`, `testMLClassifierLinReg`,
`testKMeansToolbox`, `testAAAddReferencesPath`, `testCellArrayList`, `testCQueue`,
`testThorlabsPM100PowerMeter`, `testHWVelleman`, `testHWLightSourcePS`,
`testHWCNCXProV2`, `testPolarMeasurement`, `testFPADemodulatorPSFotoel`,
`testFPADemodulatorPS6StepFotoel`, `testFPADecoderRGB`, `testTFM_VdH`,
`testTempAnalysisRetarExposure`, `testFPA_UtilFunMapperMeasureClassVer`,
`testFPA_UtilFunFPAClassVer`, `testFPA_QCZebra`, `testFPAUnwrapper`,
`testFPAPathFollowerCQueue`, `testFPADisplayProjectorPsych`,
`testFPADisplayProjectorMatlab`, `testFPADisplayProjectorC`, `testFPADisplayProjector`,
`testFPADemodulatorTempPSA`, `testFPADemodulatorSpatialFT`,
`testFPADemodulatorPSA6MultiplexedXY`, `testFPADemodulatorLSPSA`,
`testFPADemodulatorLSEquispacedPSA`, `testFPADemodulatorGCPSA`, `testFPADemodulatorGC`,
`testFPADemodulatorFTTempAnalysis`, `testFPADemodulator`, `testFFVCalibration`.

**Ficheros donde SÍ cambié yo `resetPath`→`pathdef` (los únicos 2 reales, StandardHW)**:
`testStandardHW_ImaqCam_ClassVer.m`, `testStandardHW_MockCam.m`.

**Ficheros donde quité el reset por completo** (helpers de path, ya no llaman a nada
tipo resetPath ni pathdef al principio, solo `addpath` aditivo):
`testAAAddReferencesPathFPA.m`, `testAAAddReferencesPathStandardHW.m`.

**Opciones consideradas para Fase 3:**
1. **Implementada (2026-09-13):** función propia `tests/resetPath.m` con `persistent` —
   ver detalle abajo.
2. Descartada por ahora: `matlab.unittest.fixtures.PathFixture` — mecanismo nativo de
   `matlab.unittest` para exactamente este caso (añade carpetas al path para un test,
   restaura el path original al terminar). Habría eliminado también la necesidad de los
   helpers `testAAAddReferencesPath*.m` como función aparte, pero implica reescribir el
   `SetUp`/`TearDown` de los 47 ficheros a la vez que se cambia el mecanismo de
   restauración — se prefirió el cambio mínimo ahora (sustituir la llamada) y dejar
   `PathFixture` como posible refactor futuro dentro de la reescritura general de Fase 3
   a `matlab.unittest`.

### Implementado: `tests/resetPath.m` (2026-09-13)

Función con `persistent capturedPath`: la primera vez que se llama en la sesión de
MATLAB captura `path()` (antes de que ningún test haya tocado el path) y a partir de ahí
siempre devuelve ese mismo snapshot. Uso: `matlabpath(resetPath); %#ok<RESETPATH>` en
`TestMethodTeardown`.

Cambios aplicados a los 47 ficheros de la lista de arriba:
- **`testAAAddReferencesPath.m` y `testAddReferemcesML_hg.m`** (los 2 helpers que
  reseteaban con `matlabpath(pathdef)` antes de añadir sus propias carpetas): se quitó
  esa línea por completo. Era la causa real del problema incluso sin llegar al
  `TearDown` — `addpath` es idempotente, el reset previo no hacía falta para nada.
- **Los 4 tests de hardware que además reseteaban en su propio `SetUp`**
  (`testHWVelleman`, `testHWCNCXProV2`, `testHWLightSourcePS`,
  `testThorlabsPM100PowerMeter`): se quitó esa línea del `SetUp` por el mismo motivo, y
  el `TearDown` pasa a usar `matlabpath(resetPath)`.
- **El resto (41 ficheros, `TearDown` únicamente):** `matlabpath(pathdef)` →
  `matlabpath(resetPath); %#ok<RESETPATH>` sin más cambios. En
  `testFPA_UtilFunFPAClassVer.m`, `testFPA_UtilFunMapperMeasureClassVer.m` y
  `testTFM_VdH.m` se conservó el comentario explicativo sobre `savepath` y support
  packages, adaptado a que ahora es `resetPath` (no `pathdef`) quien decide qué se
  restaura.

**Hallazgo de paso:** `testThorlabsPM100PowerMeter.m` es un test de hardware real
(Thorlabs PM100 por puerto serie, comentario propio del fichero: "antes de pasar estos
tests hay que conectar el thorlabs PM100 a un puerto serie del PC") que no se etiquetó
`Hardware` en la convención de [[hardware tests]] anterior porque no coincidía con los
patrones de búsqueda usados entonces (`*HW*.m`, `*Cam*.m`). Etiquetado ahora
(`methods (Test, TestTags = {'Hardware'})`). **Pendiente:** revisar si queda algún otro
test de hardware con nombre igual de poco obvio (p.ej. por instrumento en vez de por
"HW"/"Cam").

**Bug de paso corregido:** `testTFM_VdH.m` tenía su método `TearDown` declarado dentro
de `methods(Test)` en lugar de `methods(TestMethodTeardown)` — nunca se ejecutaba como
teardown real, MATLAB lo trataba como un test suelto sin aserciones (siempre "pasaba"
sin comprobar nada). Movido al bloque de atributo correcto de paso, ya que se estaba
editando esa misma línea.

## Eliminado del alcance: subsistema motores/fuentes de luz/potenciómetros (2026-09-13)

A petición explícita del usuario, se eliminaron por completo (sin sustituto, sin
recuperación pendiente) 16 ficheros de `src/` ya migrados en Fase 2, más sus 5 tests y 1
fixture asociados — a diferencia del resto de eliminaciones de Fase 1 bis/2 (que fueron
legacy sin migrar o duplicados), estos SÍ estaban ya en `src/`/`tests/` funcionando:

**`src/` (16):** `HWCM700Servo.m`, `HWCNCXProV2.m`, `HWLep.m`, `HWLightSourcePS.m`,
`HWSerial.m`, `HWVelleman.m`, `ILightSource.m`, `IMotor.m`, `IPowerMeter.m`,
`IPowerSource.m`, `LightSourceFactory.m`, `MotorFactory.m`, `MX64Parameter.m`,
`PRMTZ8.m`, `ThorlabsPM100DPowerMeter.m`, `ThorlabsPM100PowerMeter.m`.

**`tests/` (5):** `testHWCNCXProV2.m`, `testHWLightSourcePS.m`, `testHWSerial.m`,
`testHWVelleman.m`, `testThorlabsPM100PowerMeter.m`.

**Fixture (1):** `tests/fixtures/LensRecorderConfig_test.json` — quedó huérfana tras
borrar los 4 tests classdef que la usaban (`testHWVelleman`, `testHWCNCXProV2`,
`testHWLightSourcePS`, `testThorlabsPM100PowerMeter`); confirmado con el usuario antes
de borrarla.

Verificado antes de borrar (`grep` en `src/` y `tests/`): ningún otro fichero del
proyecto referencia ninguna de estas clases — el subsistema estaba autocontenido
(interfaces `I*` + factories + implementaciones concretas de motores/fuentes de
luz/potenciómetros, todas del mismo grupo), así que la eliminación no deja huecos ni
rutas rotas en el resto de `src/`.

**Impacto en trabajo reciente de la sesión:** esto revierte parte del trabajo de
etiquetado de hardware y `resetPath` hecho justo antes en la misma sesión sobre
`testHWVelleman`, `testHWCNCXProV2`, `testHWLightSourcePS`, `testHWSerial` y
`testThorlabsPM100PowerMeter` — no por error, sino porque el usuario decidió que estos
tests concretos ya no hacen falta en absoluto. `TODO.md` (Fase 3, pendiente de etiquetar
`mtest` legacy) y `tests/run_hardware_tests.m` (comentario de ejemplo) actualizados para
quitar las referencias a ficheros que ya no existen.

### `UtilLib/ExportFig` → recuperado al alcance y migrado (2026-09-12)

El usuario confirmó explícitamente que usa `export_fig` mucho para generar EPS de
figuras MATLAB para publicaciones (ver ejemplo real:
`AQ_SYNC\AQ\KIROS\PAPERS\Libros\FPA_src_06DIC19\FPA\Libro\SpatialMethodsWithoutCarrier\Figures\Steering1DAsinc5DemodMiract.m`,
que además usa `OrMinDer`/`calcDirection`/`PSAsinc5`, ya migrados de `UtilLib/FPA` y
`ClassLib/TestFPA` respectivamente — confirma que `ExportFig` es una dependencia real y
activa, no solo teórica). Prefiere `export_fig` sobre el exportador nativo de MATLAB.

- **`src/`**: los 15 `.m` de `export_fig` (Oliver Woodford, tercero) + `pdftops.exe`
  (binario de terceros incluido en la propia librería, necesario para conversión
  PDF/PS) + `README.txt`. Sin colisiones de nombre.
- **Verificado en MATLAB (R2024b):** exportación a PNG y a EPS ambas funcionan
  correctamente sobre una figura de prueba. Solo aviso benigno de deprecación
  (`JavaFrame`, interno de MATLAB, no relacionado con `export_fig` en sí).
- **Legacy `UtilLib/ExportFig` borrado** tras la verificación.
- **Nota de proceso:** al mismo tiempo se corrigió una inconsistencia propia menor:
  `derivest.m` (tercero, John D'Errico, dependencia de `testPoly2.m`) estaba en `src/`
  en vez de `tests/` — solo lo usa el test, no `Poly2.m`, así que por la regla ya
  establecida ("solo lo que necesita `src/` para funcionar va en `src/`") debía estar en
  `tests/`. Movido.

### Terceros pendientes de revisar (sin cambios en esta pasada)

`UtilLib/ExportFig/` y `UtilLib/jsonlab/` siguen sin migrar ni revisar — pendiente
comprobar si algún fichero OM4M ya migrado los usa (`jsonlab` se referencia desde el
helper de paths por si `loadjson`/`savejson` hacen falta, pero no se ha migrado la
librería en sí).

## FASE 3 — Convención de tests de hardware (2026-09-13)

### Problema

`run_all_tests.m` usa `matlab.unittest.TestSuite.fromFolder`, que solo descubre
`classdef` válidas de `matlab.unittest.TestCase` — los `mtest` legacy (patrón `function
test_suite = ...; initTestSuite;`) quedan fuera automáticamente. Esto significaba que la
mayoría de los tests de hardware (cámaras, motores, fuentes) ya estaban excluidos de
facto, pero por accidente (no son `classdef` todavía), no por diseño — y en cuanto Fase 3
los reescriba como `classdef` empezarían a fallar en cualquier entorno sin el hardware
conectado. Caso ya real: `testHWVelleman.m` (ya `classdef`) sí se ejecuta hoy y fallaría
sin la fuente Velleman conectada.

### Decisión

Etiquetar explícitamente los tests de hardware en vez de depender del accidente de
formato:

- `methods (Test, TestTags = {'Hardware'})` en el bloque de métodos de test que requiere
  hardware real.
- `run_all_tests.m` filtra por tag y excluye `Hardware` por defecto (`arrayfun` sobre
  `suite`, comprobando `ismember('Hardware', t.Tags)`).
- Nuevo `run_hardware_tests.m` — mismo mecanismo pero invertido, para ejecutar
  manualmente a pie de mesa con el equipo conectado.
- **Excepción explícita pedida por el usuario:** los tests contra `MockCam`
  (`testStandardHW_MockCam.m`) NO se etiquetan — son software puro, no necesitan
  hardware real, deben seguir corriendo siempre en `run_all_tests.m`.

**Aplicado ya (2026-09-13)** a los 4 `classdef` de hardware existentes: `testHWVelleman`,
`testHWCNCXProV2`, `testHWLightSourcePS`, `testStandardHW_ImaqCam_ClassVer`.
(`testHWVelleman`, `testHWCNCXProV2` y `testHWLightSourcePS` se borraron más tarde el
mismo día junto con el subsistema de motores/fuentes de luz — ver más abajo.)

**Hecho (2026-09-13, más tarde el mismo día):** al reescribir los `mtest` legacy de
hardware como `classdef` (ver "Inventario y conversión de `mtest` legacy" más abajo) se
etiquetaron también `test_HW_Passive3DCam` y `test_Facades_TwoCamCapAppInterface`.
`testStandardHW_ImaqCam` se eliminó (cobertura duplicada); `testHWSerial` se eliminó
junto con el subsistema de motores/fuentes de luz.

## Inventario y conversión de `mtest` legacy (2026-09-13)

Primer ítem real de Fase 3: inventariar los tests `mtest` (patrón antiguo `function
test_suite = ...; initTestSuite;`) y decidir, para cada uno, si están "muertos" (no
descubiertos por `matlab.unittest.TestSuite.fromFolder`, que solo reconoce `classdef`
`TestCase`) y cubiertos ya por un test moderno equivalente (→ eliminar) o no cubiertos
(→ reescribir como `classdef`).

### Inventario (19 ficheros encontrados vía `grep initTestSuite`)

Todos son "muertos" por definición (formato antiguo, invisibles para el runner actual).

### Eliminados por cobertura 100% duplicada (2)

Comparando nombres de función test uno a uno contra el `classdef` correspondiente:

- **`testStandardHW_ImaqCam.m`** (29 tests) — los 29 nombres existen tal cual en
  `testStandardHW_ImaqCam_ClassVer.m` (que además tiene uno más,
  `testSaveGVconstant`). Cobertura completa confirmada, eliminado.
- **`testFPA_UtilFunMapperMeasure.m`** (18 tests) — los 18 nombres (con o sin guión bajo
  tras `test`) existen en `testFPA_UtilFunMapperMeasureClassVer.m` (que tiene 30 en
  total). Cobertura completa confirmada, eliminado.

### Consolidado por cobertura parcial (1, el grande)

**`testFPA_UtilFunFPA.m`** (2711 líneas, 48 tests) vs `testFPA_UtilFunFPAClassVer.m` (27
tests entonces) — comparando nombres, solo 3 coincidían de verdad:
`test_GradientConsistency` y `test_GradientConsistencyWithWrappedDifs` (ambos cubiertos
por el `testGradientConsistency` moderno, que combina el caso sin envolver y el
envuelto en un solo test) y `testBin2Grey` (idéntico, mismo fixture `Dec2Grey_15`).

Los otros 40 (demoduladores FFT/PCA/AIA/IQT/PSAsync5, homografías, orientación y
dirección de franjas, etc. — código óptico de FPA sin equivalente moderno) se añadieron
como métodos `(Test)` nuevos al final de `testFPA_UtilFunFPAClassVer.m`, y
`testFPA_UtilFunFPA.m` se eliminó. El fichero resultante tiene ahora 67 tests y ~5000
líneas — es, con diferencia, el fichero de test más grande del repo; queda así
documentado por si en el futuro se plantea dividirlo por subsistema (FFT/PCA/AIA/IQT/
homografía) en vez de mantenerlo monolítico.

**Hallazgo al consolidar:** `assertAlmostEqual`/`assertElementsAlmostEqual` (funciones
del framework `xunit` legacy de MATLAB, distinto de `matlab.unittest`) no existen en
ningún sitio de este repo (comprobado con `find`) — ni como fichero propio ni como parte
de ningún toolbox vendido en el repo. Pese a esto, `testGradientConsistency` en
`testFPA_UtilFunFPAClassVer.m` (ya migrado y dado por bueno en Fase 2) los llamaba sin
convertir — bug preexistente, nunca antes ejecutado con éxito en este repo tal cual
estaba. Corregido de paso, junto con todos los usos que traía `testFPA_UtilFunFPA.m`:
todos sustituidos por `testCase.assertEqual(actual, expected, 'AbsTol', tol)`.
**How to apply:** si aparece otro `assertAlmostEqual`/`assertElementsAlmostEqual`/
`assertVectorsAlmostEqual` en cualquier test todavía sin convertir, tratarlo igual — no
asumir que existe solo porque aparece en código "ya migrado".

**`testCalculateHomographyAndTransform`** usa `ginput(4)` (clicks manuales sobre una
imagen) — no automatizable. Se marcó con `testCase.assumeFail('...')` al principio del
método para que aparezca como test filtrado (no fallado) en ejecuciones desatendidas,
mismo patrón que los casos de jsonlab ya documentados en Fase 2.

### Reescritos 1:1 como `classdef` (16, mismo nombre de fichero)

`testQC_FeatureTest`, `testSVM_Toolbox`, `testNN_Toolbox`, `testML_ClassifierZernikes`,
`test_Util_XLSUtils`, `test_HW_Passive3DCam`, `test_Util_Validation`,
`test_Util_Logging`, `test_Util_CSVUtils`, `test_UtilTime`, `test_HW_Passive3DCamData`,
`test_Facades_TwoCamCapAppInterface`, `test_DataStructs_MeasureList_P3DData`,
`testPropsEnumList`, `testCellEnumList`, `TestProcessMeasure`.

Patrón aplicado: `methods(TestMethodSetup)`/`methods(TestMethodTeardown)` con el helper
`testAAAddReferencesPath*` correspondiente al dominio (genérico para Util/DataStructs,
`testAddReferemcesML_hg` para ML, `testAAAddReferencesPathStandardHW` para HW/Facades) +
`matlabpath(resetPath)` en el teardown; cada `function testXxx()` mtest pasó a
`function testXxx(testCase)`, y las llamadas sueltas a `assertTrue`/`assertEqual`/
`assertFalse` pasaron a `testCase.assertTrue`/`testCase.assertEqual`/
`testCase.assertFalse` (`assert()` puro se dejó igual — es un builtin real de MATLAB, no
una función de `xunit`).

**Verificado antes de convertir, no solo asumido:** para cada fichero se comprobó con
`find`/`grep` que las clases y fixtures referenciadas existen de verdad en el repo,
salvo los casos bloqueados documentados abajo — evitando repetir a ciegas el patrón de
"convertir sin comprobar" que ya había costado tiempo en Fase 2 con `Poly2`/`ClassLib.ML`
y `Passive3DCam`.

### Bloqueados, aún en el repo

- **`testSVM_Toolbox.m`:** depende de `svmtrain`/`svmclassify`, eliminados de MATLAB
  hacia R2016b (mismo hueco ya documentado para `ClassifierSVM` en Fase 2/4, ver
  arriba) — no es un hallazgo nuevo, es el mismo gap aplicado a un fichero más.
- **`testQC_FeatureTest.m`:** solo `testConstructor` es ejecutable. Los otros 4 tests
  (`testCalculate`, `testSaveLoad`, `testAddSamples`, `testgenTrainSets`) llaman a
  `getQCDirectoriesTest`/`filterOKDirTest`/`genQCDataStTest`/`geteDPMTest`/
  `getSWVersionTest` — ninguna existe en el repo — y apuntan a `..\TestDB\V07`/`V08`,
  un directorio externo que tampoco existe. Hueco distinto de los anteriores (no es
  código de OM4M sin migrar conocido, sino un dataset/herramientas de pruebas QC que
  nunca llegaron a Dropbox) — no investigado más a fondo, solo documentado aquí.

### Eliminados horas después: el hueco de `Passive3DCam` no merecía la pena mantenerlo (2026-09-13)

Se habían convertido a `classdef` (y, en dos casos, etiquetado `Hardware`) 4 ficheros
bloqueados por la falta de `OM4MClassLib.HW.Passive3DCam`/`Passive3DCamData` (hueco ya
conocido, ver TODO.md Fase 7 y la sección de Zernikes/Poly2 más arriba):
`test_HW_Passive3DCam.m`, `test_HW_Passive3DCamData.m`,
`test_Facades_TwoCamCapAppInterface.m` (`TwoCamCapAppInterface` instancia `Passive3DCam`
directamente en su constructor, así que **todos** sus tests fallaban, no solo los que
usan `Passive3DCam` explícitamente — confirmado con `grep` sobre
`src/+OM4MClassLib/+Facades/TwoCamCapAppInterface.m`) y
`test_DataStructs_MeasureList_P3DData.m` (4 de sus 5 tests bloqueados; el quinto,
`testMeasureList_P3DDataConstructor`, sí pasaba porque no usa `Passive3DCamData`).

**El usuario pidió eliminarlos por completo** en vez de dejarlos esperando a que Fase 7
recupere `Passive3DCam`/`Passive3DCamData` — incluido `test_DataStructs_MeasureList_P3DData.m`
entero (se ofreció conservar solo `testMeasureList_P3DDataConstructor`, que sí pasaba,
pero se optó por el barrido completo). De paso se eliminaron también
`tests/CamLTestOM4MClassLib.m` y `tests/CamRTestOM4MClassLib.m` (stubs de cámara de
prueba que solo usaba `test_HW_Passive3DCam.m`, huérfanos tras su borrado).

**Verificado antes de borrar** (con `grep` sobre todo `src/`) que ninguna de las clases
`src/+OM4MClassLib/+Facades/TwoCamCapAppInterface.m` /
`src/+OM4MClassLib/+DataStructs/MeasureList_P3DData.m` se tocó en este primer paso —
solo se pidió borrar los tests, no las clases fuente: `TwoCamCapAppInterface.m` lo
seguía usando `src/TwoCamCaptureGUI.m` (aunque en la práctica seguía roto sin
`Passive3DCam`) y `MeasureList_P3DData.m` es una clase de datos genérica que no depende
de `Passive3DCam` en absoluto — seguía siendo válida y usable aunque ya no tuviera test.

### Continuación (2026-09-13, horas después): las 2 clases fuente + `TwoCamCaptureGUI` también eliminadas

El usuario pidió explícitamente eliminar también `TwoCamCapAppInterface.m` y
`MeasureList_P3DData.m`. Antes de borrar se comprobó con `grep` todo el repo (no solo
los tests) para ver quién más las usaba:

- `MeasureList_P3DData.m`: sin más llamadores que `TwoCamCapAppInterface.m` — huérfana
  tras el borrado, sin motivo para conservarla.
- `TwoCamCapAppInterface.m`: su único llamador es `src/TwoCamCaptureGUI.m` (GUI
  GUIDE antigua, `.m`+`.fig`) — cuya única razón de ser era envolver
  `TwoCamCapAppInterface`. Se preguntó al usuario si borrar también
  `TwoCamCaptureGUI.m`/`.fig` en vez de dejarlo referenciando una clase inexistente;
  confirmó que sí.
- `src/CamL.m`/`CamR.m`/`.mat`: comprobado que **no** dependen funcionalmente de
  `TwoCamCaptureGUI` — solo lo mencionan dentro de una ruta hardcodeada de MAT-file ya
  documentada como muerta en Fase 2 (`C:\user\AQ_SCC\Hg\...`, no funciona en ningún
  sitio). En este paso no se tocaron.

**Borrados:** `src/+OM4MClassLib/+Facades/TwoCamCapAppInterface.m`,
`src/+OM4MClassLib/+DataStructs/MeasureList_P3DData.m`, `src/TwoCamCaptureGUI.m`,
`src/TwoCamCaptureGUI.fig`.

### Tercera tanda (2026-09-13, mismo día): `CamL.m`/`CamR.m`/`.mat` también eliminados

Con `TwoCamCaptureGUI.m` ya borrado, `CamL.m`/`CamR.m`/`.mat` se quedaron sin ningún
llamador real en el repo (confirmado con `grep \bCamL\b|\bCamR\b` sobre todo `*.m` —
solo aparecían en sí mismos). El usuario pidió eliminarlos explícitamente. Borrados:
`src/CamL.m`, `src/CamR.m`, `src/CamL.mat`, `src/CamR.mat`.

**Impacto en el hueco de Fase 7:** el hueco de `Passive3DCam`/`Passive3DCamData` ya no
afecta solo a 4 tests — todo el subsistema de captura de dos cámaras
(`TwoCamCapAppInterface`, `MeasureList_P3DData`, `TwoCamCaptureGUI`, `CamL`/`CamR`) se
eliminó de `src/` junto con ellos. Si en algún momento se recupera
`Passive3DCam`/`Passive3DCamData` del repo GitHub original, habría que reconstruir
también estas clases y sus tests desde cero — este documento (y el historial de
conversación) es la referencia completa de lo que hacían.

### Hallazgo de paso: `testThorlabsPM100PowerMeter.m` y el subsistema de motores/luz

Al hacer el inventario se confirmó que `testThorlabsPM100PowerMeter.m` era el test de
hardware que se había escapado del etiquetado `Hardware` original (ver sección de
`pathdef`/`resetPath` más arriba). Poco después, en la misma sesión, el usuario pidió
eliminar por completo ese test junto con todo el subsistema de motores/fuentes de
luz/potenciómetros (`HWVelleman`, `HWCNCXProV2`, `HWLightSourcePS`, `HWSerial`,
`ThorlabsPM100PowerMeter`, etc. — ver sección "Eliminado del alcance" más abajo) — por
lo que ese hallazgo quedó resuelto por eliminación, no por etiquetado.

### Resultado

De los 19 `mtest` originales: 2 eliminados por duplicados, 1 consolidado dentro de otro
fichero y eliminado, 16 reescritos como `classdef` — de los cuales 4 se eliminaron horas
después (hueco de `Passive3DCam`, ver arriba), quedando 12 reescritos y en el repo. De
los que quedan, 2 (`testSVM_Toolbox`, `testQC_FeatureTest`) siguen bloqueados por huecos
ya conocidos y documentados, no por errores de conversión. `grep initTestSuite tests/`
devuelve ahora cero resultados — Fase 3 ya no tiene ningún `mtest` legacy pendiente de
inventariar o convertir.

## `tests/setupPath.m` sustituye a los 4 helpers de path por dominio (2026-09-13)

### El pedido inicial no era del todo seguro

El usuario pidió eliminar `testAAAddReferencesPath.m`, `testAAAddReferencesPathFPA.m`,
`testAAAddReferencesPathStandardHW.m` y `testAddReferemcesML_hg.m` porque
`run_all_tests.m` ya añade `src/`/`tests/`/`tests/fixtures/` al path por su cuenta.
Cierto para los 2 primeros (`testAAAddReferencesPath.m`,
`testAddReferemcesML_hg.m` — su único contenido, además del ya quitado reset, era
justo esos 3 `addpath`, 100% redundantes con `run_all_tests.m`).

**No cierto para los otros 2:** `testAAAddReferencesPathFPA.m` y
`testAAAddReferencesPathStandardHW.m` también añadían
`om4mtools-matlab/IOT2DPU/deploy` al path — carpeta legacy que contiene
`PUFlynMdMex.mexw64`, el binario MEX compilado detrás de `UnwrapperTypes.FlynMd`,
usado en bastantes de los tests de demodulación FPA convertidos en este mismo Fase 3
(`testDemIQTMiract`, `testDemAsync5TunShadowMoire`, etc.). Sus otras rutas legacy
(`ClassLib/`, `UtilLib/` dentro de ese mismo `legacyRoot`) sí son ya no-ops reales — se
comprobó con `ls` que esos subdirectorios ya no existen (migrados por completo en
Fase 2) — pero `IOT2DPU/deploy` sigue existiendo y siendo necesario. Borrar esos 2
helpers sin más habría roto en silencio esos tests (error de función no definida al
llamar al unwrapper FlynMd) — se detectó y se avisó antes de borrar nada.

### Restricción adicional: los tests deben poder correr en solitario

Aún no existe `setup.m` (Fase 0.5 sigue sin cerrar) así que hasta ahora cada test era
autosuficiente: `run(testFPADemodulator)` en una sesión de MATLAB nueva funcionaba
porque su propio `SetUp` montaba el path. El usuario confirmó que quiere seguir
pudiendo correr cualquier test suelto así, no solo via `run_all_tests.m`.

### Solución: un único `tests/setupPath.m`

Función que hace lo que hacían los 4 helpers combinados, sin las partes muertas:

```matlab
addpath(thisDir);                                              % tests/
addpath(fullfile(thisDir, '..', 'src'));                       % src/
addpath(fullfile(thisDir, 'fixtures'));                        % tests/fixtures/
addpath(fullfile(thisDir, '..', 'om4mtools-matlab', 'IOT2DPU', 'deploy')); % MEX FlynMd
```

- Cada uno de los 53 tests que antes llamaba a uno de los 4 helpers ahora llama a
  `setupPath();` en su `TestMethodSetup` — funciona igual en solitario que antes (MATLAB
  resuelve `setupPath` por directorio de trabajo la primera vez, igual que antes con los
  helpers viejos) y sigue funcionando dentro de la suite completa.
- `run_all_tests.m` y `run_hardware_tests.m` también llaman a `setupPath()` (tras
  `addpath(thisDir)` para poder encontrarla la primera vez), en vez de repetir sus
  propios `addpath` inline.
- **Hallazgo de paso, un miss en la primera pasada:** `testKMeansToolbox.m` llamaba a
  `run(testAddReferemcesML_hg,'addRefs')` **sin espacio** tras la coma — el `grep` inicial
  (que buscaba con espacio) no lo encontró; se detectó en la verificación final por
  patrón más amplio y se corrigió. **How to apply:** al buscar y reemplazar llamadas a
  función por patrón exacto, verificar después con un patrón más laxo (sin depender de
  espaciado exacto) antes de dar el barrido por completo.
- Comentario desactualizado corregido de paso en `testStandardHW_MockCam.m` (mencionaba
  el helper `testAAAddReferencesPathStandardHW` ya borrado).

**Borrados:** `testAAAddReferencesPath.m`, `testAAAddReferencesPathFPA.m`,
`testAAAddReferencesPathStandardHW.m`, `testAddReferemcesML_hg.m`.

**Nuevo:** `tests/setupPath.m`.

### Hallazgo aparte: un "1" suelto había corrompido `run_all_tests.m`

Durante esta misma conversación el usuario había mandado un mensaje suelto con solo
"1", sin pregunta pendiente a la que responder. Al reeditar `run_all_tests.m` se
descubrió que ese mismo caracter había terminado escrito directamente en el fichero
(`end1` en vez de `end` en la última línea) — probablemente tecleado por error
directamente en el editor mientras el usuario miraba el fichero entre mensajes.
Corregido de paso al hacer el resto de cambios en ese fichero. **How to apply:** si un
mensaje suelto sin contexto aparece a mitad de turno, no descartarlo sin más — puede
ser la señal de una edición manual concurrente sobre un fichero que se está a punto de
tocar; conviene releer el fichero antes de escribir en vez de asumir que sigue como se
dejó.

## Datos de Grupo 1 copiados a fixtures + tests actualizados; tests de Grupo 2 eliminados (2026-09-13)

Continuación de [[hardcoded_refs_group_1]]/[[hardcoded_refs_group_2]] (ver memoria para
el detalle completo del hallazgo original). En esta sesión:

### 1. Eliminados los tests que dependían de datos no recuperables (Grupo 2 + LoadStepping)

- **`testFPADemodulatorFTTempAnalysis.m`**: eliminados `testDemodRetarRealImagesBackSubstraction`,
  `testDemodRetarRealImages`, `testDemodRetarRealImagesNC` (los 3 dependían de
  `LoadStepping`/`Celda28`, confirmado en un comentario propio del fichero que esos
  datos viven en una NAS, nunca en Dropbox). Quedan 6 de los 9 tests originales — los
  6 que no tocan esos datos (constructores, demodulación simulada, generación de FPs).
- **`testTempAnalysisRetarExposure.m`**: eliminados `testFFTRetarExposure` y
  `testGetFFTRetarExposure4AllCells` (ambos llamaban al helper `GetDeltaVsExposure`,
  que dependía de `Photoalignment\Cells\Comparación7_20_30_70_110`, no localizado en
  ningún sitio de Dropbox). También eliminado el propio helper `GetDeltaVsExposure`
  (`methods(Static)`), que quedó sin ningún llamador. **Se conservó
  `testPlotDeltaH4AllCells`** — no depende de los datos crudos, solo de
  `deltaH-12-Jan-2017.mat` (un resumen ya generado), que **ya existe** en
  `tests/fixtures/` — verificado antes de decidir qué conservar, no asumido.

### 2. Tests actualizados para usar `fixturesRoot()` en vez de `dropbox()`

Todos los ficheros que referenciaban directorios ya copiados a
`DataSetsForTesting\om4mtools-matlab\` (ver [[hardcoded_refs_group_1]]) se actualizaron
para leer de ahí en vez del Dropbox personal — patrón `dropboxFolder=fixturesRoot();` +
el nombre de la carpeta fixture (solo el nombre hoja, no la ruta histórica completa,
ya que se copió tal cual con ese nombre):

- `testFFVCalibration.m` (7 sitios), `testFPADemodulatorTempPSA.m` (2),
  `testFPAUnwrapper.m` (1 — el `AQsrcDir` genérico de todo `Deflectometria` se acotó a
  `MontajeHorizontal`, la subcarpeta real donde vive el `.mat` que este test carga),
  `testFPA_UtilFunFPAClassVer.m` (7), `testFPA_UtilFunMapperMeasureClassVer.m` (13 de
  14 — ver excepción abajo), `testFPADemodulatorPSA6MultiplexedXY.m` (1 — apuntaba a
  `ExperimentsCosmeticInspection\3 Ajuste de la deteccion\Imagenes con y sin
  multiplexar`, ruta que ya no existe; redirigido a `Imagenes PSA8 y PSA6 Heuristico`,
  su ubicación real actual, localizada por nombre de fichero `.mat`, no de carpeta).

**Excepción explícita, sin tocar:** `test_SetParamsForCalculateLensPower` en
`testFPA_UtilFunMapperMeasureClassVer.m` sigue usando `dropbox()` — su dataset (`49
INFORME-AVI014 Mejoras IOTMapper`) se saltó a propósito al copiar (6.9 GB/3101
ficheros, casi seguro solo hace falta una parte). Comentario añadido en el propio test
explicando por qué, para que no parezca un descuido.

**Variantes comentadas (inactivas) no tocadas:** varios sitios tenían alternativas
comentadas (`Calibracion_9FEB21_6mm`, `Calibracion_01MAR21_8mm`,
`Calibracion_26FEB21_A_10mm`, `Calibracion_26FEB21_B_10mm`, `Calibracion_29JUN20`
sin `_2`, `CalibracionGeometricaSinVidrio`, `CalibracionFFV-1-9-2016`) — como esos
datasets no se copiaron a fixtures (no estaban en la lista de Grupo 1), se dejaron como
comentarios sin cambios, con una nota indicando que no están disponibles como fixture.

### Cierre definitivo: `test_SetParamsForCalculateLensPower` (2026-09-14)

El usuario acotó exactamente qué hacía falta del dataset `49 INFORME-AVI014` que se
había saltado: solo `ListaMuestrasINFORME-AVI014.xlsx` + el subdirectorio de muestras
`CalibracionIOTMapper_15JUN23\`. Antes de tocar el test se verificó leyendo el propio
xlsx (Python/`openpyxl`, ya que no hay MATLAB disponible en este entorno) que las filas
que el test realmente usa (nombres que contienen `15-Jun-2023_P5`) tienen
`SampleHomePath='CalibracionIOTMapper_15JUN23'` y `SampleDir='.'` — confirmando que
copiar solo ese subdirectorio (34 ficheros, no los 3101 del proyecto completo) es
suficiente.

Copiados a fixtures: `ListaMuestrasINFORME-AVI014.xlsx` (12 KB) y
`CalibracionIOTMapper_15JUN23\` (34 ficheros). Test actualizado:
`dropboxFolder=fixturesRoot(); baseFolder='';` — con `baseFolder` vacío,
`fullfile(dropboxFolder, baseFolder, ...)` resuelve igual que antes pero contra
fixtures en vez de Dropbox.

**Grupo 1 queda así cerrado al 100%** — los 14 datasets originales están en
`DataSetsForTesting\om4mtools-matlab\` y `grep` sobre todo `tests/*.m` confirma cero
referencias a `dropbox()` restantes.

**Hallazgo de proceso:** `du -sh` sobre esta carpeta de Dropbox (smart-sync, con
ficheros posiblemente "online-only") dio 973 MB — el tamaño real, sumando el tamaño de
cada fichero individual (`stat -c%s`), es **6.6 GB**. `du` parece medir bloques de
disco realmente asignados/el footprint del placeholder, no el tamaño aparente del
fichero. **How to apply:** para estimar el tamaño real de una carpeta de Dropbox antes
de copiarla, sumar el tamaño de fichero individual (`stat`/`Get-ChildItem -Recurse |
Measure-Object -Property Length -Sum`), no `du -sh`.

## FASE 2 (reversión) — `tests/fixtures/` vacío, vuelta a `dropbox()` vía `fixturesRoot()` (2026-09-14)

**Decisión revertida:** todo el trabajo de "Grupo 1" de arriba (copiar 14 datasets,
~11 GB, a `tests/fixtures/` y apuntar los tests ahí en vez de a Dropbox) se deshace.
Motivo explícito del usuario: el proyecto es estrictamente personal por ahora — no hay
consumidores externos, los tests (y el "CI/CD" de MATLAB) siempre corren en una máquina
donde existe `<dropbox root>\AQ_EXP\DataSetsForTesting\om4mtools-matlab`, y duplicar
~11 GB dentro del propio repo no aporta nada, solo gasta disco.

**Qué cambió — solo 2 ficheros, cero tests tocados:**
- `src/dropbox.m`: el usuario añadió el caso de esta máquina (`DELLXPS13-I7-AQ` →
  `C:\user\Dropbox (Personal)`) manualmente.
- `tests/fixturesRoot.m`: en vez de devolver `fullfile(<tests/>, 'fixtures')`, ahora
  devuelve `dropbox('AQ_EXP', 'DataSetsForTesting', 'om4mtools-matlab')`.
- `tests/setupPath.m`: el `addpath` de fixtures pasa de `fullfile(thisDir, 'fixtures')`
  a `addpath(fixturesRoot())` (reordenado para que `src/` esté en el path antes, ya que
  `fixturesRoot()` ahora depende de `dropbox()`, que vive en `src/`).

**Por qué cero tests necesitaron cambios:** verificado con `grep` que los ~80 sitios que
llaman `fixturesRoot()` en `tests/*.m` lo tratan siempre como una raíz opaca
(`fullfile(fixturesRoot(), 'Subcarpeta', ...)` o `dropboxFolder=fixturesRoot();` seguido
de `fullfile(dropboxFolder, ...)`) — nunca asumen que apunta dentro del propio repo.
Cambiar solo la implementación de `fixturesRoot()` bastó. También se confirmó (grep)
que cero tests llaman `dropbox()` directamente — el único caso que lo hacía
(`test_SetParamsForCalculateLensPower`) ya se había migrado a `fixturesRoot()` en el
cierre de Grupo 1 (ver arriba).

**Efecto colateral positivo:** el TODO pendiente de renombrar `DropboxDir`/
`dropboxFolder`/`dbDir` (nombres que, tras Grupo 1, apuntaban a fixtures locales pero
seguían llamándose como si apuntaran a Dropbox) queda obsoleto — con esta reversión esos
nombres vuelven a ser correctos.

**Verificado antes de borrar:** `diff` entre el listado de ficheros de
`tests/fixtures/` (409 ficheros) y `DataSetsForTesting\om4mtools-matlab\` (410) mostró
que el mirror de Dropbox es un superset exacto (1 fichero de más,
`LensRecorderConfig_test.json`, cero de menos) — se pudo borrar `tests/fixtures/` sin
pérdida de datos.

**Qué se borró:**
- Los ~11 GB de contenido de `tests/fixtures/` — sustituidos por un
  `tests/fixtures/README.md` explicando la decisión y remitiendo a `fixturesRoot()`.
- `download_fixtures.sh` — ya no tiene sentido, no hay nada que "descargar" (los datos
  ya están en Dropbox, no hace falta copiarlos a ningún sitio).

**Documentación actualizada:** `CLAUDE.md` (sección Contexto y sección Tests) y
`TODO.md` (ítem de Fase 2 "mover datos/assets a fixtures", marcado como revertido en
vez de simplemente completado; ítem de renombrar variables, marcado obsoleto).

**Nota para el futuro:** si este proyecto llega a tener consumidores/colaboradores
externos, replantear entonces un mecanismo de fixtures portable/descargable — no antes.

## Grupo 2 hardcoded refs (`testTFM_VdH.m`) — CERRADO (2026-09-14)

**Datos localizados:** el usuario apuntó a la carpeta de Dropbox del TFM+PE de Víctor
del Hierro García (2020-21) — `AQ_SYNC\AQ\KIROS\Docente\DocenciaAQ\Trabajos
investigación POP Fisicas-TFM\VictorDelHierroGarciaTFM+PE-2020-2021\
TFM+PE_VictorDelHierro_2020-21\Respuesta lineal\` — distinta de
`DataSetsForTesting\om4mtools-matlab\` (donde vive el resto de fixtures del proyecto,
Grupo 1). Contiene `datos/` (los `ImgGV_*.mat` y `jsons/*.json` que los tests de
`testTFM_VdH.m` cargaban desde `D:\User\Victor\...`) y `figurasLin.m` (helper de plots
usado por `testFigLimitsGV4LinearResponse`, nunca migrado a este repo).

**Verificación exacta contra lo que cada test necesita (no copia ciega de la carpeta):**
de los 9 tests de `testTFM_VdH.m`, se determinó archivo por archivo qué fichero activo
(no las docenas de alternativas comentadas) carga cada uno, y se comprobó su presencia:

| Test | Fichero necesario | ¿Encontrado? |
|---|---|---|
| `testLimitsGV4LinearResponse` | `ImgGV_5_bad1.mat` + `TrasmDeflConfigDGV2.json` | Sí |
| `testArgumentsLinLUTGV` | `ImgGV_5_bad1.mat` | Sí |
| `testFigLimitsGV4LinearResponse` | `ImgGV_5_bad1.mat` + `figurasLin.m` | Sí (ambos) |
| `testFigFFTLinGV` | `datatestFFTlinGV.json` + clase `figDemodulator` | Solo el json — `figDemodulator` no se localizó en ningún sitio (ni este repo, ni la carpeta de Víctor, ni el mirror GitHub original de `om4mmatlabutils`) |
| `testCalculatePowerWithCorrectionFromLMMfile` | ficheros LMM de lentes (`lentesChinaB8`/`LMM5_B8_32`) | No — `Respuesta lineal\datos\LMM\` existe pero está vacía; búsqueda exhaustiva sin resultado |
| `testFFTLinGV`, `testCalculatePowerWithCorrection` | `TrasmDeflConfigDGV15.json` + cámara real | Json sí; requieren hardware de todos modos |
| `testImages`, `testCalculateResponseFromImages` | (orquestador / captura en vivo) | N/A — hardware |

**Copiado a fixtures:**
`DataSetsForTesting\om4mtools-matlab\Datos_LinearzationGV_TFM_20-21-VdHG\` (aplanado,
sin subcarpetas `datos/`/`jsons/`, para que un único `baseFolder=fixturesRoot()`/
`'Datos_LinearzationGV_TFM_20-21-VdHG'` sirva a todos los tests): `ImgGV_5_bad1.mat`,
`TrasmDeflConfigDGV2.json`, `TrasmDeflConfigDGV15.json`, `datatestFFTlinGV.json`.
`figurasLin.m` (classdef con métodos estáticos de plotting, autogenerado por MATLAB)
migrado a `src/` — mismo criterio que otros helpers usados solo por tests (`MockCam`).

**Integración en `testFPA_UtilFunFPAClassVer.m`:** los 9 tests se movieron ahí (mismo
patrón que la consolidación de `testFPA_UtilFunFPA.m` en Fase 3). Todas las rutas
`D:\User\Victor\...`/`addpath(baseDir)` se sustituyeron por
`dropboxFolder=fixturesRoot(); baseFolder='Datos_LinearzationGV_TFM_20-21-VdHG';` +
`fullfile(dropboxFolder, baseFolder, ...)`. Las referencias internas de `testImages` a
`TestSuite.fromMethod(?testTFM_VdH, ...)` se actualizaron a
`?testFPA_UtilFunFPAClassVer`. El resto del cuerpo de cada test (incluidas las docenas
de líneas de configuraciones de lentes comentadas en
`testCalculatePowerWithCorrectionFromLMMfile`) se preservó verbatim — no se tocó lógica
de negocio, solo resolución de rutas.

- **3 tests sin hardware, totalmente funcionales** (`methods (Test)` normal):
  `testLimitsGV4LinearResponse`, `testArgumentsLinLUTGV`, `testFigLimitsGV4LinearResponse`.
- **4 tests con cámara/proyector real**, movidos a
  `methods (Test, TestTags = {'Hardware'})`: `testImages` (orquestador interactivo con
  `pause`, ejecuta los otros vía `TestSuite.fromMethod`), `testCalculateResponseFromImages`,
  `testFFTLinGV` (typo `testcase`→`testCase` corregido de paso, no se usaba en el
  cuerpo), `testCalculatePowerWithCorrection`.
- **2 tests marcados `testCase.assumeFail(...)`** (mismo patrón que
  `testCalculateHomographyAndTransform`/`ginput`): `testFigFFTLinGV` (falta la clase
  `figDemodulator`, dependencia de código no de datos — el json sí está) y
  `testCalculatePowerWithCorrectionFromLMMfile` (faltan los ficheros LMM de lentes; el
  comentario en el test apunta a `C:\user\Dropbox (Personal)\AQ_EXP\67 INFORME-OM4M006
  Medida DPM oblicuidad` como posible fuente alternativa a revisar, a petición del
  usuario — sin verificar en profundidad, solo confirmada la existencia de la carpeta).

**`tests/testTFM_VdH.m` eliminado** tras la integración. `grep testTFM_VdH` sobre el
repo solo deja los comentarios de atribución en
`testFPA_UtilFunFPAClassVer.m` y entradas históricas ya fechadas en TODO.md/DECISIONS.md.

**Deuda de estilo heredada, no corregida a propósito:** el código portado usa `i`
como variable de bucle en varios sitios (`testFFTLinGV`), lo cual viola la convención
`i`/`j` de CLAUDE.md — se preservó tal cual (no se tocó lógica numérica de un test que
no se puede ejecutar en este entorno para verificar); corregirlo es tarea de Fase 4
(modernización), no de esta integración.

## FASE 6 — Migración de Dropbox a repo Git (2026-09-14)

**Decisión del usuario:** parar de trabajar en el directorio de Dropbox
(`AQ_EXP\75 om4mtools-matlab\`) y mover el proyecto a un repo Git independiente, ahora
que Fase 2 está prácticamente cerrada. Sigue el plan ya escrito en FASE 6 del propio
TODO.md (Git y Dropbox sync no conviven bien).

**Ubicación:** `C:\user\AQ_SCC\GitHub\om4mtools-matlab` — el usuario pidió esta ruta
exacta (con un typo, faltaba la barra entre `GitHub` y `om4mtools-matlab`; corregido
por analogía directa con `C:\user\AQ_SCC\GitHub\om4mmatlabutils`, el repo original ya
usado como referencia en Fase 7 — confirmado antes de crear nada que el directorio no
existiera todavía).

**Copia, no movimiento:** por petición explícita del usuario ("mantenemos por
seguridad el directorio dropbox"), la copia de Dropbox se conserva intacta como
backup — no se borró ni modificó nada ahí salvo añadir
`README_IMPORTANTE_14SEP26.md` explicando la situación (que este directorio ya no es
el sitio de trabajo activo, apuntando al repo Git nuevo). Verificado con `diff -rq`
antes y después de la copia que las dos copias eran idénticas (386 ficheros).

**`.gitignore`:** partiendo del borrador ya redactado en TODO.md FASE 6, 3 ajustes
necesarios detectados al inspeccionar el árbol real antes de comprometer nada:
1. El borrador conservaba `!tests/fixtures/.gitkeep`, pero ya no existe ningún
   `.gitkeep` — desde la reversión de fixtures (ver más arriba, "FASE 2 (reversión)")
   lo que hay que conservar es `tests/fixtures/README.md`.
2. El legacy `om4mtools-matlab/IOT2DPU/deploy/PUFlynMdMex.mexw64` (el MEX real detrás
   de `UnwrapperTypes.FlynMd`, usado en varios tests FPA — ver `tests/setupPath.m`)
   vive fuera de `mex/bin/` porque su propia migración a `mex/src/` sigue pendiente
   (ítem sin marcar de Fase 2). El patrón genérico `*.mex*` del borrador lo habría
   excluido sin una excepción explícita — añadida
   `!om4mtools-matlab/IOT2DPU/deploy/*.mexw64`.
3. Dos ficheros/carpetas específicos de esta máquina que el borrador no contemplaba
   (no existían cuando se escribió): `.claude/settings.local.json` (permisos locales
   de Claude Code) y `src/.ignore/` (caché de ExportFig con rutas locales a
   ghostscript/pdftops — el propio nombre de la carpeta, `.ignore`, es la pista de
   ExportFig de que no debe ir al repo).

**Verificado antes del primer commit:** `git status`/`git add -A` + revisión manual
de qué quedaba excluido (`git check-ignore -v`) para confirmar que los 2 ajustes de
máquina funcionaban y que el `.mexw64` legacy SÍ se incluía — 383 ficheros
comprometidos (386 originales + `.gitignore` − 4 excluidos).

**Qué no se ha hecho todavía (a propósito, sin pedirlo el usuario):** crear el repo
remoto en GitHub, `git push`, ni el primer tag `v1.0.0` — quedan como los 3 últimos
ítems sin marcar de FASE 6, pendientes de que el usuario lo pida explícitamente.

---

## FASE 2 — Migración de `IOT2DPU` a `mex/src/`/`mex/bin/` (2026-09-14)

Último ítem pendiente de Fase 2 (ver CLAUDE.md). Petición del usuario: "vamos a por
los ficheros mex".

**Todo el árbol movido como un solo bloque, sin tocar rutas internas:** los 5
`.vcxproj` (`flynmd`, `fmg`, `goldbc`, `PUFlynMdMex`, `PUMexLib`) referencian su
código fuente con la ruta relativa fija `..\src\*.c` (verificado con `grep` sobre los
5 ficheros antes de mover nada). Aplanar `IOT2DPU/src/` directamente dentro de
`mex/src/` habría roto esas ~40 referencias y habría exigido editar XML de proyecto
VS a mano sin poder compilar aquí para verificarlo. Se optó por mover el árbol entero
tal cual (`IOT2DPU.sln`, los 5 subdirectorios de proyecto, y `src/`) a `mex/src/`,
quedando `mex/src/src/*.c` — nesting con nombre repetido pero exacto al que esperan
los `.vcxproj`, riesgo de build cero. Revisitar solo si se abre el `.sln` en Visual
Studio y se decide aplanar a mano con el IDE haciendo el rename de referencias.

**`IOT2DPU/tests/` → `mex/src/tests/`, no a `tests/`:** esa carpeta no es la suite
`matlab.unittest` del repo — es material de prueba del propio proyecto C/VS: datos
`.aq`/`.phase`/`.mask`/`.surf`/`.corr`, `.bat` que invocan los `.exe` compilados
directamente, y un puñado de `.m` (`GeneratePeaks.m`, `leer_ficheros.m`,
`testSetPaths.m`, `test_MexFilesFromIOT2DPU.m`, `test_PUMexLib.m`) que no heredan de
`matlab.unittest.TestCase`. Meterlo en `tests/` habría violado la convención de
"plano, un TestXxx.m por función" y habría colado datos binarios fuera de
`fixturesRoot()`. Se movió sin cambios a `mex/src/tests/`, junto al proyecto VS al
que pertenece. Migrar los `.m` sueltos al framework real, si compensa, queda como
tarea aparte (no pedida).

**Binarios → `mex/bin/`:** `PUFlynMdMex.mexw64` (el MEX real), `PUMexLib.dll`
(dependencia en tiempo de ejecución del anterior) y `PUMexLib.h` (cabecera que
viajaba junto a los binarios en el `deploy/` legacy, se mantiene junto a ellos por
si algún consumidor externo linka contra la DLL). Quedan cubiertos por la excepción
genérica ya existente en `.gitignore` (`!mex/bin/**/*.mexw64`) — se pudo borrar la
excepción específica `!om4mtools-matlab/IOT2DPU/deploy/*.mexw64` que ya no aplica.

**Referencias actualizadas:** `tests/setupPath.m` (ahora añade `mex/bin/` en vez de
`om4mtools-matlab/IOT2DPU/deploy/`), `tests/testStandardHW_MockCam.m` (comentario),
`CLAUDE.md` (estado de fase + descripción de `setupPath.m`), `TODO.md` (ítem
marcado). `audit_filelist.txt` NO se tocó — es un snapshot histórico del inventario
original, no una referencia viva.

**Pendiente, fuera de alcance de este cambio:** `mex/build.m` (invocar MSBuild sobre
el `.sln`) y compilar para otras plataformas — siguientes ítems sin marcar de Fase 2/3
en TODO.md.
