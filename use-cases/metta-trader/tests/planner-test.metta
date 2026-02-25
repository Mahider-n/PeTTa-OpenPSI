!(import! &self ../rule-ops)


;; =============================================================================
;; Minimal re-defined helpers needed by thompson-sample
;; =============================================================================

;; Convert confidence to count (from planner-utils)
(= (confidenceToCount $confidence) (
    / (* $confidence 800) (- 1 $confidence)
))

;; Convert STV to alpha / beta parameters (from planner-utils)
(= (stvToBeta ($strength $confidence)) (
    let* (
        ($count (confidenceToCount $confidence))
        ($alpha (* $strength $count))
        ($beta (- $count $alpha))
    ) ($alpha $beta)
))

;; Mock betaSample — deterministic mean
(= (betaSample $a $b) (/ $a (+ $a $b)))


;; =============================================================================
;; Re-defined thompson-sample from planner.metta
;; =============================================================================

(= (thompson-sample $rules) (
    if (== $rules ())
        (0 ())
        (let* (
            (($rule $tail) (decons-atom $rules))
            ((STV $s $c) (eval (extractRule STV $rule)))
            ($ruleId (eval (extractRule Id $rule)))
            (($alpha $beta) (eval (stvToBeta ($s $c))))
            ($sampledValue (eval (betaSample $alpha $beta)))
            (($currMax $currRule) (thompson-sample $tail))
        ) (if (> $sampledValue $currMax)
            ($sampledValue $rule)
            ($currMax $currRule)
        ))
))


;; =============================================================================
;; Test helpers
;; =============================================================================

;; Extract only the rule ID chosen by thompson-sample
(= (selectedRuleId $rules) (
    let* (
        (($score $rule) (thompson-sample $rules))
    ) (extractRule Id $rule)
))


;; =============================================================================
;; Reusable STV / rule fixtures
;; =============================================================================

(= (testSTV) (STV 0.2 0.1))


(= (HighStrengthRule)
    (: Rule 100
        (TTV 0)
        (STV 0.9 0.5)
        (Complexity 1)
        (IMPLICATION
            (AND
                (Context (testSTV) (AND (((PLANET A) (testSTV)))))
                (Action (SEQ_AND ((TRAVEL))))
            )
            (Goal (testSTV) (AND (((PLANET B) (testSTV)))))
    ))
)

;; Medium strength (0.5)
(= (MedStrengthRule)
    (: Rule 101
        (TTV 0)
        (STV 0.5 0.5)
        (Complexity 1)
        (IMPLICATION
            (AND
                (Context (testSTV) (AND (((PLANET A) (testSTV)))))
                (Action (SEQ_AND ((TRAVEL))))
            )
            (Goal (testSTV) (AND (((PLANET C) (testSTV)))))
    ))
)

;; Low strength (0.1)
(= (LowStrengthRule)
    (: Rule 102
        (TTV 0)
        (STV 0.1 0.5)
        (Complexity 1)
        (IMPLICATION
            (AND
                (Context (testSTV) (AND (((PLANET B) (testSTV)))))
                (Action (SEQ_AND ((TRAVEL))))
            )
            (Goal (testSTV) (AND (((PLANET A) (testSTV)))))
    ))
)

;; Equal-strength rules (for tie-breaking verification)
(= (EqualRuleFirst)
    (: Rule 200
        (TTV 0)
        (STV 0.6 0.5)
        (Complexity 1)
        (IMPLICATION
            (AND
                (Context (testSTV) (AND (((PLANET A) (testSTV)))))
                (Action (SEQ_AND ((TRAVEL))))
            )
            (Goal (testSTV) (AND (((PLANET B) (testSTV)))))
    ))
)

(= (EqualRuleSecond)
    (: Rule 201
        (TTV 0)
        (STV 0.6 0.5)
        (Complexity 1)
        (IMPLICATION
            (AND
                (Context (testSTV) (AND (((PLANET B) (testSTV)))))
                (Action (SEQ_AND ((TRAVEL))))
            )
            (Goal (testSTV) (AND (((PLANET C) (testSTV)))))
    ))
)

