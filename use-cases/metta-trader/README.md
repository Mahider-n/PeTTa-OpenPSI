# MeTTa Trader: Directory and Module Documentation

## 1. Purpose
`metta-trader` is a MeTTa-based prototype for rule-driven planning and probabilistic reasoning in a small trading world.

The project combines:
- Domain rules and world state transitions (`BUY`, `SELL`, `TRAVEL`)
- Thompson-sampling-style rule selection
- PLN-style inference to derive new rules over time
- Unit-style test files for core modules

## 2. High-Level Architecture
Execution flow in `main.metta`:
1. Import core modules (`rule-ops`, `utils`, `world`, `planner`, `schemas`, `ruleSampler`).
2. Initialize a rule space using `initializeSpace` from `schemas.metta`.
3. The Loop:
   - Sample candidate rules
   - Generate inferred rules via PLN (`pln-reasoning`)
   - Add inferred rules to rule space
   - Filter applicable rules for the current context/money
   - Select a rule via Thompson sampling
   - Apply rule to update context/money
   - Compute reward and update rule confidence

## 3. Directory Structure
```text
metta-trader/
├── main.metta
├── world.metta
├── utils.metta
├── rule-ops.metta
├── planner.metta
├── planner-utils.metta
├── schemas.metta
├── ruleSampler.metta
├── tests/
└── pln/
    ├── engine.metta
    ├── formula.metta
    ├── utils.metta
    ├── rule-sampler.metta
    ├── inference/
    ├── rule/
    └── tests/
```

## 4. Top-Level Files
- `main.metta`: Main orchestration loop and runtime entry point.
- `world.metta`: Static market/world data and pricing helpers.
- `utils.metta`: Environment-aware rule validation, action application, item/planet extraction, and state evaluation.
- `rule-ops.metta`: Rule parsing/extraction functions (`extractRule`, `extractRuleAction`, `extractRuleGoal`, etc.).
- `planner.metta`: Thompson-style selection (`thompson-sample`) and sample baseline rules.
- `planner-utils.metta`: STV/Beta conversion and Beta sampling support.
- `schemas.metta`: Initial rule-space population (`initializeSpace`) with domain rules.
- `ruleSampler.metta`: Top-k probabilistic rule sampler (scoring + sorting + extraction).

## 5. `tests/` (Top-Level)
Unit-style behavioral tests for core non-PLN modules:
- `tests/world-test.metta`: Price/travel helper checks.
- `tests/util-tests.metta`: `getItem`, `evaluateState`, `getPlanetFromContexts`.
- `tests/state-update.metta`: `addItem`, `removeItem`, `updatePlanet`.
- `tests/rule-tests.metta`: Rule validity checks against money/context.
- `tests/apply-rule.metta`: `applyTravel`, `applyBuy`, `applySell`.

## 6. `pln/` Subsystem
The `pln` directory contains probabilistic logical reasoning components that generate new rules from existing ones.

### 6.1 Core PLN files
- `pln/engine.metta`: Coordinates all inference families and normalizes output into rule format with IDs/TTV.
- `pln/formula.metta`: Truth-value formulas for deduction, induction, abduction, conjunction.
- `pln/utils.metta`: Utility primitives used by PLN modules (`/safe`, similarity helpers, flattening, etc.).

### 6.2 `pln/inference/`
Inference-family implementations:
- `abduction.metta`
- `deduction.metta`
- `induction.metta`
- `conjunction.metta`
- `direct-evaluation.metta`

### 6.3 `pln/rule/`
Rule-model and query helpers used by inference modules:
- `rule.metta`: Aggregator imports for rule helpers/query utilities.
- `helpers.metta`: Rule creation, complexity handling, filtering by context/goal/action, rule ID/TTV tracking.
- `query.metta`: Rule structure extraction/query (`Id`, `STV`, `ContextValues`, `Action`, `GoalValues`, etc.).
- `inference-utils.metta`: Matching-premise discovery and reasoning dispatch helpers.

### 6.4 `pln/tests/`
PLN-focused tests:
- `pln/tests/engine-test.metta`: End-to-end PLN engine test using grid-world-style movement rules.
- `pln/tests/inference-tests/abduction-test.metta`
- `pln/tests/inference-tests/deduction-test.metta`
- `pln/tests/inference-tests/induction-test.metta`
- `pln/tests/inference-tests/conjunction-test.metta`
- `pln/tests/inference-tests/directly-evaluate-test.metta` (targets direct evaluation path).

## 7. Suggested Entry Points
- Main runtime: `main.metta`
- Rule/environment logic: `utils.metta`, `rule-ops.metta`, `world.metta`
- Reasoning extension point: `pln/engine.metta` plus files under `pln/inference/`
- Rule schema bootstrap: `schemas.metta`