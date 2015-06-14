ref_intervals, ref_labels = mir_eval.io.load_labeled_intervals('ref.lab')
est_intervals, est_labels = mir_eval.io.load_labeled_intervals('est.lab')
Trim or pad the estimate to match reference timing
ref_intervals, ref_labels = mir_eval.util.adjust_intervals(ref_intervals,
                                                  ref_labels,
                                                  t_min=0)
est_intervals, est_labels = mir_eval.util.adjust_intervals(est_intervals,
                                                  est_labels,
                                                  t_min=0,
                                                  t_max=ref_intervals.max())
precision, recall, f = mir_eval.structure.pairwise(ref_intervals,
                                                       ref_labels,
                                                       est_intervals,
                                                       est_labels)