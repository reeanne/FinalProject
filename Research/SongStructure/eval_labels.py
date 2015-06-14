import structure
import mir_eval
import sys

def evaluate():

    output_predictions_file = "bound_predictions.lab"

    #file = sys.argv[1]
    #comparison = sys.argv[2]
    comparison = sys.argv[1]
    #bounds, labels, pitch, beat_times = structure.process_track(file)
    bounds = [ 0.00000000e+00, 1.85759637e-01, 1.42570522e+01, 2.51239909e+01, 3.15791383e+01, 3.43655329e+01, 4.50931519e+01, 9.08364626e+01, 1.17400091e+02, 1.69459229e+02, 2.19521451e+02, 2.42880726e+02, 2.86441361e+02, 2.90226667e+02]
    labels = [5, 1, 3, 4, 3, 1, 3, 2, 3, 2, 3, 4, 5]
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
	precision, recall, f = mir_eval.segment.pairwise(ref_intervals,
	                                               ref_labels,
	                                               est_intervals,
	                                               est_labels)

	print "precision", precision
	print "recall", recall
	print "f", f


evaluate()








