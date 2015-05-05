from __future__ import division

import os
import sys
import subprocess
import json


chords_lookup = {'C': 1, 'C#': 2, 'D': 3, 'D#': 4, 'E': 5, 'E#': 6, 'F': 7, 'F#': 8, 'G': 9, 'G#': 10, 'A': 11, 'A#': 12, 'B':13, 'B#':14}


def main():
	output = open("MLData", 'aw')
	for i, arg in enumerate(sys.argv):
		if i == 0:
			pass
		else:
			analyse_track(arg, output)
	output.close()


def analyse_track(file, output):
	file_name = os.path.basename(os.path.split(file)[-1])
	outputfile = file_name + 'descriptors'
	subprocess.call(['../essentia-master/build/src/examples/streaming_extractor_music', str(file), outputfile])
	with open(outputfile) as datafile:
		data = json.load(datafile)
		loudness = data["lowlevel"]["average_loudness"]
		silence20 = data["lowlevel"]["silence_rate_20dB"]["dmean"]
		silence30 = data["lowlevel"]["silence_rate_30dB"]["dmean"]
		silence60 = data["lowlevel"]["silence_rate_60dB"]["dmean"]
		spectral_centroid = data["lowlevel"]["spectral_centroid"]["dmean"]
		dynamic_complexity = data["lowlevel"]["dynamic_complexity"]
		bmp = data["rhythm"]["bpm"]
		chords_key = chords_lookup[data["tonal"]["chords_key"]]
		chords_scale = data["tonal"]["chords_scale"] == "major" ? 1 : 0
		key_key = chords_lookup[data["tonal"]["key_key"]]
		key_scale = data["tonal"]["key_scale"] == "major" ? 1: 0

		output.write(file_name + '\t' + str(loudness) + '\t' + str(silence20) + '\t' + str(silence30) + '\t' + str(silence60) + '\t' \
						+ str(dynamic_complexity) + '\t' + str(bmp) + '\t'  + str(spectral_centroid) + '\t' + str(chords_change) + '\t' \
						+ str(chords_scale) + '\t' + str(chords_key) + '\t' + str(key_key) + '\t' + str(key_scale) + " \n")


if __name__ == "__main__":
    main()