; (: addPerceptions (-> hyperon::space::DynSpace Expression (->)))
(= (addPerceptions $space $perceptions)
    (if (== $perceptions ())
        ()
        (let $added (superpose $perceptions) (add-atom $space $added))
    )
)

; (: miner (-> hyperon::space::DynSpace Number Expression))
(= (miner $perceptaSpace $noOfRules)
    (let* (
          ($perceptaList (collapse (get-atoms $perceptaSpace)))
          ($perceptaCount (size-atom $perceptaList))
          ($query (py-call (utils.query_llm $perceptaList $noOfRules $perceptaCount)))
        )
      $query
))
