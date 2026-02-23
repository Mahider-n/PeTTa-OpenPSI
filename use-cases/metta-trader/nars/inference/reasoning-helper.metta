
(= (getMatchingPremisesNars $type $premises $rule $remRules) (
    let* (
        ($ruleGoal (extractRule GoalValues $rule))
        ; ($_ (println! ("Rule Goal: " $ruleGoal)))
        ($ruleContextAction (extractRule ContextAndAction $rule))
        ; ($_ (println! ("Rule Context and Action: " $ruleContextAction)))
        ; ($_ (println! ("Remaining Rules: " (collapse (get-atoms &ruleSpace)))))
        ($matchingRules (case $type (
            (abduction (eval (filter-rules-by-goal $ruleGoal $remRules)))
            (deduction (eval (filter-rules-by-context $ruleGoal $remRules)))
            (induction (eval (filter-rules-by-antecedent $ruleContextAction $remRules)))
            (exemplification (eval (filter-rules-by-context $ruleGoal $remRules)))
            ($default ())
        )))
    ) (
        if (== $type deduction)
            (map-atom $matchingRules $matchingRule (reasonDed $rule $matchingRule $premises))
            (if (== $type abduction)
                (map-atom $matchingRules $matchingRule (reasonAbd $rule $matchingRule $premises))
                (if (== $type induction)
                    (map-atom $matchingRules $matchingRule (reasonInd $rule $matchingRule $premises))
                    (if (== $type exemplification)
                        (map-atom $matchingRules $matchingRule (reasonExe $rule $matchingRule $premises))
                        (empty)
                    )
                ))
    )
))


(= (applyDeductionNars $rules) (
    if (<= (size-atom $rules) 1)
        ()
        (let* (
            (($rule $remRules) (decons-atom $rules))
            ($premise-one (eval (extractRule ContextSTV $rule)))
            ($premise-two (eval (extractRule GoalSTV $rule)))
            ($premise-four (eval (extractRule STV $rule)))
            ($premises ($premise-one $premise-two $premise-four))
            ($matchingRuleDeductions (getMatchingPremisesNars deduction $premises $rule $remRules))
            ($restDeductions (applyDeductionNars $remRules))
        ) (union-atom $restDeductions $matchingRuleDeductions))
))

(= (reasonDed $rule $matchingRule $premises) (
    let* (
        (($id1 $narsRule) (convertRuleToNars $rule))
        (($id2 $narsMatchingRule) (convertRuleToNars $matchingRule))
        ; ($_ (println! ("Reasoning with rule: " $narsRule)))
        ; ($_ (println! ("Reasoning with matching rule: " $narsMatchingRule)))
        ($inferenceResult (eval (deductionResp $narsRule $narsMatchingRule)))
        ; ($_ (println! ("Inference result: " $inferenceResult)))
    ) (convertRuleToPSI $inferenceResult)
))


(= (reasonAbd $rule $matchingRule $premises) (
    let* (
        (($id1 $narsRule) (convertRuleToNars $rule))
        (($id2 $narsMatchingRule) (convertRuleToNars $matchingRule))
        ($inferenceResult (eval (abductionResp $narsRule $narsMatchingRule)))
    ) (convertRuleToPSI $inferenceResult)
))


(= (reasonInd $rule $matchingRule $premises) (
    let* (
        (($id1 $narsRule) (convertRuleToNars $rule))
        (($id2 $narsMatchingRule) (convertRuleToNars $matchingRule))
        ($inferenceResult (eval (inductionResp $narsRule $narsMatchingRule)))
    ) (convertRuleToPSI $inferenceResult)
))


(= (reasonExe $rule $matchingRule $premises) (
    let* (
        (($id1 $narsRule) (convertRuleToNars $rule))
        (($id2 $narsMatchingRule) (convertRuleToNars $matchingRule))
        ($inferenceResult (eval (exemplificationResp $narsRule $narsMatchingRule)))
    ) (convertRuleToPSI $inferenceResult)
))


(= (applyInductionNars $rules) (
    if (<= (size-atom $rules) 1)
        ()
        (let* (
            (($rule $remRules) (decons-atom $rules))
            ($premise-one (eval (extractRule ContextSTV $rule)))
            ($premise-two (eval (extractRule GoalSTV $rule)))
            ($premise-four (eval (extractRule STV $rule)))
            ($premises ($premise-one $premise-two $premise-four))
            ($matchingRuleInductions (eval (getMatchingPremisesNars induction $premises $rule $remRules)))
            ($restInductions (applyInductionNars $remRules))
        ) (union-atom $restInductions $matchingRuleInductions))
))


(= (applyAbductionNars $rules) (
    if (<= (size-atom $rules) 1)
        ()
        (let* (
            ($_ (println! (abduction started)))
            (($rule $remRules) (decons-atom $rules))
            ($premise-one (eval (extractRule ContextSTV $rule)))
            ($premise-two (eval (extractRule GoalSTV $rule)))
            ($premise-four (eval (extractRule STV $rule)))
            ($premises ($premise-one $premise-two $premise-four))
            ($_ (println! (premises $premises)))
            ($matchingRuleAbductions (eval (getMatchingPremisesNars abduction $premises $rule $remRules)))
            ($restAbductions (applyAbductionNars $remRules))
        ) (union-atom $restAbductions $matchingRuleAbductions))
))

(= (applyExemplificationNars $rules) (
    if (<= (size-atom $rules) 1)
        ()
        (let* (
            (($rule $remRules) (decons-atom $rules))
            ($premise-one (eval (extractRule ContextSTV $rule)))
            ($premise-two (eval (extractRule GoalSTV $rule)))
            ($premise-four (eval (extractRule STV $rule)))
            ($premises ($premise-one $premise-two $premise-four))
            ($matchingRuleExemplifications (eval (getMatchingPremisesNars exemplification $premises $rule $remRules)))
            ($restExemplifications (applyExemplificationNars $remRules))
        ) (union-atom $restExemplifications $matchingRuleExemplifications))
))