!(import! &self ../inference/deduction)
!(import! &self ../inference/induction)
!(import! &self ../inference/abduction)
!(import! &self ../inference/conjunction)
!(import! &self ../formula)
!(import! &self ../utils)
!(import! &self ../engine)

!(import! &self ../rule/query)
!(import! &self ../rule/inference-utils)
!(import! &self ../rule/helpers)

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
                    (Action (SEQ_AND (MOVE_LEFT))))
                (Goal (STV 0.2 0.1) (AND (
                    (LEFT_SQUARE (STV 0.2 0.1))
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
                    (Action (SEQ_AND (MOVE_UP))))
                (Goal (STV 0.2 0.1) (AND (
                    (LEFT_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))
            ))
        ))
        ;; Rule 4
        (: Rule 4
            (TTV 0)
            (STV 0.5 0.002)
            (Complexity 1)
            (IMPLICATION
                (AND
                    (Context (STV 0.2 0.1) (AND (
                        (LEFT_SQUARE (STV 0.2 0.1))
                        (STILL_ALIVE (STV 0.2 0.1)))))
                    (Action (SEQ_AND (MOVE_DOWN))))
                (Goal (STV 0.2 0.1) (AND (
                    (LEFT_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))
            ))
        ))
        ;; Rule 5
        (: Rule 5
            (TTV 0)
            (STV 0.5 0.002)
            (Complexity 1)
            (IMPLICATION
                (AND
                    (Context (STV 0.2 0.1) (AND (
                        (CENTER_SQUARE (STV 0.2 0.1))
                        (STILL_ALIVE (STV 0.2 0.1)))))
                    (Action (SEQ_AND (MOVE_LEFT))))
                (Goal (STV 0.2 0.1) (AND (
                    (LEFT_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))
            ))
        ))
        ;; Rule 6
        (: Rule 6
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
        ;; Rule 7
        (: Rule 7
            (TTV 0)
            (STV 0.5 0.002)
            (Complexity 1)
            (IMPLICATION
                (AND
                    (Context (STV 0.2 0.1) (AND (
                        (CENTER_SQUARE (STV 0.2 0.1))
                        (STILL_ALIVE (STV 0.2 0.1)))))
                    (Action (SEQ_AND (MOVE_UP))))
                (Goal (STV 0.2 0.1) (AND (
                    (UP_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))
            ))
        ))
        ;; Rule 8
        (: Rule 8
            (TTV 0)
            (STV 0.5 0.002)
            (Complexity 1)
            (IMPLICATION
                (AND
                    (Context (STV 0.2 0.1) (AND (
                        (CENTER_SQUARE (STV 0.2 0.1))
                        (STILL_ALIVE (STV 0.2 0.1)))))
                    (Action (SEQ_AND (MOVE_DOWN))))
                (Goal (STV 0.2 0.1) (AND (
                    (DOWN_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))
            ))
        ))
        ;; Rule 9
        (: Rule 9
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
        ;; Rule 10
        (: Rule 10
            (TTV 0)
            (STV 0.5 0.002)
            (Complexity 1)
            (IMPLICATION
                (AND
                    (Context (STV 0.2 0.1) (AND (
                        (RIGHT_SQUARE (STV 0.2 0.1))
                        (STILL_ALIVE (STV 0.2 0.1)))))
                    (Action (SEQ_AND (MOVE_RIGHT))))
                (Goal (STV 0.2 0.1) (AND (
                    (RIGHT_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))
            ))
        ))
        ;; Rule 11
        (: Rule 11
            (TTV 0)
            (STV 0.5 0.002)
            (Complexity 1)
            (IMPLICATION
                (AND
                    (Context (STV 0.2 0.1) (AND (
                        (RIGHT_SQUARE (STV 0.2 0.1))
                        (STILL_ALIVE (STV 0.2 0.1)))))
                    (Action (SEQ_AND (MOVE_UP))))
                (Goal (STV 0.2 0.1) (AND (
                    (RIGHT_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))
            ))
        ))
        ;; Rule 12
        (: Rule 12
            (TTV 0)
            (STV 0.5 0.002)
            (Complexity 1)
            (IMPLICATION
                (AND
                    (Context (STV 0.2 0.1) (AND (
                        (RIGHT_SQUARE (STV 0.2 0.1))
                        (STILL_ALIVE (STV 0.2 0.1)))))
                    (Action (SEQ_AND (MOVE_DOWN))))
                (Goal (STV 0.2 0.1) (AND (
                    (RIGHT_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))
            ))
        ))
        ;; Rule 13
        (: Rule 13
            (TTV 0)
            (STV 0.5 0.002)
            (Complexity 1)
            (IMPLICATION
                (AND
                    (Context (STV 0.2 0.1) (AND (
                        (UP_SQUARE (STV 0.2 0.1))
                        (STILL_ALIVE (STV 0.2 0.1)))))
                    (Action (SEQ_AND (MOVE_LEFT))))
                (Goal (STV 0.2 0.1) (AND (
                    (UP_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))
            ))
        ))
        ;; Rule 14
        (: Rule 14
            (TTV 0)
            (STV 0.5 0.002)
            (Complexity 1)
            (IMPLICATION
                (AND
                    (Context (STV 0.2 0.1) (AND (
                        (UP_SQUARE (STV 0.2 0.1))
                        (STILL_ALIVE (STV 0.2 0.1)))))
                    (Action (SEQ_AND (MOVE_RIGHT))))
                (Goal (STV 0.2 0.1) (AND (
                    (UP_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))
            ))
        ))
        ;; Rule 15
        (: Rule 15
            (TTV 0)
            (STV 0.5 0.002)
            (Complexity 1)
            (IMPLICATION
                (AND
                    (Context (STV 0.2 0.1) (AND (
                        (UP_SQUARE (STV 0.2 0.1))
                        (STILL_ALIVE (STV 0.2 0.1)))))
                    (Action (SEQ_AND (MOVE_UP))))
                (Goal (STV 0.2 0.1) (AND (
                    (UP_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))
            ))
        ))
        ;; Rule 16
        (: Rule 16
            (TTV 0)
            (STV 0.5 0.002)
            (Complexity 1)
            (IMPLICATION
                (AND
                    (Context (STV 0.2 0.1) (AND (
                        (UP_SQUARE (STV 0.2 0.1))
                        (STILL_ALIVE (STV 0.2 0.1)))))
                    (Action (SEQ_AND (MOVE_DOWN))))
                (Goal (STV 0.2 0.1) (AND (
                    (CENTER_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))
            ))
        ))
        ;; Rule 17
        (: Rule 17
            (TTV 0)
            (STV 0.5 0.002)
            (Complexity 1)
            (IMPLICATION
                (AND
                    (Context (STV 0.2 0.1) (AND (
                        (DOWN_SQUARE (STV 0.2 0.1))
                        (STILL_ALIVE (STV 0.2 0.1)))))
                    (Action (SEQ_AND (MOVE_LEFT))))
                (Goal (STV 0.2 0.1) (AND (
                    (DOWN_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))
            ))
        ))
        ;; Rule 18
        (: Rule 18
            (TTV 0)
            (STV 0.5 0.002)
            (Complexity 1)
            (IMPLICATION
                (AND
                    (Context (STV 0.2 0.1) (AND (
                        (DOWN_SQUARE (STV 0.2 0.1))
                        (STILL_ALIVE (STV 0.2 0.1)))))
                    (Action (SEQ_AND (MOVE_RIGHT))))
                (Goal (STV 0.2 0.1) (AND (
                    (DOWN_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))
            ))
        ))
        ;; Rule 19
        (: Rule 19
            (TTV 0)
            (STV 0.5 0.002)
            (Complexity 1)
            (IMPLICATION
                (AND
                    (Context (STV 0.2 0.1) (AND (
                        (DOWN_SQUARE (STV 0.2 0.1))
                        (STILL_ALIVE (STV 0.2 0.1)))))
                    (Action (SEQ_AND (MOVE_UP))))
                (Goal (STV 0.2 0.1) (AND (
                    (CENTER_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))
            ))
        ))
        ;; Rule 20
        (: Rule 20
            (TTV 0)
            (STV 0.5 0.002)
            (Complexity 1)
            (IMPLICATION
                (AND
                    (Context (STV 0.2 0.1) (AND (
                        (DOWN_SQUARE (STV 0.2 0.1))
                        (STILL_ALIVE (STV 0.2 0.1)))))
                    (Action (SEQ_AND (MOVE_DOWN))))
                (Goal (STV 0.2 0.1) (AND (
                    (DOWN_SQUARE (STV 0.2 0.1))
                    (STILL_ALIVE (STV 0.2 0.1)))
            ))
        ))
    )) (add-atom $ruleSpace $rules)
))



!(addRule &ruleSpace)
!(pln-reasoning (collapse (get-atoms &ruleSpace)))