!(import! &self ../inference/query)
!(import! &self ../inference/converter)
!(import! &self helpers)
!(test (convertRuleToNars (: Rule 1
            (TTV 0)
            (STV 0.5 0.002)
            (Complexity 1)
            (IMPLICATION
                (AND
                    (Context (STV 0.2 0.1) (AND (
                        ((PLANET A) (STV 0.2 0.1))
                    )))
                    (Action (SEQ_AND ((TRAVEL))))
                )
                (Goal (STV 0.2 0.1) (AND (
                    ((PLANET B) (STV 0.2 0.1))
                )))
        ))) (1 ((((((PLANET A) (STV 0.2 0.1))) ((TRAVEL))) --> (((PLANET B) (STV 0.2 0.1)))) (0.5 0.002)))) 

;!(test 
!(test (areEqualRules (convertRuleToPSI ((((((PLANET A) (STV 0.2 0.1))) ((TRAVEL))) --> (((PLANET B) (STV 0.2 0.1)))) (0.5 0.002))) (: Rule 1
            (TTV 0)
            (STV 0.5 0.01)
            (Complexity 1)
            (IMPLICATION
                (AND
                    (Context (STV 0.2 0.1) (AND (
                        ((PLANET A) (STV 0.2 0.1))
                    )))
                    (Action (SEQ_AND ((TRAVEL))))
                )
                (Goal (STV 0.2 0.1) (AND (
                    ((PLANET B) (STV 0.2 0.1))
                )))
        ))) true) 
