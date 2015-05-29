from __future__ import division

import os
import sys
import subprocess
import json


chords_lookup = {'C': 1, 'C#': 2, 'D': 3, 'D#': 4, 'E': 5, 'E#': 6, 'F': 7, 'F#': 8, 'G': 9, 'G#': 10, 'A': 11, 'A#': 12, 'B':13, 'B#':14}


def main():
	output = open("mlmydata", 'aw')
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

		silence20_mean = data["lowlevel"]["silence_rate_20dB"]["mean"]
		silence20_dvar = data["lowlevel"]["silence_rate_20dB"]["dvar"]
		silence30_mean = data["lowlevel"]["silence_rate_30dB"]["mean"]
		silence30_dvar = data["lowlevel"]["silence_rate_30dB"]["dvar"]
		silence60_mean = data["lowlevel"]["silence_rate_60dB"]["mean"]
		silence60_dvar = data["lowlevel"]["silence_rate_60dB"]["dvar"]

		dissonance_mean = data["lowlevel"]["dissonance"]["mean"]
		dissonance_dvar = data["lowlevel"]["dissonance"]["dvar"]

		pitch_salience =  data["lowlevel"]["pitch_salience"]["mean"]
		zerocrossingrate = data["lowlevel"]["zerocrossingrate"]["mean"]


		spectral_centroid = data["lowlevel"]["spectral_centroid"]["mean"] #
		spectral_rms = data["lowlevel"]["spectral_rms"]["mean"]
		spectral_energy = data["lowlevel"]["spectral_energy"]["mean"]

		dynamic_complexity = data["lowlevel"]["dynamic_complexity"]

		bmp = data["rhythm"]["bpm"]
		beat_loudness_mean = data["rhythm"]["beats_loudness"]["mean"]
		beat_loudness_dvar = data["rhythm"]["beats_loudness"]["dvar"]

		chords_key = chords_lookup[data["tonal"]["chords_key"]]
		chords_scale = 1 if data["tonal"]["chords_scale"] == "major" else 0
		key_key = chords_lookup[data["tonal"]["key_key"]]
		key_scale = 1 if data["tonal"]["key_scale"] == "major" else 0

		output.write(file_name + '\t' + str(loudness) + '\t' + str(silence20_mean) + '\t' + str(silence20_dvar) + '\t' + str(silence30_mean)+ '\t' + str(silence30_dvar) + '\t' + str(silence60_mean)  \
						+ '\t' + str(silence60_dvar) + '\t' + str(dynamic_complexity) + '\t' + str(bmp) + '\t'  + str(spectral_centroid)  + '\t' + str(spectral_rms) + '\t' + str(spectral_energy) + '\t' +str(beat_loudness_dvar) + '\t' + str(beat_loudness_mean)
						+ '\t' + str(chords_scale) + '\t' + str(chords_key) + '\t' + str(key_key) + '\t' + str(key_scale) + '\t' + str(zerocrossingrate) + '\t' + str(pitch_salience) + '\t' + str(dissonance_mean) + '\t' + str(dissonance_dvar) + " \n")


if __name__ == "__main__":
    main()