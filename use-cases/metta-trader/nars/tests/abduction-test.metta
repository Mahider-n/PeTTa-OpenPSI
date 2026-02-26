!(import! &self ../inference/converter)
!(import! &self ../inference/query)
!(import! &self ../inference/inference-rules)
!(import! &self ../inference/reasoning-helper)
!(import! &self ../inference/rule-helpers)
!(import! &self helpers)

!(bind! &ruleSpace (new-space))

(= (addRuleAbd $ruleSpace) ( 
    let $rules (superpose (
    ;; Rule 1
    (: Rule 1
        (TTV 0)
        (STV 0.5 0.002)  
        (Complexity 1)
        (IMPLICATION
            (AND 
                (Context (STV 0.2 0.1) (AND (
                    (LEFT_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))))
                (Action (SEQ_AND (MOVE_RIGHT))))
            (Goal (STV 0.2 0.1) (AND (
                    (CENTER_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))
        )) 
    ))

    ;; Rule 3
    (: Rule 3
        (TTV 0)
        (STV 0.5 0.002)  
        (Complexity 1)
        (IMPLICATION 
            (AND 
                (Context (STV 0.2 0.1) (AND (
                    (RIGHT_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))))
                (Action (SEQ_AND (MOVE_LEFT))))
            (Goal (STV 0.2 0.1) (AND (
                    (CENTER_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))
        )) 
    ))

    ;; Rule 2
    (: Rule 2
        (TTV 0)
        (STV 0.5 0.002)  
        (Complexity 1)
        (IMPLICATION 
            (AND 
                (Context (STV 0.2 0.1) (AND (
                    (CENTER_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))))
                (Action (SEQ_AND (MOVE_RIGHT))))
            (Goal (STV 0.2 0.1) (AND (
                    (RIGHT_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))
        )) 
    ))

    )) (add-atom $ruleSpace $rules)
))

!(addRuleAbd &ruleSpace)
;;!(collapse (get-atoms &ruleSpace))
;;!(applyAbductionNars (collapse (get-atoms &ruleSpace)))
!(let* (
    ($results (applyAbductionNars (collapse (get-atom &ruleSpace))))
    ($result (car-atom $results))
    ($judgement (areEqualRules $result (: Rule 2603 (TTV 0) (STV 0.5 0.01) (Complexity 1) (IMPLICATION (AND (Context (STV 0.2 0.1) (AND ((LEFT_SQUARE (STV 0.2 0.1)) (STILL_ALIVE (STV 0.2 0.1))))) (Action (SEQ_AND (MOVE_RIGHT)))) (Goal (STV 0.2 0.1) (AND ((RIGHT_SQUARE (STV 0.2 0.1)) (STILL_ALIVE (STV 0.2 0.1)))))))))
)
    (test $judgement true)
)
