!(import! &self ../rule-ops)
!(import! &self ../world)
!(import! &self ../utils)
(= (TravelRule) 
        (: Rule 1
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
        ))
)

;; Travel Rule Tests
!(test (applyTravel (TravelRule) (((PLANET A) (STV 0.2 0.1)) ((HAS FOOD) (STV 0.2 0.1))) 10) ((((PLANET B) (STV 0.2 0.1)) ((HAS FOOD) (STV 0.2 0.1))) 9))
!(test (applyTravel (TravelRule) (((PLANET A) (STV 0.2 0.1))) 10) ((((PLANET B) (STV 0.2 0.1))) 9))

(= (BuyRule) 
        (: Rule 9
            (TTV 0)
            (STV 0.5 0.002)
            (Complexity 1)
            (IMPLICATION
                (AND
                    (Context (STV 0.2 0.1) (AND (((PLANET C) (STV 0.2 0.1)))))
                    (Action (SEQ_AND ((BUY FOOD))))
                )
                (Goal (STV 0.2 0.1) (AND (
                    ((PLANET C) (STV 0.2 0.1))
                    ((HAS FOOD) (STV 0.2 0.1))
                )))
        ))
)

;; Buy Rule Tests: It buys food in this case
!(test (applyBuy (BuyRule) (((PLANET C) (STV 0.2 0.1))) 100) ((((PLANET C) (STV 0.2 0.1)) ((HAS FOOD) (STV 0.2 0.1))) 82))
!(test (applyBuy (BuyRule) (((PLANET C) (STV 0.2 0.1)) ((HAS FOOD) (STV 0.1 0.1))) 100) ((((PLANET C) (STV 0.2 0.1)) ((HAS FOOD) (STV 0.2 0.1))) 82))
!(test (applyBuy (BuyRule) (((PLANET C) (STV 0.2 0.1)) ((HAS FUEL) (STV 0.1 0.1))) 100) ((((PLANET C) (STV 0.2 0.1)) ((HAS FUEL) (STV 0.1 0.1)) ((HAS FOOD) (STV 0.2 0.1))) 82))




(= (SellRule)         
        (: Rule 16
            (TTV 0)
            (STV 0.5 0.002)
            (Complexity 1)
            (IMPLICATION
                (AND
                    (Context (STV 0.2 0.1) (AND (
                        ((PLANET A) (STV 0.2 0.1))
                        ((HAS FOOD) (STV 0.1 0.1))
                    )))
                    (Action (SEQ_AND ((SELL FOOD))))
                )
                (Goal (STV 0.2 0.1) (AND (
                    ((PLANET A) (STV 0.2 0.1))
                )))
        ))
)

;; Sell Rule Tests: It sells food in this case
!(test (applySell (SellRule) (((PLANET A) (STV 0.2 0.1)) ((HAS FOOD) (STV 0.1 0.1))) 10) ((((PLANET A) (STV 0.2 0.1))) 18))
!(test (applySell (SellRule) (((PLANET A) (STV 0.2 0.1)) ((HAS FOOD) (STV 0.1 0.1))) 0) ((((PLANET A) (STV 0.2 0.1))) 8))