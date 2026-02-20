;; Import from previous implementation
; !(import! &self planner-utils)
;; !(import! &self rule-ops)
;; Takes a list of rules and returns the selected rules
(= (thompson-sample $rules) (
    if (== $rules ())
        (0 ())
        (let* (
            (($rule $tail) (decons-atom $rules))
            ((STV $s $c) (eval (extractRule STV $rule)))
            ($ruleId (eval (extractRule Id $rule)))
            (($alpha $beta) (eval (stvToBeta ($s $c))))
            ; ($_ (println! (Alpha: $alpha Beta: $beta)))
            ($sampledValue (eval (betaSample $alpha $beta)))
            ; ($_ (println! (Rule $ruleId $sampledValue)))
            (($currMax $currRule) (thompson-sample $tail))
            ; ($_ (println! (Current Max: $currMax Rule: $currRule)))
        ) (if (> $sampledValue $currMax)
            ($sampledValue $rule)
            ($currMax $currRule)
        ))
))

(= (Rules) (
        ;; Travel A -> B
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

        ;; Travel A -> C
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

        ;; Travel B -> A
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

