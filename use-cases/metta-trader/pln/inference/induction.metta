(= (pln-induction $rules) (
    let* (
        ($_ (println! "PLN Induction Started"))
        ($inductions (induction-helper $rules))
    ) $inductions
))

(= (induction-helper $rules) (
    if (<= (size-atom $rules) 1)
        ()
        (let* (
            (($rule $remRules) (decons-atom $rules))
            ($premise-one (eval (extractRule GoalSTV $rule)))
            ($premise-two (eval (extractRule ContextSTV $rule)))
            ($premise-four (eval (extractRule STV $rule)))
            ($premises ($premise-one $premise-two $premise-four))
            ($matchingRuleAbductions (eval (getMatchingPremises induction $premises $rule $remRules)))
            ($restAbductions (induction-helper $remRules))
        ) (union-atom $restAbductions $matchingRuleAbductions))
))

(= (reason-ind $rule $matchingRule $premises) (
    let* (
        ($randomNo 100) ;; TODO: Fix this
        ($ruleContext (eval (extractRule Context $rule)))
        ($ruleGoal (eval (extractRule Goal $rule)))
        ($matchingContext (eval (extractRule Context $matchingRule)))
        ($matchingGoal (eval (extractRule Goal $matchingRule)))
        ($matchingGoalSTV (eval (extractRule GoalSTV $matchingRule)))

        ($ruleAction (eval (extractRule Action $rule)))
        ($ruleContextSTV (eval (extractRule ContextSTV $rule)))
        ($ruleGoalSTV (eval (extractRule GoalSTV $rule)))
        ($matchingRuleAction (eval (extractRule Action $matchingRule)))
        ($newRuleAction (union-atom $ruleAction $matchingRuleAction))

        (($premise-one $premise-two $premise-four) $premises)
        ($premise-three (eval (extractRule GoalSTV $matchingRule)))
        ($premise-five (eval (extractRule STV $matchingRule)))
        
        ($newRuleSTV (eval (inductionFormula $premise-one $premise-two $premise-three $premise-four $premise-five)))
        ($newRule (: Rule $randomNo (TTV 1) $newRuleSTV (Complexity 1) (IMPLICATION (AND (Context $matchingGoalSTV (AND $matchingGoal)) (Action (SEQ_AND $matchingRuleAction))) (Goal $ruleGoalSTV (AND $ruleGoal)))))

        ;; The inverse can be applied.
    ) $newRule
))

