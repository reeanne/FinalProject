import sys
import os
import json
import structure
import smoothing
import extract_and_predict
import numpy

output_file = "analysis.json"

def main():
	file = sys.argv[1]
	output_file = sys.argv[2]

	median_size = 100
	if (len(sys.argv) > 3):
		median_size = sys.argv[3]

	bounds, labels, pitch, beat_times = structure.process_track(file)
	#pitch = smoothing.rectangular_smooth(pitch.tolist(), 1001, True)
	pitch = smoothing.median_filter(pitch, median_size)
	filtered_bounds, filtered_labels = structure.merge_bounds(bounds, labels)
	mood = extract_and_predict.process_track(file, filtered_bounds)

	print type(bounds), type(labels), type(pitch), type(filtered_bounds), type(filtered_labels), type(mood)

	output = {"bounds": bounds.tolist(), "labels": labels, "pitch": pitch, 
			  "filtered_bounds": filtered_bounds, "filtered_labels": filtered_labels,
			   "mood": mood, "beats": beat_times.tolist()}

	with open(output_file, 'w') as outfile:
		json.dump(output, outfile)

main()