;;NAL-1
; deduction
;;This code is a modification of narsese which is appropriated to the cognitive schematics used by OpenPSI.
;; The original narsese representation wasn't compatible with the implication representation structure of our cognitive schema
;; So the original nars code found on the nars-compiled document resulted in rules but the rules where not semantically correct
;; so the reasoning method was modified to have a better structure.
;; This are the first set of reasoning rules from pei wang's book (Non-Axiomatic Logic) (2013) and they are called NAL-1.
(= (Truth_c2w $c) (/ $c (- 1 $c)))
(= (Truth_w2c $w) (/ $w (+ $w 1)))
(= (Truth_Deduction ($f1 $c1) ($f2 $c2)) ((* $f1 $f2) (* (* $f1 $f2) (* $c1 $c2))))
(= (Truth_Abduction ($f1 $c1) ($f2 $c2)) ($f2 (Truth_w2c (* (* $f1 $c1) $c2))))
(= (Truth_Induction $T1 $T2) (Truth_Abduction $T2 $T1))
(= (Truth_Exemplification ($f1 $c1) ($f2 $c2)) (1.0 (Truth_w2c (* (* $f1 $f2) (* $c1 $c2)))))


(= (deductionResp ((($c1 $a1) --> $g1) $T1) ((($g1 $a2) --> $g2) $T2)) ((($c1 (union-atom $a1 $a2)) --> $g2) (Truth_Deduction $T1 $T2)))
(= (inductionResp ((($c1 $a1) --> $g1) $T1) ((($c1 $a1) --> $g2) $T2)) ((($g1 $a1) --> $g2) (Truth_Induction $T1 $T2)))
(= (abductionResp ((($c1 $a1) --> $g1) $T1) ((($c2 $a2) --> $g1) $T2)) ((($c1 $a1) --> $c2) (Truth_Abduction $T1 $T2)))
(= (exemplificationResp ((($c1 $a1) --> $g1) $T1) ((($g1 $a2) --> $g2) $T2)) ((($g2 (union-atom $a2 $a1)) --> $c2) (Truth_Exemplification $T1 $T2)))