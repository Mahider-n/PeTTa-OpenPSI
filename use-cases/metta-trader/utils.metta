(= (round-float $num $decimalPlace) (py-call (round $num $decimalPlace)))
(= (getPlanetFromContexts $contexts) (
    let* (
        (($head $tail) (decons-atom $contexts))
        (($data $stv) $head)
        ($contextType (index-atom $data 0))
        ($contextValue (index-atom $data 1))
    ) (if (== $contextType PLANET)
        $contextValue
        (getPlanetFromContexts $tail)
    ))
)

(= (isValidRule $contexts $money $rule) (
    let* (
        ($ruleContext (extractRule ContextValues $rule))
        ($ruleActions (extractRule Action $rule))
        ($currPlanet (getPlanetFromContexts $contexts))
        ($rulePlanet (getPlanetFromContexts $ruleContext))
    ) 
    (if (not (== $currPlanet $rulePlanet)) 
        False
        (isValidActions $rule $ruleActions $contexts $money)
    )
))

(= (isValidActions $rule $actions $contexts $money) (
    if (== $actions ())
        True
        (let* (
            (($head $tail) (decons-atom $actions))
            ($isValid (isValidSingleAction $rule $head $contexts $money))
            (($newContexts $newMoney) (applySingleAction $rule $head $contexts $money))
            ($isValid2 (if $isValid (isValidActions $rule $tail $newContexts $newMoney) False))
        ) $isValid2
        )
))

(= (isValidSingleAction $rule $action $contexts $money) (
    let* (
        ($actionType (index-atom $action 0))
        ($ruleGoal (extractRule GoalValues $rule))
        ($currPlanet (getPlanetFromContexts $contexts))
    ) (case $actionType (
            (TRAVEL (
                let* (
                    ($source $currPlanet)
                    ($destination (getPlanetFromContexts $ruleGoal))
                    ($cost 1)
                ) (if (> $cost $money)
                    False
                    True
                )
            ))

            (SELL (
                let* (
                    ($item (index-atom $action 1))
                    (($foundName $stv) (getItem $contexts $item))
                ) (if (== $item $foundName)
                    True
                    False
                )
            ))

            (BUY (
                let* (
                    ($item (index-atom $action 1))
                    ($itemPrice (eval (getItemPrice $item $currPlanet)))
                ) (if (>= $money $itemPrice ) 
                    True
                    False
                )
            ))
    ))
))

(= (getApplicableRules $contexts $money $rules) (
    if (== () $rules)
        ()
        (let* (
            (($head $tail) (decons-atom $rules))
            ;; ($_ (println! (head $head)))
            ($isValid (isValidRule $contexts $money $head))
            ($rest (getApplicableRules $contexts $money $tail))
        ) (if $isValid
            (cons-atom $head $rest)
            $rest
        ))
))

(= (updatePlanet $contexts $planet) (
    if (== $contexts ())
        ()
        (let* (
            (($head $tail) (decons-atom $contexts))
            (($data $stv) $head)
            ($contextType (index-atom $data 0))
            ($rest (updatePlanet $tail $planet))
        ) (if (== $contextType PLANET)
            (cons-atom ((PLANET $planet) $stv) $rest)
            (cons-atom $head $rest)
        )))
)

(= (addItem $contexts $newItem $newStv) (
    if (== $contexts ())
        (cons-atom ((HAS $newItem) $newStv) ())
        (let* (
            (($head $tail) (decons-atom $contexts))
            (($data $stv) $head)
            ($rest (addItem $tail $newItem $newStv))
        ) (if (== $data (HAS $newItem))
            $rest
            (cons-atom $head $rest)
        ))
))

(= (removeItem $contexts $item) (
    if (== $contexts ())
        ()
        (let* (
            (($head $tail) (decons-atom $contexts))
            (($data $stv) $head)
            ($contextType (index-atom $data 0))
            ($contextValue (index-atom $data 1))
            ($rest (removeItem $tail $item))
        ) (if (and (== $contextType HAS) (== $contextValue $item))
            $rest
            (cons-atom $head $rest)
        ))
))

(= (applyTravel $rule $contexts $money) (
    let* (
        ($ruleGoal (extractRule GoalValues $rule))
        ($source (getPlanetFromContexts $contexts))
        ($destination (getPlanetFromContexts $ruleGoal))
        ($cost 1)
        ($newContext (updatePlanet $contexts $destination))
        ($newMoney (- $money $cost))
    ) ($newContext $newMoney)
))

(= (applySell $item $contexts $money) (
    let* (
        ($planet (getPlanetFromContexts $contexts))
        ($newContext (removeItem $contexts $item))
        ($newMoney (+ $money (eval (getItemPrice $item $planet))))
    ) ($newContext $newMoney)
))

