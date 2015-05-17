import os
import sys
import subprocess
import numpy
import json
import essentia
import essentia.standard as ES

outputfile = "mfcc"


def extract_mfcc(audio):
	subprocess.call(['/Users/paulinakoch/Documents/Year 4/Project/FinalProject/essentia-master/build/src/examples/streaming_mfcc', audio, outputfile])
	with open(outputfile) as datafile:
		data = json.load(datafile)
		mfcc = data["lowlevel"]["mfcc"]["frames"]







sample_rate = 11025
window_type = "blackmanharris74"
frame_size = 2048
hop_size = 512

# Instantiate Essentia Objects 
loader = ES.MonoLoader(filename="HeyJude.wav", sampleRate=sample_rate);
w = ES.Windowing(type = window_type)
spectrum = ES.Spectrum()
mfcc = ES.MFCC()
hpcp = ES.HPCP()
spectral = ES.SpectralPeaks()

# Load Audio
audio = loader()

# Compute MFCCs
mfccs = []
for frame in ES.FrameGenerator(audio, frameSize = frame_size, hopSize = hop_size):
    mfcc_bands, mfcc_coeffs = mfcc(spectrum(w(frame)))
    mfccs.append(mfcc_coeffs)

# we need to convert the list to an essentia.array first (== numpy.array of floats)
mfccs = essentia.array(mfccs)


hpcps = []
for frame in ES.FrameGenerator(audio, frameSize = frame_size, hopSize = hop_size):
	frequencies, magnitudes = spectral(w(frame))
	hpcps.append(hpcp(frequencies, magnitudes))

# and plot
print mfccs
print hpcps

bt = ES.BeatTrackerMultiFeature()
beats, _ = bt(audio)
print beats

print 'All done!'

mfccs.shape
mfcc.name()