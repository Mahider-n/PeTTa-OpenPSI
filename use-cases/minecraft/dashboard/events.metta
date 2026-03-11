; !(import! &self "comms.py")

(= (pushEvent $type $data) (
    py-call (comms.send_event ($type $data))
))

;; Tests
; !(pushEvent Demand (energy 0.9 water 0.23))
; !(pushEvent Emotion (happinessValue 0.64 sadnessValue 0.02 angerValue 0.45 fearValue 0.12 gratitudeValue 0.32))
; !(pushEvent Action (Eat Food))
