(= (areEqualRules $rule1 $rule2)
    (let* (
        ((: Rule $id $ttv $stv $complexity (IMPLICATION (AND $context (Action (SEQ_AND $action))) $goal)) $rule1)
        ((: Rule $id2 $ttv2 $stv2 $complexity2 (IMPLICATION (AND $context2 (Action (SEQ_AND $action2))) $goal2)) $rule2)
        ($content1 ($stv $complexity $context $action $goal))
        ($content2 ($stv2 $complexity2 $context2 $action2 $goal2))
        ($_ (println! (content $content1)))
        ($_ (println! (content $content2)))
    )
        (== $content1 $content2)
    )
)


