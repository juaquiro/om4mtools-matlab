# om4mtools-matlab — Plan de Modernización

> Proyecto: modernización de `om4mmatlabutils` → `om4mtools-matlab`  
> Grupo: Optical Methods for Measuring (OM4M)  
> Estado inicial: directorio de trabajo en Dropbox, sin Git todavía  
> Fecha de inicio: 2026-05

---

## FASE 0 — Setup del entorno de trabajo

- [ ] Copiar proyecto legacy a `Dropbox/om4mtools-matlab/`
- [x] Instalar **Claude Code** (terminal o VS Code extension)
- [x] Instalar **MATLAB Agentic Toolkit** — instala y configura todo de una vez:
  ```bash
  git clone https://github.com/matlab/matlab-agentic-toolkit.git
  # Lanzar Claude Code desde ese directorio y pedir setup automático
  # El toolkit detecta MATLAB, instala MCP Core Server, registra skills
  ```
- [x] Verificar skills instalados relevantes para el proyecto:
  - `matlab-software-development:matlab-modernize-code` ← Fase 4
  - `matlab-core:matlab-testing`                        ← Fase 3 (crea y ejecuta tests)
  - `matlab-core:matlab-review-code`                    ← Fases 4 y 5
- [ ] Leer `https://github.com/mathworks/toolboxdesign` antes de arrancar Fase 2
- [ ] Revisar prompts útiles en `https://github.com/matlab/prompts/tree/main/prompts/programming`
- [x] Crear `DECISIONS.md` vacío en la raíz
- [x] Crear borrador de `CLAUDE.md` (ver plantilla al final de este fichero)

---

## FASE 0.5 — Modelo de consumo como submodule

> Decisión de diseño que afecta a la estructura del repo y al setup.m

`om4mtools-matlab` se consume desde otros proyectos como **Git submodule
congelado** en un commit/tag concreto.

### Estructura en el proyecto consumidor

```
mi-proyecto/
├── lib/
│   └── om4mtools-matlab/   ← submodule @ v1.0.0
├── src/
└── setup.m                 ← llama a lib/om4mtools-matlab/setup.m
```

### Comandos para el consumidor

```bash
# Añadir om4mtools a un proyecto nuevo
git submodule add https://github.com/tuusuario/om4mtools-matlab lib/om4mtools-matlab

# Clonar un proyecto que ya lo usa
git clone --recurse-submodules mi-proyecto

# Actualizar deliberadamente a una versión nueva
cd lib/om4mtools-matlab
git checkout v1.2.0
cd ../..
git add lib/om4mtools-matlab
git commit -m "bump om4mtools to v1.2.0"
```

### Política de MEX en el repo

Los binarios precompilados **sí van al repo** — son 1-2 ficheros sin
dependencias externas. Esto elimina la necesidad de compilador C++ en
el proyecto consumidor.

```
mex/
├── src/         ← C/C++ + .sln + .vcxproj (siempre al repo)
├── bin/
│   ├── win64/   ← .mexw64 (SÍ al repo)
│   └── linux64/ ← .mexa64 (SÍ al repo)
└── build.m      ← para recompilar si fuera necesario
```

`.gitignore` del MEX:

```gitignore
# Intermedios de compilación (NO al repo)
mex/bin/**/Debug/
mex/bin/**/Release/
mex/bin/**/*.obj
mex/bin/**/*.pdb

# Binarios precompilados (SÍ al repo — excepciones explícitas)
!mex/bin/**/*.mexw64
!mex/bin/**/*.mexa64
!mex/bin/**/*.mexmaci64
```

### Requisitos para setup.m

Paths siempre relativos a su propia ubicación, nunca asunciones sobre
el proyecto padre:

```matlab
rootDir = fileparts(mfilename('fullpath'));
addpath(fullfile(rootDir, 'src'));
addpath(fullfile(rootDir, 'mex', 'bin', computer('arch')));
```

### Tags de versión semánticos

Crear tags `v1.0.0`, `v1.1.0`... para que los consumidores referencien
versiones con nombre en lugar de hashes de commit.

- [ ] Documentar modelo de consumo en `README.md`
- [ ] Verificar que `setup.m` funciona correctamente como submodule
- [ ] Crear primer tag semántico tras Fase 6

---

## FASE 1 — Auditoría e inventario

- [x] Ejecutar script de auditoría de ficheros → `audit_filelist.txt` (2422 ficheros)
- [x] Generar inventario de **datos y assets** (candidatos a Dropbox):
  - 159.1 MB; .mat (57), .jpg (66), .bmp (25), .tif (16), .png (15), + ficheros ópticos
  - Ver detalle en `DECISIONS.md`
- [x] Generar inventario de **código fuente** `.m`:
  - 373 ficheros OM4M (162 classdef, 161 function, 50 script); 155 tests, 218 src
  - Ver detalle en `DECISIONS.md`
- [x] Verificar que no hay colisiones de nombres al aplanar los 4 subdirectorios
  - Las 200+ colisiones son de terceros (chebfun). Solo 4 reales en OM4M: CamL, CamR, DMK33UX183Bin3, GVPCCam
  - Ver análisis completo en `DECISIONS.md`
