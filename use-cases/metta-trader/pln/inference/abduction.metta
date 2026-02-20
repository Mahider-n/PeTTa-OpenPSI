(= (pln-abduction $rules) (
    let* (
        ($_ (println! "PLN Abduction Started"))
        ($abductions (abduction-helper $rules))
    ) $abductions
))

(= (abduction-helper $rules) (
    if (<= (size-atom $rules) 1)
        ()
        (let* (
            (($rule $remRules) (decons-atom $rules))
            ($premise-one (eval (extractRule ContextSTV $rule)))
            ($premise-two (eval (extractRule GoalSTV $rule)))
            ($premise-four (eval (extractRule STV $rule)))
            ($premises ($premise-one $premise-two $premise-four))
            ($matchingRuleAbductions (eval (getMatchingPremises abduction $premises $rule $remRules)))
            ($restAbductions (abduction-helper $remRules))
        ) (union-atom $restAbductions $matchingRuleAbductions))
))

(= (reason-abd $rule $matchingRule $premises) (
    let* (
        ($randomNo 100) ;; TODO: Fix this
        ($ruleContext (eval (extractRule Context $rule)))
        ($matchingContext (eval (extractRule Context $matchingRule)))
        ($matchingGoal (eval (extractRule Goal $matchingRule)))
        ($matchingGoalSTV (eval (extractRule GoalSTV $matchingRule)))

        ($ruleAction (eval (extractRule Action $rule)))
        ($ruleContextSTV (eval (extractRule ContextSTV $rule)))
        ($matchingRuleAction (eval (extractRule Action $matchingRule)))
        ($newRuleAction (union-atom $ruleAction $matchingRuleAction))

        (($premise-one $premise-two $premise-four) $premises)
        ($premise-three (eval (extractRule ContextSTV $matchingRule)))
        ($premise-five (eval (extractRule STV $matchingRule)))

        ($newRuleSTV (eval (abductionFormula $premise-one $premise-two $premise-three $premise-four $premise-five)))

        ($newRule (: Rule $randomNo (TTV 1) $newRuleSTV (Complexity 1) (IMPLICATION (AND (Context $ruleContextSTV (AND $matchingContext)) (Action (SEQ_AND $matchingRuleAction))) (Goal $matchingGoalSTV (AND $ruleContext)))))
    ) $newRule
))

