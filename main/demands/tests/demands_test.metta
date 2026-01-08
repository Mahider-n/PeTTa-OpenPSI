!(import! &self ../../../psi-utilities/psi_utils)
!(import! &self ../demands)

!(bind! &demandSpace (new-space))

!(addDemand &demandSpace energy 0.6)
!(addDemand &demandSpace affiliation 0.5)
!(addDemand &demandSpace competence 0.2)
!(skipDemand &demandSpace competence)

!(test (getDemandByName &demandSpace energy) (demand energy 0.6))

!(test (exists-In &demandSpace (demand energy 0.6)) True)
!(test (exists-In &demandSpace (demand competence 0.2)) True)
!(test (getAllDemands &demandSpace )  ((demand energy 0.6) (demand affiliation 0.5) (demand competence 0.2)))
!(test (exists-In &demandSpace (skip competence)) True)

!(setDemandValue &demandSpace energy 0.8)
!(test (exists-In &demandSpace (demand energy 0.6)) False)
!(test (exists-In &demandSpace (demand energy 0.8)) True)

!(test (fetch-demand &demandSpace energy)  (demand energy 0.8))
!(test (fetch-demand-val &demandSpace energy) 0.8)
!(test (getEnabledDemands &demandSpace) ((demand affiliation 0.5) (demand energy 0.8)))
;;!(bind! &decayspace (new-space))
;;!(addDemand &decayspace energy 0.6)
;;!(addDemand &decayspace affiliation 0.5)
;;!(addDemand &decayspace competence 0.4)
;;!(skipDemand &decayspace competence)
;;!(getEnabledDemands &decayspace)
;;!(decaySkippedDemands &decayspace 0.1)
;;!(decayAllDemands &decayspace 0.05)
;;!(get-atoms &decayspace)
