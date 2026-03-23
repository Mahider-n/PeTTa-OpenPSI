!(import! &self "utils.py")
!(import! &self ../../main/modulator/modulator)
!(import! &self ../../main/feedback-loop/feedback-loop)
!(import! &self utils)
!(import! &self ts-algorithm)

!(import! &self "dashboard/comms.py")
!(import! &self dashboard/events)
!(import! &self perception)
!(import! &self rules)


!(bind! &kb              (new-space))
!(bind! &perceptionSpace (new-space))
!(bind! &modulatorSpace  (new-space))
!(bind! &ruleSpace       (new-space))
!(bind! &demandSpace     (new-space))


(= (kbInitializer $kb)
   (let* (
      ($rules     (collapse (get-atoms &ruleSpace)))
      ($modulators (collapse (get-atoms &modulatorSpace)))
      ($demands   (collapse (get-atoms &demandSpace)))
      ($partialKb (union-atom $rules $modulators))
      ($kbExp     (union-atom $partialKb $demands))
      ($_ (collapse (let $atom (superpose $kbExp) (add-atom $kb $atom))))
   ) ()))

(= (cognitiveStep)
   (let* (
      ($_ (updatePerception &perceptionSpace))
      ($_ (perceptionToDemands &perceptionSpace &demandSpace))

      ($demands (collapse (get-atoms &demandSpace)))
      ($_ (pushEvent Demand $demands))

      ($currDemand (getLeastSatisfiedDemandEpsilonGreedy &demandSpace 0.1))
      ($_ (println! (Selected-Demand: $currDemand)))

      ((demand $demandName $minVal $maxVal $demandValue) $currDemand)

      ($goalObj (openClawGoalSelector $demandName))
      ((Goal $goal $goalVal1 $goalVal2) $goalObj)
      ($_ (println! (Selected-Goal: $goal)))

      (($actions $id) (actionPlanner &ruleSpace $goal))
      ($_ (println! (Planned-Actions: $actions)))

      ($result (if (== $actions ())
         ()
         (performAction $actions)))

      ($_ (if (== $result ())
         ()
         (updateRule $id $result &ruleSpace)))
   )
   (Step Completed)))

(= (cognitiveLoop $maxSteps $currentStep)
   (if (> $currentStep $maxSteps)
      ()
      (let* (
         ($_ (println! (Step $currentStep / $maxSteps)))
         ($_ (cognitiveStep))
         ($_ (py-call (utils.sleepSeconds 1.0)))
      )
      (cognitiveLoop $maxSteps (+ $currentStep 1)))))

!(py-call (utils.connectToOpenClaw))
!(insert-modulators &modulatorSpace)
!(collapse (kbInitializer &kb))
!(cognitiveLoop 5 1)