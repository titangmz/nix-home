---
name: add-module
description: Add or integrate a Nix configuration module in this nix-home repository, choosing profile imports, documenting behavior, and checking the resulting configurations. Use when introducing a module or assigning existing functionality to profiles.
---

Read `AGENTS.md` and `docs/rules.md` from the repository root before changing configuration. Read the affected module's README and a nearby module with the same kind of configuration. Treat those files as the source of repository conventions.

## Choose ownership and profiles

Determine which profiles and supported systems need the behavior. Inspect `profiles/default.nix`, the relevant profile import trees, and `tests/checks.nix` rather than assuming every module works on every platform.

Prefer the lowest shared layer whose consumers all need the module. The usual layering is the shared terminal core in `base.nix`, workstation additions in `workstation.nix`, and profile-specific behavior in the leaf profile.

Preserve the server subset by default, but allow intentional differences when the user's requested behavior needs them. For example, a headless service needed only on servers belongs in the server profile; installing it on every workstation just to maintain a subset would be incorrect. Use existing task context to resolve these choices. Ask only when the intended target profiles remain materially ambiguous.

For an exception, document why the profiles differ in the module's README. Keep shared functionality in shared layers; split common configuration from specialized additions when that makes ownership clearer.

Distinguish Home Manager configuration from NixOS system configuration before choosing a location. Follow the existing `modules/nixos/desktop` and `modules/nixos/system` boundary, and keep machine identity and hardware outside reusable modules.

## Integrate the module

Create or extend `modules/<name>/default.nix` and import it through the chosen layer or profile. Follow existing module patterns and avoid adding a second import site when a common ancestor already supplies the module.

Check package and option availability on the target systems. Gate platform-specific settings and packages where necessary so evaluation remains valid for the other supported systems. Keep package installation separate from configuration when the requested setup manages settings for an externally installed application.

Use `modules/theme` for visual values and `profiles/user.nix` for identity. For installed commands, use the discovery mechanism in `modules/scripts` and its documentation and test conventions rather than creating another installation list.

Write the module's README with its purpose, target profiles, configuration behavior, and relevant controls or activation steps. Keep module details there; update architecture documentation only when the integration changes the architecture.

## Verify the result

Routine package additions need evaluation and build validation, not package presence/absence assertions. Do not grow inventories of installed or excluded packages, or add literal setting, color, or source-string checks that merely repeat configuration.

Add focused tests for executable behavior, interactions, or meaningful regressions when needed. Use the existing script or editor test harness where appropriate; keep checks about outcomes rather than implementation details.

Run `nix fmt` and `just check`. Use `path:` flake URLs for targeted evaluation or builds so new and uncommitted module files are included. Distinguish cross-system evaluation from checks actually built on the current machine when reporting validation.

Report the module's placement, affected profiles, intentional exceptions, and validation results. Applying the configuration or committing changes is a separate action unless the user requested it.
