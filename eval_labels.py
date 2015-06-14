import structure
import mir_eval
import sys

def evaluate():

    output_predictions_file = "bound_predictions.lab"

    #file = sys.argv[1]
    #comparison = sys.argv[2]
    comparison = sys.argv[1]
    #bounds, labels, pitch, beat_times = structure.process_track(file)
    bounds = [ 0.0, 3.25079365, 8.45206349, 11.70285714, 29.58222222, 41.9352381, 49.73714286, 70.86730159, 82.24507937, 90.04698413, 111.22358277, 122.97287982, 130.49614512, 134.09333333]
    labels = [5, 2, 4, 1, 3, 0, 1, 3, 0, 1, 3, 0, 5]
    boundaries = zip(bounds[:-1], bounds[1:])


     with open(output_predictions_file, 'w') as outfile:
          for (i, bound) in enumerate(boundaries):
               print str(bound[0]) + '\t' + str(bound[1]) + '\t' + str(labels[i]) + '\n'
               outfile.write(str(bound[0]) + '\t' + str(bound[1]) + '\t' + str(labels[i]) + '\n')

     ref_intervals, ref_labels = mir_eval.io.load_labeled_intervals(comparison)
     print ref_intervals
     est_intervals, est_labels = mir_eval.io.load_labeled_intervals(output_predictions_file)
     print est_intervals
     
     # Trim or pad the estimate to match reference timing
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

     print "precision", precision
     print "recall", recall
     print "f", f


evaluate()








