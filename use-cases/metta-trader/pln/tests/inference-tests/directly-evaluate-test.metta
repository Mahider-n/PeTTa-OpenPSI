!(import! &self directly-evaluate)
!(import! &self utils:util)
!(import! &self utils:rule-ops)
!(import! &self utils:directly-evaluate-utils)

;; ============================================================================
;; Test Setup: Create Percepta Space with Historical Observations
;; ============================================================================

!(bind! &perceptaSpace (new-space))

;; Add observations from agent's history
!(add-atom &perceptaSpace (: Percepta 0 (LEFT_SQUARE STILL_ALIVE)))
!(add-atom &perceptaSpace (: Percepta 1 (CENTER_SQUARE STILL_ALIVE)))
!(add-atom &perceptaSpace (: Percepta 2 (LEFT_SQUARE STILL_ALIVE)))
!(add-atom &perceptaSpace (: Percepta 3 (CENTER_SQUARE DEAD)))
!(add-atom &perceptaSpace (: Percepta 4 (LEFT_SQUARE STILL_ALIVE)))
!(add-atom &perceptaSpace (: Percepta 5 (RIGHT_SQUARE STILL_ALIVE)))
!(add-atom &perceptaSpace (: Percepta 6 (CENTER_SQUARE STILL_ALIVE)))
!(add-atom &perceptaSpace (: Percepta 7 (LEFT_SQUARE DEAD)))
!(add-atom &perceptaSpace (: Percepta 8 (RIGHT_SQUARE DEAD)))
!(add-atom &perceptaSpace (: Percepta 9 (CENTER_SQUARE STILL_ALIVE)))

!(bind! &ruleSpace (new-space))

;; Result: 3 match out of 10 observations = 0.3 frequency
!(add-atom &ruleSpace (: Rule 3
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
)))

!(pln-directly-evaluate &ruleSpace &perceptaSpace)