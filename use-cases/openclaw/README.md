# OpenClaw and OpenPsi Minimal integration 

## Overview


A minimal integration where **OpenPsi acts as the cognitive brain** and **OpenClaw as the messaging body**.

---

This use case implements **Option 2** from the OpenClaw–OpenPsi design:

- **OpenPsi** runs independently as the cognitive engine  
- **OpenClaw** handles messaging, tools, and external interaction  
- The agent perceives messages, reasons using demand-driven cognition, and responds via OpenClaw  

This setup enables a self-contained agent that can:
- Monitor WhatsApp conversations  
- Prioritize actions based on internal “demands”  
- Learn which actions work best over time  


**Design reference:** https://docs.google.com/document/d/1dGZAcUNeI6vc6do0Ih8aLjQaR4goMSWPt1rIdYqGi14/edit?usp=sharing 

---

## Why This Use Case Was Chosen

- It is a concrete brain-body demo. OpenPsi is the cognitive layer, and OpenClaw is the messaging/action layer. That makes the separation very visible and easy to explain.

- Messaging is a natural real-world environment. A WhatsApp-style chat gives clear observations, clear goals, and easy-to-evaluate actions, so it is a very practical testbed for demand-driven cognition.

---

## What It Shows

- It shows how internal demands can drive external behavior. The agent does not just react with fixed rules rather it maps perception into demands like responsiveness, helpfulness, curiosity, and energy, then chooses a goal from there.

- It shows how symbolic planning can connect to real tool execution. Rules defined in MeTTa eventually call Python actions that talk to OpenClaw, search the web, or send a WhatsApp message.

- It shows how a cognitive architecture can be inspected and debugged. The module has step logs, explicit rule choices, demand updates, and a log analyzer, which makes the agent’s decisions legible.

---

## Main Relevance

The main relevance of this use case is that it turns OpenPsi from a purely internal cognitive model into something embodied and testable in a real communication environment. In other words, it demonstrates not just “how the agent thinks,” but how that thinking becomes observable, useful, and debuggable in an actual messaging workflow.

---

## Architecture

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

### Brain–Body Separation

| Component | Role | Analogy |
|---|---|---|
| OpenPsi  | Cognitive core — emotions, demands, planning | Brain |
| OpenClaw | Execution layer — messaging, tools, channels | Body |
| `openclaw_env.py` | Bridge between brain and body | Nervous system |
| `observation.py` | Reads world state from OpenClaw | Sensory organs |
| `actions.py` | Sends calls to OpenClaw | Motor output |

---

## Key Concepts

- **Demands** — Internal drives (e.g. responsiveness, curiosity) that determine behavior  
- **Rules** — Map context → actions → goals  
- **Thompson Sampling** — Selects the best rule based on past success  

---

## Quick Flow

1. A message arrives via OpenClaw  
2. OpenPsi perceives it and updates internal demands  
3. The least satisfied demand determines the goal  
4. A rule is selected using Thompson Sampling  
5. The action is executed through OpenClaw  

---

## Rules

| Context                      | Action                             | Goal             |
|------------------------------|------------------------------------|------------------|
| hasMessage + urgentMessage   | respondToMessage                   | messageAnswered  |
| hasMessage + infoRequest     | searchWeb → respondWithSearchResult| messageAnswered  |
| hasMessage + notUrgent       | respondToMessage                   | messageAnswered  |
| noMessage                    | waitForMessage                     | agentReady       |
| noMessage + curiosityHigh    | listSessions → searchWeb           | Explore          |


---

## File Structure

```
use-cases/openclaw/
├── main.metta              # Cognitive loop entry point
├── perception.metta        # Demand initialisation and perception→demand mapping
├── rules.metta             # OpenPsi rule definitions
├── utils.metta             # Context predicates, action dispatch, goal selector
├── ts-algorithm.metta      # Thompson Sampling, STV update, rule selection
│
├── utils.py                # MeTTa-callable Python bridge
├── openclaw_env.py         # OpenClaw environment class 
├── observation.py          # Reads session state from OpenClaw gateway
├── actions.py              # Sends reply to OpenClaw gateway
├── type.py                 # ActionType enum + Observation dataclass
│
|── dashboard/
|    ├── progress_dashboard.py   # Live demand visualisation 
|    ├── comms.py                # TCP socket sender to dashboard
|    └── events.metta            # MeTTa pushEvent helper
|
|── doc/ INTEGRATION_DOCUMENTATION.md  #Detail implementation explanation  

```

---

## How a Message Triggers the Agent

1. A WhatsApp message arrives at the OpenClaw gateway
2. On the next cognitive step, `updatePerception` calls `utils.getObservation()`
3. `openclaw_env.py` provides the environment interface and state used during execution  
4. The observation is converted to MeTTa atoms: `(hasMessage True)`, `(urgency 0.8)`, etc.
5. `perceptionToDemands` computes: `responsiveness` 
6. `getLeastSatisfiedDemandEpsilonGreedy` selects `responsiveness` as the most urgent demand
7. `openClawGoalSelector(responsiveness)` returns `Goal messageAnswered`
8. `actionPlanner` finds rules 1, 2, 3 matching `messageAnswered`
9. Context predicates filter: `hasMessage=True`, `urgentMessage` evaluated
10. Thompson Sampling picks the best rule based on its STV history
11. `performSingleAction(respondToMessage)` calls `utils.executeAction(send_message)`
12. `actions.py` sends to OpenClaw (CLI for messages)  
13. OpenClaw delivers the reply to the user's WhatsApp
14. The rule's STV confidence is updated (success → alpha+1, fail → beta+1)

---

### For detailed architecture, cognitive loop, and file-level explanations refer:

 -> doc/INTEGRATION_DOCUMENTATION.md

---

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