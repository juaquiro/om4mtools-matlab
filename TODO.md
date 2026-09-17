# om4mtools-matlab — TODO

> **Objetivo original del proyecto — CUMPLIDO y liberado como v1.0.0
> (2026-09-16):** limpiar la migración desde `om4mmatlabutils`, dejarla
> ordenada en Git y volver a tener la suite de tests corriendo. Este repo es
> estrictamente personal, no hay plan de empaquetarlo/distribuirlo como
> toolbox o módulo MATLAB (ver "Descartado explícitamente" más abajo — nota:
> la infraestructura de branching/CI/versionado semántico sí se construyó
> después, ver ese apartado). **Excepciones añadidas 2026-09-16:** unificar
> la validación de parámetros con `arguments` (name-value) en todo `src/`,
> y unificar docstrings (convención estándar de MATLAB, incluida una breve
> por test) — ambas en "Pendiente" abajo. El resto de
> refactorización/modernización sigue descartado.
>
> Historial completo de todas las fases (auditoría, reorganización de
> estructura, migración de tests, creación del repo Git, CI, cierre de la
> suite) está en `DECISIONS.md` (condensado a un resumen por sección — el
> detalle completo sigue en `git log -- DECISIONS.md`) y en el historial de
> git de este mismo fichero (`git log -- TODO.md`).

## Completado (resumen)

- Estructura reorganizada: `src/` y `tests/` planos (salvo `+OM4MClassLib` y
  `+Zernikes`), `mex/src/` + `mex/bin/` y `dll/src/` + `dll/bin/` para los
  proyectos Visual Studio (`IOT2DPU`, `CProjector`).
- Migración de tests legacy (`mtest` → `matlab.unittest.TestCase`),
  `tests/setupPath.m`/`resetPath.m` como único punto de entrada de path.
- Repo Git creado, publicado en `github.com/juaquiro/om4mtools-matlab`, con
  branching model (`develop`/`main`), gate de CI estático
  (`structure-check.yml`/`release.yml`) y versionado semántico automático
  (`src/Contents.m` + tag/release en merges a `main`).
- Suite de tests cerrada (2026-09-16): de 9 failed + ~29 incomplete
  originales a **0 failed, 1 incomplete documentado** (ambigüedad de
  formato JSON en `testJsonlabRoundTrip/example4.json`, no un bug).
  Detalle completo de cada fix en DECISIONS.md.
- Decisión de no recuperar `Passive3DCam.m`/`Passive3DCamData.m`
  (`+OM4MClassLib/+HW/`) — se quedan fuera para siempre (2026-09-15).
- **Release v1.0.0 (2026-09-16):** PR #1 `develop → main` mergeado, tag y
  GitHub Release publicados automáticamente por `release.yml`.

## Pendiente

> Cada TODO pendiente tiene su issue de GitHub enlazado (sincronizado
> 2026-09-16) — al completar uno, márcalo `[x]` aquí y cierra el issue
> correspondiente; al añadir uno nuevo, crea también su issue.

