!(import! &self ../rule-ops)


;; =============================================================================
;; Re-defined pure helpers from planner-utils.metta
;; =============================================================================

;; Convert confidence to count
(= (confidenceToCount $confidence) (
    / (* $confidence 800) (- 1 $confidence)
))

;; Convert count to confidence
(= (countToConfindence $count) (
    / $count (+ 800 $count)
))

;; Convert STV to alpha / beta parameters of the Beta distribution
(= (stvToBeta ($strength $confidence)) (
    let* (
        ($count (confidenceToCount $confidence))
        ($alpha (* $strength $count))
        ($beta (- $count $alpha))
    ) ($alpha $beta)
))

;; Range check
(= (isBetween $val $low $high) (and (>= $val $low) (<= $val $high)))

;; Mock betaSample 
(= (betaSample $a $b) (/ $a (+ $a $b)))


;; =============================================================================
;;  confidenceToCount
;; =============================================================================

;;   confidence 
!(test (confidenceToCount 0.5) 800.0)

;;   confidence 
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
;; 5. betaSample mock 
;; =============================================================================

;; 5.1  Equal α and β → mean = 0.5
!(test (betaSample 400 400) 0.5)

;; 5.2  Skewed α → high value close to 1
!(test (betaSample 800.0 200.0) 0.8)
