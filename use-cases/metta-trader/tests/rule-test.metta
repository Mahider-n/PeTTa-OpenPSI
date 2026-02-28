
!(import! &self ../rule-ops)
!(import! &self ../world)
!(import! &self ../utils)

(= (TestRule) 
        (: Rule 22
            (TTV 0)
            (STV 0.5 0.002)
            (Complexity 1)
            (IMPLICATION
                (AND
                    (Context (STV 0.2 0.1) (AND (
                        ((PLANET A) (STV 0.2 0.1))
                    )))
                    (Action (SEQ_AND ((BUY FUEL))))
                )
                (Goal (STV 0.2 0.1) (AND (
                    ((PLANET A) (STV 0.2 0.1))
                    ((HAS FUEL) (STV 0.1 0.1))
                )))
        ))
)

!(test (isValidRule (((PLANET A) (STV 0.2 0.1))) 25 (TestRule)) True)
!(test (isValidRule (((PLANET A) (STV 0.2 0.1))) 24 (TestRule)) False)
