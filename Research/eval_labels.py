import structure
import mir_eval
import sys

def evaluate():

	output_predictions_file = "bound_predictions.lab"

	#file = sys.argv[1]
	#comparison = sys.argv[2]
	comparison = sys.argv[1]
	#bounds, labels_, pitch, beat_times, labels = structure.process_track(file)
	bounds = [   0.0, 10.17034014, 14.34993197, 25.21687075, 33.99401361, 51.64117914, 52.47709751, 55.03129252, 90.79002268, 116.51773243, 129.24226757, 134.30421769, 154.3662585, 163.16081633]
	labels = [5, 4, 4, 4, 1, 3, 3, 2, 2, 0, 4, 2, 5]
	boundaries = zip(bounds[:-1], bounds[1:])
	print bounds, labels

	with open(output_predictions_file, 'w') as outfile:
		for (i, bound) in enumerate(boundaries):
			print str(bound[0]) + '\t' + str(bound[1]) + '\t' + str(labels[i]) + '\n'
			outfile.write(str(bound[0]) + '\t\t' + str(bound[1]) + '\t\t' + str(labels[i]) + '\n')

	ref_intervals, ref_labels = mir_eval.io.load_labeled_intervals(comparison)
	print ref_intervals
	est_intervals, est_labels = mir_eval.io.load_labeled_intervals(output_predictions_file)
	print "SDKUAHKDHAK"
	print est_intervals

	P05, R05, F05 = mir_eval.segment.detection(ref_intervals,
	                                        est_intervals,
	                                        window=0.5,
	                                        trim=False)
	print P05, R05, F05

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
	ari_score = mir_eval.segment.ari(ref_intervals, ref_labels,
	                               est_intervals, est_labels)

	S_over, S_under, S_F = mir_eval.segment.nce(ref_intervals,
	                                          ref_labels,
	                                          est_intervals,
	                                          est_labels)
	scores = mir_eval.segment.evaluate(ref_intervals, ref_labels,
	                               est_intervals, est_labels)

	print "precision", precision
	print "recall", recall
	print "f", f
	print "ari_score", ari_score
	print "nce", S_over, S_under, S_F
	print "scores", scores


evaluate()








