!(import! &self ../planner-utils)


;; =============================================================================
;;  confidenceToCount
;; =============================================================================

!(test (confidenceToCount 0.5) 800.0)

!(test (confidenceToCount 0.2) 200.0)


;; =============================================================================
;;  countToConfindence
;; =============================================================================

!(test (countToConfindence 800) 0.5)

!(test (countToConfindence 0) 0)

!(test (countToConfindence 200) 0.2)


;; =============================================================================
;;  stvToBeta
;; =============================================================================

!(test (stvToBeta (0.5 0.5)) (400.0 400.0))

!(test (stvToBeta (0.75 0.5)) (600.0 200.0))

!(test (stvToBeta (0.25 0.5)) (200.0 600.0))

!(test (stvToBeta (1.0 0.5)) (800.0 0.0))


;; =============================================================================
;;  isBetween
;; =============================================================================

;;   Value inside the range
!(test (isBetween 5 1 10) True)

;;   Value below the range
!(test (isBetween 0 1 10) False)

;;   Lower boundary (inclusive)
!(test (isBetween 1 1 10) True)

;;   Upper boundary (inclusive)
!(test (isBetween 10 1 10) True)

;;   Value above the range
!(test (isBetween 11 1 10) False)

;;   Equal bounds — value matches
!(test (isBetween 5 5 5) True)

;;   Equal bounds — value does not match
!(test (isBetween 4 5 5) False)


;; =============================================================================
;;  round  (py-call wrapper)
;; =============================================================================

!(test (round 3.14159 2) 3.14)

!(test (round 2.718 1) 2.7)

!(test (round 0.5 2) 0.5)


;; =============================================================================
;;  logarithm  (py-call wrapper — natural log)
;; =============================================================================

!(test (logarithm 1) 0.0)


;; =============================================================================
;; 7. betaToSTV  (inverse of stvToBeta, uses round via py-call)
;; =============================================================================


;;   Symmetric 
!(test (betaToSTV (400.0 400.0)) (0.5 0.501))

;;   Skewed 
!(test (betaToSTV (600.0 200.0)) (0.75 0.501))

;;   Opposite skew 
!(test (betaToSTV (200.0 600.0)) (0.25 0.501))

;;   Tiny counts 
!(test (betaToSTV (1.0 1.0)) (0.5 0.001))


;; =============================================================================
;;  betaSample  (deterministic mean-based verification)
;; =============================================================================


;; Helper: deterministic Beta mean
(= (betaMean $a $b) (/ $a (+ $a $b)))

;;   Symmetric parameters 
!(test (betaMean 400.0 400.0) 0.5)

;;   Skewed toward 
!(test (betaMean 800.0 200.0) 0.8)

;;   Skewed toward 
!(test (betaMean 200.0 800.0) 0.2)

;;   Small parameters 
!(test (isBetween (betaMean 2.0 3.0) 0.0 1.0) True)


;; =============================================================================
;;  Round-trip: stvToBeta → betaToSTV
;; =============================================================================

!(test (let* (
    (($a $b) (stvToBeta (0.5 0.5)))
    (($s $c) (betaToSTV ($a $b)))
) $s) 0.5)

!(test (let* (
    (($a $b) (stvToBeta (0.75 0.5)))
    (($s $c) (betaToSTV ($a $b)))
) $s) 0.75)

!(test (let* (
    (($a $b) (stvToBeta (0.25 0.5)))
    (($s $c) (betaToSTV ($a $b)))
) $s) 0.25)