- [x] Localizar ficheros del proyecto Visual Studio (MEX):
  - `IOT2DPU/IOT2DPU.sln` + 5 .vcxproj; binario: `PUFlynMdMex.mexw64`
  - Ver detalle en `DECISIONS.md`
- [x] Guardar resultados en `DECISIONS.md`

---

## FASE 2 — Reorganización de la estructura

> **Nota (2026-09-14):** el diagrama de abajo es el plan original de Fase 2 y ya no
> refleja el estado actual — `download_fixtures.sh` se eliminó y `tests/fixtures/` se
> mantiene vacío a propósito. Ver el ítem "Mover datos/assets a fixtures" más abajo y
> DECISIONS.md, sección "FASE 2 (reversión)".

Estructura objetivo (histórico, ver nota arriba):

```
om4mtools-matlab/
├── CLAUDE.md
├── DECISIONS.md
├── README.md
├── TODO.md
├── setup.m                  ← paths relativos, funciona como submodule
├── download_fixtures.sh     ← bash, descarga en tests/fixtures/ desde Dropbox
├── .gitignore
│
├── src/                     ← todo plano, sin subdirectorios ni namespaces
│   ├── funcA.m
│   └── funcB.m
│
├── tests/                   ← todo plano, un TestXxx.m por función
│   ├── fixtures/
│   │   └── .gitkeep
│   ├── TestFuncA.m
│   └── run_all_tests.m
│
├── mex/
│   ├── src/                 ← C/C++ + .sln + .vcxproj
│   ├── bin/
│   │   ├── win64/           ← .mexw64 (en repo)
│   │   └── linux64/         ← .mexa64 (en repo)
│   └── build.m              ← llama a MSBuild sobre el .sln (Opción A)
│
└── docs/
```

- [x] Crear estructura de directorios objetivo (`src/`, `tests/`, `tests/fixtures/`) — creada en `75 om4mtools-matlab/` el 2026-09-12
- [x] Aplanar los 4 subdirectorios → `src/` plano — completo (2026-09-12): `ClassLib/FPA` (40), `ClassLib/StandardHW` (20), `UtilLib/FPA` (9 fuente), `UtilLib/DeployPaths`, `UtilLib/CamCalToolboxWrappers`, `UtilLib/FullScreen`, `GUILib/TwoCamCaptureGUI`, `ClassLib/+OM4MClassLib` y `UtilLib/+Zernikes` (mantenidos como package `+` dentro de `src/` — decisión explícita del usuario, excepción a "sin namespaces")
- [x] Migrar tests a `tests/` plano — completo (2026-09-12): `ClassLib/TestFPA` (34/35, `Untitled.m` excluido), `ClassLib/TestStandardHW` (8 tests + 15 scripts de config), `UtilLib/FPA` (5 scripts de demo), `ClassLib/TestOM4MClassLib` (13 tests, solo 1 con framework vivo — ver DECISIONS.md), `UtilLib/TestZernike` (4 tests — 1 de ellos revela dependencias ya borradas `Poly2`/`ClassLib/ML`, pendiente decisión del usuario)
- [x] Mover proyecto Visual Studio → `mex/src/` — completo (2026-09-14): `IOT2DPU.sln` +
  los 5 `.vcxproj` (`flynmd`, `fmg`, `goldbc`, `PUFlynMdMex`, `PUMexLib`) + `src/` (los
  `.c`/`.h`) movidos tal cual como un solo bloque a `mex/src/`, preservando la estructura
  interna (cada `.vcxproj` referencia `..\src\*.c` con ruta relativa — mover el árbol
  entero evita tener que tocar esas referencias). El harness de test en C legado
  (`IOT2DPU/tests/`: datos `.aq`/`.phase`/etc., `.bat`, y unos pocos `.m` que no siguen
  el framework `matlab.unittest`) se movió a `mex/src/tests/` sin cambios — no es la
  suite `tests/` del repo, es material de prueba del propio proyecto VS. Binarios
  (`PUFlynMdMex.mexw64`, `PUMexLib.dll`, `PUMexLib.h`) movidos a `mex/bin/`.
  `tests/setupPath.m` actualizado para apuntar a `mex/bin/` (antes
  `om4mtools-matlab/IOT2DPU/deploy/`). Ver DECISIONS.md.
- [x] Crear `mex/build.m` invocando MSBuild sobre el `.sln` — completo (2026-09-14):
  localiza `MSBuild.exe` vía `vswhere.exe`, compila `Release|x64` (solo
  `PUFlynMdMex`/`PUMexLib`), copia de `mex/src/deploy/` (destino del post-build event
  de cada `.vcxproj`, creado por el script si no existe) a `mex/bin/`. `.gitignore`
  ampliado para los intermedios que MSBuild deja dentro de `mex/src/` (antes solo
  cubría `mex/bin/`). Pasa `MATLAB=matlabroot()` explícito a MSBuild (los `.vcxproj`
  referencian `$(MATLAB)extern\include` sin definirlo, dependían de una variable de
  entorno ambiental que no está garantizada). Verificado de extremo a extremo tras
  retargetar el toolset (ítem siguiente) — ver DECISIONS.md.
