import mir_eval
import sys
import json
import os


def evaluate_file(file, reference):


	ref_time, ref_freq = mir_eval.io.load_time_series(reference)
	est_time, est_freq = mir_eval.io.load_time_series(file)
	(ref_v, ref_c, est_v, est_c) = mir_eval.melody.to_cent_voicing(ref_time, ref_freq, est_time, est_freq)
	print ref_v, ref_c, est_v, est_c

	recall, false_alarm = mir_eval.melody.voicing_measures(ref_v, est_v)
	print recall, false_alarm

	raw_pitch = mir_eval.melody.raw_pitch_accuracy(ref_v, ref_c,
                                                   est_v, est_c)
	print raw_pitch


	raw_chroma = mir_eval.melody.raw_chroma_accuracy(ref_v, ref_c,
                                                   est_v, est_c)
	print raw_chroma
	

def parse_file(file, minimum):
    name = os.path.splitext(file)[0]
    name = name + '_formatted.txt'
    result = open(str(name), 'w+')
    with open(file) as datafile:
		data = json.load(datafile)
		for i in range(0, minimum):
			pitches = data["tonal"]["predominant_melody"]["pitch"]
			to_write = str(i / float(minimum)) + '\t' + str(pitches[i]) + '\n'
			result.write(to_write)
		return name


def file_len(fname):
    with open(fname) as f:
        for i, l in enumerate(f):
            pass
    return i + 1


def parse_ground(file, len):
	name = os.path.splitext(file)[0]
	name = name + '_formatted2.txt'
	result = open(str(name), 'w+')
	with open(file) as input:
		for (i, line) in enumerate(input):
			if i % 2 == 0 and i <= len:
				result.write(line)
		return name


def parse_durrieu(file, len):
	name = os.path.splitext(file)[0]
	name = name + '_formatted2.txt'
	result = open(str(name), 'w+')
	with open(file) as input:
		for (i, line) in enumerate(input):
			to_write = str(i / float(len)) + '\t'  + str(line.strip().split('\t')[1]) + '\n'
			result.write(to_write)
		return name



def parse_files(file1, file2):
	f1, f2 = 0, 0
	with open(file1) as datafile:
		data = json.load(datafile)
		f1 = len(data["tonal"]["predominant_melody"]["pitch"])
	with open(file2) as datafile:
		data = json.load(datafile)
		f2 = len(data["tonal"]["predominant_melody"]["pitch"])
	result = min(f1, f2)
	return result



def main():
	estimation_file = sys.argv[1]
	ground_truth_file = sys.argv[2]

	len1, len2 = file_len(estimation_file), file_len(ground_truth_file)
	print len1
	print len2
	ground_truth_file = parse_ground(ground_truth_file, len1)
	estimation_file = parse_durrieu(estimation_file, len1)

	print file_len(ground_truth_file)

	evaluate_file(estimation_file, ground_truth_file)

main()

