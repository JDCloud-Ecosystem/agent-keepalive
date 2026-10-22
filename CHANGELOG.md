# Changelog

## [1.1.1](https://github.com/JDCloud-Ecosystem/agent-keepalive/compare/v1.1.0...v1.1.1) (2026-10-22)


### Bug Fixes

* **menu:** put the colons back where Spanish expects them on every screen ([#24](https://github.com/JDCloud-Ecosystem/agent-keepalive/issues/24)) ([32e3e77](https://github.com/JDCloud-Ecosystem/agent-keepalive/commit/32e3e77a8bf7f1f20452ae7e37eddc97a85e7da5))


### Tests

* **update:** read the installed version in the update scenarios instead of assuming 1.0.1 ([#21](https://github.com/JDCloud-Ecosystem/agent-keepalive/issues/21)) ([ccd6ff7](https://github.com/JDCloud-Ecosystem/agent-keepalive/commit/ccd6ff73ef4e5618632826f9780a1f0e2f1c9b34))

## [1.1.0](https://github.com/JDCloud-Ecosystem/agent-keepalive/compare/v1.0.1...v1.1.0) (2026-10-22)


### Features

* **menu:** one Spanish menu with tables, single-key options and 0 to go back from every screen ([#10](https://github.com/JDCloud-Ecosystem/agent-keepalive/issues/10)) ([8ddf70c](https://github.com/JDCloud-Ecosystem/agent-keepalive/commit/8ddf70c26e6efa9f2c50452dace036f6b3edb448))
* **update:** announce new versions with their changelog and update even after a history rewrite ([#17](https://github.com/JDCloud-Ecosystem/agent-keepalive/issues/17)) ([136fd8c](https://github.com/JDCloud-Ecosystem/agent-keepalive/commit/136fd8c6ffbf0b622ca811d22a45a8d722bb2bcd))


### Code Refactoring

* **layout:** keep the scripts in lib and scripts and the person's data in ~/.config ([#19](https://github.com/JDCloud-Ecosystem/agent-keepalive/issues/19)) ([142a401](https://github.com/JDCloud-Ecosystem/agent-keepalive/commit/142a4017acc645433544c32bb7cc06cbad85ad05))


### Documentation

* **conventions:** open an issue and a pull request for every change ([#16](https://github.com/JDCloud-Ecosystem/agent-keepalive/issues/16)) ([1a35716](https://github.com/JDCloud-Ecosystem/agent-keepalive/commit/1a357168d8475b0cb10fbd9400a7fe3f2ae9acdb))

## [1.0.1](https://github.com/JDCloud-Ecosystem/agent-keepalive/compare/v1.0.0...v1.0.1) (2026-10-21)


### Bug Fixes

* **login:** ask again for the Claude account until it is a plain email ([#7](https://github.com/JDCloud-Ecosystem/agent-keepalive/issues/7)) ([f8d42bf](https://github.com/JDCloud-Ecosystem/agent-keepalive/commit/f8d42bfb21749aaa0bc238e6a8e51753fd87e8eb))


### Continuous Integration

* **release:** publish each version with Release Please ([#8](https://github.com/JDCloud-Ecosystem/agent-keepalive/issues/8)) ([9a5c168](https://github.com/JDCloud-Ecosystem/agent-keepalive/commit/9a5c168c7bf90d8bb8bd2037a71a1ee266e71a37))

## 1.0.0 (2026-10-21)

La primera versión con número, con lo que había en `main` ese día. Abre la ventana de uso de Claude Code,
Codex y OpenCode con un cron de hasta tres envíos al día, y trae el comando `keepalive` con su menú, el
estado de cada agente con su cuenta, el inicio y el cierre de sesión, el editor de horario y la prueba
completa.
