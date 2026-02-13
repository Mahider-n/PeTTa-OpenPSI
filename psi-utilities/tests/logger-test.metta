
;; Import the logger definitions 
!(import! &self "main.py")

;; -----------------------------
;; Existing examples (modulator)
;; -----------------------------

!(test (log-event modulator_change (Volume 0.5 0.75)) "[MODULATOR_UPDATE]-Volume 0.5' -> 0.75   diff=0.25")

!(test (log-event modulator_debug (FilterCutoff 800 650)) "[MODULATOR_UPDATE]-FilterCutoff 800' -> 650   diff=-150.0")

;; -----------------------------
;; New PSI: feeling updates
;; -----------------------------

!(test (log-event feeling_update_debug (Joy 0.6 0.8)) "[FEELING_UPDATE]-Joy 0.6' -> 0.8  ")

!(test (log-event feeling_update_debug (Fear 0.2 0.15)) "[FEELING_UPDATE]-Fear 0.2' -> 0.15  ")

;; -----------------------------
;; New PSI: schema updates
;; -----------------------------

!(test (log-event schema_update (Schema-Approach-Reward activated "Triggered by Goal(FindFood)")) "[SCHEMA_UPDATE]-Schema-Approach-Reward activated \"Triggered by Goal(FindFood)\"")

!(test (log-event schema_update (Schema-Avoid-Threat strengthened "Connection to Concept(LoudNoise) increased")) "[SCHEMA_UPDATE]-Schema-Avoid-Threat strengthened \"Connection to Concept(LoudNoise) increased\"")

!(test (log-event schema_update (ComplexSchemaID modified "Sub-node 'X' value changed")) "[SCHEMA_UPDATE]-ComplexSchemaID modified \"Sub-node 'X' value changed\"")

;; -----------------------------------------------
;; Graceful fallback: non-numeric modulator change
;; -----------------------------------------------

!(test (log-event feeling_update (Mood Calm Tense)) "[FEELING_UPDATE]-Mood Calm' -> Tense  ")

;; -----------------------------------------------
;; Errors and unknown events (should still print)
;; -----------------------------------------------

!(test (log-event unknown_event (Data1 Data2)) "log-event: No handler found for event type 'unknown_event'")

!(test (log-event modulator_change (ReverbDecay 2.5 3.0)) "[MODULATOR_UPDATE]-ReverbDecay 2.5' -> 3.0   diff=0.5")