(= (applyBuy $rule $contexts $money) (
    let* (
        ($ruleGoal (extractRule GoalValues $rule))
        (($item $stv) (getItem $ruleGoal))
        ($planet (getPlanetFromContexts $contexts))
        ($itemPrice (eval (getItemPrice $item $planet)))
        ($newContext (addItem $contexts $item $stv))
        ($newMoney (- $money $itemPrice))
    ) ($newContext $newMoney)
))

(= (applySingleAction $rule $action $contexts $money) (
    let* (
        ($actionType (index-atom $action 0))
    ) (case $actionType (
        (TRAVEL (applyTravel $rule $contexts $money))
        (SELL (applySell (index-atom $action 1) $contexts $money ))
        (BUY (applyBuy $rule $contexts $money))
    ))
))

(= (applyActions $rule $actions $contexts $money) (
    if (== $actions ())
        ($contexts $money)
        (let* (
            (($head $tail) (decons-atom $actions))
            (($newContexts $newMoney) (applySingleAction $rule $head $contexts $money))
        ) (applyActions $rule $tail $newContexts $newMoney))
))

(= (applyRule $rule $contexts $money) (
    let $actions (extractRule Action $rule)
    (applyActions $rule $actions $contexts $money)
))

(= (getItem $contexts) (
    if (== $contexts ())
        (() ())
        (let* (
            (($head $tail) (decons-atom $contexts))
            (($data $stv) $head)
            ($contextType (index-atom $data 0))
            ($itemName (index-atom $data 1))
        ) (if (== $contextType HAS)
            ($itemName $stv)
            (getItem $tail)
        ))
))

(= (getItem $contexts $targetItem) (
    if (== $contexts ())
        (() ())
        (let* (
            (($head $tail) (decons-atom $contexts))
            (($data $stv) $head)
            ($contextType (index-atom $data 0))
            ($itemName (index-atom $data 1))
        ) (if (and (== $contextType HAS) (== $itemName $targetItem))
            ($itemName $stv)
            (getItem $tail $targetItem)
        ))
))

(= (evaluateState $contexts $money) (
    let* (
        (($item $stv) (getItem $contexts))
        ($itemValue (if (== $item ())
            0
            (eval (getAvgPrice $item))
        ))
    ) (+ $itemValue $money)
))

(= (updateBeta $alpha $beta $reward) (
    if (== $reward 0) 
        ((+ 1 $alpha) (+ 1 $beta))
        (if (> $reward 0)
            ((+ $alpha $reward) $beta)
            ($alpha (+ $beta (abs-math $reward)))
        )
))

(= (dynamicBetaUpdate $alpha $beta $reward) (
    let* (
        (($updatedAlpha $updatedBeta) (updateBeta $alpha $beta $reward))
        ;; ($updatedAlpha (round-float $resultAlpha 3))
        ;; ($updatedBeta (round-float $resultBeta 3))
        ($threshold 10)
        ($discountFactor (/ $threshold (+ 1 $threshold)))
        ($_ (println! (Updated Alpha: $updatedAlpha Updated Beta: $updatedBeta Discount Factor: $discountFactor)))
    ) (if (>= (+ $alpha $beta) $threshold)
        ( (* $updatedAlpha $discountFactor)  (* $updatedBeta $discountFactor) )
        ( $updatedAlpha   $updatedBeta ))
))

(= (updateSTV $rule ($strength $confidence)) (
    let* (
        ((: Rule $id $ttv (STV $s $c) $comp $impl) $rule)
        ($_ (println! (the stv in update $s $c $ttv)))
    ) (: Rule $id $ttv (STV $strength $confidence) $comp $impl)
))

(= (updateRule $rule $reward) (
    let* (
        ($ruleAction (eval (extractRule Action $rule)))
        ((STV $s $c) (eval (extractRule STV $rule)))
        (($alpha $beta) (eval (stvToBeta ($s $c))))
        (($newAlpha $newBeta) (dynamicBetaUpdate $alpha $beta $reward))
        (($newStrength $newConfidence) (eval (betaToSTV ($newAlpha $newBeta))))
    ) (if (== $ruleAction ((TRAVEL)))
        $rule
        (updateSTV $rule ($newStrength $newConfidence))
    )
))



(= (add-atoms $space $values) 
    (if (== $values ()) 
        ()
        (let* (
            (($head $tail) (decons-atom $values))
            ($_ (add-atom $space $head))
        )
            (add-atoms $space $tail)
        )
    )
)
;; Update Atoms in a space
(= (updateAtom $oatom $natom $space) (let $_ (remove-atom $space $oatom) (add-atom $space $natom)))