- [x] Mover datos/assets a fixtures — **decisión revertida 2026-09-14** (ver DECISIONS.md
  y `tests/fixtures/README.md`): al ser proyecto estrictamente personal, los datos
  (~11 GB) se sacaron de `tests/fixtures/` (que ahora se mantiene vacío a propósito) y
  se dejaron vivir solo en `<dropbox root>\AQ_EXP\DataSetsForTesting\om4mtools-matlab`,
  resueltos vía `fixturesRoot()` (envuelve `src/dropbox.m`). `download_fixtures.sh`
  eliminado por obsoleto. Ficheros no-.m que el propio `src/` necesita para funcionar
  (no solo los tests) siguen en `src/`, no en fixtures.
- [x] Adaptar `download_fixtures.sh` para descargar en `tests/fixtures/` — creado 2026-09-12 a partir de `download_dropbox_directory.sh` (renombrado y destino cambiado a `tests/fixtures/`, sustituido). Apunta al link de Dropbox ya existente en el script; el usuario indicó que la fuente es `DataSetsForTesting\om4mtools-matlab` (confirmado por espejo exacto de contenido con `tests/fixtures/`, pero no se pudo verificar automáticamente que el link concreto resuelva a esa carpeta — página de Dropbox es una SPA JS, no inspeccionable por fetch estático)
- [x] Retargetar `PlatformToolset` de `v120` (VS2013, no instalado) a `v143` (VS2022)
  en los 5 `.vcxproj` — completo (2026-09-14). Verificado con
  `run(testFPAUnwrapper)`: 5/5 Passed tanto con el binario `v120` original (tag
  `mex_dll_working`, punto de rollback) como con el `v143` recompilado — ver
  DECISIONS.md para el detalle y la salvedad sobre qué prueba realmente esa
  verificación (no hay harness numérico dedicado para el path FlynMd).
- [ ] Compilar MEX para otras plataformas (`mex/bin/`, ej. `glnxa64`/`maci64`) —
  requiere migrar de MSBuild a CMake (ver decisión de diseño arriba), no lo cubre el
  retarget de toolset de este ítem
