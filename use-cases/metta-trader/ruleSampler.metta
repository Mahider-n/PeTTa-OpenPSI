;; Updated Quick Sort Based Sampler
(= (ruleSampler $rules $k) (
    let* (
        ($stvWithRules (map-atom $rules $rule ((extractRule STV $rule) $rule)))
        ;; ($_ (println! (Stv With Rules: $stvWithRules)))
        ($betaWithRules (map-atom $stvWithRules ((STV $s $c) $rule) ((stvToBeta ($s $c)) $rule)))
        ;; ($_ (println! (Beta with Rules: $betaWithRules)))
        ($sampledRules (map-atom $betaWithRules (($alpha $beta) $rule) ((betaSample $alpha $beta) $rule)))
        ;; ($_ (println! (Sampled Rules: $sampledRules)))
    ) (get-top-k $k $sampledRules)
))

; Helper: Concatenate two expression lists
(= (concat $list1 $list2) (
   union-atom $list1 $list2
))

; Helper: Filter Greater Than or Equal based on score
(= (filter-gte $pivot $list)
   (if (== $list ())
       ()
       (let* (
           ($head (car-atom $list))
           ($tail (cdr-atom $list))
           ($score (car-atom $head))
       )
       (if (>= $score $pivot)
           (cons-atom $head (filter-gte $pivot $tail))
           (filter-gte $pivot $tail)))))

; Helper: Filter Less Than based on score
(= (filter-lt $pivot $list)
   (if (== $list ())
       ()
       (let* (
           ($head (car-atom $list))
           ($tail (cdr-atom $list))
           ($score (car-atom $head))
       )
       (if (< $score $pivot)
           (cons-atom $head (filter-lt $pivot $tail))
           (filter-lt $pivot $tail)))))

; Sort Descending (QuickSort)
(= (sort-desc $list)
   (if (== $list ())
       ()
       (let* (
           ($pivotTuple (car-atom $list))
           ($tail (cdr-atom $list))
           ($pivotScore (car-atom $pivotTuple))
           ($greater (filter-gte $pivotScore $tail))
           ($less (filter-lt $pivotScore $tail))
       )
       (concat (sort-desc $greater) (cons-atom $pivotTuple (sort-desc $less))))))

; Take first K elements
(= (take $k $list)
   (if (or (<= $k 0) (== $list ()))
       ()
       (cons-atom (car-atom $list) (take (- $k 1) (cdr-atom $list)))))

; Extract User Data from ($score $data) tuple
(= (extract-data $list)
   (if (== $list ())
       ()
       (let* (
           ($head (car-atom $list))
           ($tail (cdr-atom $list))
           ($data (car-atom (cdr-atom $head))) 
       )
       (cons-atom $data (extract-data $tail)))))

; Main Function
(= (get-top-k $k $list)
   (extract-data (take $k (sort-desc $list))))