!(import! &self ../../main/mind-agents/action-planner/action-planner-v2)
!(import! &self ../../main/type)
!(import! &self ../../main/rules/rule) 
!(import! &self ../../utils)


!(bind! &r (new-space))

!(bind! sleep (py-atom time.sleep))


(= (ping) (let $t (sleep 1)  (println! (Just ball is pinged))))

(= (pong) 
    (let*
    
        (
            ($t (sleep 1))
            ($du (decrease-urge (ball is ponged) 1 &r))
        ) 
            (println! (Just ball is ponged))
    )
)

(= (pong-step) 
    (let*
    
        (
            ($t (sleep 1))
            ($urge (urge-value (ball is ponged) &r))
        ) 

        (if (< $urge 0.7)
            (let $p (println! (Not yet feeling like ponging the ball. Urge = $urge))
            (increase-urge (ball is ponged) 0.2 &r))
            
            (let* 
                (
                ($p (println! (Feeling like ponging the ball. Urge = $urge)))
                ($inc (increase-urge (ball is ponged) 0.2 &r))
                )
                (pong)
                
            )
        )
    )
)

(= (pong-step-loop)
    (let $urge (urge-value (ball is ponged) &r)
        
        (if (< $urge 0.7)
            (let $ps (pong-step) (pong-step-loop)) ; recursively call until urge >= 0.7
            (pong-step) ;  call to trigger pong when urge >= 0.7
        )
    )
)

(=(reverse $list $acc)  
    (if(== $list ()) $acc
    (let ($head $tail ) (decons-atom $list) (reverse $tail (cons-atom $head $acc) ))
    )
)

!(addGoal (ball is neutral) 0.0 1.0 &r)
!(addGoal (ball is pinged) 0.0 1.0 &r)
!(addGoal (ball is ponged) 1.0 1.0 &r)

; qoute the actions for the plannerAdd commentMore actions
!(addRule &r r1 ((ball is neutral))  (quote (ping)) (ball is pinged) (TTV 0 (STV 1.0 1.0)))
!(addRule &r r2 ((ball is pinged))  (quote (pong-step-loop)) (ball is ponged) (TTV 0 (STV 1.0 1.0)))
!(addRule &r r3 ((ball is ponged))  (quote (ping)) (ball is pinged) (TTV 0 (STV 1.0 1.0)))


; !(let $planner (hillClimbingPlanner  (ball is neutral) (ball is ponged) (&TestedActions) () &r) (reverse $planner ()))


; ; to see the actions step
!(ping)
 
; !(pong-step-loop)
