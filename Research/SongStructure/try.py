import os
import sys
import subprocess
import numpy as np
import librosa
from scipy.ndimage import filters
from scipy.spatial import distance
import json
import os.path
import pymf
import sys, csv
from essentia import *
from essentia.standard import *
import essentia
from pylab import *
import logging
import sklearn.cluster


def show_matrix(matrix, print_statement):
    import pylab as plt
    print print_statement
    plt.imshow(matrix, interpolation="nearest", aspect="auto")
    plt.show()


def median_filter(X, M=8):
    """ Median filter along the first axis of the feature matrix X. """
    for i in xrange(X.shape[1]):
        X[:, i] = filters.median_filter(X[:, i], size=M)
    return X


def cnmf(S, rank, iterations=500, hull=False):
    """ Convex Non-Negative Matrix Factorization. """
    nmf_mdl = pymf.CNMF(S, num_bases=rank)  
    nmf_mdl.factorize(niter=iterations)

    W = np.asarray(nmf_mdl.W)
    H = np.asarray(nmf_mdl.H)

    return W, H


def most_frequent(x):
    """ Returns the most frequent value in x. """
    return np.argmax(np.bincount(x))


def compute_labels(X, pitch, rank, median_size, bound_idxs, iterations=300):
    vocal = "vocal"
    semi = "semi_vocal"
    instrumental = "instrumental"
    mixed = "mixed"
    labels = []

    bound_intervals = zip(bound_idxs[:-1], bound_idxs[1:])
    for interval in bound_intervals:
        nonzero = np.count_nonzero(pitch[interval[0] : interval[1]])
        if nonzero < (interval[1] - interval[0]) / 4:
            labels.append(instrumental)
        if nonzero < (interval[1] - interval[0]) / 2:
            labels.append(mixed)
        if nonzero < (interval[1] - interval[0]) * 3 / 4:
            labels.append(semi)
        else:
            labels.append(vocal)
    return labels


def compute_labels_old(X, rank, median_size, bound_idxs, iterations=300):
    """ Computes the labels using the bounds. """

    print "Computing Labels."
    try:
        W, H = cnmf(X, rank, iterations=iterations)
    except:
        return [1]

    label_frames = filter_cluster_matrix(W.T, median_size)    # get the border frames. Again. Need to change it.
    label_frames = np.asarray(label_frames, dtype=int)        # convert to numpy array

    labels = []
    bound_intervals = zip(bound_idxs[:-1], bound_idxs[1:])

    for interval in bound_intervals:
        if interval[1] - interval[0] <= 0:
            labels.append(np.max(label_frames) + 1)
        else:
            labels.append(most_frequent(
                label_frames[interval[0]: interval[1]]))

    return labels


def merge_boundaries(W_bounds, H_bounds, window=6):
    bounds = []
    i = 0
    j = 0

    while i < len(W_bounds) and j < len(H_bounds):
        if abs(W_bounds[i] - H_bounds[j]) <= window:
            bounds.append(int(np.average([W_bounds[i], H_bounds[j]])))
            i += 1
            j += 1
        elif W_bounds[i] < H_bounds[j]:
            bounds.append(W_bounds[i])
            i += 1
        else:
            bounds.append(H_bounds[j])
            j += 1

    return bounds


def filter_cluster_matrix(W, median_size):
    """ Filters the cluster matrix F, and returns a flattened copy. """

    indexes = np.argmax(W, axis=0)                      
    max_indexes = np.arange(W.shape[1])                 
    max_indexes = (indexes.flatten(), max_indexes)
    W[:, :] = 0                                         
    W[max_indexes] = indexes + 1                        

    W = np.sum(W, axis=0)                               
    W = median_filter(W[:, np.newaxis], median_size)    
    return W.flatten()


def filter_activation_matrix(H, median_size):
    """ Filters the activation matrix G, and returns a flattened copy. """

    indexes = np.argmax(H, axis=1)                      # Indices of the maximum values in every row, essentially the class assignment.
    max_indexes = np.arange(H.shape[0])                 # Create an array with numbers 0.. G.shape[0].
    max_indexes = (max_indexes, indexes.flatten())
    H[:, :] = 0                                         # Reset G
    H[max_indexes] = indexes + 1                        # For every frame mark it with the most likely assignments  

    H = np.sum(H, axis=1)                               # sum every row, making it a 1d array
    H = median_filter(H[:, np.newaxis], median_size)    
    return H.flatten()


