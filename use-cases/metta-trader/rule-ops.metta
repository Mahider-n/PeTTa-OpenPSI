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

; (: extractRuleId (-> Expression Number))
(= (extractRuleId $rule) (
    unify (: Rule $id $ttv $stv $complexity $implication) $rule
        $id
        -1
))

; (: extractRuleTTV (-> Expression Number))
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
    let $contexts (extractRuleContext $rule) (map-atom $contexts $context ((index-atom $context 0) (index-atom $context 1)))
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
    let $goals (extractRuleGoal $rule) (map-atom $goals $goal ((index-atom $goal 0) (index-atom $goal 1)))
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

;; General Rule helpers

;; For now complexity is the number of actions in the rule

; (= (calculateComplexity $rule) (
;     let* (
;         ($action (extractRuleAction $rule))
;         ($actionCount (size-atom $action))
;     ) $actionCount
; ))

;; This could be optimized by adding an atom that tracks the max TTV in the rule space instead of searching every time
; (: findCurrentTTV (-> hyperon::space::DynSpace Number))
(= (findCurrentTTV $ruleSpace) (
    let* (
        ($rules (collapse (get-atoms $ruleSpace)))
        ($ttvValues (map-atom $rules $rule (extractRule TTV $rule)))
        ($_ (println! ("Current TTV values: " $ttvValues)))
    ) (max-atom $ttvValues) ;; For some reason max-atom returns a float instead of int
))

; (: findCurrentRuleId (-> hyperon::space::DynSpace Number))
(= (findCurrentRuleId $ruleSpace) (
    let* (
        ($rules (collapse (get-atoms $ruleSpace)))
        ($ruleIds (map-atom $rules $rule (extractRule Id $rule)))
        ($_ (println! ("Current Rule IDs: " $ruleIds)))
    ) (max-atom $ruleIds)
))