!(import! &self reasoning-helper)
(= (nars-reasoning $rules) (
    let* (
        ($deductions (applyDeductionNars $rules))
        ;; ($inductions (applyInductionNars $rules))
        ;; ($abductions (applyAbductionNars $rules))
        ;;($exemplifications ()) ;; Todo
        ($inductions ())
        ($abductions ())
    )
    (union-atom $deductions (union-atom $inductions $abductions))
))
