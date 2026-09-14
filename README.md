# om4mtools-matlab

Toolbox de utilidades MATLAB del grupo OM4M (Optical Methods for Measuring).
Modernizacion de `om4mmatlabutils`. Proyecto estrictamente personal por
ahora (ver `CLAUDE.md`).

## Estructura

- `src/` -- codigo fuente, plano salvo los packages `+OM4MClassLib` y `+Zernikes`
- `tests/` -- un `TestXxx.m` por funcion, framework `matlab.unittest.TestCase`
- `mex/` -- codigo C/C++ (`mex/src/`) y binarios precompilados (`mex/bin/`)

Ver `TODO.md` para el estado detallado del proyecto y `DECISIONS.md` para
el porque de las decisiones de diseno.

## Consumo

Se usa como Git submodule congelado (version fija por proyecto) en
proyectos consumidores. Ver FASE 0.5 en `TODO.md`.

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
