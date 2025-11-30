
!(import! &self ../monitor-changes)
;!(import! &self ../monitor-changes-helpers)
!(import! &self ../../perception-updater/perception-updater)

;Test 
;setPreviousTime...works
;!(test (setPreviousTime (10 20 30 4)) (20 30))

;update-atom
;!(bind! &t (newSpace))
;!(add-atom &t (A))
;!(add-atom &t (B))
;!(add-atom &t (Link (A) (B)))
;!(collapse (get-atoms &t))
;!(update-atom &t (A) (A (stv 0.9 0.8)))
;!(collapse (get-atoms &t))

;;Test update-drmtc-chng-tv function that updates the predicate (Predicate has-dramatic-changes)
;!(bind! &t (new-space))
;!(update-drmtc-chng-tv ("Predicate has-dramatic-changes") &t (STV 0 0))
;!(update-drmtc-chng-tv ("Predicate has-dramatic-changes") &t (STV 1.0 1.0))
;!(test (get-atoms &t) (("Predicate has-dramatic-changes") (STV 1.0 1.0)))

;!(bind! &z (new-space))
;!(record-changes-tv &z ((L1 A) (L2 A)))
;!(record-changes-arg &z (L1 L2 ))
;!(collapse (get-atoms &z))
;!(if (and 
;       (and 
;         (and 
;           (match &z (LIST_LINK (L1 A)) true)
;           (match &z (LIST_LINK (L2 A)) true)
;         )
;         (and 
;           (match &z (LIST_LINK (L1 L2)) true)
;           (match &z (REFERENCE_LINK ((Predicate change-with-tv) (LIST_LINK (L1 A)))) true)
;         )
;       )
;       (and 
;         (match &z (REFERENCE_LINK ((Predicate change-with-tv) (LIST_LINK (L2 A)))) true)
;         (match &z (REFERENCE_LINK ((Predicate change-with-arg) (LIST_LINK (L1 L2)))) true)
;       )
;     )
;     ("final test passed")
;     ("test failed")
;)

;addAndLink
;!(bind! &r (new-space)) 
;!(test (addAndLink &r (a b) c) (AND_LINK ((a b) c)))
; add the same AND_LINK the second time, it should not be added again. It should 
; return the Already existing AND_LINK.
;!(test (addAndLink &r (a b) c) (AND_LINK ((a b) c)))

;get-type-space and getRuleType
;!(bind! &test (new-space))
;!(add-atom &test (: eat-when-hungry (IMPLICATION_LINK (hungry) (eat food))))
;!(add-atom &test (: eat-when-hungry (TTV 90 (STV 0.9 0.9))))
;!(add-atom &test (: eat-when-hungry Goal))
;!(get-atoms &test)
;!(getRuleType eat-when-hungry &test)
;!(test 
;   (getRuleType eat-when-hungry &test)
;   ((IMPLICATION_LINK (hungry) (eat food)) (TTV 90 (STV 0.9 0.9)) Goal)
;)

;existingIn
;!(bind! &exi (new-space))
;!(test (existsIn &exi hungry-rule) false)
;!(add-atom &exi (: real-atom Goal))
;!(test (existsIn &exi real-atom) true)
;!(test (existsIn &exi hungry-rule) false)

;monitor-changes test
!(bind! &test-space (new-space)) 
!(addRule &test-space a (a1 a2) action g (TTV 10 (STV 0.1 0.1)))
!(addRule &test-space b (b1 b2) action g (TTV 40 (STV 0.1 0.1)))
!(addRule &test-space b' (b1 b2) action g (TTV 40 (STV 0.1 0.1)))
!(addRule &test-space c (c1 c2) action g (TTV 20 (STV 0.1 0.1)))
!(addRule &test-space d (d1 d2) action g (TTV 15 (STV 0.1 0.1)))
!(addRule &test-space e (e1 e2) action g (TTV 13 (STV 0.1 0.1)))
;!(get-atoms &test-space)


!(add-atom &test-space (TimeValue 10 a))
!(add-atom &test-space (TimeValue 40 b))
!(add-atom &test-space (TimeValue 20 c))
!(add-atom &test-space (TimeValue 15 d))
!(add-atom &test-space (TimeValue 13 e))
!(add-atom &test-space (TimeValue 15 a))
!(add-atom &test-space (TimeValue 45 b))
!(add-atom &test-space (TimeValue 25 b'))
!(add-atom &test-space (TimeValue 20 d))
!(add-atom &test-space (TimeValue 18 e))

!(add-atom &test-space (tv_delta 0.1))
;!(get-previous-times &test-space)
;!(collapse (match &test-space (TimeValue $ts $obj) (TimeValue $ts $obj)))
;!(get-atoms &test-space)
!(monitor-changes &test-space)
!(let $res (collapse (match &test-space (REFERENCE_LINK $change) $change)) 
   (test () $res)
   )

!(let $res (match &test-space ((Predicate has-dramatic-change) $tv) $tv) 
   (test $res (STV 0.0 0.0))
   )
!(update-atom &test-space (: b' (TTV 40 (STV 0.1 0.1))) (: b' (TTV 40 (STV 0.5 0.5)))) ;update the tv change on b'


;second test case, when there is change with tv for a rule 
!(monitor-changes &test-space)
!(let $res (match &test-space ((Predicate has-dramatic-change) $tv) $tv) 
   (test $res (STV 1.0 1.0))
   )

!(let $res (collapse (match &test-space (REFERENCE_LINK $change) $change)) 
   (test (((Predicate change-with-tv) (LIST_LINK (b b')))) $res)
   )
