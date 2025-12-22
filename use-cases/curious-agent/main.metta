!(import! &self ../../main/feedback-loop/feedback-loop)
!(import! &self ../curious-agent/setup-kb)
!(import! &self "./util.py")

; ;; This function implements the kb-initializer for the open-psi loop to work
(= (kb-initializer $kb)
   (let* 
     (
      ($rules (collapse (get-atoms &ruleSpace)))
      ($modulators (collapse (get-atoms &modulator-space)))
      ($demands (collapse (get-atoms &demandspace)))
      ($_ (println! (demands in kb init $demands)))
      ($partialKb (union-atom $rules $modulators))
      ($kbExp (union-atom $partialKb $demands))
      ($_ (collapse (let $atom (superpose $kbExp) (add-atom $kb $atom))))
    )
    ()
	)
)

(= (computeEmotionVals $userInput $emotionVals) 
   (let* (
        ($response (py-call (util.generateResponse $userInput $emotionVals)))
        ($summary (extractSummary $response))
        ($rules (collapse (get-atoms &ruleSpace)))
        ($rule (py-call (util.correlation_matcher $summary $rules $userInput)))
        ($_ (println! (MATCHED RULE $rule)))
        (((: $handle ($tv (IMPLICATION_LINK (AND_LINK (((Goal $context $x $y)) $action)) $goal))) $wght) $rule)
        ($_ (println! (CONTEXT -> $context)))
        ($emotion (psi-agent-loop $context &kb))
        ($_ (println! (EMOTION VALUES $emotion)))
      )
     $emotion
    )
   )

(= (mainLoop $emotionVals)
     (let* (
            ($userInput (py-call (util.getUserInput)))
            ($emotionValStr (py-call (util.parseEmotionVals $emotionVals)))
            ; ($_ (py-call (util.visualizeEmotionValues $emotionValStr)))   
            )
            (if (== $userInput "exit")
              Goodbye!
              (let $updatedEmotionVals (computeEmotionVals $userInput $emotionValStr) (println! (UPDATED_VALS $updatedEmotionVals)))
            )
      )
   )

;; Alternative main loop for speech-only mode
(= (mainLoopSpeech $emotionVals)
     (let* (
            ($userInput (py-call util.getSpeechInput ("Speak your message:")))
            ($_ (py-call util.visualizeEmotionValues $emotionVals))   
            )
            (if (== $userInput "")
              (mainLoopSpeech $emotionVals)  ;; Continue listening if no speech detected
              (if (== $userInput "exit")
                Goodbye!
                (let $updatedEmotionVals (computeEmotionVals $userInput $emotionVals) (mainLoopSpeech $updatedEmotionVals))
              )
            )
      )
   )

;; (interactive mode removed)

(= (extractSummary $response) 
   (let* (
          ($summary (py-call (getattr $response summary "")))
        )
        $summary
     )
   )

;; Startup function to choose input mode
(= (startCuriousAgent $emotionVals)
   (let* (
          ($mode (py-call (util.chooseInputMode)))
          (() (println! $mode))
        )
        (if (== $mode "text")
          (mainLoop $emotionVals)
          (if (== $mode "speech")
            (mainLoopSpeech $emotionVals)
            (mainLoop $emotionVals)  ;; default fallback
          )
        )
   )
)

!(collapse (addDemandGoalRels &self))
!(collapse (populateRuleSpace &ruleSpace))
!(collapse (populateDemandSpace &demandspace))
!(collapse (insert-modulators &modulator-space))
!(kb-initializer &kb)

!(psi-agent-loop Acknowledge-Greeting &kb)
