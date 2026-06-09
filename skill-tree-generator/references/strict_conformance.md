# Strict Conformance

This file is mandatory when `skill-tree-generator` is invoked. It prevents replacing the skill workflow with an easier local approximation.

## Anti-Substitution Rule

Do not replace the selected mode with a custom fast path, heading-only splitter, heuristic generator, partial validator, or "best effort" output. Helper scripts are allowed only for mechanical work after the required analysis artifacts exist.

If full conformance is too large, slow, ambiguous, or blocked, stop and report the blocker. Do not silently downgrade.

## Pre-Write Gate

Before creating or modifying tree output files, produce a checklist for the selected mode and mark every required step as pending: Mode 1 Step 1-7, Mode 2 Step A-G, or Mode 3 Step A-F along the selected branch.

## Required Evidence

Every generated or updated tree must include `GENERATION-REPORT.md`. Validation and Routing Refinement may each write or update their own report sections independently. Do not claim completion unless the report records:

- selected mode and completed step checklist
- source skill inventory and non-empty SKILL.md checks
- tree design/topology decision: Mode 1 module design, Mode 2 capability matrix plus shared/unique classification and overlap_rate, or Mode 3 branch decision and update plan
- leaf decomposition and single-leaf justifications
- reference handling decisions
- validation results for every applicable `validation_template.md` check, grouped by executor:
  - main agent source-dependent checks and any fixes/remeasurement
  - sub agent tree-only checks, with confirmation that the sub agent did not read source skills or modify files
  - revalidation results after every fix
- Routing Refinement Stage results:
  - covered routing nodes and sibling groups
  - ambiguous/high-frequency/dynamically discovered shared signals
  - regression prompt matrix with expected route paths and manual traces
  - fixes and revalidation results after every refinement failure

For multi-skill trees, `cross-cutting/SKILL.md` must also exist. Missing evidence means the task is incomplete.
