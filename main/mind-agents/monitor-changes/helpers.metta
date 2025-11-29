
;;;;;helper;;;;;

 
 
;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; The code below is borrowed from the hyperon-pln's implementation
;; of the TruthValue. 
;; The complete implementation can be found in the hyperon-pln's TruthValue.metta file . 


;; Constants for beta distribution prior
;(: prior-alpha (-> Number))
(= (prior-alpha) 0.5)
;(: prior-beta (-> Number))
(= (prior-beta) 0.5)

;; Truth Value type and constructors
;(: TruthValue Type)
;(: Bl (-> Bool TruthValue))
;(: Pr (-> Number TruthValue))
;(: STV (-> Number Number TruthValue))
 

;; Return the TVMode of a truth value
;(: TVMode (-> TruthValue Number))
(= (TVMode (Bl True)) 1.0)
(= (TVMode (Bl False)) 0.0)
(= (TVMode (Pr $pr)) $pr)
(= (TVMode (STV $pr $_)) $pr)


;; Return the positive count of a truth value
;(: pos-count (-> TruthValue Number))
(= (pos-count $tv) (* (TVMode $tv) (count $tv)))

;; Return the negative count of a truth value
;(: neg-count (-> TruthValue Number))
(= (neg-count $tv) (* (- 1 (TVMode $tv)) (count $tv)))

;; Return the posterior alpha of a truth value
;(: post-alpha (-> TruthValue Number))
(= (post-alpha $tv) (+ (prior-alpha) (pos-count $tv)))

;; Return the posterior beta of a truth value
;(: post-beta (-> TruthValue Number))
(= (post-beta $tv) (+ (prior-beta) (neg-count $tv)))

;; Return the first order probability TVMean of the second order
;; distribution associated to a truth value.
;(: TVMean (-> TruthValue Number))
(= (TVMean (Bl True)) 1.0)
(= (TVMean (Bl False)) 0.0)
(= (TVMean (Pr $pr)) $pr)
(= (TVMean (STV $pr $conf))
   (let* (($a (post-alpha (STV $pr $conf)))
          ($b (post-beta (STV $pr $conf))))
     (/ $a (+ $a $b))))




(= (get-outgoing $atom $space $type)
   (collapse 
     (match $space ($type ($source $atom)) (match $space ($type ($atom $source)) ($type ($atom $source))))
     )
   )

(= (get-outgoing $atom $space)
   (collapse 
     (match $space ($type ($source $atom)) (match $space ($type ($atom $source))))
     )
   )

(= (out ($type $s $t))
   $t
   )

(= (get-incoming-by-type $space $atom $type)
   (collapse 
     (union 
      (match $space ($type $atom $target) $target)
      (match $space ($type $source $atom) $source)
      )
    )
   )

(= (get-incoming $atom $space)
   (collapse 
     (union 
      (match $space ($type $atom $target) ($type $atom $target))
      (match $space ($type $source $atom) ($type $source $atom))
      )
     )
   )

;;;addRule helper

;(: addRuleLink (-> Grounded Symbol Expression Expression Expression))

;;addRuleLink
(= (addRuleLink  $space $handle $goal $andLink)
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
                    ($_ (add-atom  $space (: $handle (TTV 0 (STV 0.0 0.0)))))
                    ($_ (add-atom  $space (isExecuted $handle (DEFAULT_TV)))) ;TODO: define DEFAULT_TV
                  )
                  ()
            )
      )
     )
)
;(: addAndLink (-> Grounded Expression Expression Expression))
;;addAndLink
(= (addAndLink $space $context $action)
   (let $res 
        (collapse (match  $space (AND_LINK ($context $action)) (AND_LINK ($context $action))))
        (if (not (== $res ()))
          (car-atom $res)
          (let () (add-atom  $space (AND_LINK ($context $action))) (AND_LINK ($context $action)))
        )
     )
)
;(: addRule (-> Grounded Symbol Expression Expression Symbol Expression Expression))
;(: addRule (-> Symbol Expression Action Symbol Goal Expression))
(= (addRule $space $ruleHandle $context $action $goal $tv)
    (let* (
            ($andLink (addAndLink $space $context $action))
            ($_ (addRuleLink   $space $ruleHandle $goal $andLink))
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
                (let () (if (== (len $context) 1)
                    (add-atom &psiRules (: $ruleHandle ($context $action $goal (car-atom $context))))
                    (add-atom &psiRules (: $ruleHandle ($context $action $goal (AND_LINK $context))))
                  )
                  $ruleHandle
                )
              )
          )
    )
)



;;additional helpers 
(= (update-atom $space $oatom $natom) (let $_ (remove-atom $space $oatom) (add-atom $space $natom)))
(= (getRuleType $id $space) (collapse (get-type-space $space $id)))
(= (existsIn $space $atom)
   ( let $res (collapse (get-type-space $space $atom)) (not (== (%Undefined%) $res)) )
)
