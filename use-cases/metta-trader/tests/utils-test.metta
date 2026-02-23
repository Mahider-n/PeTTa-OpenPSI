;; =============================================================================
;; Utils Test Suite — use-cases/metta-trader/utils.metta
;; =============================================================================
;; Comprehensive unit tests for every utility function used by the MeTTa-Trader
;; agent.
;; =============================================================================

;; ---- Imports ----------------------------------------------------------------
!(import! &self ../rule-ops)
!(import! &self ../world)
!(import! &self ../utils)

;; ---- Reusable test fixtures -------------------------------------------------

(= (testSTV) (STV 0.2 0.1))
(= (altSTV) (STV 0.8 0.8))
(= (itemSTV) (STV 0.1 0.1))

;; A minimal context: trader is on planet A carrying FOOD.
(= (ctxPlanetA) (
    ((PLANET A) (testSTV))
    ((HAS FOOD) (itemSTV))
))

;; Context on planet B with METAL.
(= (ctxPlanetB) (
    ((PLANET B) (testSTV))
    ((HAS METAL) (itemSTV))
))

;; Context on planet C — no items.
(= (ctxPlanetCEmpty) (
    ((PLANET C) (testSTV))
))

;; Context on planet A with multiple items.
(= (ctxPlanetAMultiItems) (
    ((PLANET A) (testSTV))
    ((HAS FOOD) (itemSTV))
    ((HAS FUEL) (altSTV))
))

;; ---- Rule fixtures ----------------------------------------------------------

;; Travel from A to B
(= (TravelRuleAB)
    (: Rule 1
        (TTV 0)
        (STV 0.5 0.002)
        (Complexity 1)
        (IMPLICATION
            (AND
                (Context (testSTV) (AND (
                    ((PLANET A) (testSTV))
                )))
                (Action (SEQ_AND ((TRAVEL))))
            )
            (Goal (testSTV) (AND (
                ((PLANET B) (testSTV))
            )))
    ))
)

;; Travel from B to C
(= (TravelRuleBC)
    (: Rule 2
        (TTV 0)
        (STV 0.5 0.002)
        (Complexity 1)
        (IMPLICATION
            (AND
                (Context (testSTV) (AND (
                    ((PLANET B) (testSTV))
                )))
                (Action (SEQ_AND ((TRAVEL))))
            )
            (Goal (testSTV) (AND (
                ((PLANET C) (testSTV))
            )))
    ))
)

;; Buy FOOD on planet A
(= (BuyFoodRuleA)
    (: Rule 7
        (TTV 0)
        (STV 0.5 0.002)
        (Complexity 1)
        (IMPLICATION
            (AND
                (Context (testSTV) (AND (((PLANET A) (testSTV)))))
                (Action (SEQ_AND ((BUY FOOD))))
            )
            (Goal (testSTV) (AND (
                ((PLANET A) (testSTV))
                ((HAS FOOD) (testSTV))
            )))
    ))
)

;; Buy FUEL on planet C
(= (BuyFuelRuleC)
    (: Rule 15
        (TTV 0)
        (STV 0.5 0.002)
        (Complexity 1)
        (IMPLICATION
            (AND
                (Context (testSTV) (AND (((PLANET C) (testSTV)))))
                (Action (SEQ_AND ((BUY FUEL))))
            )
            (Goal (testSTV) (AND (
                ((PLANET C) (testSTV))
                ((HAS FUEL) (testSTV))
            )))
    ))
)

;; Sell FOOD on planet A (requires HAS FOOD in context)
(= (SellFoodRuleA)
    (: Rule 16
        (TTV 0)
        (STV 0.5 0.002)
        (Complexity 1)
        (IMPLICATION
            (AND
                (Context (testSTV) (AND (
                    ((PLANET A) (testSTV))
                    ((HAS FOOD) (itemSTV))
                )))
                (Action (SEQ_AND ((SELL FOOD))))
            )
            (Goal (testSTV) (AND (
                ((PLANET A) (testSTV))
            )))
    ))
)

;; Sell METAL on planet B
(= (SellMetalRuleB)
    (: Rule 20
        (TTV 0)
        (STV 0.5 0.002)
        (Complexity 1)
        (IMPLICATION
            (AND
                (Context (testSTV) (AND (
                    ((PLANET B) (testSTV))
                    ((HAS METAL) (itemSTV))
                )))
                (Action (SEQ_AND ((SELL METAL))))
            )
            (Goal (testSTV) (AND (
                ((PLANET B) (testSTV))
            )))
    ))
)