- [x] Verificar que nada en `src/` tiene rutas hardcodeadas a datos movidos — corregido para FPA (ver DECISIONS.md, 2026-09-12): 6 tests usaban `baseDir='.\Subcarpeta'` (solo resuelve contra cwd) en vez de rutas vía `fixturesRoot()`
- [x] **Segunda ronda de rutas hardcodeadas: `dropbox()` en vez de `fixturesRoot()`
  (2026-09-13/14) — CERRADO AL 100%** — ~30 sitios en 7 ficheros de test FPA cargaban
  datos directamente del Dropbox personal del usuario (`AQ_SYNC\...`,
  `perseusmedidas\...`, etc.) en vez de `tests/fixtures/`. Localizados los datos reales
  en `AQ_EXP` (fuera de `DataSetsForTesting`), copiados los 14/14 datasets de la lista a
  `DataSetsForTesting\om4mtools-matlab\` (~10 GB en total, incluido
  `CalibracionIOTMapper_15JUN23\` — 6.6 GB reales, acotado del proyecto `49
  INFORME-AVI014` de 6.9GB/3101 ficheros a solo el subdirectorio + xlsx que
  `test_SetParamsForCalculateLensPower` usa de verdad), y actualizados **todos** los
  tests afectados a `fixturesRoot()` — `grep` sobre `tests/*.m` confirma cero
  referencias a `dropbox()` restantes. 2 tests (`testDemodRetarRealImages*` en
  `testFPADemodulatorFTTempAnalysis.m`, `testFFTRetarExposure`/
  `testGetFFTRetarExposure4AllCells` en `testTempAnalysisRetarExposure.m`) se
  eliminaron por depender de datos no localizables en ningún sitio de Dropbox
  (`LoadStepping`/`Celda28` — confirmado por comentario propio del código que vivían en
  una NAS, nunca en Dropbox). Ver DECISIONS.md y memoria `hardcoded_refs_group_1`/`_2`
  para el detalle completo.
- [x] **Grupo 2 (`testTFM_VdH.m`, máquina de "Victor"/TFM) — CERRADO (2026-09-14):**
  localizados los datos reales en la carpeta de Dropbox del TFM de Víctor del Hierro
  (`AQ_SYNC\...\VictorDelHierroGarciaTFM+PE-2020-2021\...\Respuesta lineal`, ajena a
  `DataSetsForTesting`, encontrada buscando el `figurasLin.m`/`datos` que el propio
  test menciona). Copiados a
  `DataSetsForTesting\om4mtools-matlab\Datos_LinearzationGV_TFM_20-21-VdHG\`:
  `ImgGV_5_bad1.mat`, `TrasmDeflConfigDGV2.json`, `TrasmDeflConfigDGV15.json`,
  `datatestFFTlinGV.json`. `figurasLin.m` (helper de plots, hallado en la misma
  carpeta) migrado a `src/`. Los 9 tests de `testTFM_VdH.m` se integraron en
  `testFPA_UtilFunFPAClassVer.m` (3 sin hardware y totalmente funcionales:
  `testLimitsGV4LinearResponse`, `testArgumentsLinLUTGV`,
  `testFigLimitsGV4LinearResponse`; 4 con cámara real movidos a
  `methods (Test, TestTags = {'Hardware'})`: `testImages`,
  `testCalculateResponseFromImages`, `testFFTLinGV`, `testCalculatePowerWithCorrection`;
  2 marcados `assumeFail` por dependencias irrecuperables:
  `testFigFFTLinGV` — falta la clase `figDemodulator`, no localizada en ningún sitio —
  y `testCalculatePowerWithCorrectionFromLMMfile` — faltan datos de lentes
  `lentesChinaB8`/`LMM5_B8_32`, con nota apuntando a `67 INFORME-OM4M006 Medida DPM
  oblicuidad` como posible fuente alternativa para revisar más adelante).
  `tests/testTFM_VdH.m` eliminado. Ver DECISIONS.md, "Grupo 2 hardcoded refs — CERRADO",
  para el detalle completo.
- [x] ~~Renombrar las variables `DropboxDir`/`dropboxFolder`/`dbDir`/`dropboxDir` (ya
  apuntan a `fixturesRoot()`, no a Dropbox) a un nombre que no induzca a error~~ —
  **obsoleto 2026-09-14:** con la reversión de la decisión de fixtures (ver arriba),
  `fixturesRoot()` vuelve a apuntar a Dropbox, así que esos nombres de variable ya
  vuelven a ser correctos otra vez. No hace falta tocarlos.
- [x] Repetir el aplanado/migración para el resto de `ClassLib/` y `UtilLib/` — completo 2026-09-12, `ClassLib/` legacy eliminado por completo
- [x] `UtilLib/ExportFig` (tercero) → recuperado al alcance a petición del usuario (lo usa mucho para EPS de figuras, mejor que el exportador nativo) — migrado a `src/`, verificado (PNG+EPS OK en R2024b), legacy borrado
- [x] `UtilLib/jsonlab` (tercero) → recuperado al alcance a petición del usuario (lo usa para generar/leer JSON) — migrado a `src/`, verificado (loadjson/savejson OK en R2024b), legacy borrado
- [x] `jsonlab/examples/` → recuperados y transformados en tests unitarios reales (`testJsonlabRoundTrip.m`, `testJsonlabBasicTypes.m`) a petición explícita del usuario — 30 tests pasan, 4 correctamente filtrados por una limitación real de jsonlab con arrays de strings planos (ver DECISIONS.md)
- [x] Una vez verificado FPA/TestFPA en MATLAB, borrar `ClassLib/FPA` y `ClassLib/TestFPA` del legacy — hecho 2026-09-12

---

## FASE 3 — Migración de tests

- [x] **Convención de tests de hardware establecida (2026-09-13):** tests que requieren
  hardware real (cámaras, motores, fuentes) se etiquetan `methods (Test, TestTags =
  {'Hardware'})`; `run_all_tests.m` los excluye por defecto, `run_hardware_tests.m` los
  ejecuta a pie de mesa. Excepción: tests contra `MockCam` (software) NO se etiquetan —
  corren siempre. Aplicado a `testStandardHW_ImaqCam_ClassVer`.
  (`testHWVelleman`, `testHWCNCXProV2`, `testHWLightSourcePS`, `testHWSerial` y
  `testThorlabsPM100PowerMeter` ya no aplican — eliminados el 2026-09-13 junto con todo
  el subsistema de motores/fuentes de luz/potenciómetros; `test_HW_Passive3DCam` y
  `test_Facades_TwoCamCapAppInterface` se etiquetaron brevemente tras convertirlos pero
  se eliminaron el mismo día — ver más abajo. Ver DECISIONS.md).
- [x] **Inventario completo de `mtest` legacy + conversión (2026-09-13)** — ver
  DECISIONS.md, "Inventario y conversión de `mtest` legacy", para el detalle completo.
  Resumen: 19 ficheros `mtest` encontrados (ninguno descubierto por
  `matlab.unittest.TestSuite.fromFolder`, todos "muertos" por formato).
  - **2 eliminados por cobertura 100% duplicada:** `testStandardHW_ImaqCam.m` (cubierto
    por `testStandardHW_ImaqCam_ClassVer.m`), `testFPA_UtilFunMapperMeasure.m` (cubierto
    por `testFPA_UtilFunMapperMeasureClassVer.m`).
  - **1 consolidado (cobertura parcial):** `testFPA_UtilFunFPA.m` (48 tests) — solo 3
    (`test_GradientConsistency`, `test_GradientConsistencyWithWrappedDifs`,
    `testBin2Grey`) ya estaban cubiertos; los 40 restantes se añadieron como métodos
    nuevos a `testFPA_UtilFunFPAClassVer.m` y el fichero legacy se borró.
  - **16 reescritos como `classdef` `matlab.unittest.TestCase`** (mismo nombre de
    fichero) en un primer momento; **4 de ellos eliminados horas después el mismo día**
    (ver más abajo, "Eliminados por decisión del usuario: hueco de `Passive3DCam` no
    merece la pena mantenerlo"). Los 12 que quedan: `testQC_FeatureTest`,
    `testSVM_Toolbox`, `testNN_Toolbox`, `testML_ClassifierZernikes`,
    `test_Util_XLSUtils`, `test_Util_Validation`, `test_Util_Logging`,
    `test_Util_CSVUtils`, `test_UtilTime`, `testPropsEnumList`, `testCellEnumList`,
    `TestProcessMeasure`.
  - **Bloqueados, aún en el repo:** `testSVM_Toolbox` depende de
    `svmtrain`/`svmclassify`, eliminados de MATLAB ~R2016b (Fase 4, ya conocido); la
    mayoría de `testQC_FeatureTest` depende de helpers (`getQCDirectoriesTest` etc.) y
    un directorio `..\TestDB\` que no existen en este repo.
  - **Eliminados por decisión del usuario: hueco de `Passive3DCam` no merece la pena
    mantenerlo (2026-09-13, mismo día):** `test_HW_Passive3DCam.m`,
    `test_HW_Passive3DCamData.m`, `test_Facades_TwoCamCapAppInterface.m` y
    `test_DataStructs_MeasureList_P3DData.m` (entero, incluido su único test que sí
    pasaba, `testMeasureList_P3DDataConstructor`) se convirtieron a `classdef` y
    horas después se eliminaron a petición explícita del usuario, en vez de esperar a
    que Fase 7 recupere `Passive3DCam`/`Passive3DCamData`. De paso se eliminaron
    `tests/CamLTestOM4MClassLib.m` y `tests/CamRTestOM4MClassLib.m` (stubs de cámara
    huérfanos, solo los usaba `test_HW_Passive3DCam.m`). En un primer momento no se
    tocaron las clases fuente `src/+OM4MClassLib/+Facades/TwoCamCapAppInterface.m` ni
    `src/+OM4MClassLib/+DataStructs/MeasureList_P3DData.m` — pero **horas después,
    misma sesión, el usuario pidió eliminarlas también**, junto con
    `src/TwoCamCaptureGUI.m`+`.fig` (único llamador de `TwoCamCapAppInterface`, quedaba
    huérfano y roto sin él). `MeasureList_P3DData.m` no dependía de `Passive3DCam` en
    absoluto pero se borró igualmente por quedar sin ningún llamador ni test.
    **Tercera tanda, mismo día:** el usuario pidió eliminar también
    `src/CamL.m`/`CamR.m`/`.mat` — no dependían funcionalmente de `TwoCamCaptureGUI`
    (solo lo mencionaban en una ruta hardcodeada ya documentada como muerta) pero,
    tras eliminarse `TwoCamCaptureGUI`, se quedaron sin ningún llamador real en el repo.
    Ver DECISIONS.md.
  - **Hallazgo de paso:** `assertAlmostEqual`/`assertElementsAlmostEqual` (funciones del
    framework `xunit` legacy) no existen en ningún sitio del repo — ya se usaban sin
    convertir en `testFPA_UtilFunFPAClassVer.m` (bug preexistente, corregido de paso) y
    en el propio `testFPA_UtilFunFPA.m`. Todas sustituidas por
    `testCase.assertEqual(a, b, 'AbsTol', tol)`.
  - **`testCalculateHomographyAndTransform`** (dentro de `testFPA_UtilFunFPAClassVer.m`)
    usa `ginput()` — requiere clicks manuales, no es automatizable; se marcó con
    `testCase.assumeFail(...)` para que aparezca como filtrado, no fallado, en
    ejecuciones desatendidas.
- [x] **`tests/setupPath.m` sustituye a los 4 helpers de path por dominio (2026-09-13)**
  — ver DECISIONS.md, "`tests/setupPath.m` sustituye a los 4 helpers de path por
  dominio", para el detalle completo. Resumen: `testAAAddReferencesPath.m` y
  `testAddReferemcesML_hg.m` eran 100% redundantes con el `addpath` de
  `run_all_tests.m`; `testAAAddReferencesPathFPA.m`/`testAAAddReferencesPathStandardHW.m`
  **no lo eran del todo** — también añadían `IOT2DPU/deploy` (el MEX de
  `UnwrapperTypes.FlynMd`, usado en varios tests FPA). El usuario pidió además que
  cada test siguiera pudiendo correr en solitario (`run(testXxx)`, sin `setup.m`
  todavía). Solución: un único `tests/setupPath.m` que añade `src/`/`tests/`/
  `tests/fixtures/`/`IOT2DPU/deploy`, llamado desde el `SetUp` de los 53 tests
  afectados y desde `run_all_tests.m`/`run_hardware_tests.m`. Los 4 helpers viejos se
  borraron.
- [ ] Estandarizar estructura de todos los tests:
  ```matlab
  classdef TestNombreFuncion < matlab.unittest.TestCase
      methods (TestMethodSetup)    ... end
      methods (Test)               ... end
      methods (TestMethodTeardown) ... end
  end
  ```
- [x] **`matlabpath(pathdef)` sustituido por `matlabpath(resetPath); %#ok<RESETPATH>`
  (2026-09-13)** en los 47 ficheros de `tests/` que lo usaban — ver DECISIONS.md,
  "`pathdef` no es `resetPath`", para el detalle completo. Resumen:
  - Nuevo `tests/resetPath.m`: función con `persistent` que captura `path()` la
    primera vez que se llama en la sesión (antes de que ningún test toque el path) y
    devuelve siempre ese snapshot — a diferencia de `pathdef`, que devuelve el path de
    fábrica de MATLAB y tira cualquier cosa que el usuario tuviera cargada.
  - Los helpers `testAAAddReferencesPath.m` y `testAddReferemcesML_hg.m` ya NO resetean
    el path antes de añadir sus carpetas (ese reset-antes-de-añadir era la causa real
    del problema, no solo el `TearDown`) — `addpath` es idempotente, no hacía falta.
    (**Nota posterior, mismo día:** estos 2 helpers y los otros 2 análogos de FPA/
    StandardHW se sustituyeron por un único `tests/setupPath.m` — ver más abajo, sección
    de conversión de `mtest`, y DECISIONS.md.)
  - Los 4 tests de hardware que también reseteaban en `SetUp` (`testHWVelleman`,
    `testHWCNCXProV2`, `testHWLightSourcePS`, `testThorlabsPM100PowerMeter`) — esa línea
    se eliminó del `SetUp` por el mismo motivo. **Nota (2026-09-13, mismo día):** estos
    4 ficheros concretos ya no existen — se borraron después junto con todo el
    subsistema de motores/fuentes de luz/potenciómetros (ver más abajo en esta misma
    fase y DECISIONS.md); el fix de `resetPath` en sí sigue aplicado en todo lo demás.
  - **Hallazgo de paso:** `testThorlabsPM100PowerMeter.m` es un test de hardware (PM100
    por puerto serie) que no se etiquetó `Hardware` en el trabajo anterior porque no
    coincidía con los patrones de búsqueda usados (`*HW*`, `*Cam*`) — etiquetado ahora.
    Revisar si queda algún otro test de hardware sin etiquetar con un nombre igual de
    poco obvio.
  - **Bug de paso corregido:** `testTFM_VdH.m` tenía su método `TearDown` dentro de
    `methods(Test)` en vez de `methods(TestMethodTeardown)` — nunca se ejecutaba como
    teardown real, corría como un test suelto sin aserciones. Movido al bloque
    correcto.
- [ ] Usar skill `matlab-test-creator` para acelerar la reescritura
- [x] Crear `tests/run_all_tests.m` — creado 2026-09-12 (descubre la suite vía `matlab.unittest.TestSuite.fromFolder`, ignora los `mtest` muertos automáticamente porque no son classdef `TestCase` válidas). No se ha corrido la suite completa (429 tests, muchos necesitan hardware real o datos de Coursera excluidos a propósito — tardaría mucho y fallaría por motivos ya documentados)
- [ ] Verificar que todos los tests pasan con `matlab-test-execution`

---

## FASE 4 — Modernización del código

- [ ] Usar skill `matlab-reviewing-code` como primera pasada
- [ ] Pasar `checkcode` sobre todo `src/` y registrar warnings
- [ ] Añadir bloques `arguments` a todas las funciones que usen `nargin`/`varargin`
- [ ] Eliminar uso de `i` y `j` como variables de bucle
- [ ] Revisar y modernizar uso de estructuras → considerar clases donde tenga sentido
- [ ] Usar skill `matlab-modernizing-code` para acelerar el proceso
- [ ] Decidir versión mínima de MATLAB objetivo

---

## FASE 5 — Documentación uniforme

Formato de docstring objetivo para todas las funciones:

```matlab
function result = myFunction(a, b, opts)
% MYFUNCTION  Descripción breve en una línea.
%
% Descripción extendida del comportamiento, algoritmo
% y contexto de uso.
%
% Syntax:
%   result = myFunction(a, b)
%   result = myFunction(a, b, Name=Value)
%
% Input Arguments:
%   a       - Descripción (tipo, unidades, restricciones)
%   b       - Descripción
%
% Name-Value Arguments:
%   Option1 - Descripción (default: valor)
%
% Output Arguments:
%   result  - Descripción (tipo, unidades)
%
% Example:
%   result = myFunction(1, 2, Option1=true);
%
% See Also:
%   otraFuncion, otraFuncionRelacionada
%
% Version: 1.0.0 | Date: YYYY-MM | Author: OM4M Group
```

- [ ] Aplicar formato uniforme a todas las funciones en `src/`
- [ ] Generar `Contents.m` en `src/`
- [ ] Verificar que `help om4mtools` funciona correctamente

---

## FASE 6 — Creación del repo Git

> Hacer esto solo cuando la estructura esté estable (Fases 1-3 completadas)

- [x] Crear repo **fuera de Dropbox** — hecho 2026-09-14:
  `C:\user\AQ_SCC\GitHub\om4mtools-matlab` (no `~/repos/`, ubicación real pedida por
  el usuario junto al resto de sus repos en `AQ_SCC\GitHub\`, junto a `om4mmatlabutils`)
- [x] Copiar proyecto desde Dropbox al directorio del repo — hecho 2026-09-14,
  copia verificada idéntica con `diff -rq` (386 ficheros) antes de tocar nada más.
  La copia de Dropbox (`AQ_EXP\75 om4mtools-matlab\`) se conserva por seguridad —
  ver `README_IMPORTANTE_14SEP26.md` ahí, no es ya el sitio de trabajo activo.
- [x] Crear `.gitignore` definitivo — hecho 2026-09-14, con 3 ajustes sobre el
  borrador de abajo (obsoleto, dejado como referencia histórica):
  - Fixtures: `!tests/fixtures/README.md` en vez de `!tests/fixtures/.gitkeep`
    (ya no hay `.gitkeep`, el `README.md` de la reversión de fixtures es lo que
    hay que conservar — ver DECISIONS.md, "FASE 2 (reversión)")
  - `!om4mtools-matlab/IOT2DPU/deploy/*.mexw64` — el legacy MEX aún vive fuera de
    `mex/bin/` (pendiente su propia migración, ítem de arriba), el patrón genérico
    `*.mex*` lo habría excluido sin esta excepción explícita
  - `.claude/settings.local.json` y `src/.ignore/` (caché local de ExportFig con
    rutas a ghostscript/pdftops de esta máquina) — específicos de máquina, no al repo
  ```gitignore
  # MATLAB
  *.asv
  *.mex*
  octave-workspace

  # MEX — intermedios de compilación (NO al repo)
  mex/bin/**/Debug/
  mex/bin/**/Release/
  mex/bin/**/*.obj
  mex/bin/**/*.pdb

  # MEX — binarios precompilados (SÍ al repo — excepciones explícitas)
  !mex/bin/**/*.mexw64
  !mex/bin/**/*.mexa64
  !mex/bin/**/*.mexmaci64

  # Fixtures de test (en Dropbox)
  tests/fixtures/**/*
  !tests/fixtures/.gitkeep

  # OS
  .DS_Store
  Thumbs.db
  ```
- [x] `git init` + primer commit con estructura limpia — hecho 2026-09-14, 383
  ficheros / 62052 inserciones en el commit raíz
- [ ] Crear repo en `github.com/tuusuario/om4mtools-matlab`
- [ ] `git push`
- [ ] Crear primer tag semántico: `v1.0.0`
- [ ] Cuando exista organización del grupo → transfer a `github.com/om4mlab/om4mtools-matlab`

---

## FASE 7 — Lo que vaya surgiendo

- [ ] **Detectar ficheros/dependencias que faltan y buscarlos en
  `C:\user\AQ_SCC\GitHub\om4mmatlabutils`** (repo GitHub del `om4mmatlabutils`
  original — más completo que la copia de Dropbox con la que se ha trabajado en Fase 2:
  tiene además `CHighPerform`, `MATLABCompilerLib`, `dmbarcodereader`, sin podar).
  Ya localizados ahí (2026-09-12), pendientes de decidir si se recuperan:
  - **`Polyval2.m`** → `UtilLib/SurfProcessor/Polyval2.m`. La función que le falta a
    `testPolyval2.m` (Zernike, ver DECISIONS.md). **Ojo:** `UtilLib/SurfProcessor/`
    está marcada fuera de alcance desde Fase 1 bis — recuperar este único fichero
    reabre la misma pregunta de scope que `Poly2`/`ClassLib.ML`, no copiar sin más.
  - **`Passive3DCam.m` + `Passive3DCamData.m`** → `ClassLib/+OM4MClassLib/+HW/`. Es un
    subpaquete `+HW` que **nunca llegó a la copia de Dropbox migrada** — nuestro
    `src/+OM4MClassLib/` solo tiene `+DataStructs`/`+Facades`/`+Util`. Sus tests
    (`test_HW_Passive3DCam.m`, `test_HW_Passive3DCamData.m`,
    `test_Facades_TwoCamCapAppInterface.m`, `test_DataStructs_MeasureList_P3DData.m`) se
    convirtieron a `classdef` en Fase 3 pero se eliminaron el 2026-09-13 (decisión
    explícita del usuario, ver DECISIONS.md) en vez de dejarlos bloqueados esperando
    esta recuperación. **También se eliminaron, horas después la misma sesión, las
    clases fuente que solo servían a esos tests eliminados:**
    `src/+OM4MClassLib/+Facades/TwoCamCapAppInterface.m`,
    `src/+OM4MClassLib/+DataStructs/MeasureList_P3DData.m`, y
    `src/TwoCamCaptureGUI.m`+`.fig` (único llamador de `TwoCamCapAppInterface`, quedaba
    huérfano). Si en algún momento se recupera `Passive3DCam`/`Passive3DCamData`, tanto
    los tests como estas tres clases habría que reconstruirlos desde cero (o rescatarlos
    del historial de conversación/DECISIONS.md) — recuperar solo `Passive3DCam`/
    `Passive3DCamData` ya no basta, todo el subsistema de captura de dos cámaras se
    eliminó con ellos.
    También hay una copia en `ClassLib/StandardHW/legacy/` — esa se descarta por
    convención (código muerto, ya reemplazado).
  - Revisar si hay más huecos silenciosos además de estos dos antes de decidir cuáles
    recuperar — no asumir que son los únicos dos.
- [ ] **Detectar si los fixtures de test que faltan (datos/assets, no código) están en
  `C:\user\AQ_SCC\GitHub\om4mmatlabutils`** — mismo repo original más completo que la
  copia de Dropbox; revisar si cubre datos que `tests/fixtures/` necesita y que no
  llegaron a migrarse (p.ej. por tests rotos por dependencias ausentes como
  `Passive3DCam`/`Polyval2` de arriba, o por scope reducido en Fase 1 bis).
- [ ] Evaluar `buildtool` de MATLAB (R2022b+) para automatizar build + test
- [ ] Configurar GitHub Actions para CI (ejecutar tests en push)
- [ ] Crear organización GitHub del grupo (`om4mlab`)
- [ ] Migrar a Python (`om4mtools-python`):
  - Al iniciar el port → migrar build MEX de MSBuild a CMake
  - CMake es el build system estándar para extensiones Python (pybind11/ctypes)
  - Permitirá compilar en Linux/Mac para CI

---

## Plantilla CLAUDE.md inicial

```markdown
# om4mtools-matlab

