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
        ($summary (py-call (util.extractVal summary $response)))
        ($rules (collapse (get-atoms &ruleSpace)))
        ($context (py-call (util.correlation_matcher $summary $rules $userInput)))
        ($emotion (psi-agent-loop $context &kb))
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
              (let $updatedEmotionVals (computeEmotionVals $userInput $emotionValStr) (mainLoop $updatedEmotionVals))
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

!(mainLoop (happinessValue 0.5 sadnessValue 0.039 angerValue 0.5 fearValue 0.04 gratitudeValue 0.6))