- [ ] **Unificar validación de parámetros con `arguments` (name-value) en
  todo `src/` (añadido 2026-09-16).** [GH #2](https://github.com/juaquiro/om4mtools-matlab/issues/2) Hoy solo 5 de 139 ficheros `.m` en
  `src/` usan bloques `arguments`; el resto valida a mano (`nargin`,
  chequeos manuales de tipo/tamaño dentro del cuerpo) o no valida en
  absoluto. Ningún fichero usa `inputParser` (ya descartado previamente,
  no hace falta migrar eso). Objetivo: que toda función/método de `src/`
  con parámetros de entrada los declare en un bloque `arguments`, con
  opciones nominales (name-value) donde tenga sentido — mismo patrón que
  ya sigue código nuevo como `LensMapperMeasurement.CalculateLensPower`
  (ver `src/LensMapperMeasurement.m`).
  - **Alcance:** `src/` plano y los packages `+OM4MClassLib`/`+Zernikes`.
    No toca `tests/`, `mex/`, `dll/`.
  - **No-objetivos explícitos:** no cambiar lógica/comportamiento, solo
    añadir/normalizar la validación de entrada. No renombrar parámetros
    posicionales existentes salvo que haga falta para exponerlos como
    name-value. No es una pasada de `checkcode`/modernización general —
    eso sigue descartado (ver abajo).
  - **Red de seguridad:** cada función/fichero tocado debe seguir pasando
    su(s) test(s) correspondiente(s) (`run('tests/run_all_tests.m')`)
    antes de darlo por hecho — el bloque `arguments` no debe cambiar qué
    llamadas son válidas salvo que esa sea la corrección buscada.
  - **Cómo abordarlo:** incremental, fichero a fichero o por lotes
    pequeños, no una PR única de 139 ficheros — más fácil de revisar y de
    aislar si algo rompe un test.

- [ ] **Unificar docstrings en todo el código, incluida una breve en cada
  test (añadido 2026-09-16).** [GH #3](https://github.com/juaquiro/om4mtools-matlab/issues/3) Reactiva la "Fase 5 (docstrings)" que ya
  mencionaba `src/Contents.m` como pendiente. La mayoría de ficheros de
  `src/` ya tiene *algún* comentario tras la firma de función/`classdef`
  (solo 6/139 no tienen ninguno), pero el formato es inconsistente —
  mayúsculas sueltas, frases sin H1 line, texto en español/inglés mezclado,
  etc. — así que el problema es de formato, no de ausencia total.
  Objetivo: que toda función/método de `src/` y todo fichero de test en
  `tests/` tenga un docstring breve siguiendo la convención de
  `MATLAB-Coding-Guidelines.pdf` (raíz del repo, sección "Code Comments
  Guidelines" → "H1 and help content and placement", verificada
  2026-09-16 con `pdftotext`, no está protegido con contraseña):
  - **Línea H1** inmediatamente después de la declaración de la función
    y **antes** del bloque `arguments` — una frase breve de qué hace la
    función, con el propio nombre de la función (no en mayúsculas, ver
    el ejemplo del PDF: `function b = rowWiseLast(A)` / `% rowWiseLast
    finds the last non-zero element in each row`).
  - Tras el H1, *help text* con `% Syntax:`, `% Inputs:`, `% Outputs:` y
    cualquier efecto secundario relevante.
  - Comentarios en inglés (regla del PDF, "Language"); al menos un
    espacio tras el `%`; mismo nivel de indentación que la declaración
    de la función.
  - **Alcance:** `src/` plano, `+OM4MClassLib`/`+Zernikes`, y **todo
    `tests/`** — para los tests, docstring *breve* (qué verifica el test,
    una frase, sin Syntax/Inputs/Outputs completos salvo que el test
    tenga parámetros no obvios). No toca `mex/`, `dll/`.
  - **No-objetivos explícitos:** no cambiar lógica/comportamiento — es un
    cambio de comentarios únicamente. No es la pasada de modernización
    general de `checkcode` (sigue descartada). No hace falta prosa
    extensa ni ejemplos por función — "breve" es el criterio, sobre todo
    en `tests/`.
  - **Efecto colateral esperado:** una vez esto avance, regenerar
    `src/Contents.m` con el listado de funciones por categoría vía `help
    om4mtools`, tal como ya anotaba su propio comentario.
  - **Cómo abordarlo:** incremental, igual que el TODO de `arguments`
    arriba — por lotes pequeños, verificando que `run('tests/run_all_tests.m')`
    sigue en verde tras cada lote (por si un docstring mal formado rompe
    el parseo de algún `.m`).

## Descartado explícitamente

A petición del usuario, se descarta cualquier objetivo relacionado con:

- **(2026-09-16) Auditar huecos silenciosos frente a `om4mmatlabutils`**
  (`C:\user\AQ_SCC\GitHub\om4mmatlabutils`, repo original más completo que la
  copia de Dropbox usada en la migración) más allá de `Passive3DCam`/
  `Passive3DCamData` (ya resuelto: no se recuperan). Decidido no perseguir
  esta auditoría — no se ha revisado si hay más huecos.
- **(2026-09-16) Auditar fixtures de test faltantes** (datos/assets, no
  código) que `om4mmatlabutils` pudiera tener y que no llegaron a migrarse a
  `fixturesRoot()`. Decidido no perseguir esta auditoría — no se ha
  revisado si faltan fixtures.
- **(2026-09-15) Refactorización de código**, incluida la exploración de `dynamicprops`
  para `Demodulator`/`Classifier`/`Unwrapper`/`aFeature`/`imaqCam` — la lista
  dinámica de propiedades actual (`PropsEnumList`) se queda tal cual está.
- **(2026-09-15) Modernización de código** en general (`checkcode` sobre
  todo `src/`, eliminar `i`/`j` donde queden, etc.). *(Excepción añadida
  2026-09-16: unificar bloques `arguments` en todo `src/` sí está en
  alcance — ver "Pendiente" arriba. El resto de modernización general
  sigue descartado.)*
- **(2026-09-15) Documentación uniforme** en el sentido de un formato de
  docstring *propio* inventado para OM4M. *(Excepción añadida 2026-09-16:
  unificar docstrings siguiendo la convención estándar de MATLAB — no una
  inventada — sí está en alcance, incluida `tests/`, ver "Pendiente"
  arriba.)*
- **(2026-09-15) Empaquetado/distribución como toolbox o módulo MATLAB** en
  el sentido de transferencia a una organización GitHub del grupo
  (`om4mlab`) o modelo de consumo como Git submodule congelado con
  `setup.m` propio. *(Nota 2026-09-16: el branching model, la CI y el
  versionado semántico — `src/Contents.m` + tags `vX.Y.Z` — sí se
  construyeron y ya produjeron la release v1.0.0; lo descartado es la
  distribución fuera de este repo, no el versionado en sí. Ver
  `Appendix_Branching_Model_Bootstrap.md`.)*
- **(2026-09-15) Compilar MEX para otras plataformas** (`glnxa64`/`maci64`)
  o migrar el build de MSBuild a CMake.
- **(2026-09-15) Migración a Python** (`om4mtools-python`).

Si alguno de estos puntos vuelve a hacer falta en el futuro, el detalle
completo de cada uno (motivación, estado, decisiones ya tomadas) sigue
disponible en el historial de git de este fichero.
