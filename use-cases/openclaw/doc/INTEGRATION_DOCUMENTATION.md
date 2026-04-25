# OpenClaw + OpenPsi Integration Documentation

## Table of Contents

1. [Overview & Purpose](#overview--purpose)
2. [Architecture Overview](#architecture-overview)
3. [Brain-Body Separation](#brain-body-separation)
4. [File-by-File Explanation](#file-by-file-explanation)
   - [Python Files (Body)](#python-files-body)
   - [MeTTa Files (Brain)](#metta-files-brain)
5. [Cognitive Loop Explained](#cognitive-loop-explained)
6. [Demands System](#demands-system)
7. [Rules & Thompson Sampling](#rules--thompson-sampling)
8. [How Messages Flow Through the System](#how-messages-flow-through-the-system)
9. [Current Implementation Details](#current-implementation-details)
10. [How to Run](#how-to-run)
11. [Troubleshooting](#troubleshooting)

---

## Overview & Purpose

This integration implements **Option 2** from the OpenClaw-OpenPsi design: using OpenClaw as the **environment layer** (the "body") for OpenPsi acting as the **cognitive core** (the "brain").

**Main Purpose:**
- OpenPsi runs independently as the cognitive engine
- OpenClaw serves as the sensorimotor interface to the messaging channel used in this use case
- The agent can perceive incoming messages, reason about them using demand-driven cognition, and respond via OpenClaw

**What this enables:**
- A self-sustaining AI agent that monitors messaging platforms
- Demand-driven behavior (responsiveness, helpfulness, curiosity, energy)
- Learning from action outcomes via Thompson Sampling
- Real-time adaptation to conversation state

---

## Architecture Overview

```
WhatsApp message
          ↓
   OpenClaw Gateway          ← "body" — messaging, tool execution
          ↓
  openclaw_env.py            ← environment bridge 
          ↓
   utils.py / MeTTa          ← OpenPsi perception layer
          ↓
  perception.metta           ← converts observations to demand values
          ↓
  feedback-loop.metta        ← demand update logic
          ↓
  ts-algorithm.metta         ← Thompson Sampling rule selection
          ↓
  utils.metta                ← action dispatch
          ↓
  actions.py                 ← OpenClaw tool calls 
          ↓
   OpenClaw Gateway          ← delivers reply back to user
```

---


## File-by-File Explanation

### Python Files (Body)

#### `type.py` — Data Structures

Defines the core data types used throughout the integration:

```python
class ActionType(Enum):
    SEND_MESSAGE = auto()
    SEND_MESSAGE_WITH_SEARCH = auto()
    WEB_SEARCH = auto()
    READ_FILE = auto()
    WRITE_FILE = auto()
    LIST_SESSIONS = auto()
    GET_HISTORY = auto()
    IDLE = auto()
```

**Purpose:** Enumerates all possible actions the agent can perform.

```python
@dataclass
class Observation:
    sender: str              # Who sent the message
    channel: str             # Messaging channel (currently WhatsApp)
    message_text: str        # The actual message content
    session_id: str          # Conversation identifier
    message_urgency: float   # 0.0-1.0 urgency score
    unanswered_count: int    # How many messages await reply
    last_action_success: bool # Did the last action succeed?
    time_since_last_message: float # Seconds since last message
    web_search_result: Optional[str] = None
    file_content: Optional[str] = None
    active_sessions: List[str] = field(default_factory=list)
    sentiment: Optional[str] = None
```

**Purpose:** Represents the agent's perception of the world state.

---

#### `openclaw_env.py` — Environment Bridge

The main class that connects OpenPsi to OpenClaw:

```python
class OpenClawEnvironment:
    def __init__(self):
        self.connected = False
        self.current_session_id: Optional[str] = None
        self.last_message_time: Optional[float] = None
        self.last_action_success: bool = True
        self.last_search_result: Optional[str] = None
        self.last_file_content: Optional[str] = None
        self.active_sessions: list = []
```

**Key Methods:**
- `connect()` — Tests connection to OpenClaw Gateway
- `getObservation()` — Returns current world state
- `executeAction(action_type, *args)` — Dispatches actions to handlers
- `doSendMessage()`, `doWebSearch()`, `doListSessions()` — Action handlers

**Purpose:** Acts as the nervous system, translating between OpenPsi's cognitive decisions and OpenClaw's execution capabilities.

---

#### `observation.py` — Sensory Processing

Reads and interprets messages from OpenClaw:

**Key Functions:**

1. **`_computeUrgency(text)`** — Scores message urgency (0.0-1.0) based on keywords:
   ```python
   URGENT_KEYWORDS = ["urgent", "help", "emergency", "asap", "immediately", ...]
   ```
   Each keyword adds 0.25 to the score (capped at 1.0).

2. **`_isInfoRequest(text)`** — Detects information-seeking messages using broader heuristics, not just a fixed keyword list:
   - returns `True` for messages containing `?`
   - returns `True` when the first word is a question or lookup cue such as `what`, `who`, `how`, `why`, `when`, `where`, `define`, `explain`, `describe`, `tell`, or `search`
   - returns `True` for phrases like `meaning of`, `definition of`, `what is`, `search for`, `find`, `look up`, and `tell me about`

3. **`buildObservation(env)`** — Main function that:
   - Fetches message history from OpenClaw
   - Counts unanswered messages
   - Computes urgency
   - **Generates Metta atoms** for perception.metta:
     ```python
     metta_atoms = [
         f"(hasMessage {str(has_message).lower()})",
         f"(unansweredCount {unanswered_count})",
         f"(urgency {urgency:.2f})",
         f"(noMessage {str(not has_message).lower()})",
         f"(urgentMessage {str(urgency > 0.5).lower()})",
         f"(notUrgent {str(urgency <= 0.5).lower()})",
         f"(infoRequest {str(_isInfoRequest(message_text)).lower()})",
         f"(curiosityHigh True)",
         f"(timeSinceMessage {time_since:.1f})",
         f'(messageText "{escaped_text}")'
     ]
     ```

**Purpose:** Converts raw message data into structured observations and Metta atoms that OpenPsi can reason about.

---

#### `actions.py` — Motor Output

Sends actions to OpenClaw for execution:

**Key Functions:**

1. **`_invoke(tool, args)`** — Central HTTP client for OpenClaw Gateway:
   - Sends POST requests to `/tools/invoke`
   - Handles authentication via Bearer token
   - Returns parsed JSON results

2. **`fetchHistory(session_key, limit=50)`** — Retrieves message history:
   - Uses `sessions_history` tool
   - Returns list of messages with role, content, timestamp

3. **`doSendMessage(env, text, session_id)`** — **Uses CLI instead of HTTP and owns the safety guards and greeting logic**:
   ```python
   cmd = [
       "openclaw", "message", "send",
       "--channel", "whatsapp",
       "--target", target,
       "--message", text
   ]
   result = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
   ```
   **Behavior includes:**
   - sending a one-time greeting only when there is no latest user message and the greeting has not been used yet
   - blocking duplicate replies to the same already-handled user message

   **Why CLI?** The HTTP `sessions_send` endpoint in the OpenClaw Gateway is currently not functioning (returns 404 errors). The CLI approach provides a reliable fallback for sending messages when the HTTP API fails.

4. **`doWebSearch(env, query)`** — Performs grounded web search with Gemini:
   - Reads `GEMINI_API_KEY` or `GOOGLE_API_KEY`
   - Calls Gemini `generateContent` with the `google_search` tool enabled
   - Extracts grounded source URLs from response metadata
   - Falls back to the OpenClaw gateway `web_search` tool if Gemini is unavailable

5. **`doSendMessageWithSearch(env)`** — Sends the latest search result back to the user:
   - Uses `env.last_search_result` if already available
   - Otherwise searches from the latest user message first
   - Reuses the existing CLI-based message send path

6. **`doListSessions(env)`** — Lists active messaging sessions

**Purpose:** Executes the agent's decisions by communicating with OpenClaw.

---

#### `utils.py` — MeTTa Bridge

Connects Python to MeTTa:

```python
def getObservation():
    """Called from MeTTa: returns list of Metta atoms"""
    env = OpenClawEnvironment()    
    observationOps.buildObservation(env)          
    return getattr(env, 'metta_observation_atoms', ["(hasMessage False)", "(unansweredCount 0)"])
```

**Key Functions:**
- `connectToOpenClaw()` — Initializes connection (called from main.metta)
- `getObservation()` — Called by MeTTa via `py-call (utils.getObservation)`
- `executeAction(actionName, *args)` — Maps action names to ActionType enums
- `sleepSeconds(seconds)` — Adds delay between cognitive steps

**Purpose:** Provides the interface that allows MeTTa code to call Python functions.

---

### MeTTa Files (Brain)

#### `main.metta` — Cognitive Loop Entry Point

The main program that runs the agent:

```metta
!(import! &self "utils.py")
!(import! &self ../../main/modulator/modulator)
!(import! &self ../../main/feedback-loop/feedback-loop)
!(import! &self utils)
!(import! &self ts-algorithm)
!(import! &self "dashboard/comms.py")
!(import! &self dashboard/events)
!(import! &self perception)
!(import! &self rules)
```

**Spaces:**
```metta
!(bind! &kb              (new-space))      ; Knowledge base
!(bind! &perceptionSpace (new-space))      ; Current observations
!(bind! &modulatorSpace  (new-space))      ; Emotional modulators
!(bind! &ruleSpace       (new-space))      ; Action rules
!(bind! &demandSpace     (new-space))      ; Agent demands
```

**Main Loop:**
```metta
(= (cognitiveStep)
   (let* (
      ($_ (updatePerception &perceptionSpace))           ; 1. Sense
      ($_ (perceptionToDemands &perceptionSpace &demandSpace)) ; 2. Update demands
      ($demands (collapse (get-atoms &demandSpace)))
      ($_ (pushEvent Demand $demands))
      ($currDemand (getLeastSatisfiedDemandEpsilonGreedy &demandSpace 0.1)) ; 3. Select demand
      ($_ (println! (Selected-Demand: $currDemand)))
      ((demand $demandName $minVal $maxVal $demandValue) $currDemand)
      ($goalObj (openClawGoalSelector $demandName))      ; 4. Map to goal
      ((Goal $goal $goalVal1 $goalVal2) $goalObj)
      ($_ (println! (Selected-Goal: $goal)))
      (($actions $id) (actionPlanner &ruleSpace $goal))  ; 5. Plan action
      ($_ (println! (Planned-Actions: $actions)))
      ($result (if (== $actions ()) () (performAction $actions))) ; 6. Execute
      ($_ (if (== $result ()) () (updateRule $id $result &ruleSpace))) ; 7. Learn
   ) (Step Completed)))
```

**Purpose:** Orchestrates the entire cognitive cycle — perceive, reason, act, learn.

---

#### `perception.metta` — Demand Initialization & Perception Mapping

**Part 1: Demand Initialization**
```metta
!(add-atom &demandSpace (demand responsiveness 0.0 1.0 1.0))
!(add-atom &demandSpace (demand curiosity      0.0 1.0 0.75))
!(add-atom &demandSpace (demand helpfulness    0.0 1.0 0.8))
!(add-atom &demandSpace (demand energy         0.0 1.0 1.0))
```

**Part 2: Perception Update**
```metta
(= (updatePerception $space)
   (let* (
      ($_ (removeOccurrences $space))
      ($obs (py-call (utils.getObservation)))  ; Get atoms from Python
      ($_ (collapse (addIndividualObservation $obs $space)))
   ) ()))
```

**Part 3: Perception-to-Demands Mapping**
```metta
(= (perceptionToDemands $perceptionSpace $demandSpace)
   (let* (
      ; Responsiveness = 1 - combined urgency signal
      ($respUrgency (responsivenessUrgency $perceptionSpace))
      ($respVal (- 1.0 $respUrgency))
      ($_ (safeUpdateDemand $demandSpace responsiveness $respVal))

      ; Helpfulness = low if message waiting, high if idle
      ($hasMsg (hasMessageNow $perceptionSpace))
      ($helpVal (if $hasMsg 0.3 0.9))
      ($_ (safeUpdateDemand $demandSpace helpfulness $helpVal))
   ) ()))
```

**Purpose:** Converts raw perceptions into meaningful demand values that drive behavior.

In the current code, `responsivenessUrgency` combines unanswered count and urgency before the final inversion.

---

#### `rules.metta` — Action Rules

Five rules are defined in `rules.metta`:

| Rule | Context | Action | Goal | STV |
|------|---------|--------|------|-----|
| 1 | hasMessage + urgentMessage | respondToMessage | messageAnswered | 0.95/0.9 |
| 2 | hasMessage + infoRequest | searchWeb → respondWithSearchResult | messageAnswered | 0.9/0.85 |
| 3 | hasMessage + notUrgent | respondToMessage | messageAnswered | 0.88/0.85 |
| 4 | noMessage | waitForMessage | agentReady | 0.8/0.75 |
| 5 | noMessage + curiosityHigh | listSessions → searchWeb | Explore | 0.75/0.7 |

**Purpose:** Defines when and how the agent should act based on context.

---

#### `utils.metta` — Context Predicates & Action Dispatch

**Goal Selector:**
```metta
(= (openClawGoalSelector $x) (
  case $x (
    (responsiveness (Goal messageAnswered 1.0 0.9))
    (helpfulness    (Goal messageAnswered 1.0 0.85))
    (curiosity      (Goal Explore 1.0 0.5))
    (energy         (Goal agentReady 1.0 0.8))
  )))
```

**Context Evaluation:**
```metta
(= (evalContextPredicate $name)
   (case $name (
      (hasMessage     (hasMessageNowGlobal))
      (noMessage      (noMessageNow))
      (urgentMessage  (isUrgentNow))
      (notUrgent      (not (isUrgentNow)))
      (infoRequest    (isUrgentNow))
      (curiosityHigh  (isCuriosityHighNow))
   )))
```

**Action Execution:**
```metta
(= (performSingleAction $action) (
  case $action (
    ((respondToMessage)
       (py-call (utils.executeAction send_message)))
    ((respondWithSearchResult)
       (py-call (utils.executeAction send_message_with_search)))
    ((searchWeb)
       (py-call (utils.executeAction web_search)))
    ((listSessions)
       (py-call (utils.executeAction list_sessions)))
    ((waitForMessage)
       (py-call (utils.sleepSeconds 2.0)))
  )))
```

**Purpose:** Evaluates context, selects goals, and dispatches actions to Python.

---

#### `ts-algorithm.metta` — Thompson Sampling

Implements probabilistic rule selection:

```metta
; Convert STV to Beta distribution parameters
(= (stvToBeta ($strength $confidence)) (
    let* (
        ($count (confidenceToCount $confidence))
        ($alpha (* $strength $count))
        ($beta (- $count $alpha))
    ) ($alpha $beta)))

; Sample from Beta and pick highest
(= (sampler $ids $space) (
    if (== () $ids)
        (-1 0)
        (let* (
            (($s $c) (getSTV $head $space))
            (($alpha $beta) (stvToBeta ($s $c)))
            (($sample) (thompson-sampler $alpha $beta 1))
            (($chosenId $chosenSample) (sampler $tail $space))
        ) (if (> $sample $chosenSample)
            ($head $sample)
            ($chosenId $chosenSample)))))
```

**Learning:**
```metta
(= (updateRule $ruleId $result $space) (
    ; If result=1 (success): alpha+1
    ; If result=0 (failure): beta+1
    ($newAlpha (if (== $result 1) (+ $alpha 1) $alpha))
    ($newBeta (if (== $result 1) $beta (+ $beta 1)))
))
```

**Purpose:** Balances exploration vs exploitation by sampling from rule confidence distributions.

---

## Cognitive Loop Explained

```
┌─────────────────────────────────────────────────────────────┐
│                    COGNITIVE STEP                           │
├─────────────────────────────────────────────────────────────┤
│ 1. UPDATE PERCEPTION                                        │
│    - Call utils.getObservation()                            │
│    - Python fetches messages from OpenClaw history          │
│    - Returns Metta atoms: (hasMessage True), (urgency 0.8)  │
│                                                             │
│ 2. PERCEPTION → DEMANDS                                     │
│    - responsiveness = 1 - combined(unansweredCount, urgency)│
│    - helpfulness = 0.3 if hasMessage else 0.9               │
│                                                             │
│ 3. SELECT DEMAND                                            │
│    - Epsilon-greedy: 10% random, 90% least-satisfied        │
│    - Least satisfied demand drives behavior                 │
│                                                             │
│ 4. MAP DEMAND → GOAL                                        │
│    - responsiveness → messageAnswered                       │
│    - curiosity → Explore                                    │
│                                                             │
│ 5. PLAN ACTION                                              │
│    - Find rules matching the goal                           │
│    - Filter by context (hasMessage, urgentMessage, etc.)    │
│    - Thompson Sampling selects best rule                    │
│                                                             │
│ 6. EXECUTE ACTION                                           │
│    - Call Python via py-call                                │
│    - actions.py sends to OpenClaw (CLI for messages)        │
│                                                             │
│ 7. LEARN                                                    │
│    - If success: increase rule strength (alpha+1)           │
│    - If failure: increase rule confidence (beta+1)          │
└─────────────────────────────────────────────────────────────┘
```

---

## Demands System

| Demand | Initial | Range | What Drives It |
|--------|---------|-------|----------------|
| **responsiveness** | 1.0 | 0.0-1.0 | Drops when unanswered count and urgency rise; improves when they fall |
| **helpfulness** | 0.8 | 0.0-1.0 | Low (0.3) when message pending; high (0.9) when idle |
| **curiosity** | 0.75 | 0.0-1.0 | Stable; drives exploration when no messages |
| **energy** | 1.0 | 0.0-1.0 | Stable; represents general readiness |

**Why demands matter:**
- The agent prioritizes the **least-satisfied demand**
- This creates adaptive behavior: respond to messages when they arrive, explore when idle

---

## Rules & Thompson Sampling

**STV (Strength, Confidence):**
- **Strength** (0-1): Expected success rate
- **Confidence** (0-1): How much we trust the strength estimate

**Thompson Sampling:**
1. Convert each rule's STV to Beta distribution parameters (alpha, beta)
2. Sample from each rule's Beta distribution
3. Select the rule with highest sample
4. After execution, update alpha (on success) or beta (on failure)

**Result:** The agent tries rules with high uncertainty more often early on, then converges to best-performing rules over time.

---

## How Messages Flow Through the System

```
User sends WhatsApp message
         ↓
OpenClaw Gateway receives it
         ↓
main.metta calls cognitiveStep
         ↓
updatePerception → py-call (utils.getObservation)
         ↓
actions.py: fetchHistory() → retrieves session history
         ↓
observation.py: buildObservation() → parses messages
         ↓
buildObservation() → generates Metta atoms
         ↓
perception.metta: addIndividualObservation() stores atoms
         ↓
perceptionToDemands() → updates demand values
         ↓
getLeastSatisfiedDemandEpsilonGreedy() → selects "responsiveness"
         ↓
openClawGoalSelector(responsiveness) → returns "messageAnswered"
         ↓
actionPlanner() → finds Rules 1,2,3 matching "messageAnswered"
         ↓
filterRulesByContext() → evaluates hasMessage, urgentMessage, etc.
         ↓
sampler() → Thompson Sampling selects best rule
         ↓
performAction() → py-call (utils.executeAction send_message)
         ↓
actions.py: doSendMessage() → subprocess.run(["openclaw", "message", "send", ...])
         ↓
OpenClaw delivers reply to WhatsApp
         ↓
updateRule() → adjusts STV based on success/failure
```

---

## Current Implementation Details

### CLI-Based Messaging
The integration now uses the `openclaw` CLI via subprocess for sending messages:

```python
cmd = [
    "openclaw", "message", "send",
    "--channel", "whatsapp",
    "--target", target,
    "--message", text
]
result = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
```

The same send function also contains the runtime send guards:

- one-time greeting for a fresh session with no user message yet
- duplicate-response prevention through `env.last_handled_user_message`
- empty-response blocking for normal replies
 

### Metta Atom Generation
Observation.py now generates Metta atoms directly:

```python
metta_atoms = [
    "(hasMessage True)",
    "(unansweredCount 1)",
    "(urgency 0.75)",
    "(notUrgent False)",
    "(urgentMessage True)",
    "(infoRequest False)",
    "(curiosityHigh True)",
    "(timeSinceMessage 5.2)"
]
```

These are stored in `env.metta_observation_atoms` and returned to MeTTa.

### Debug Output
Added println statements throughout for debugging:
```metta
($_ (println! (Step $currentStep / $maxSteps)))
($_ (println! (perception: $obs)))
($_ (println! (Demands: responsiveness= $respVal helpfulness= $helpVal)))
($_ (println! (Context: hasMessage= $hasMsg unanswered= (getUnansweredCount $perceptionSpace))))
($_ (println! (Selected-Demand: $currDemand)))
($_ (println! (Selected-Goal: $goal)))
($_ (println! (Planned-Actions: $actions)))
```

### Terminal Log Analysis

The use case includes [`log_analyzer.py`] for post-run analysis of OpenPsi terminal output.

Purpose:

- parse a saved terminal log from a `main.metta` run
- begin at the first `(Step 1 / N)` marker
- ignore startup/import noise before the first cognitive step
- summarize chosen rules, goals, actions, and message-handling behavior
- generate saved report artifacts for later inspection

---

## How to Run


## Setup

Before running this integration, set up OpenClaw and connect it to WhatsApp, which is the messaging channel used in this use case.

A walkthrough for the initial OpenClaw setup is available here:
[OpenClaw setup video](https://youtu.be/cQ6diPGtwAY?si=OXNc-2J3LsfH-LSB)

After OpenClaw is running and your WhatsApp session is connected, continue with the steps below.


### Prerequisites

- OpenClaw Gateway running  
- Python environment with dependencies  

---

### Install dependencies:

```bash

cd use-cases/openclaw
pip install -r requirements.txt

```

### Environment Variables

```bash

OPENCLAW_GATEWAY_TOKEN="your_token_here"
GATEWAY_URL="http://127.0.0.1:18789"
DEFAULT_SESSION_KEY="your_session_key" / agent:main:whatsapp:direct:"your_phone_number"
GEMINI_API_KEY="your_api_key"
GEMINI_MODEL="gemini-2.5-flash"

```
---

### Run the Agent

1. Visualizes demand levels in real time

```bash
cd use-cases/openclaw/dashboard
python progress_dashboard.py
```
2. Run the agent 
 ```bash
cd use-cases/openclaw
petta main.metta
``` 

3. Optional: Log Analyzer

Analyze agent behavior from logs:

```bash
petta main.metta | tee result.txt
python log_analyzer.py result.txt

```
Outputs:

- analysis_output/analysis_report.txt — human-readable summary report
- analysis_output/rule_choice_timeline.png — rule selection over time
- analysis_output/rule_and_action_summary.png — aggregated rule/action stats

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Connection failed | Check OpenClaw Gateway is running |
| Messages not arriving | Verify session key is correct |
| No replies sent | Check CLI (`openclaw message send --help`) |

---

## Future Enhancements

1. **Emotional modulators** — Currently initialized but not fully integrated
2. **Multi-session support** — Currently monitors single session

---

## Summary

This integration demonstrates a complete cognitive agent architecture:
- **Perception** — Reads messages from OpenClaw, computes urgency
- **Demands** — Tracks responsiveness, helpfulness, curiosity, energy
- **Reasoning** — Thompson Sampling over context-matched rules
- **Action** — Sends replies via OpenClaw CLI
- **Learning** — Updates rule confidence based on outcomes

The brain-body separation allows OpenPsi to focus on cognition while delegating communication to OpenClaw.
