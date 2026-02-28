
!(import! &self ../../../modulator/modulator)
!(import! &self modulator-updater-test-helpers)
!(import! &self ../../../demands/demands)
!(import! &self ../../../../normalization)
!(import! &self ../../../main/modulator/modulator)
!(import! &self ../../../../psi-utilities/psi_utils)
!(import! &self ../../modulator-updater/modulator-updater)

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

!(test (ActivationHelper 4 3) 0.8743169398907105)
!(test (SecuringThresholdHelper 4 0.8) 60.23529411764706)
!(test (SelectionThresholdHelper 3.0) 0.01639344262295082)

!(test (compareModulatorValues (modulator arousal 0.5) (modulator arousal 0.5)) True)
!(test (compareModulatorValues (modulator selection-threshold 0.5) (modulator arousal 0.5)) False)
!(test (compareModulatorValues (modulator arousal 0.4) (modulator arousal 0.5)) False)

!(compareModulators &modulator-space &demandspace)