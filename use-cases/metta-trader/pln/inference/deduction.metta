(= (pln-deduction $rules) (
    let* (
        ($_ (println! "PLN Deduction Started"))
        ($deductions (deduction-helper $rules))
    ) $deductions
))

(= (deduction-helper $rules) (
    if (<= (size-atom $rules) 1)
        ()
        (let* (
            (($rule $remRules) (decons-atom $rules))
            ($premise-one (eval (extractRule ContextSTV $rule)))
            ($premise-two (eval (extractRule GoalSTV $rule)))
            ($premise-four (eval (extractRule STV $rule)))
            ($premises ($premise-one $premise-two $premise-four))
            ; ($_ (println! ("Deduction premises: " $premise-one $premise-two $premise-four)))
            ($matchingRuleDeductions (eval (getMatchingPremises deduction $premises $rule $remRules)))
            ($restDeductions (deduction-helper $remRules))
        ) (union-atom $restDeductions $matchingRuleDeductions))
))

(= (reason-ded $rule $matchingRule $premises) (
    let* (
        ($randomNo 100) ;; TODO: Fix this
        ($ruleContext (eval (extractRule Context $rule)))
        ($matchingGoal (eval (extractRule Goal $matchingRule)))
        ($matchingGoalSTV (eval (extractRule GoalSTV $matchingRule)))

        ($ruleAction (eval (extractRule Action $rule)))
        ($ruleContextSTV (eval (extractRule ContextSTV $rule)))
        ($matchingRuleAction (eval (extractRule Action $matchingRule)))
        ($newRuleAction (union-atom $ruleAction $matchingRuleAction))

        ($premise-five (eval (extractRule STV $matchingRule)))
        ($premise-three (eval (extractRule GoalSTV $matchingRule)))
        (($premise-one $premise-two $premise-four) $premises)

        ($newRuleSTV (eval (deductionFormula $premise-one $premise-two $premise-three $premise-four $premise-five)))
        ($newRule (: Rule $randomNo (TTV 1) $newRuleSTV (Complexity 1) (IMPLICATION (AND (Context $ruleContextSTV (AND $ruleContext)) (Action (SEQ_AND $newRuleAction))) (Goal $matchingGoalSTV (AND $matchingGoal)))))
    ) $newRule
))

