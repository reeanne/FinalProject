import mir_eval
import sys

def evaluate_file(file, reference):

	ref_time, ref_freq = mir_eval.io.load_time_series(reference)
	est_time, est_freq = mir_eval.io.load_time_series(file)
	(ref_v, ref_c, est_v, est_c) = mir_eval.melody.to_cent_voicing(ref_time, ref_freq, est_time, est_freq)
	print ref_v, ref_c, est_v, est_c

	recall, false_alarm = mir_eval.melody.voicing_measures(ref_v, est_v)
	print recall, false_alarm


def main():
	estimation_file = sys.argv[1]
	ground_truth_file = sys.argv[2]

	evaluate_file(estimation_file, ground_truth_file)

main()