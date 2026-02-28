(= (unify $a $b $then $else)
   (if (= $a $b)
       (eval $then)
       (eval $else)))

(= (extractRule $section $rule) (
    case $section (
        (Id (extractRuleId $rule))
        (TTV (extractRuleTTV $rule))
        (STV (extractRuleSTV $rule))
        (AllContext (extractAllContext $rule))
        (Context (extractRuleContext $rule))
        (ContextSTV (extractRuleContextSTV $rule))
        (ContextValues (extractRuleContextValues $rule))
        (Action (extractRuleAction $rule))
        (ContextAndAction (extractContextAndAction $rule))
        (AllGoal (extractAllGoal $rule))
        (Goal (extractRuleGoal $rule))
        (GoalSTV (extractRuleGoalSTV $rule))
        (GoalValues (extractRuleGoalValues $rule))
        ($default ())
    )
))


(= (extractRuleId $rule) (
    unify (: Rule $id $ttv $stv $complexity $implication) $rule
        $id
        -1
))


(= (extractRuleTTV $rule) (
    unify (: Rule $id (TTV $ttv) $stv $complexity $implication) $rule
        $ttv
        -1
))

(= (extractRuleContext $rule) (
    unify (: Rule $id $ttv $stv $complexity (IMPLICATION (AND (Context $context-stv (AND $context)) $action) $goal))
      $rule
      $context
      empty        
))

(= (extractRuleContextValues $rule) (
    let $contexts (extractRuleContext $rule) (map-atom $contexts $context (car-atom $context))
))

(= (extractRuleAction $rule) (
    unify (: Rule $id $ttv $stv $complexity (IMPLICATION (AND $context (Action (SEQ_AND $action))) $goal)) $rule
        $action
        empty
))

(= (extractRuleGoal $rule) (
    unify (: Rule $id $ttv $stv $complexity (IMPLICATION $and-link (Goal $goal-stv (AND $goal)))) $rule
        $goal
        empty
))

(= (extractRuleGoalValues $rule) (
    let $goals (eval (extractRuleGoal $rule)) (map-atom $goals $goal (car-atom $goal))
))

(= (extractRuleSTV $rule) (
    unify (: Rule $id $ttv (STV $s $c) $complexity $implication) $rule
        (STV $s $c)
        (STV 1 0)
))

(= (extractRuleContextSTV $rule) (
    unify (: Rule $id $ttv $stv $complexity (IMPLICATION (AND (Context $cont-stv $contexts) $actions) $goal)) $rule
        $cont-stv
        (STV 1 0)
))

(= (extractRuleGoalSTV $rule) (
    unify (: Rule $id $ttv $stv $complexity (IMPLICATION (AND $context $action) (Goal $goal-stv $goals))) $rule
        $goal-stv
        (STV 1 0)
))

(= (extractContextAndAction $rule) (
    unify (: Rule $id $ttv $stv $complexity (IMPLICATION $contextAction $goal)) $rule
        $contextAction
        empty
))

(= (extractAllGoal $rule) (
    unify (: Rule $id $ttv $stv $complexity (IMPLICATION $contextAction $goal)) $rule
        $goal
        empty
))

(= (extractAllContext $rule) (
    unify (: Rule $id $ttv $stv $complexity (IMPLICATION (AND $context $action) $goal)) $rule
        $context
        empty
))
;; Save Division: Avoids dividing by zero

(= (/safe $A $B) (
    if (> $B 0.0)
       (/ $A $B)
       (empty))
)


(= (isMember $list $val) (
    let $exists (collapse (let $member (superpose $list) (if (== $member $val) True (empty))))
    (if (== $exists ()) 0 1)
))


(= (sum $list) (
    if (== $list ())
        0
        (let* (
            (($head $tail) (decons-atom $list))
            ($rest (sum $tail))
        ) (+ $head $rest))
))


(= (countSimilar $listOne $listTwo) (
    let* (
        ($count (collapse (let $value (superpose $listOne) (let $isIn (isMember $listTwo $value) $isIn))))
    ) (sum $count)
))

(= (areSimilar $listOne $listTwo) 
    (if (not (== (size-atom $listOne) (size-atom $listTwo)))
        False
        (if (== (size-atom $listOne) (countSimilar $listOne $listTwo))
            True 
            False)
))

(= (clearSpace $space)
  (match $space $atom
    (remove-atom $space $atom)
  )
)

; (= (round $x $d) 
;    (py-call ("round" $x $d)))


(= (toInt $num) (
    py-call ("int" $num)
))



(= (flattenList $list) (
    if (== () $list)
        ()
        (let* (
            (($head $tail) (decons-atom $list))
            ($rest (flattenList $tail))
        ) (union-atom $head $rest))
))