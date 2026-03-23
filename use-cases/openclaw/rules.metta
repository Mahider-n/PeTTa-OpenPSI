(= (addOpenClawRules $space) (
  let $rules (superpose (

    ;; Rule 1: Respond immediately to urgent messages
    (: Rule 1
        (TTV 0)
        (STV 0.95 0.9)
        (Complexity 3)
        (IMPLICATION
            (AND
                (Context (STV 1.0 1.0) (AND (
                    (hasMessage (STV 1.0 1.0))
                    (urgentMessage (STV 1.0 0.95))
                )))
                (Action (SEQ_AND (
                    (respondToMessage)
                )))
            )
            (Goal (STV 1.0 0.95) (AND (
                (messageAnswered (STV 1.0 1.0))
            )))
        )
    )

    ;; Rule 2: Search the web and then respond for info requests
    (: Rule 2
        (TTV 0)
        (STV 0.9 0.85)
        (Complexity 5)
        (IMPLICATION
            (AND
                (Context (STV 1.0 1.0) (AND (
                    (hasMessage (STV 1.0 1.0))
                    (infoRequest (STV 1.0 0.9))
                )))
                (Action (SEQ_AND (
                    (searchWeb)
                    (respondWithSearchResult)
                )))
            )
            (Goal (STV 1.0 0.9) (AND (
                (messageAnswered (STV 1.0 1.0))
            )))
        )
    )

    ;; Rule 3: Respond to non-urgent messages normally
    (: Rule 3
        (TTV 0)
        (STV 0.85 0.8)
        (Complexity 3)
        (IMPLICATION
            (AND
                (Context (STV 1.0 1.0) (AND (
                    (hasMessage (STV 1.0 1.0))
                    (notUrgent (STV 1.0 0.85))
                )))
                (Action (SEQ_AND (
                    (respondToMessage)
                )))
            )
            (Goal (STV 1.0 0.85) (AND (
                (messageAnswered (STV 1.0 1.0))
            )))
        )
    )

    ;; Rule 4: Idle/wait when no messages pending
    (: Rule 4
        (TTV 0)
        (STV 0.8 0.75)
        (Complexity 2)
        (IMPLICATION
            (AND
                (Context (STV 1.0 1.0) (AND (
                    (noMessage (STV 1.0 1.0))
                )))
                (Action (SEQ_AND (
                    (waitForMessage)
                )))
            )
            (Goal (STV 1.0 0.8) (AND (
                (agentReady (STV 1.0 1.0))
            )))
        )
    )

    ;; Rule 5: Proactively explore sessions when curious
    (: Rule 5
        (TTV 0)
        (STV 0.75 0.7)
        (Complexity 4)
        (IMPLICATION
            (AND
                (Context (STV 1.0 1.0) (AND (
                    (noMessage (STV 1.0 1.0))
                    (curiosityHigh (STV 1.0 0.75))
                )))
                (Action (SEQ_AND (
                    (listSessions)
                    (searchWeb)
                )))
            )
            (Goal (STV 1.0 0.75) (AND (
                (Explore (STV 1.0 1.0))
            )))
        )
    )

  ))
  (add-atom $space $rules)
))

!(addOpenClawRules &ruleSpace)