;; Buy METAL on planet B (for planet-mismatch testing)
(= (BuyMetalRuleB)
    (: Rule 11
        (TTV 0)
        (STV 0.5 0.002)
        (Complexity 1)
        (IMPLICATION
            (AND
                (Context (testSTV) (AND (((PLANET B) (testSTV)))))
                (Action (SEQ_AND ((BUY METAL))))
            )
            (Goal (testSTV) (AND (
                ((PLANET B) (testSTV))
                ((HAS METAL) (testSTV))
            )))
    ))
)


;; =============================================================================
;; 1. getPlanetFromContexts
;; =============================================================================

;; 1.1  Planet is the first context entry
!(test (getPlanetFromContexts (((PLANET A) (testSTV)))) A)

;; 1.2  Planet is the first entry, followed by items
!(test (getPlanetFromContexts (((PLANET A) (testSTV)) ((HAS METAL) (itemSTV)))) A)

;; 1.3  Planet appears after an item entry — must still be found
!(test (getPlanetFromContexts (((HAS METAL) (itemSTV)) ((PLANET A) (testSTV)))) A)

;; 1.4  Different planets
!(test (getPlanetFromContexts (((PLANET B) (testSTV)))) B)
!(test (getPlanetFromContexts (((PLANET C) (altSTV)))) C)

;; 1.5  Multiple items before the planet
!(test (getPlanetFromContexts (((HAS FOOD) (itemSTV)) ((HAS FUEL) (altSTV)) ((PLANET C) (testSTV)))) C)


;; =============================================================================
;; 2. getItem  (single-argument overload — returns first item found)
;; =============================================================================

;; 2.1  Item is found as first entry
!(test (getItem (((HAS FOOD) (testSTV)) ((PLANET A) (testSTV)))) (FOOD (testSTV)))

;; 2.2  Item appears after the planet entry
!(test (getItem (((PLANET A) (testSTV)) ((HAS FOOD) (testSTV)))) (FOOD (testSTV)))

;; 2.3  Returns first item when multiple items present
!(test (getItem (((HAS FUEL) (altSTV)) ((HAS FOOD) (testSTV)) ((PLANET B) (testSTV)))) (FUEL (altSTV)))

;; 2.4  No items — returns empty tuple pair
!(test (getItem (((PLANET C) (testSTV)))) (() ()))


;; =============================================================================
;; 3. getItem  (two-argument overload — search for a specific item)
;; =============================================================================

;; 3.1  Target item present
!(test (getItem (((HAS FOOD) (testSTV)) ((PLANET A) (testSTV))) FOOD) (FOOD (testSTV)))

;; 3.2  Target item present but not first
!(test (getItem (((PLANET B) (testSTV)) ((HAS METAL) (altSTV))) METAL) (METAL (altSTV)))

;; 3.3  Target item absent — returns empty tuple pair
!(test (getItem (((PLANET A) (testSTV)) ((HAS FOOD) (testSTV))) FUEL) (() ()))

;; 3.4  Empty contexts — returns empty tuple pair
!(test (getItem () FOOD) (() ()))


;; =============================================================================
;; 4. updatePlanet
;; =============================================================================

;; 4.1  Simple single-context update
!(test (updatePlanet (((PLANET A) (testSTV))) B) (((PLANET B) (testSTV))))

;; 4.2  Update preserves item entries
!(test (updatePlanet (((PLANET A) (testSTV)) ((HAS FOOD) (testSTV))) B)
       (((PLANET B) (testSTV)) ((HAS FOOD) (testSTV))))

;; 4.3  Update preserves multiple items
!(test (updatePlanet (((PLANET A) (testSTV)) ((HAS FOOD) (itemSTV)) ((HAS FUEL) (altSTV))) C)
       (((PLANET C) (testSTV)) ((HAS FOOD) (itemSTV)) ((HAS FUEL) (altSTV))))

;; 4.4  Update to same planet (idempotent)
!(test (updatePlanet (((PLANET A) (testSTV))) A) (((PLANET A) (testSTV))))

;; 4.5  Empty contexts
!(test (updatePlanet () B) ())


;; =============================================================================
;; 5. addItem
;; =============================================================================

;; 5.1  Add item to context without any items
!(test (addItem ((PLANET A)) FOOD (testSTV))
       ((PLANET A) ((HAS FOOD) (testSTV))))

;; 5.2  Add item when a different item already exists
!(test (addItem ((PLANET A) ((HAS FUEL) (altSTV))) FOOD (testSTV))
       ((PLANET A) ((HAS FUEL) (altSTV)) ((HAS FOOD) (testSTV))))

