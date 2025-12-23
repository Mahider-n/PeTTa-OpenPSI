
!(import! &self ../../../modulator/modulator)
!(import! &self modulator-updater-test-helpers)

; !(import! &self ../../../../utils)
; !(import! &self ../../../../psi-utilities/psi_utils)
; !(import! &self ../../../demands/demands)
; !(import! &self ../../../../psi-utilities/normalization)

(= (populateDemandSpace $demandspace) 
   (let $demand (superpose 
      (
        (demand affiliation 0.5 0.6 0.5)
        (demand energy      0.4 0.7 0.6)
        (demand competence  0.3 0.5 0.2)
        )
      )
     (add-atom $demandspace $demand)
    )
   )

!(collapse (populateDemandSpace &demandspace))
!(get-atoms &demandspace)

!(insert-modulators &modulator-space)

!(test (ActivationHelper 4 3 2) 4.8743169398907105)
!(test (SecuringThresholdHelper 4 3) 70)
!(test (SelectionThresholdHelper 3 4) 8.01639344262295)

!(test (compareModulatorValues (modulator arousal 0.5) (modulator arousal 0.5)) True)
!(test (compareModulatorValues (modulator selection-threshold 0.5) (modulator arousal 0.5)) False)
!(test (compareModulatorValues (modulator arousal 0.4) (modulator arousal 0.5)) False)
; !(let $res (compareModulators &modulator-space &demandspace) (println! (res $res))) 
!(compareModulators &modulator-space &demandspace)