;; Buy-type rule (0.7 strength — different action type)
(= (BuyFoodRule)
    (: Rule 300
        (TTV 0)
        (STV 0.7 0.5)
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

;; Very-high strength (0.95) — for order-independence tests
(= (VeryHighStrengthRule)
    (: Rule 400
        (TTV 0)
        (STV 0.95 0.5)
        (Complexity 1)
        (IMPLICATION
            (AND
                (Context (testSTV) (AND (((PLANET C) (testSTV)))))
                (Action (SEQ_AND ((TRAVEL))))
            )
            (Goal (testSTV) (AND (((PLANET A) (testSTV)))))
    ))
)


;; ---- Rule list fixtures -----------------------------------------------------

(= (ThreeRules)    ((HighStrengthRule) (MedStrengthRule) (LowStrengthRule)))
(= (ReversedRules) ((LowStrengthRule) (MedStrengthRule) (HighStrengthRule)))
(= (TwoRules)      ((LowStrengthRule) (MedStrengthRule)))
(= (SingleRule)    ((HighStrengthRule)))
(= (EqualRules)    ((EqualRuleFirst) (EqualRuleSecond)))
(= (MixedTypeRules) ((BuyFoodRule) (MedStrengthRule) (LowStrengthRule)))
(= (FourRules)     ((MedStrengthRule) (LowStrengthRule) (VeryHighStrengthRule) (HighStrengthRule)))


;; =============================================================================
;; extractRule integration 
;; =============================================================================

;;   Extract STV
!(test (extractRule STV (HighStrengthRule)) (STV 0.9 0.5))
!(test (extractRule STV (MedStrengthRule)) (STV 0.5 0.5))
!(test (extractRule STV (LowStrengthRule)) (STV 0.1 0.5))

;;   Extract Id
!(test (extractRule Id (HighStrengthRule)) 100)
!(test (extractRule Id (MedStrengthRule)) 101)
!(test (extractRule Id (BuyFoodRule)) 300)

;;   Extract TTV
!(test (extractRule TTV (HighStrengthRule)) 0)

;;   Extract Action
!(test (extractRule Action (HighStrengthRule)) ((TRAVEL)))
!(test (extractRule Action (BuyFoodRule)) ((BUY FOOD)))


;; =============================================================================
;;  thompson-sample — base case
;; =============================================================================

;;   Empty rule list returns (0 ())
!(test (thompson-sample ()) (0 ()))


;; =============================================================================
;;  thompson-sample — single rule
;; =============================================================================

;;   Single rule is always selected
!(test (selectedRuleId (SingleRule)) 100)


;; =============================================================================
;;  thompson-sample — picks highest strength
;; =============================================================================

!(test (selectedRuleId (ThreeRules)) 100)

!(test (selectedRuleId (ReversedRules)) 100)

!(test (selectedRuleId (TwoRules)) 101)


;; =============================================================================
;;  thompson-sample — mixed action types
;; =============================================================================

!(test (selectedRuleId (MixedTypeRules)) 300)


;; =============================================================================
;;  thompson-sample — four rules with clear winner
;; =============================================================================

!(test (selectedRuleId (FourRules)) 400)


;; =============================================================================
;;thompson-sample — tie-breaking with equal strengths
;; =============================================================================

!(test (selectedRuleId (EqualRules)) 201)


;; =============================================================================
;; thompson-sample — original planner.metta Rules fixture
;; =============================================================================

(= (PlannerRules) (
        (: Rule 1
            (TTV 0)
            (STV 0.5 0.7)
            (Complexity 1)
            (IMPLICATION
                (AND
                    (Context (STV 0.2 0.1) (AND (
                        (PLANET A (STV 0.2 0.1))
                    )))
                    (Action (SEQ_AND ((TRAVEL))))
                )
                (Goal (STV 0.2 0.1) (AND (
                    (PLANET B (STV 0.2 0.1))
                )))
        ))

        (: Rule 2
            (TTV 0)
            (STV 0.9 0.02)
            (Complexity 1)
            (IMPLICATION
                (AND
                    (Context (STV 0.2 0.1) (AND (
                        (PLANET A (STV 0.2 0.1))
                    )))
                    (Action (SEQ_AND ((TRAVEL))))
                )
                (Goal (STV 0.2 0.1) (AND (
                    (PLANET C (STV 0.2 0.1))
                )))
        ))

        (: Rule 3
            (TTV 0)
            (STV 0.1 0.2)
            (Complexity 1)
            (IMPLICATION
                (AND
                    (Context (STV 0.2 0.1) (AND (
                        (PLANET B (STV 0.2 0.1))
                    )))
                    (Action (SEQ_AND ((TRAVEL))))
                )
                (Goal (STV 0.2 0.1) (AND (
                    (PLANET A (STV 0.2 0.1))
                )))
        ))
))

;;   With deterministic mock, Rule 2 (strength 0.9) wins
!(test (selectedRuleId (PlannerRules)) 2)
