!(import! &self reasoning-helper)
(= (nars-reasoning $rules) (
    let* (
        ($deductions (applyDeduction $rules))
        ;; ($inductions (applyInduction $rules))
        ;; ($abductions (applyAbduction $rules))
        ;;($exemplifications ()) ;; Todo
        ($inductions ())
        ($abductions ())
    )
    (union-atom $deductions (union-atom $inductions $abductions))
))
