!(bind! &newSpace (new-space))
!(bind! &sngSpace (new-space))

;A function that takes the latestTime and a list of times
;and finds the appropriate position to set previous time pointer.
;
;returns: a tuple of previous time and latest time.
;(: setPreviousTime (-> Expression Number))
(= (setPreviousTime $times)
   (let* 
     (
      ($random-num (random-int 0 1))
      ($interval (+ 5 (* 5 $random-num)))
      ($times' (reverse (sort-atom $times)))
      ($latestTime (car-atom $times'))
      ($prevTime (setPreviousTime' $times' $latestTime $interval)) 
      )
     ($prevTime $latestTime) 
   )
)

(= (setPreviousTime' $times $latest $interval)
   (if (== $times ())
     ()
     (let*
       (
        (($previous $tail) (decons-atom $times)) 
        )
       (if (>= (- $latest $previous) $interval)
         $previous
         (setPreviousTime' $tail $latest $interval)
         )
      )
     )
   )

;(: addPredicatesHelper (-> Grounded Expression))
(= (addPredicatesHelper $space) 
  (let* 
    (
      ($pred-change-with-tv (Predicate change-with-tv))
      ($pred-change-with-arg (Predicate change-with-arg))
      ($pred-has-dramatic-changes (Predicate has-dramatic-change))
      ($_ (collapse (let $x 
                        (superpose ($pred-change-with-tv $pred-change-with-arg $pred-has-dramatic-changes))
                        (addPredicate $x $space)
                  )
            )
          )
      )
    ($pred-change-with-tv $pred-change-with-arg $pred-has-dramatic-changes)
  )
)

;a function that removes previous changes with tv and with args from 
;a provided space

(= (removePrevChanges $space $atoms)
   (collapse (let* (
            ($atm (superpose $atoms))
            ($link (out $atm))
            ; (() (println! ($atm $link) ))
            ($_ (remove-atom $space $link)) 
            ($_ (remove-atom $space $atm))
          )
    ())
   )
)

(= (addPredicate $pred $space)
   (if (== (collapse (match $space $pred $pred)) ())
     (let $_ (add-atom $space $pred) $pred)
     (empty)
     )
   )
(= (update-atom $space $oatom $natom) (let $_ (remove-atom $space $oatom) (add-atom $space $natom)))
(= (update-drmtc-chng-tv $pred $space $ntv)
   (let $result (collapse (match $space ($pred (STV $s $c)) ($s $c))) 
        (if (== $result ())
            (let $re (add-atom $space ($pred $ntv)) $re)
            (let $tv (car-atom $r) (update-atom $space ($pred $tv) ($pred $ntv)))
        )
   )
)
; Record the changes in the atomspace
(= (record-changes-tv $space $changes-tv)
   (collapse (let* 
       (
         ($atom (superpose $changes-tv))
         ($_ (add-atom $space (LIST_LINK $atom)))
         ($_ (add-atom $space (REFERENCE_LINK ((Predicate change-with-tv) (LIST_LINK $atom)))))
       )
    ()
    ))
)
(= (record-changes-arg $space $changes-arg)
  (if (== () $changes-arg)()
    (let $_ (add-atom $space (LIST_LINK $changes-arg))
      (add-atom $space (REFERENCE_LINK ((Predicate change-with-arg) (LIST_LINK $changes-arg))))
    )
  )
)
;(: NetDifference Type)
;(: netDiff (-> Number Expression NetDifference))
;!(get-type (netDiff 7 (a b c))) 
;(: NetDifference Type)
;(: netDiff (-> Number Expression NetDifference))
;!(get-type (netDiff 7 (a b c))) 
;(: compareChanges (-> hyperon::space::DynSpace hyperon::space::DynSpace Expression))
(= (compareChanges $space1 $space2)
    (let* (
            ($space_val_1 (collapse (get-atoms $space1)))
            ($space_val_2 (collapse (get-atoms $space2)))
            ($net (subtraction-atom $space_val_1 $space_val_2))
          )
        ((size-atom $net) $net)
    )
)

;(: compareSpaceToList (-> hyperon::space::DynSpace Expression Expression))

(= (compareSpaceToList $space $list)
	(let* (
          ($space_val (collapse (get-atoms $space)))
          ($net (subtraction-atom $space_val $list))
        )
        ((size-atom $net) $net)
    )
)

;(: detectChangesHelper (-> Grounded Expression Expression Number Expression Expression))

(= (detectChangesHelper $space $time $previous_times $delta $accum)
     (let* (
            ($head (superpose $previous_times))
            ; (() (println! ("head" $head)))
            ($x (getImplication $head $space))
            ($y (getImplication $time $space))
          )
       (if (== $x $y)
         (let* (
                 ($timeTv (extractTvFromRule $time $space))
                 ($latestTv (extractTvFromRule $head $space))
                 ($prevTvMean (cogTvMean $timeTv))
                 ($latestTvMean (cogTvMean $latestTv))
                 ($diff (- $latestTvMean $prevTvMean))
               )
           (if (>= (abs-math $diff) $delta)
               (union-atom $accum (($time $head)))
               $accum
            )
         )
         $accum
       )
     
   )
)
;The following function is written for checking 
; the state of the atomspace. This is between two consecutive time cycles.
;(: detectChanges (-> Grounded Expression Expression Number Expression Expression))

(= (detectChanges $space $prev_times $latest_times $delta $accum)
   (if (or (== $prev_times ()) (== $latest_times ()))
       $accum
       (let* (
                ($latest (superpose $latest_times))
                ($res (detectChangesHelper $space $latest $prev_times $delta ()))
                ; (() (println! ("res" $res)))
               )
           (union-atom $accum $res)
         )
       
   )
)
;(: monitor-changes (-> Grounded (->)))
(= (monitor-changes $space) 
   (let $prev_times (get-previous-times $space)
     (if (== () $prev_times)
          ()
          (let* (
                ($prev_times' (get-timevals $prev_times))
                (($previous_time $latest_time) (setPreviousTime $prev_times'))
                
                ($at_times_latest (get-incoming-by-type $space $latest_time TimeValue)) 
                ($at_times_previous (get-incoming-by-type $space $previous_time TimeValue))
                ;(() (println! (prev $at_times_previous latest $at_times_latest)))

                ($delta (match $space (tv_delta $v) $v))
                ($changes-with-tv (detectChanges $space $at_times_previous $at_times_latest $delta ()))
                ;(() (println! (changes from dc $changes-with-tv)))

                (($pred-change-with-tv $pred-change-with-arg 
                                      $pred-has-dramatic-changes) (addPredicatesHelper $space))

                ($old-changes-with-tv (get-incoming-by-type $space $pred-change-with-tv REFERENCE_LINK))

                ($_ (removePrevChanges $space $old-changes-with-tv))
                ($_ (update-drmtc-chng-tv $pred-has-dramatic-changes $space (STV 0.0 0.0)))

                ($at_times_latest' (get-incoming-by-type $space $latest_time TimeValue)) 
                ($at_times_previous' (get-incoming-by-type $space $previous_time TimeValue))
                ($__ (record-changes-tv $space $changes-with-tv))
                ($remainingChanges (detectChanges $space $at_times_previous' $at_times_latest' $delta ()))
              )
              (if (== $remainingChanges ())
                ()
                (update-drmtc-chng-tv $pred-has-dramatic-changes $space (STV 1.0 1.0))
              )
          )
       )
     )
)


;============= Helper Functions =============
;(: addRuleLink (-> Grounded Symbol Expression Expression Expression))
(= (addRuleLink  $space $handle $goal $andLink $tv)
   (let*
     (
      ($rule (collapse (get-type $handle)))
      )
      (if (not (== $rule (%Undefined%))) 
            () 
            (
              let* (
                    ($newRule (: $handle (IMPLICATION_LINK $andLink $goal)))
                    ($_ (add-atom  $space $newRule))
                    ($_ (add-atom  $space (: $handle $tv)))
                    ($_ (add-atom  $space (isExecuted $handle (FALSE_TV)))) 
                  )
                  ()
            )
      )
     )
)

(= (addRule $space $ruleHandle $context $action $goal $tv)
    (let* (
            ($andLink (addAndLink $space $context $action))
            ($_ (addRuleLink   $space $ruleHandle $goal $andLink $tv))
            ($exists (existsIn &psiRules $ruleHandle))
          )
          (if $exists 
              $ruleHandle
              (let* 
                (
                  ($res (getRuleType $ruleHandle $space))
                  ($_ (if (== (size-atom $res) 2) ; Important to avoid adding another $tv to $ruleHandle as type.
                          (update-atom $space (: $ruleHandle (TTV 0 (STV 0.0 0.0))) (: $ruleHandle $tv)) 
                          () ))
                  ($_ (update-atom $space (isExecuted $ruleHandle (DEFAULT_TV)) (isExecuted $ruleHandle (FALSE_TV))))
                )
                (let $rb (if (== (len $context) 1)
                    (add-atom &psiRules (: $ruleHandle ($context $action $goal (car-atom $context))))
                    (add-atom &psiRules (: $ruleHandle ($context $action $goal (AND_LINK $context))))
                  )
                  $ruleHandle
                )
              )
          )
    )
)


(= (existsIn $space $atom)
   ( let $res (collapse (get-type-space $space $atom)) (not (== (%Undefined%) $res)) )
)
(= (addAndLink $space $context $action)
   (let $res 
        (collapse (match  $space (AND_LINK ($context $action)) (AND_LINK ($context $action))))
        (if (not (== $res ())) 
          (car-atom $res)
          (let $t (add-atom  $space (AND_LINK ($context $action))) (AND_LINK ($context $action)))
        )
     )
)
(= (getRuleType $id $space)
   (collapse (match $space (: $id $type) $type))
)
(= (get-previous-times $space) 
   (collapse (match $space (TimeValue $time-stamp $atom) (TimeValue $time-stamp $atom)))

)
(= (get-timevals $prev_times) 
   (collapse (let $x (superpose $prev_times) (extract-timestamp $x)))
)
(= (extractTvFromRule $rule $space)
   (let (TTV $ts $tv) (getTV $rule $space) $tv)
)
(= (extract-timestamp (TimeValue $time-stamp $atom)) $time-stamp)
