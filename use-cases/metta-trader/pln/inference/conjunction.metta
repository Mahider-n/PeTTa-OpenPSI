; Conditional Conjunction Introduction (Goal Aggregation): 
;   creates more complex goals. 
;   Eg. A & B => G1 and A & B => G2 it infers A & B => G1 & G2.

(= (pln-conjunction $rules) (
    let* (
        ($_ (println! "PLN Conjunction Started"))
        ($conjunctions (conjunction-helper $rules))
    ) $conjunctions
))

(= (conjunction-helper $rules) (
    if (<= (size-atom $rules) 1)
        ()
        (let* (
            (($rule $remRules) (decons-atom $rules))
            ($conjunctions (findConjunctions $rule $remRules))
            ($restConjunctions (conjunction-helper $remRules))
        ) (union-atom $restConjunctions $conjunctions))
))

(= (findMatchingConjunctions $ruleContext $ruleAction $rules) (
    if (== $rules ())
        ()
        (let* (
            (($head $tail) (decons-atom $rules))
            ($matchingContext (eval (extractRule ContextValues $head)))
            ($matchingAction (eval (extractRule Action $head)))
            ; ($_ (println! ("Matching context & action :" $matchingContext $matchingAction)))
            ($isContextSimilar (eval (areSimilar $ruleContext $matchingContext)))
            ($isActionSimilar (eval (areSimilar $ruleAction $matchingAction)))
            ($restMatches (findMatchingConjunctions $ruleContext $ruleAction $tail))
        ) (if (and $isContextSimilar $isActionSimilar)
            (cons-atom $head $restMatches)
            $restMatches
        ))
))

(= (findConjunctions $rule $rules) (
    let* (
        ($ruleContext (eval (extractRule ContextValues $rule)))
        ($ruleAction (eval (extractRule Action $rule)))
        ($matchingRules (findMatchingConjunctions $ruleContext $ruleAction $rules))
        ($conjoinedGoals (map-atom $matchingRules $matchingRule (reason-conj $rule $matchingRule)))
    ) $conjoinedGoals
))

(= (reason-conj $rule $matchingRule) (
    let* (
        ($maxRuleId 200) ;; TODO: Fix this for rule IDs

        ($ruleGoal (eval (extractRule Goal $rule)))
        ($matchingRuleGoal (eval (extractRule Goal $matchingRule)))
        ($ruleContext (eval (extractRule Context $rule)))
        ($ruleContextSTV (eval (extractRule ContextSTV $rule)))
        ($ruleAction (eval (extractRule Action $rule)))
        ($ruleGoalSTV (eval (extractRule GoalSTV $rule)))
        ($newGoal (union-atom $ruleGoal $matchingRuleGoal)) 
        ($uniqueNewGoal (unique-atom $newGoal))

        ((STV $ruleStrength $ruleConfidence) (eval (extractRule STV $rule)))
        ((STV $matchingStrength $matchingConfidence) (eval (extractRule STV $matchingRule)))
        ($newStrength (* $ruleStrength $matchingStrength))
        ($newConfidence (min $ruleConfidence $matchingConfidence))
        ($newSTV (STV $newStrength $newConfidence))

        ($newRule (: Rule $maxRuleId (TTV 1) $newSTV (Complexity 1) (IMPLICATION (AND (Context $ruleContextSTV (AND $ruleContext)) (Action (SEQ_AND $ruleAction))) (Goal $ruleGoalSTV (AND $uniqueNewGoal)))))
    ) $newRule
))