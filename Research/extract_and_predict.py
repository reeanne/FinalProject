"get predictions for the song with given features in "

import numpy as np
import cPickle as pickle


import os
import sys
import subprocess
import json

from math import sqrt
from sklearn.metrics import mean_squared_error as MSE

model_file = 'model.pkl'
output_predictions_file = 'gamepredictions.txt'
min_max_file = 'minMax.csv'

# load model

def main():
	for i, arg in enumerate(sys.argv):
		if i == 0:
			pass
		else:
			analyse_track(arg)

def analyse_track(file):

	net = pickle.load( open( model_file, 'rb' ))

	min_max_fl = np.loadtxt(min_max_file, delimiter = ',' )
	min_max = min_max_fl[:, :]

	# load data

	file_name = os.path.basename(os.path.split(file)[-1])
	outputfile = file_name + 'descriptors'
	subprocess.call(['../essentia-master/build/src/examples/streaming_extractor_music', str(file), outputfile])

	with open(outputfile) as datafile:
		data = json.load(datafile)

		silence60_mean = (data["lowlevel"]["silence_rate_60dB"]["mean"] - min_max[0][0]) / (min_max[1][0] - min_max[0][0])
		silence60_dvar = (data["lowlevel"]["silence_rate_60dB"]["dvar"]  - min_max[0][1]) / (min_max[1][1]- min_max[0][1])
		dynamic_complexity = (data["lowlevel"]["dynamic_complexity"] - min_max[0][2]) / (min_max[1][2] - min_max[0][2])
		spectral_centroid = (data["lowlevel"]["spectral_centroid"]["mean"] - min_max[0][3]) / (min_max[1][3] - min_max[0][3])
		spectral_energy = (data["lowlevel"]["spectral_energy"]["mean"] - min_max[0][4]) / (min_max[1][4] - min_max[0][4])
		zerocrossingrate = (data["lowlevel"]["zerocrossingrate"]["mean"] - min_max[0][5]) / (min_max[1][5] - min_max[0][5])
		pitch_salience =  (data["lowlevel"]["pitch_salience"]["mean"] - min_max[0][6]) / (min_max[1][6] - min_max[0][6])
		dissonance_mean = (data["lowlevel"]["dissonance"]["mean"] - min_max[0][7]) / (min_max[1][7] - min_max[0][7])

		input = [silence60_mean, silence60_dvar, dynamic_complexity, spectral_centroid, spectral_energy, zerocrossingrate, pitch_salience, dissonance_mean]

		os.remove(outputfile)

		# predict
		p = net.activate(input)

		np.savetxt( output_predictions_file, p, fmt = '%.6f' )

if __name__ == "__main__":
    main()
