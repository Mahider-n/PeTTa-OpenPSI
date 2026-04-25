
(= (openClawGoalSelector $x) (
  case $x (
    (responsiveness (Goal messageAnswered 1.0 0.9))
    (helpfulness    (Goal messageAnswered 1.0 0.85))
    (curiosity      (Goal Explore 1.0 0.5))
    (energy         (Goal agentReady 1.0 0.8))
    ($default       (Goal agentReady 1.0 0.5))
  )))

(= (urgencyThreshold) 0.5)

(= (isUrgentNow)
   (let $vals (collapse (match &perceptionSpace (urgency $u) $u))
      (if (== $vals ())
         False
         (>= (car-atom $vals) (urgencyThreshold)))))

(= (hasMessageNowGlobal)
   (let $vals (collapse (match &perceptionSpace (hasMessage $b) $b))
      (if (== $vals ()) False (car-atom $vals))))

(= (noMessageNow)
   (not (hasMessageNowGlobal)))

(= (isCuriosityHighNow)
   (let $vals (collapse (match &demandSpace (demand curiosity $mn $mx $val) $val))
      (if (== $vals ()) False (>= (car-atom $vals) 0.6))))

(= (contextAtomName $ctxAtom)
   (case $ctxAtom (
      (($name (STV $s $c)) $name)
      (($name $x)          $name)
      ($name               $name)
   )))

(= (evalContextPredicate $name)
   (case $name (
      (hasMessage     (hasMessageNowGlobal))
      (noMessage      (noMessageNow))
      (urgentMessage  (isUrgentNow))
      (notUrgent      (not (isUrgentNow)))
      (infoRequest    (isUrgentNow))
      (curiosityHigh  (isCuriosityHighNow))
      ($_ False)
   )))

(= (isContextAtomApplicable $ctxAtom)
   (let $ctxName (contextAtomName $ctxAtom)
      (evalContextPredicate $ctxName)))

(= (isContextApplicable $ctxAtoms)
   (if (== $ctxAtoms ())
      True
      (let* (
         (($head $tail) (decons-atom $ctxAtoms))
         ($isHeadApplicable (isContextAtomApplicable $head))
         ($_ (println! (Context: $head -> $isHeadApplicable)))
      )
      (if $isHeadApplicable
         (isContextApplicable $tail)
         False))))

(= (isContextApplicable $ctxAtoms $currentContext)
   (isContextApplicable $ctxAtoms))

(= (filterRulesByContext $ruleIds $space)
   (if (== $ruleIds ())
      ()
      (let* (
         (($head $tail) (decons-atom $ruleIds))
         ($ctxAtoms (eval (getContextAtoms $head $space)))
         ($isMatch  (isContextApplicable $ctxAtoms))
         ($filteredTail (filterRulesByContext $tail $space))
      )
      (if $isMatch
         (cons-atom $head $filteredTail)
         $filteredTail))))

(= (performAction $actions)
   (if (== $actions ())
      1
      (let* (
         (($head $tail) (decons-atom $actions))
         ($_ (eval (pushEvent Action ($head))))
         ($result (performSingleAction $head))
         ($_ (println! (Action: $head -> $result)))
         ($_ (updatePerception &perceptionSpace))
      )
      (if (== $result ())
         0
         (performAction $tail)))))

(= (performSingleAction $action) (
  case $action (
    ((respondToMessage)
       (py-call (utils.executeAction send_message)))

    ((respondWithSearchResult)
       (py-call (utils.executeAction send_message_with_search)))

    ((searchWeb)
       (py-call (utils.executeAction web_search)))

    ((listSessions)
       (py-call (utils.executeAction list_sessions)))

    ((waitForMessage)
       (py-call (utils.sleepSeconds 2.0)))

    ($else (let* (
       ($_ (println! (Unknown Action: $else)))
    ) ()))
  )
))

(= (actionPlanner $space $goalName)
   (let* (
      ($goalMatchedRules (eval (matchGoal $goalName $space)))
      ($rules (filterRulesByContext $goalMatchedRules $space))
      ($_ (println! (Goal-Matched: $goalMatchedRules)))
      ($_ (println! (Context-Matched: $rules)))
      ($result (if (== $rules ())
         (() ())
         (let* (
            (($chosenId $score) (eval (sampler $rules $space)))
            ($_ (println! (Chosen-Rule: $chosenId Score: $score)))
            ($actionAtom (eval (getAction $chosenId $space)))
            ((SEQ_AND $actions) $actionAtom)
         )
         ($actions $chosenId))))
   )
   $result))