;; 5.3  Add item replaces existing item of the same type (updated STV)
!(test (addItem ((PLANET A) ((HAS FOOD) (itemSTV))) FOOD (testSTV))
       ((PLANET A) ((HAS FOOD) (testSTV))))

;; 5.4  Add to empty context
!(test (addItem () FOOD (testSTV))
       (((HAS FOOD) (testSTV))))


;; =============================================================================
;; 6. removeItem
;; =============================================================================

;; 6.1  Remove existing item
!(test (removeItem (((HAS FOOD) (testSTV)) ((PLANET A) (testSTV))) FOOD)
       (((PLANET A) (testSTV))))

;; 6.2  Remove item that does not exist — contexts unchanged
!(test (removeItem (((HAS FUEL) (altSTV)) ((PLANET A) (testSTV))) FOOD)
       (((HAS FUEL) (altSTV)) ((PLANET A) (testSTV))))

;; 6.3  Remove from context with multiple items
!(test (removeItem (((HAS FOOD) (testSTV)) ((HAS FUEL) (altSTV)) ((PLANET B) (testSTV))) FOOD)
       (((HAS FUEL) (altSTV)) ((PLANET B) (testSTV))))

;; 6.4  Remove from context with only a planet — no change
!(test (removeItem (((PLANET A) (testSTV))) FOOD)
       (((PLANET A) (testSTV))))

;; 6.5  Remove from empty context
!(test (removeItem () FOOD) ())


;; =============================================================================
;; 7. evaluateState
;; =============================================================================

;; 7.1  Context has FOOD, money = 10 → avg-price(FOOD)=15 + 10 = 25
!(test (evaluateState (((HAS FOOD) (1.0 0.9)) ((PLANET A) (1.0 0.9))) 10) 25)

;; 7.2  Context has FUEL, money = 0 → avg-price(FUEL)=16 + 0 = 16
!(test (evaluateState (((HAS FUEL) (1.0 0.9)) ((PLANET B) (1.0 0.9))) 0) 16)

;; 7.3  Context has METAL, money = 23 → avg-price(METAL)=15 + 23 = 38
!(test (evaluateState (((HAS METAL) (1.0 0.9)) ((PLANET C) (1.0 0.9))) 23) 38)

;; 7.4  No items in context — value comes from money only
!(test (evaluateState (((PLANET A) (1.0 0.9))) 50) 50)


;; =============================================================================
;; 8. applyTravel
;; =============================================================================

;; 8.1  Travel from A to B with items — planet updated, money decremented by 1
!(test (applyTravel (TravelRuleAB) (((PLANET A) (testSTV)) ((HAS FOOD) (testSTV))) 10)
       ((((PLANET B) (testSTV)) ((HAS FOOD) (testSTV))) 9))

;; 8.2  Travel from A to B without items
!(test (applyTravel (TravelRuleAB) (((PLANET A) (testSTV))) 10)
       ((((PLANET B) (testSTV))) 9))

;; 8.3  Travel from B to C
!(test (applyTravel (TravelRuleBC) (((PLANET B) (testSTV))) 5)
       ((((PLANET C) (testSTV))) 4))


;; =============================================================================
;; 9. applySell
;; =============================================================================
;; applySell takes ($item $contexts $money) — note: no $rule parameter.

;; 9.1  Sell FOOD on planet A — FOOD removed, money += price(FOOD, A) = 8
!(test (applySell FOOD (((PLANET A) (testSTV)) ((HAS FOOD) (itemSTV))) 10)
       ((((PLANET A) (testSTV))) 18))

;; 9.2  Sell FOOD on planet A starting with 0 money
!(test (applySell FOOD (((PLANET A) (testSTV)) ((HAS FOOD) (itemSTV))) 0)
       ((((PLANET A) (testSTV))) 8))

;; 9.3  Sell METAL on planet B — money += price(METAL, B) = 8
!(test (applySell METAL (((PLANET B) (testSTV)) ((HAS METAL) (itemSTV))) 20)
       ((((PLANET B) (testSTV))) 28))

;; 9.4  Sell FUEL on planet C — money += price(FUEL, C) = 5
!(test (applySell FUEL (((PLANET C) (testSTV)) ((HAS FUEL) (altSTV))) 15)
       ((((PLANET C) (testSTV))) 20))


;; =============================================================================
;; 10. applyBuy
;; =============================================================================

;; 10.1  Buy FOOD on planet A — money -= price(FOOD, A) = 8
!(test (applyBuy (BuyFoodRuleA) (((PLANET A) (testSTV))) 100)
       ((((PLANET A) (testSTV)) ((HAS FOOD) (testSTV))) 92))

