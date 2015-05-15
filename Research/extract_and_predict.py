"get predictions for the song with given features in "

from __future__ import division

import numpy as np
import cPickle as pickle

import os
import sys
import subprocess
import json

from math import sqrt, ceil
from sklearn.metrics import mean_squared_error as MSE


model_file = '/Users/paulinakoch/Documents/Year 4/Project/FinalProject/Research/model.pkl'
output_predictions_file = '/Users/paulinakoch/Documents/Year 4/Project/FinalProject/Research/gamepredictions.json'
min_max_file = '/Users/paulinakoch/Documents/Year 4/Project/FinalProject/Research/minMax.csv'
profile = '/Users/paulinakoch/Documents/Year 4/Project/FinalProject/Research/profile.json'
start = "startTime"
end = "endTime"
_30 = 40

# load model

def main():
	track = sys.argv[1]
	length = int(sys.argv[2])
	analyse_track(track, length)


def analyse_track(file, length):

	net = pickle.load( open( model_file, 'rb' ))

	min_max_fl = np.loadtxt(min_max_file, delimiter = ',' )
	min_max = min_max_fl[:, :]

	# load data

	iterations = int(ceil(length / 30))
	startdata = {}
	file_name = os.path.basename(os.path.split(file)[-1])
	outputfile = 'descriptors.json'
	collected_data = []

	for x in range(0, iterations):

		with open(profile, 'w') as outfile:
			if start in startdata:
				startdata[start] += 30
				startdata[end] += 30
			else:
				startdata[start] = 0
				startdata[end] = 30
			json.dump(startdata, outfile)
			print startdata

		subprocess.call(['/Users/paulinakoch/Documents/Year 4/Project/FinalProject/essentia-master/build/src/examples/streaming_extractor_music', str(file), outputfile, profile])

		with open(outputfile) as datafile:
			data = json.load(datafile)

			loudness = (data["lowlevel"]["average_loudness"] - min_max[0][0]) / (min_max[1][0] - min_max[0][0])
			silence60_mean = (data["lowlevel"]["silence_rate_60dB"]["mean"] - min_max[0][1]) / (min_max[1][1]- min_max[0][1])
			dynamic_complexity = (data["lowlevel"]["dynamic_complexity"] - min_max[0][2]) / (min_max[1][2] - min_max[0][2])
			spectral_centroid = (data["lowlevel"]["spectral_centroid"]["mean"] - min_max[0][3]) / (min_max[1][3] - min_max[0][3])
			spectral_energy = (data["lowlevel"]["spectral_energy"]["mean"] - min_max[0][4]) / (min_max[1][4] - min_max[0][4])
			zerocrossingrate = (data["lowlevel"]["zerocrossingrate"]["mean"] - min_max[0][5]) / (min_max[1][5] - min_max[0][5])
			pitch_salience =  (data["lowlevel"]["pitch_salience"]["mean"] - min_max[0][6]) / (min_max[1][6] - min_max[0][6])
			dissonance_mean = (data["lowlevel"]["dissonance"]["mean"] - min_max[0][7]) / (min_max[1][7] - min_max[0][7])

			input = [loudness, silence60_mean, dynamic_complexity, spectral_centroid, spectral_energy, zerocrossingrate, pitch_salience, dissonance_mean]

			# predict
			p = net.activate(input)
			collected_data.append([p[0], p[1]])
			print collected_data
	
	with open(output_predictions_file, 'w') as outfile:
		json.dump(collected_data, outfile)


if __name__ == "__main__":
    main()