def kmeans_bounds(H, W, rank):
    """ Calculates the borders of the segments using kmeans clustering. """

    C = sklearn.cluster.KMeans(n_clusters=rank, tol=1e-8)

    labels_H = C.fit_predict(H.T)
    bound_H = np.where(np.diff(labels_H) != 0)[0] + 1   # Get the border elements

    labels_W = C.fit_predict(W)
    bound_W = np.where(np.diff(labels_W) != 0)[0] + 1   # Get the border elements
    return merge_boundaries(bound_W, bound_H)


def straightforward_bounds(H, W, median_size):
    """ Calculates the segment boundaries using only the C-NMF. """

    H = filter_activation_matrix(H.T, median_size)
    bound_H = np.where(np.diff(H) != 0)[0] + 1   # Get the border elements

    W = filter_cluster_matrix(W.T, median_size)
    bound_W = np.where(np.diff(W) != 0)[0] + 1

    return merge_boundaries(bound_W, bound_H)


def get_segmentation(X, pitch, rank, median_size, rank_labels, R_labels, iterations=300):
    """ Gets the segmentation (boundaries and labels) from the factorization matrices. """

    # Find non filtered boundaries
    while True:

        try:
            W, H = cnmf(X, rank, iterations=iterations)
        except:
            print "Bounds failed."
            return np.empty(0), [1]

        #bound_idxs = kmeans_bounds(H, W, rank+1)
        bound_indexes = straightforward_bounds(H, W, median_size)

        # Increase rank if we found too few boundaries
        if len(np.unique(bound_indexes)) <= 2:
            rank += 1
            bound_indexes = None
        else:
            break

    # Add first and last boundary
    bound_indexes = np.concatenate(([0], bound_indexes, [X.shape[1] - 1]))
    bound_indexes = np.asarray(bound_indexes, dtype=int)
    #labels = compute_labels(X, pitch, rank_labels, R_labels, bound_idxs, iterations=iterations)
    labels = compute_labels_old(X, rank_labels, R_labels, bound_indexes, iterations=iterations)

    #plt.imshow(G[:, np.newaxis], interpolation="nearest", aspect="auto")
    #for b in bound_idxs:
    #    plt.axvline(b, linewidth=2.0, color="k")
    #plt.show()

    return bound_indexes, labels


def intervals_to_times(intervals):
    """ Given a set of intervals, convert them into times. """
    return np.concatenate((intervals.flatten()[::2], [intervals[-1, -1]]), axis=0)


def remove_empty_segments(times, labels):
    """Removes empty segments if needed."""
    intervals = np.asarray(zip(times[:-1], times[1:]))
    new_intervals = []
    new_labels = []
    for inter, label in zip(intervals, labels):
        if inter[0] < inter[1] and (inter[0] == 0 or inter[1] - inter[0] > 1):
            print inter
            new_intervals.append(inter)
            new_labels.append(label)
    return intervals_to_times(np.asarray(new_intervals)), new_labels


def process_segmentation_level(estimated_indexes, estimated_labels, N, frame_times, dur):
    """ Processes a level of segmentation, and converts it into times. """

    assert estimated_indexes[0] == 0 and estimated_indexes[-1] == N - 1
    estimates_times = np.concatenate(([0], frame_times[estimated_indexes], [dur])) # Add silences, if needed.

    #silence_label = np.max(est_labels) + 1
    silence_label = "silence"
    estimated_labels = np.concatenate(([silence_label], estimated_labels, [silence_label]))

    estimates_times, estimated_labels = remove_empty_segments(estimates_times, estimated_labels)
    return estimates_times, estimated_labels


def postprocess(estimated_indexes, estimated_labels):
    estimated_indexes, estimated_labels = remove_empty_segments(estimated_indexes, estimated_labels)
    estimated_indexes = np.asarray(estimated_indexes, dtype=int)
    return estimated_indexes, estimated_labels


def get_predominant(audio, sampling_rate, size):
    """ Computes the pitches of predominant melody of the song. """
    hop_size = 512
    frame_size = 2048
    run_predominant_melody = PredominantMelody(frameSize=frame_size,
                                               hopSize=hop_size);

    # Load audio file, apply equal loudness filter, and compute predominant melody.
    audio = EqualLoudness()(audio)
    pitch, confidence = run_predominant_melody(audio)

    # Prope the pitches to make the data as small as the other.
    ratio = int(len(pitch) / size)
    pitch = pitch[::ratio]
    pitch = pitch[:-1] if len(pitch) > size else pitch
    return pitch