;; 10.2  Buy FOOD replaces existing FOOD (STV updated)
!(test (applyBuy (BuyFoodRuleA) (((PLANET A) (testSTV)) ((HAS FOOD) (itemSTV))) 100)
       ((((PLANET A) (testSTV)) ((HAS FOOD) (testSTV))) 92))

;; 10.3  Buy FUEL on planet C — money -= price(FUEL, C) = 5
!(test (applyBuy (BuyFuelRuleC) (((PLANET C) (testSTV))) 50)
       ((((PLANET C) (testSTV)) ((HAS FUEL) (testSTV))) 45))


;; =============================================================================
;; 11. applySingleAction
;; =============================================================================

;; 11.1  Single TRAVEL action
!(test (applySingleAction (TravelRuleAB) (TRAVEL) (((PLANET A) (testSTV))) 10)
       ((((PLANET B) (testSTV))) 9))

;; 11.2  Single BUY action
!(test (applySingleAction (BuyFoodRuleA) (BUY FOOD) (((PLANET A) (testSTV))) 50)
       ((((PLANET A) (testSTV)) ((HAS FOOD) (testSTV))) 42))

;; 11.3  Single SELL action
!(test (applySingleAction (SellFoodRuleA) (SELL FOOD) (((PLANET A) (testSTV)) ((HAS FOOD) (itemSTV))) 10)
       ((((PLANET A) (testSTV))) 18))


;; =============================================================================
;; 12. applyActions  (sequential action application)
;; =============================================================================

;; 12.1  Empty action list — contexts and money unchanged
!(test (applyActions (TravelRuleAB) () (((PLANET A) (testSTV))) 10)
       ((((PLANET A) (testSTV))) 10))

;; 12.2  Single-element action list (TRAVEL)
!(test (applyActions (TravelRuleAB) ((TRAVEL)) (((PLANET A) (testSTV))) 10)
       ((((PLANET B) (testSTV))) 9))


;; =============================================================================
;; 13. applyRule  (extracts actions from rule, then applies them)
;; =============================================================================

;; 13.1  Travel rule
!(test (applyRule (TravelRuleAB) (((PLANET A) (testSTV))) 10)
       ((((PLANET B) (testSTV))) 9))

;; 13.2  Buy rule
!(test (applyRule (BuyFoodRuleA) (((PLANET A) (testSTV))) 100)
       ((((PLANET A) (testSTV)) ((HAS FOOD) (testSTV))) 92))

;; 13.3  Sell rule
!(test (applyRule (SellFoodRuleA) (((PLANET A) (testSTV)) ((HAS FOOD) (itemSTV))) 10)
       ((((PLANET A) (testSTV))) 18))


;; =============================================================================
;; 14. isValidSingleAction
;; =============================================================================

;; 14.1  TRAVEL is valid when money >= cost (1)
!(test (isValidSingleAction (TravelRuleAB) (TRAVEL) (((PLANET A) (testSTV))) 10) True)

;; 14.2  TRAVEL is invalid when money < cost
!(test (isValidSingleAction (TravelRuleAB) (TRAVEL) (((PLANET A) (testSTV))) 0) False)

;; 14.3  BUY valid — enough money for FOOD on A (price = 8)
!(test (isValidSingleAction (BuyFoodRuleA) (BUY FOOD) (((PLANET A) (testSTV))) 10) True)

;; 14.4  BUY invalid — not enough money
!(test (isValidSingleAction (BuyFoodRuleA) (BUY FOOD) (((PLANET A) (testSTV))) 5) False)

;; 14.5  BUY at exact price boundary — should succeed (>= check)
!(test (isValidSingleAction (BuyFoodRuleA) (BUY FOOD) (((PLANET A) (testSTV))) 8) True)

;; 14.6  SELL valid — item exists in context
!(test (isValidSingleAction (SellFoodRuleA) (SELL FOOD) (((PLANET A) (testSTV)) ((HAS FOOD) (itemSTV))) 10) True)

;; 14.7  SELL invalid — item not in context
!(test (isValidSingleAction (SellFoodRuleA) (SELL FOOD) (((PLANET A) (testSTV))) 10) False)


;; =============================================================================
;; 15. isValidActions  (validates a sequence of actions)
;; =============================================================================

;; 15.1  Empty action list is always valid
!(test (isValidActions (TravelRuleAB) () (((PLANET A) (testSTV))) 10) True)

;; 15.2  Single valid action
!(test (isValidActions (TravelRuleAB) ((TRAVEL)) (((PLANET A) (testSTV))) 10) True)

