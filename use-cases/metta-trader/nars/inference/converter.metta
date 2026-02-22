(= (convertRuleToPSI $rule)
    (let* (
        ($id (random-int 2000 3000)) ;; temporary ID generation
        (((($context $action) --> $goal) ($freq $conf)) $rule)
        ($lbConf (max 0.01 $conf)) ;; due to arthmetic issues, I set a lower bound for confidence
        

        ($complexity (size-atom $action))
    )
      (: Rule $id 
        (TTV 0)
        (STV $freq $lbConf)
        (Complexity $complexity)
        (IMPLICATION 
            (AND 
                (Context 
                    (STV 0.2 0.1) 
                    (AND $context)
                )
                (Action (SEQ_AND $action)))
            (Goal 
                (STV 0.2 0.1) 
                (AND $goal)
            )
        )))
)

(= (convertRulesToPSI $rules) (collapse (convertRuleToPSI (superpose $rules))))


;; Description
;; Changes these rules to nars representation (narsese)
(= (convertRuleToNars $rule) 
    (let* (
      ($context (eval (extractRule Context $rule)))
      ($action (eval (extractRule Action $rule)))
      ($goal (eval (extractRule Goal $rule)))
      ($STV (eval (extractRule STV $rule)))
      ((STV $freq $conf) $STV)

      ($id (eval (extractRule Id $rule)))
    )
      ($id ((($context $action) --> $goal) ($freq $conf))) 
    )
)