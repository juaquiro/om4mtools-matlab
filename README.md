# om4mtools-matlab

Modernizacion y actualizacion de
[`om4mmatlabutils`](https://github.com/juaquiro/om4mmatlabutils).

Toolbox de utilidades MATLAB del grupo OM4M (Optical Methods for Measuring).
Proyecto estrictamente personal por ahora (ver `CLAUDE.md`).

## Estructura

- `src/` -- codigo fuente, plano salvo los packages `+OM4MClassLib` y `+Zernikes`
- `tests/` -- un `TestXxx.m` por funcion, framework `matlab.unittest.TestCase`
- `mex/` -- codigo C/C++ (`mex/src/`) y binarios precompilados (`mex/bin/`)
- `dll/` -- dependencias `loadlibrary()` (no MEX), codigo en `dll/src/<Nombre>/`
  y binarios precompilados en `dll/bin/`

Ver `TODO.md` para el estado detallado del proyecto y `DECISIONS.md` para
el porque de las decisiones de diseno.

## MEX

`mex/src/` contiene el proyecto Visual Studio (`IOT2DPU.sln` + 5
`.vcxproj`) detras de `UnwrapperTypes.FlynMd`; `mex/bin/` tiene los
binarios ya compilados (`PUFlynMdMex.mexw64`, `PUMexLib.dll`) -- **SI**
van al repo, no hace falta compilador C++ para consumir el toolbox.

Para recompilar (Windows, con Visual Studio o Build Tools instalado):

```matlab
run('mex/build.m')
```

Localiza `MSBuild.exe` via `vswhere.exe`, compila `Release|x64`
(solo `PUFlynMdMex`/`PUMexLib`, los dos proyectos que consume MATLAB)
y copia el resultado a `mex/bin/`, sobrescribiendo los binarios
existentes.

> **Toolset (actualizado 2026-09-14):** los `.vcxproj` apuntaban
> originalmente a PlatformToolset `v120` (Visual Studio 2013).
> Reapuntados (`retarget`) a `v143` (Visual Studio 2022) -- ver tag
> `mex_dll_working` (estado verificado con el `v120` original, punto de
> rollback) y DECISIONS.md para el detalle completo, incluida la
> verificación con `run(testFPAUnwrapper)` (5/5) tras el cambio.

## DLL

`dll/src/<Nombre>/` contiene el codigo C/C++ de dependencias que se
consumen via `loadlibrary()` en vez de como MEX -- un subdirectorio por
DLL, con su propio `.vcxproj` (sin `.sln` propio salvo que haga falta).
Por ahora solo existe `dll/src/CProjector/`, detras de
`DisplayProjectorC`. `dll/bin/` tiene el `.dll` ya compilado mas los
`.h` que `loadlibrary()` necesita en tiempo de ejecucion (`CProjector.h`
y `shrhelp.h`, que este incluye) -- **SI** van al repo, mismo criterio
que `mex/bin/`.

Para recompilar (Windows, con Visual Studio o Build Tools instalado):

```matlab
run('dll/build.m')
```

Localiza `MSBuild.exe` via `vswhere.exe`, compila `CProjector.vcxproj`
(`Release|x64` -- no hay `.sln` propio, a diferencia de `mex/`, ver
comentario en cabecera de `dll/build.m`) y copia el `.dll` + headers
necesarios a `dll/bin/`, sobrescribiendo lo existente.

> Si MATLAB ya tiene la DLL cargada (`loadlibrary`), hay que descargarla
> primero (`unloadlibrary CProjector`) -- Windows la deja bloqueada
> mientras siga cargada, y la recompilacion falla al intentar
> sobrescribir `dll/bin/CProjector.dll`.

## Convenciones de codigo

Seguimos las [MATLAB Coding Guidelines de MathWorks](https://github.com/mathworks/MATLAB-Coding-Guidelines),
con copia local en [`MATLAB-Coding-Guidelines.pdf`](./MATLAB-Coding-Guidelines.pdf)
en la raiz del repo.

## MATLAB MCP (MATLAB Agentic Toolkit)

Este repo se trabaja con Claude Code apoyandose en el
[MATLAB Agentic Toolkit](https://github.com/matlab/matlab-agentic-toolkit),
que expone un servidor MCP (`matlab-mcp-core-server`) capaz de hablar con
una sesion MATLAB real desde la sesion de Claude Code.

### Por que conviene

- Permite a Claude ejecutar y evaluar codigo MATLAB de verdad
  (`evaluate_matlab_code`) en vez de solo leer/escribir ficheros `.m` a
  ciegas -- util para correr `tests/run_all_tests.m` y ver resultados reales
  sin salir de la sesion.
- Detecta toolboxes instaladas (`detect_matlab_toolboxes`) -- forma fiable
  de confirmar por que ciertos tests fallan en una maquina concreta (p. ej.
  los tests que dependen de Computer Vision Toolbox, ver `TODO.md`), en vez
  de asumirlo.
- Trae los skills especializados de MATLAB (`matlab-testing`,
  `matlab-debugging`, etc.) que ya aparecen listados para este proyecto.

### Instalacion

Forma mas simple: desde una sesion de Claude Code, pedir "set up the MATLAB
Agentic Toolkit" (invoca la skill `toolkit:matlab-agentic-toolkit-setup`).
El proceso es interactivo: detecta la instalacion de MATLAB local, descarga
el binario `matlab-mcp-core-server` a `~/.matlab/agentic-toolkits/bin/`, lo
registra globalmente para Claude Code y verifica la conexion antes de
terminar.

Instalacion manual (referencia rapida -- ver el repo del toolkit para el
detalle completo):

1. Descargar el binario para la plataforma (`matlab-mcp-core-server-win64.exe`
   en Windows) desde
   `https://github.com/matlab/matlab-mcp-core-server/releases/latest` a
   `~/.matlab/agentic-toolkits/bin/`.
2. Registrar el servidor con el agente (Claude Code: `claude mcp add-json`
   apuntando al binario + `--matlab-root <ruta a MATLAB>`).
3. Reiniciar la sesion del agente.

### Verificar que funciona

- Binario: `~/.matlab/agentic-toolkits/bin/matlab-mcp-core-server --version`.
- Config: `~/.matlab/agentic-toolkits/config.json` debe existir y apuntar a
  un `matlab.root` real y a un `mcpServerPath` ejecutable.
- Dentro de una sesion nueva de Claude Code: preguntar "What version of
  MATLAB is running?" -- si responde con la version real instalada (no con
  una suposicion), el MCP esta conectado. Tambien puede comprobarse pidiendo
  "detect installed MATLAB toolboxes".

## Tests

```matlab
run('tests/run_all_tests.m')        % suite completa, sin hardware
run('tests/run_hardware_tests.m')   % solo tests de hardware, a pie de mesa
```

## Branching Model

Dos ramas de larga duracion, gestionadas segun
[`Appendix_Branching_Model_Bootstrap.md`](./Appendix_Branching_Model_Bootstrap.md)
(Caso B -- MATLAB, Opcion 2: sin runner self-hosted con MATLAB):

| Rama | Rol |
|---|---|
| `develop` | Rama por defecto -- integracion diaria de features |
| `main` | Rama estable / production-ready. Protegida: sin push directo, sin force-push, sin borrado |

**Flujo:**
- Cambios pequenos y de bajo riesgo (docs, fixes triviales) -> push directo a `develop`
- Trabajo real -> rama `feature/xyz` desde `develop`, PR a `develop`
- Release -> PR `develop -> main`, bump de version en `src/Contents.m`
- Hotfix -> rama `hotfix/xyz` desde `main`, PR a `main`, luego back-merge
  `main -> develop` (merge commit real, nunca squash)

## CI/CD

MATLAB no puede ejecutarse en runners de GitHub (sin licencia/instalacion
ahi), asi que el gate automatico es parcial:

- **`smoke`** (`.github/workflows/structure-check.yml`, gate de `develop`)
  y **`full-suite`** (`.github/workflows/release.yml`, gate de `main`)
  verifican convenciones estaticas sin correr MATLAB: nada de `i`/`j` como
  variable de bucle, nada de `matlabpath(pathdef)`, `src/`/`tests/` planos,
  sin intermedios de compilacion MEX en el repo, y (solo en `main`) que
  `src/Contents.m` tenga la version bumpeada.
- La correctitud real la confirma una **review humana obligatoria**: el
  autor corre `runtests` en local antes de abrir el PR y pega el resultado
  en la plantilla (`.github/pull_request_template.md`).
- En push a `main`, `tag-and-release` crea el tag `vX.Y.Z` (leido de
  `src/Contents.m`) y una GitHub Release.

Detalle completo, incluidos los 4 escenarios de trabajo, en
[`Appendix_Branching_Model_Bootstrap.md`](./Appendix_Branching_Model_Bootstrap.md).