Toolbox de utilidades MATLAB del grupo OM4M (Optical Methods for Measuring).
Modernización de om4mmatlabutils.

## Contexto
- Fase actual: [ACTUALIZAR]
- Directorio de trabajo: Dropbox/om4mtools-matlab/ (sin Git todavía)
- Fixtures de test en: Dropbox/om4mtools-matlab_data/

## Recursos de referencia
- MATLAB Agentic Toolkit:    https://github.com/matlab/matlab-agentic-toolkit
- MATLAB Coding Guidelines:  https://github.com/mathworks/MATLAB-Coding-Guidelines
- Toolbox best practices:    https://github.com/mathworks/toolboxdesign
- Prompts de referencia:     https://github.com/matlab/prompts/tree/main/prompts/programming

## Modelo de consumo
Se usa como Git submodule congelado en proyectos consumidores.
Ver FASE 0.5 en TODO.md para detalles y comandos.

## Estructura
- `src/`     — todo plano, sin subdirectorios ni namespaces
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
- Ejecutar suite completa: run('tests/run_all_tests.m')
- Fixtures en tests/fixtures/ — poblar con: bash download_fixtures.sh

## Commits
- Atómicos: un cambio lógico por commit
- No mezclar refactor con nueva funcionalidad

## Lo que NO tocar sin confirmación explícita
- [Añadir aquí según vaya surgiendo]
```

---

## Decisiones pendientes (bloquean Fase 2)

> Responder antes de arrancar la reorganización de estructura.

- [x] ~~**CamCalToolboxWrappers:** ¿mantener dependencia de CameraCalibrationToolbox externa
  o migrar a `estimateCameraParameters`?~~ **Resuelto 2026-09-12:** migrar a
  `estimateCameraParameters` (MATLAB Computer Vision Toolbox, R2014b+). Dependencia
  externa eliminada del repo (ver `DECISIONS.md` — FASE 1 bis).
- [x] ~~**+Zernikes al aplanar a `src/`:** ¿renombrar con prefijo o mantener como package
  `+` dentro de `src/`?~~ **Resuelto 2026-09-12:** mantener como package `+` (junto con
  `+OM4MClassLib`, misma decisión) — excepción explícita documentada en CLAUDE.md.
- [ ] **Versión mínima de MATLAB objetivo (Fase 4):** ¿R2022b? ¿R2023a? Afecta a:
  - `arguments` con opciones nominales → R2021a+
  - `mustBeMember`, `mustBeInteger`, etc. → R2020b+
  - `buildtool` → R2022b+

> **2026-09-12:** el usuario borró manualmente `ClassLib/ML`, `ClassLib/MSurface` y
> varias subcarpetas de `UtilLib` (Surfaces, OptimaLib, Poly2, RoiPolyIOT, SurfProcessor,
> functionDependencies, Other functions, image2clipboard) — confirmado como reducción de
> alcance intencional, no accidental. Ver `DECISIONS.md` FASE 1 bis para el detalle
> completo y las cifras actualizadas (2422 → 538 ficheros).

---

## Notas y decisiones tomadas

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
| 2026-05 | Skills principales: `matlab-modernizing-code`, `matlab-test-creator` | Directamente relevantes para Fases 3 y 4 |
