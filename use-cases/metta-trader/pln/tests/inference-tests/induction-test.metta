!(import! &self ../../inference/induction)
!(import! &self ../../formula)
!(import! &self ../../utils)

!(import! &self ../../rule/query)
!(import! &self ../../rule/inference-utils)
!(import! &self ../../rule/helpers)

!(bind! &ruleSpace (new-space))

(= (addRule $ruleSpace) ( 
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
                    (LEFT_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))))
                (Action (SEQ_AND (MOVE_RIGHT))))
            (Goal (STV 0.2 0.1) (AND (
                    (CENTER_SQUARE (STV 0.2 0.1))
                    (DEAD (STV 0.2 0.1)))
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
                (Action (SEQ_AND (MOVE_RIGHT)) ) )
            (Goal (STV 0.2 0.1) (AND (
                    (RIGHT_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))
        )) 
    ))

    )) (add-atom $ruleSpace $rules)
))


!(addRule &ruleSpace)

!(test (pln-induction (collapse(get-atoms &ruleSpace))) ((: Rule 100 (TTV 1) (STV 0.3125 0.001996007984031936) (Complexity 1) (IMPLICATION (AND (Context (STV 0.2 0.1) (AND ((CENTER_SQUARE (STV 0.2 0.1)) (DEAD (STV 0.2 0.1))))) (Action (SEQ_AND (MOVE_RIGHT)))) (Goal (STV 0.2 0.1) (AND ((CENTER_SQUARE (STV 0.2 0.1)) (STILL_ALIVE (STV 0.2 0.1)))))))))