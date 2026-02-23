;; Deduction Formula
;; (= (deductionFormula (STV $Ps $Pc) (STV $Qs $Qc) (STV $Rs $Rc) (STV $PQs $PQc) (STV $QRs $QRc)) (
;;     STV (round-float (if (< 0.9999 $Qs) ; avoid division by 0
;;                 $Rs
;;                 (+ (* $PQs $QRs) (/ (* (- 1 $PQs) (- $Rs (* $Qs $QRs))) (- 1 $Qs)))) 3)
;;             (round-float (min $Pc (min $Qc (min $Rc (min $PQc $QRc)))) 3)
;; ))

(= (deductionFormula (STV $Ps $Pc) (STV $Qs $Qc) (STV $Rs $Rc) (STV $PQs $PQc) (STV $QRs $QRc))
    (let* (
        ($strength (if (< 0.9999 $Qs) ; avoid division by 0
                $Rs
                (+ (* $PQs $QRs) (/ (* (- 1 $PQs) (- $Rs (* $Qs $QRs))) (- 1 $Qs)))))
        ($confidence (min $Pc (min $Qc (min $Rc (min $PQc $QRc)))))
        ($roundedStrength (round-float $strength 5))
        ($roundedConfidence (round-float $confidence 5))

    )
        (STV $roundedStrength $roundedConfidence)
    )
)

; Induction formula: PLN book "Appendix A: Comparison of PLN Rules with NARS Rules", page 307
(= (inductionFormula (STV $sA $cA)
                    (STV $sB $cB)
                    (STV $sC $cC)
                    (STV $sBA $cBA)
                    (STV $sBC $cBC))
    (let* (
        ($op1 (eval (/safe (* (* $sBA $sBC) $sB) $sA)))
        ($op2 (* (- 1 (eval (/safe (* $sBA $sB) $sA)))
               (eval (/safe (- $sC (* $sB $sBC)) (- 1 $sB)))))
        ($strength (round-float (+ $op1 $op2) 5))
        ($confidence (round-float (Truth_w2c (min $cBA $cBC)) 5))
    ) (STV $strength $confidence)))

; Abduction formula: PLN book "Appendix A: Comparison of PLN Rules with NARS Rules", page 307
(= (abductionFormula (STV $sA $cA)
                    (STV $sB $cB)
                    (STV $sC $cC)
                    (STV $sAB $cAB)
                    (STV $sCB $cCB))
    (let* (
        ($op1 (eval (/safe (* (* $sAB $sCB) $sC) $sB)))
        ($op2 (eval (/safe (* $sC (* (- 1 $sAB) (- 1 $sCB))) (- 1 $sB))))
        ($strength (+ $op1 $op2))
        ($confidence (Truth_w2c (min $cAB $cCB)))
    ) (STV (round-float $strength 5) (round-float $confidence 5))))

;; Conjunction Introduction Formula
(= (conjunctionFormula (STV $Ps $Pc) (STV $Qs $Qc)) (
    STV (round-float (* $Ps $Qs) 5) (round-float (min $Pc $Qc) 5)
))

;; Helper Function
(= (Truth_w2c $w)
   (eval (/safe $w (+ $w 1))))
