(= (pln-reasoning $rules) 
    (if (<= (size-atom $rules) 1)
        ()
    (let* (
        ;($abductionResults (eval (pln-abduction $rules)))
        ($conjunctionResults (eval (pln-conjunction $rules)))
        ($deductionResults (eval (pln-deduction $rules)))
        ;($inductionResults (eval (pln-induction $rules)))
        ($abductionResults ())
        ($inductionResults ())
    

        ; ($_ (println! (Abduction Results: $abductionResults)))
        ; ($_ (println! (Conjunction Results: $conjunctionResults)))
        ; ($_ (println! (Deduction Results: $deductionResults)))
        ; ($_ (println! (Induction Results: $inductionResults)))
        
        ($reasonedRules (eval (flattenList ($deductionResults $conjunctionResults $abductionResults $inductionResults))))
        
        
        ;; Give them unique IDs, TTV, and Complexity
        ($prevRuleId (eval (getLatestRuleId $rules)))
        ($prevTTV (eval (getCurrentTimeCycle $rules)))
        ($currRuleId (+ 1 $prevRuleId))
        ($currTTV (+ 1 $prevTTV))
        ($_ (println! (reasonedRulesIn $reasonedRules)))
        ($s_ (println! (rulePln $rules)))
        ($_ (println! (prevRuleId $prevRuleId prevTTV $prevTTV currRuleId $currRuleId currTTV $currTTV)))
        
        ($newRules (eval (processRules $reasonedRules $currRuleId $currTTV)))
    ) $newRules

)))