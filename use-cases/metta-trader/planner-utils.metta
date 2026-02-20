;; Utility functions for Thompson Sampling based action planner

;; Convert confidence to count
(= (confidenceToCount $confidence) (
    / (* $confidence 800) (- 1 $confidence)
))

;; Convert count to confidence
(= (countToConfindence $count) (
    / $count (+ 800 $count)
))

;; Convert strength and confidence to alpha and beta parameters of Beta distribution
(= (stvToBeta ($strength $confidence)) (
    let* (
        ($count (confidenceToCount $confidence))
        ($alpha (* $strength $count))
        ($beta (- $count $alpha))
    ) ($alpha $beta)
))

;; Convert alpha and beta parameters of Beta distribution to strength and confidence
(= (betaToSTV ($alpha $beta)) (
    let* (
        ($count (+ $alpha $beta))
        ($strength (round (/ $alpha $count) 2))
        ($confidence (+ 0.001 (round (countToConfindence $count) 2))) ;; A small value should be added to avoid 0 when rounding
    ) ($strength $confidence)
))

;; Math utilities for Metta
(= (isBetween $val $low $high) (and (>= $val $low) (<= $val $high)))




(= (getRandomInt $a $b) (py-call ("random.randint" $a $b)))
(= (getRandom) (py-call ("random.random")))

(= (logarithm $x) (py-call ("math.log" $x)))
(= (round $x $d) 
   (py-call ("round" $x $d)))
   
(= (sampleEngine $alpha $beta $a $b $gamma) (
    let* (
        ($u1 (getRandom))
        ($u2 (getRandom))
        ($v (* $beta (logarithm (/ $u1 (- 1 $u1)))))
        ($w (* $a (exp $v)))
        ($temp (logarithm (/ $alpha (+ $b $w))))
        ($left (+ (* $alpha $temp) (* $gamma $v)))
        ($right (+ (logarithm 4) (logarithm (* (* $u1 $u1) $u2))))
    ) (if (>= $left $right)
        (round (/ $w (+ $b $w)) 4)
        (sampleEngine $alpha $beta $a $b $gamma)
    )
))


(= (betaSample $a $b) (
    let* (
        ($alpha (+ $a $b))
        ($beta (if (<= (min $a $b) 1) (max (/ 1 $a) (/ 1 $b)) (sqrt-math (/ (- $alpha 2) (- (* 2 (* $a $b)) $alpha))))) 
        ($gamma (/ (+ $a 1) $beta))
    ) (sampleEngine $alpha $beta $a $b $gamma)
))

;; An alternative to beta sampling for PeTTa
; (= (np) (import numpy))
; (= (np.random) (get-attribute (np) random))
; (= (betaSample $a $b) (
;     py-call (".beta" (np.random) $a $b 1)
; ))