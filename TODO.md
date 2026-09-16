# om4mtools-matlab — TODO

> **Objetivo del proyecto — CUMPLIDO y liberado como v1.0.0 (2026-09-16):**
> limpiar la migración desde `om4mmatlabutils`, dejarla ordenada en Git y
> volver a tener la suite de tests corriendo. Nada más. Este repo es
> estrictamente personal, no va a evolucionar mucho más allá de esto — no hay
> plan de empaquetarlo/distribuirlo como toolbox o módulo MATLAB, ni de
> refactorizar el código existente (ver "Descartado explícitamente" más
> abajo — nota: la infraestructura de branching/CI/versionado semántico sí
> se construyó después, ver ese apartado).
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

Nada pendiente por ahora — ver "Descartado explícitamente" abajo para lo que
se decidió no perseguir.

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
- **(2026-09-15) Modernización de código** más allá de lo ya hecho (bloques
  `arguments` generalizados, `checkcode` sobre todo `src/`, eliminar `i`/`j`
  donde queden, etc.).
- **(2026-09-15) Documentación uniforme**: formato de docstring estándar
  OM4M en todo `src/`, `Contents.m`, `help om4mtools`.
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
