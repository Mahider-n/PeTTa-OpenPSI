# OpenClaw and OpenPsi Minimal integration 

## Overview

This use case implements **Option 2** from the OpenClaw OpenPsi integration design: using OpenClaw as the **environment layer** (the "body") for OpenPsi acting as the **cognitive core** (the "brain").

Rather than embedding OpenPsi inside OpenClaw, OpenPsi runs independently and controls OpenClaw. OpenClaw becomes the sensorimotor interface to real-world messaging platforms like WhatsApp and Telegram.

OpenClaw and OpenPsi integration minimal design: https://docs.google.com/document/d/1dGZAcUNeI6vc6do0Ih8aLjQaR4goMSWPt1rIdYqGi14/edit?usp=sharing 

```
WhatsApp / Telegram message
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
  actions.py                 ← OpenClaw tool calls (send, search, etc.)
          ↓
   OpenClaw Gateway          ← delivers reply back to user
```

---

## Architecture

### Brain–Body Separation

| Component | Role | Analogy |
|---|---|---|
| OpenPsi (MeTTa) | Cognitive core — emotions, demands, planning | Brain |
| OpenClaw | Execution layer — messaging, tools, channels | Body |
| `openclaw_env.py` | Bridge between brain and body | Nervous system |
| `observation.py` | Reads world state from OpenClaw | Sensory organs |
| `actions.py` | Sends tool calls to OpenClaw | Motor output |

### Cognitive Architecture

OpenPsi models the agent's internal state through **demands** — drives that must be satisfied. Each cognitive step:

1. **Perceive** — reads session state from OpenClaw (pending messages, urgency)
2. **Update demands** — maps observations to demand satisfaction levels
3. **Select demand** — epsilon-greedy selection of least-satisfied demand
4. **Select goal** — maps demand to a goal (e.g. `responsiveness` → `messageAnswered`)
5. **Plan** — Thompson Sampling over rules matching the goal and current context
6. **Act** — executes the chosen action sequence via OpenClaw tools
7. **Learn** — updates rule STVs based on outcome

---

## Demands

The agent has four demands, each scored 0.0–1.0 (1.0 = fully satisfied):

| Demand | Meaning | How it changes |
|---|---|---|
| `responsiveness` | How caught-up the agent is on messages | Drops when unanswered messages arrive; rises after responding |
| `helpfulness` | Desire to assist | Drops when a message is pending; rises when no messages |
| `curiosity` | Drive to explore | Stays at 0.75 baseline; drives proactive exploration |
| `energy` | General readiness | Stays at 1.0; falls if agent idles too long |

The dashboard shows these in real time using the progress bars.

---

## Rules

Rules follow the OpenPsi IMPLICATION format: `context + action → goal`. Each rule has an STV (Strength, Confidence) updated via Thompson Sampling after each execution.

| Rule | Context | Action | Goal |
|---|---|---|---|
| 1 | hasMessage + urgentMessage | respondToMessage | messageAnswered |
| 2 | hasMessage + infoRequest | searchWeb → respondWithSearchResult | messageAnswered |
| 3 | hasMessage + notUrgent | respondToMessage | messageAnswered |
| 4 | noMessage | waitForMessage | agentReady |
| 5 | noMessage + curiosityHigh | listSessions + searchWeb | Explore |

Rules 1–3 fire when a WhatsApp/Telegram message arrives. Rules 4–5 are idle-time behaviour. The Thompson Sampling algorithm in `ts-algorithm.metta` selects which rule to use based on accumulated success history.

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
├── openclaw_env.py         # OpenClaw environment class (HTTP polling)
├── observation.py          # Reads session state from OpenClaw gateway
├── actions.py              # Sends tool calls to OpenClaw gateway
├── type.py                 # ActionType enum + Observation dataclass
│
└── dashboard/
    ├── progress_dashboard.py   # Live demand visualisation (dearpygui)
    ├── comms.py                # TCP socket sender to dashboard
    └── events.metta            # MeTTa pushEvent helper
```

---

## How a Message Triggers the Agent

1. A WhatsApp message arrives at the OpenClaw gateway
2. On the next cognitive step, `updatePerception` calls `utils.getObservation()`
3. `openclaw_env.py` polls OpenClaw's HTTP API for new messages
4. The observation is converted to MeTTa atoms: `(hasMessage True)`, `(urgency 0.8)`, etc.
5. `perceptionToDemands` computes: `responsiveness = 1 - urgency` → drops to 0.2
6. `getLeastSatisfiedDemandEpsilonGreedy` selects `responsiveness` as the most urgent demand
7. `openClawGoalSelector(responsiveness)` returns `Goal messageAnswered`
8. `actionPlanner` finds rules 1, 2, 3 matching `messageAnswered`
9. Context predicates filter: `hasMessage=True`, `urgentMessage` evaluated
10. Thompson Sampling picks the best rule based on its STV history
11. `performSingleAction(respondToMessage)` calls `utils.executeAction(send_message)`
12. `actions.py` posts the reply to OpenClaw's API
13. OpenClaw delivers the reply to the user's WhatsApp
14. The rule's STV confidence is updated (success → alpha+1, fail → beta+1)

---

## Dashboard

The dashboard shows four demand bars that update every cognitive step:

- **Responsiveness** — high when caught up, drops when messages arrive
- **Helpfulness** — high when idle, drops when a message needs answering  
- **Curiosity** — stable at 75%, drives proactive web search
- **Energy** — stable at 100%, drives waitForMessage when other demands are met

The **Action** field shows the last executed action (e.g. `searchWeb`, `waitForMessage`, `respondToMessage`).

---

## Known Limitations

1. **Gateway auth** — The OpenClaw WebSocket requires Ed25519 device authentication using a keypair stored in the browser's `localStorage`. Until this is extracted and used, the agent connects via HTTP polling which works but cannot receive push notifications for new messages in real time — it polls instead on each cognitive step.

2. **Message polling** — The HTTP REST endpoints for session history are not officially documented. The current implementation tries several likely endpoint paths. If they all return 404, messages will not be detected (but the rest of the cognitive loop still works).

3. **No real-time push** — Without WebSocket auth, the agent discovers new messages only when a cognitive step happens. For low-latency response, reduce the sleep in `cognitiveLoop` or increase steps.

4. **Infinite loop** — `main.metta` runs `cognitiveLoop 50 1` which completes 50 steps and stops. For continuous operation change to a larger number or wrap in a shell loop.

---

 