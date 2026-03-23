!(add-atom &demandSpace (demand responsiveness 0.0 1.0 1.0))
!(add-atom &demandSpace (demand curiosity      0.0 1.0 0.75))
!(add-atom &demandSpace (demand helpfulness    0.0 1.0 0.8))
!(add-atom &demandSpace (demand energy         0.0 1.0 1.0))

(= (totalPoints) 1.0)

(= (removeOccurrences $space)
   (let $atoms (collapse (get-atoms $space))
        (let $_ (collapse (let $a (superpose $atoms) (remove-atom $space $a)))
             ())))

(= (updatePerception $space)
   (let* (
      ($_ (removeOccurrences $space))
      ($obs (py-call (utils.getObservation)))
      ($_ (collapse (addIndividualObservation $obs $space)))
   ) ()))

(= (addIndividualObservation $atoms $space)
   (if (== $atoms ())
      (empty)
      (let* (
         (($head $tail) (decons $atoms))
         ($expr (sread $head))
         ($_ (collapse (add-atom $space $expr)))
         ($_ (collapse (addIndividualObservation $tail $space)))
      ) ())))

(= (getUrgency $space)
   (let $vals (collapse (match $space (urgency $u) $u))
      (if (== $vals ()) 0.0 (car-atom $vals))))

(= (getUnansweredCount $space)
   (let $vals (collapse (match $space (unansweredCount $n) $n))
      (if (== $vals ()) 0 (car-atom $vals))))

(= (getTimeSinceMessage $space)
   (let $vals (collapse (match $space (timeSinceMessage $t) $t))
      (if (== $vals ()) 9999.0 (car-atom $vals))))

(= (hasMessageNow $space)
   (let $vals (collapse (match $space (hasMessage $b) $b))
      (if (== $vals ()) False (car-atom $vals))))

(= (responsivenessUrgency $space)
   (let* (
      ($count   (getUnansweredCount $space))
      ($urgency (getUrgency $space))
      ($combined (+ (* $count 0.3) (* $urgency 0.7)))
   )
   (if (> $combined 1.0) 1.0 $combined)))

(= (getDemandByName $space $name)
   (let $result (collapse (match $space (demand $name $mn $mx $v) (demand $name $mn $mx $v)))
      (if (== $result ()) (demand $name 0.0 1.0 1.0) (car-atom $result))))

(= (safeUpdateDemand $space $name $newVal)
   (let* (
      ($old (getDemandByName $space $name))
      ((demand $name $mn $mx $oldV) $old)
      ($clamped (if (< $newVal 0.0) 0.0 (if (> $newVal 1.0) 1.0 $newVal)))
      ($new (demand $name $mn $mx $clamped))
      ($_ (collapse (remove-atom $space $old)))
      ($_ (add-atom $space $new))
   ) ()))

(= (perceptionToDemands $perceptionSpace $demandSpace)
   (let* (
      ($respUrgency (responsivenessUrgency $perceptionSpace))
      ($respVal (- 1.0 $respUrgency))
      ($_ (safeUpdateDemand $demandSpace responsiveness $respVal))

      ($hasMsg (hasMessageNow $perceptionSpace))
      ($helpVal (if $hasMsg 0.3 0.9))
      ($_ (safeUpdateDemand $demandSpace helpfulness $helpVal))

      ($_ (println! (Demands: responsiveness= $respVal helpfulness= $helpVal)))
   ) ()))

(= (isEdible $item) False)
(= (hasEdibleFood $space) False)
(= (hasFoodNearby $space) False)
(= (hostileNearBy $space) False)