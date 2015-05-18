import os
import sys
import subprocess
import numpy as np
import json
import essentia
import essentia.standard as ES
import librosa
import logging

from pylab import *



outputfile = "mfcc"


def extract_mfcc(audio):
    subprocess.call(['/Users/paulinakoch/Documents/Year 4/Project/FinalProject/essentia-master/build/src/examples/streaming_mfcc', audio, outputfile])
    with open(outputfile) as datafile:
        data = json.load(datafile)
        mfcc = data["lowlevel"]["mfcc"]["frames"]

def chroma_to_tonnetz(C):
    """Transforms chromagram to Tonnetz (Harte, Sandler, 2006)."""
    N = C.shape[0]
    T = np.zeros((N, 6))

    r1 = 1      # Fifths
    r2 = 1      # Minor
    r3 = 0.5    # Major

    # Generate Transformation matrix
    phi = np.zeros((6, 12))
    for i in range(6):
        for j in range(12):
            if i % 2 == 0:
                fun = np.sin
            else:
                fun = np.cos

            if i < 2:
                phi[i, j] = r1 * fun(j * 7 * np.pi / 6.)
            elif i >= 2 and i < 4:
                phi[i, j] = r2 * fun(j * 3 * np.pi / 2.)
            else:
                phi[i, j] = r3 * fun(j * 2 * np.pi / 3.)

    # Do the transform to tonnetz
    for i in range(N):
        for d in range(6):
            denom = float(C[i, :].sum())
            if denom == 0:
                T[i, d] = 0
            else:
                T[i, d] = 1 / denom * (phi[d, :] * C[i, :]).sum()

    return T

def extract_features():

    window_type = "blackmanharris74"
    frame_size = 2048
    hop_size = 512

    # The loader.
    loader = ES.MonoLoader(filename="Houses.wav");

    # Instantiate the algorithms.
    w = ES.Windowing(type = window_type)
    spectrum = ES.Spectrum()
    mfcc = ES.MFCC()
    hpcp = ES.HPCP()
    bt = ES.BeatTrackerMultiFeature()
    spectral = ES.SpectralPeaks()

    # Load Audio.
    audio = loader()

    # Compute MFCCs and HPCPs.
    mfccs = []
    hpcps = []

    for frame in ES.FrameGenerator(audio, frameSize = frame_size, hopSize = hop_size):
        mfcc_bands, mfcc_coeffs = mfcc(spectrum(w(frame)))
        mfccs.append(mfcc_coeffs)
        frequencies, magnitudes = spectral(w(frame))
        hpcps.append(hpcp(frequencies, magnitudes))

    # we need to convert the list to an essentia.array first (== numpy.array of floats)
    mfccs = essentia.array(mfccs)

    ##
    print "Computing HPCPs..."
    CQT         = librosa.cqt(waveform, sampling_rate)
    print "Computing HPCPs..."
    chroma_map  = librosa.filters.cq_to_chroma(CQT.shape[0])
    print "Computing HPCPs..."

    ##



    # Compute beats.
    beats, _ = bt(audio)


    mfccs.shape
    mfcc.name()
    return mfccs, hpcps, beats

def extract_features_librosa():

    frame_size = 2048
    hop_size = 64

    waveform, sampling_rate = librosa.load("HeyJude.wav")
    plot(waveform[1*44100:2*44100])
    show()

    tempo, beat_frames = librosa.beat.beat_track(y=waveform, sr=sampling_rate, hop_length=hop_size)

    #beat_times = librosa.frames_to_time(beat_frames, sr=sampling_rate, hop_length=hop_size)
    print "done beats"

    mfcc = librosa.feature.mfcc(y=waveform, sr=sampling_rate, hop_length=hop_size, n_mfcc=12)
    mfcc_delta = librosa.feature.delta(mfcc)
    print "done mfcc"

    beat_mfcc_delta = librosa.feature.sync(np.vstack([mfcc, mfcc_delta]), beat_frames)

    waveform_harmonic, waveform_percussive = librosa.effects.hpss(waveform)

    chromagram = librosa.feature.chromagram(y=waveform_harmonic, sr=sampling_rate, hop_length=hop_size)
    print "chromagram basic done"

    beat_chroma = librosa.feature.sync(chromagram, beat_frames, aggregate=np.median)

    beat_features = np.vstack([beat_chroma, beat_mfcc_delta])

    print beat_features
    from matplotlib.colors import LogNorm
    imshow(beat_features.T, aspect = 'auto')
    show()


def extract_features_librosa2():

    frame_size = 2048
    hop_size = 512
    n_mels = 128
    mfcc_coeff = 12

    print "Loading the file."
    waveform, sampling_rate = librosa.load("HeyJude.wav")
    print "HPSS."
    waveform_harmonic, waveform_percussive = librosa.effects.hpss(waveform)

    #plot(waveform[1*44100:2*44100])
    #show()
    print "Beats."
    tempo, beats_idx = librosa.beat.beat_track(y=waveform_percussive, sr=sampling_rate, hop_length=hop_size)

    #frame_time = librosa.frames_to_time(beats_idx, sr=sampling_rate, hop_length=hop_size)

    print "Melspectrogram."
    S = librosa.feature.melspectrogram(waveform, sr=sampling_rate, n_fft=frame_size, hop_length=hop_size, n_mels=n_mels)

    print "MFCCs."
    log_S = librosa.logamplitude(S, ref_power=np.max)
    mfcc = librosa.feature.mfcc(S=log_S, n_mfcc=12).T

    print "HPCP"
    hpcp = librosa.feature.chroma_cqt(y=waveform_harmonic, sr=sampling_rate, hop_length=hop_size).T

    print "Tonnetz."
    tonnetz = chroma_to_tonnetz(hpcp)

    print "Beat synchronising."
    bs_mfcc = librosa.feature.sync(mfcc.T, beats_idx, pad=False).T
    bs_hpcp = librosa.feature.sync(hpcp.T, beats_idx, pad=False).T
    bs_tonnetz = librosa.feature.sync(tonnetz.T, beats_idx, pad=False).T

    print "before plotting"
    plot(bs_tonnetz)

    return bs_mfcc, bs_hpcp, bs_tonnetz

extract_features_librosa2()
