import sys
import os
import json
import structure
import extract_and_predict
import numpy

output_file = "analysis.json"

def main():
	file = sys.argv[1]
	bounds, labels, pitch = structure.process_track(file)
	filtered_bounds, filtered_labels = structure.merge_bounds(bounds, labels)
	mood = extract_and_predict.process_track(file, filtered_bounds)

	print type(bounds), type(labels), type(pitch), type(filtered_bounds), type(filtered_labels), type(mood)

	output = {"bounds": bounds.tolist(), "labels": labels, "pitch": pitch.tolist(), 
			  "filtered_bounds": filtered_bounds, "filtered_labels": filtered_labels,
			   "mood": mood}

	with open(output_file, 'w') as outfile:
		json.dump(output, outfile)

main()