;; 15.3  Single invalid action
!(test (isValidActions (TravelRuleAB) ((TRAVEL)) (((PLANET A) (testSTV))) 0) False)


;; =============================================================================
;; 16. isValidRule  (planet match + action validation)
;; =============================================================================

;; 16.1  Valid rule — planet matches and enough money
!(test (isValidRule (((PLANET A) (testSTV))) 25 (BuyFoodRuleA)) True)

;; 16.2  Invalid — planet mismatch (trader on B, rule needs A)
!(test (isValidRule (((PLANET B) (testSTV))) 100 (BuyFoodRuleA)) False)

;; 16.3  Invalid — planet matches but not enough money for BUY FUEL at C (price 5)
!(test (isValidRule (((PLANET C) (testSTV))) 3 (BuyFuelRuleC)) False)

;; 16.4  Valid sell rule — planet matches and item exists
!(test (isValidRule (((PLANET A) (testSTV)) ((HAS FOOD) (itemSTV))) 10 (SellFoodRuleA)) True)

;; 16.5  Invalid sell — item missing from context
!(test (isValidRule (((PLANET A) (testSTV))) 10 (SellFoodRuleA)) False)

;; 16.6  Valid travel — planet matches and money >= 1
!(test (isValidRule (((PLANET A) (testSTV))) 5 (TravelRuleAB)) True)


;; =============================================================================
;; 17. getApplicableRules  (filters a list of rules)
;; =============================================================================

;; 17.1  Empty rule list — returns empty
!(test (getApplicableRules (((PLANET A) (testSTV))) 100 ()) ())

;; 17.2  Single applicable rule
!(test (getApplicableRules (((PLANET A) (testSTV))) 100 ((BuyFoodRuleA)))
       ((BuyFoodRuleA)))

;; 17.3  Single non-applicable rule (planet mismatch)
!(test (getApplicableRules (((PLANET A) (testSTV))) 100 ((BuyFuelRuleC)))
       ())

;; 17.4  Mix of applicable and non-applicable rules
!(test (getApplicableRules (((PLANET A) (testSTV))) 100 ((BuyFoodRuleA) (BuyFuelRuleC) (TravelRuleAB)))
       ((BuyFoodRuleA) (TravelRuleAB)))


;; =============================================================================
;; 18. updateBeta  (beta distribution parameter updates)
;; =============================================================================

;; 18.1  Zero reward — both alpha and beta increment by 1
!(test (updateBeta 5 3 0) (6 4))

;; 18.2  Positive reward — alpha increases by reward amount
!(test (updateBeta 5 3 2) (7 3))

;; 18.3  Negative reward — beta increases by |reward|
!(test (updateBeta 5 3 -2) (5 5))

;; 18.4  Starting from (1, 1) with positive reward
!(test (updateBeta 1 1 3) (4 1))

;; 18.5  Starting from (1, 1) with zero reward
!(test (updateBeta 1 1 0) (2 2))


;; =============================================================================
;; 19. updateSTV  (replace STV in a rule structure)
;; =============================================================================

;; 19.1  Update STV of a travel rule
!(test (updateSTV (TravelRuleAB) (0.9 0.5))
       (: Rule 1
           (TTV 0)
           (STV 0.9 0.5)
           (Complexity 1)
           (IMPLICATION
               (AND
                   (Context (testSTV) (AND (
                       ((PLANET A) (testSTV))
                   )))
                   (Action (SEQ_AND ((TRAVEL))))
               )
               (Goal (testSTV) (AND (
                   ((PLANET B) (testSTV))
               )))
       ))
)

;; 19.2  Update STV of a buy rule
!(test (updateSTV (BuyFoodRuleA) (0.7 0.3))
       (: Rule 7
           (TTV 0)
           (STV 0.7 0.3)
           (Complexity 1)
           (IMPLICATION
               (AND
                   (Context (testSTV) (AND (((PLANET A) (testSTV)))))
                   (Action (SEQ_AND ((BUY FOOD))))
               )
               (Goal (testSTV) (AND (
                   ((PLANET A) (testSTV))
                   ((HAS FOOD) (testSTV))
               )))
       ))
)


;; =============================================================================
;; 20. updateAtom  (space manipulation)
;; =============================================================================

;; 20.1  Add and then replace an atom in a new space
!(bind! &utilsTestSpace (new-space))
!(add-atom &utilsTestSpace (testEntry old-value))
!(updateAtom (testEntry old-value) (testEntry new-value) &utilsTestSpace)
!(test (match &utilsTestSpace (testEntry $v) $v) new-value)