def extract_features(path):

    frame_size = 2048
    hop_size = 512
    n_mels = 128
    mfcc_coeff = 14
    sampling_rate = 11025

    print "Loading the file for Essentia."
    audio = MonoLoader(filename=path)()

    print "Loading the file for Librosa."
    waveform, _ = librosa.load(path, sr=11025)
    print "HPSS."
    waveform_harmonic, waveform_percussive = librosa.effects.hpss(waveform)

    print "Beats."
    tempo, beats_idx = librosa.beat.beat_track(y=waveform_percussive, sr=sampling_rate, hop_length=hop_size)

    print "Melspectrogram."
    S = librosa.feature.melspectrogram(waveform,
                                       sr=sampling_rate,
                                       n_fft=frame_size,
                                       hop_length=hop_size,
                                       n_mels=n_mels)

    print "MFCCs."
    log_S = librosa.logamplitude(S, ref_power=np.max)
    mfcc = librosa.feature.mfcc(S=log_S, n_mfcc=14).T
    print(len(mfcc))


    print "Predominant."
    pitch = get_predominant(audio, sampling_rate, len(mfcc))
    print len(pitch)


    if os.path.isfile('data.json'):
        with open('data.json') as data_file:    
            print "HPCP 1"
            data = json.load(data_file)
            hpcp = np.array(data["hpcp"])
            print(len(hpcp))
    else:
        print "HPCP 2"
        hpcp = librosa.feature.chroma_cqt(y=waveform_harmonic, sr=sampling_rate,
                                          hop_length=hop_size).T
        print(len(hpcp))
        with open('data.json', 'w') as outfile:
            json.dump({"hpcp": hpcp.tolist()}, outfile)

    #show_matrix(hpcp.T, "unsynched hpcp")
    #show_matrix(mfcc.T, "unsynched mfcc")

    print "Beat synchronising."
    bs_mfcc = librosa.feature.sync(mfcc.T, beats_idx, pad=False).T
    bs_hpcp = librosa.feature.sync(hpcp.T, beats_idx, pad=False).T
    bs_pitch = librosa.feature.sync(pitch.T, beats_idx, pad=False).flatten()

    #show_matrix(bs_hpcp.T, "synched hpcp")
    #show_matrix(bs_mfcc.T, "synched mfcc")
    
    #unsynchSSM = lognormalise_chroma(mfcc)
    #unsynchSSM = compute_ssm(unsynchSSM)
    #show_matrix(unsynchSSM, "unsynched ssm")

    return bs_mfcc, bs_hpcp, beats_idx, waveform.shape[0] / sampling_rate, bs_pitch


def lognormalise_chroma(C):
    """ Log-normalizes chroma such that each vector is between -80 to 0. """
    C += np.abs(C.min()) + 0.1
    C = C / C.max(axis=0)
    C = 80 * np.log10(C)  # Normalize from -80 to 0
    return C


def compute_ssm(X):
    """ Computes the self-similarity matrix of X. """
    D = distance.pdist(X, metric='correlation')
    D = distance.squareform(D)
    D /= D.max()
    return 1 - D


def process_track(path):
    """ Processes the file to get the section boundaries and labels. """
    frame_size = 2048
    hop_size = 512
    n_mels = 128
    mfcc_coeff = 14
    sampling_rate = 11025
    iterations = 500 
    H = 20

    mfcc, hpcp, beats, dur, pitch = extract_features(path)
    hpcp = lognormalise_chroma(hpcp)
    #show_matrix(hpcp.T, "ssm synched")
    
    if hpcp.shape[0] >= H:
        # Median filter
        hpcp = median_filter(hpcp, M=9)
        #show_matrix(hpcp.T, "median filter")

        hpcp = compute_ssm(hpcp)
        #show_matrix(hpcp.T, "SSM")

        print "Segmentation."
        est_idxs, est_labels = get_segmentation(hpcp.T, pitch, 2, 16, 4, 16, iterations=iterations)
        est_idxs = np.unique(np.asarray(est_idxs, dtype=int))
    else:
        # The track is too short. We will only output the first and last
        # time stamps
        est_idxs = np.array([0, F.shape[0]-1])
        est_labels = [1]
  
    # Post process estimations
    est_idxs, est_labels = postprocess(est_idxs, est_labels)
    frames = librosa.frames_to_time(beats, sr=sampling_rate, hop_length=hop_size)
    est_times, est_labels = process_segmentation_level(est_idxs, est_labels,
                                                       hpcp.shape[0], frames, dur)
    np.savetxt(sys.stdout, est_times, '%5.2f')
    print est_times, est_labels
    return est_times, est_labels


def main():    
    if len(sys.argv) > 1:
        path = sys.argv[1]
    else:
        path = "Help.mp3"
    process_track(path)

main()
