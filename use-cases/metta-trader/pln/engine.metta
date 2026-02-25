(= (pln-reasoning $rules) (
    let* (
        ($abductionResults (eval (pln-abduction $rules)))
        ($conjunctionResults (eval (pln-conjunction $rules)))
        ($deductionResults (eval (pln-deduction $rules)))
        ($inductionResults (eval (pln-induction $rules)))

        ($reasonedRules (eval (flattenList ($deductionResults $conjunctionResults $abductionResults $inductionResults))))
        
        ;; Give them unique IDs, TTV, and Complexity
        ($prevRuleId (eval (getLatestRuleId $rules)))
        ($prevTTV (eval (getCurrentTimeCycle $rules)))
        ($currRuleId (+ 1 $prevRuleId))
        ($currTTV (+ 1 $prevTTV))
        
        ($newRules (eval (processRules $reasonedRules $currRuleId $currTTV)))
    ) $newRules
))