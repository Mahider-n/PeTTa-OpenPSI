!(import! &self ../rule-ops)
!(import! &self ../planner)

;; =============================================================================
;; Pure helpers from planner-utils (no py-call dependency)
;; =============================================================================

(= (confidenceToCount $confidence) (
    / (* $confidence 800) (- 1 $confidence)
))

(= (stvToBeta ($strength $confidence)) (
    let* (
        ($count (confidenceToCount $confidence))
        ($alpha (* $strength $count))
        ($beta (- $count $alpha))
    ) ($alpha $beta)
))

(= (isBetween $val $low $high) (and (>= $val $low) (<= $val $high)))

;; =============================================================================
;; betaSample — deterministic mean
;; =============================================================================

(= (betaSample $a $b) (/ $a (+ $a $b)))


;; =============================================================================
;; Test helpers
;; =============================================================================

;; Extract only the rule ID chosen by thompson-sample
(= (selectedRuleId $rules) (
    let* (
        (($score $rule) (thompson-sample $rules))
    ) (extractRule Id $rule)
))

;; Check thompson-sample returns a score in [0, 1]
(= (thompsonScoreInRange $rules) (
    let* (
        (($score $rule) (thompson-sample $rules))
    ) (isBetween $score 0.0 1.0)
))

;; Check the selected rule has a valid positive Id
(= (selectedRuleIdPositive $rules) (
    let* (
        (($score $rule) (thompson-sample $rules))
        ($id (extractRule Id $rule))
    ) (> $id 0)
))

;; Check if a value is a member of a list
(= (isMember $val $list) (
    if (== $list ())
        False
        (let* (
            (($head $tail) (decons-atom $list))
        ) (if (== $val $head)
            True
            (isMember $val $tail)
        ))
))

;; Check the selected rule Id is one of the expected Ids
(= (selectedRuleIdIn $rules $expectedIds) (
    let* (
        (($score $rule) (thompson-sample $rules))
        ($id (extractRule Id $rule))
    ) (isMember $id $expectedIds)
))


;; =============================================================================
;; Reusable STV / rule fixtures
;; =============================================================================

(= (testSTV) (STV 0.2 0.1))

;; High strength (0.9)
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

;; Buy-type rule 
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

;; Very-high strength 
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

(= (ThreeRules)     ((HighStrengthRule) (MedStrengthRule) (LowStrengthRule)))
(= (SingleRule)     ((HighStrengthRule)))
(= (MixedTypeRules) ((BuyFoodRule) (MedStrengthRule) (LowStrengthRule)))
(= (FourRules)      ((MedStrengthRule) (LowStrengthRule) (VeryHighStrengthRule) (HighStrengthRule)))


;; =============================================================================
;;  extractRule integration (via rule-ops import)
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
;;  thompson-sample — base case (deterministic)
;; =============================================================================

!(test (thompson-sample ()) (0 ()))


;; =============================================================================
;;  thompson-sample — single rule (deterministic)
;; =============================================================================

!(test (selectedRuleId (SingleRule)) 100)


;; =============================================================================
;;  thompson-sample — score always in valid range [0, 1]
;; =============================================================================

;;   Single rule — score in range
!(test (thompsonScoreInRange (SingleRule)) True)

;;   Three rules — score in range
!(test (thompsonScoreInRange (ThreeRules)) True)

;;   Mixed action types — score in range
!(test (thompsonScoreInRange (MixedTypeRules)) True)

;;   Four rules — score in range
!(test (thompsonScoreInRange (FourRules)) True)


;; =============================================================================
;;  thompson-sample — selected rule has a valid positive Id
;; =============================================================================

!(test (selectedRuleIdPositive (ThreeRules)) True)

!(test (selectedRuleIdPositive (MixedTypeRules)) True)

!(test (selectedRuleIdPositive (FourRules)) True)


;; =============================================================================
;;  thompson-sample — selected rule Id is from the input set
;; =============================================================================

!(test (selectedRuleIdIn (ThreeRules) (100 101 102)) True)

!(test (selectedRuleIdIn (MixedTypeRules) (300 101 102)) True)

!(test (selectedRuleIdIn (FourRules) (101 102 400 100)) True)


;; =============================================================================
;;  thompson-sample — picks highest strength (deterministic override)
;; =============================================================================


!(test (selectedRuleId (ThreeRules)) 100)

!(test (selectedRuleId (MixedTypeRules)) 300)

!(test (selectedRuleId (FourRules)) 400)


;; =============================================================================
;; 8. thompson-sample — original planner.metta Rules fixture
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

!(test (thompsonScoreInRange (PlannerRules)) True)

!(test (selectedRuleIdIn (PlannerRules) (1 2 3)) True)

!(test (selectedRuleId (PlannerRules)) 2)
