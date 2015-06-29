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
		median_size = int(sys.argv[3])

	bounds, labels, pitch, beat_times, numeric = structure.process_track(file)
	#[   0.            1.11455782  176.23945578  181.06920635  202.2922449 256.85913832  280.        ]
	# ['silence', 'verse', 'chorus', 'verse', 'outro', 'silence']
	#pitch = smoothing.rectangular_smooth(pitch.tolist(), 1001, True)
	bounds = numpy.asarray([0.0, 1.0, 18.0, 54., 100., 108., 122., 186., 200., 245., 273., 280.])
	labels = ["silence", "intro", "verse", "chorus", "bridge", "verse", "chorus", "bridge", "chorus", "outro", "silence"]
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