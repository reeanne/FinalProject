import os
import sys
import subprocess
import numpy as np
import essentia
import essentia.standard as ES
import librosa
from scipy.ndimage import filters
from scipy.spatial import distance
import json
import os.path
import pymf
import sys, csv
from essentia import *
from essentia.standard import *
from pylab import *
import logging


def median_filter(X, M=8):
    """Median filter along the first axis of the feature matrix X."""
    for i in xrange(X.shape[1]):
        X[:, i] = filters.median_filter(X[:, i], size=M)
    return X


def cnmf(S, rank, iterations=500, hull=False):
    """(Convex) Non-Negative Matrix Factorization.
    Parameters
    ----------
    S: np.array(p, N)
        Features matrix. p row features and N column observations.
    rank: int
        Rank of decomposition
    iterations: int
        Number of iterations to be used
    Returns
    -------
    F: np.array
        Cluster matrix (decomposed matrix)
    G: np.array
        Activation matrix (decomposed matrix)
        (s.t. S ~= F * G)
    """

    nmf_mdl = pymf.CNMF(S, num_bases=rank)  
    nmf_mdl.factorize(niter=iterations)
    F = np.asarray(nmf_mdl.W)
    G = np.asarray(nmf_mdl.H)
    return F, G



def most_frequent(x):
    """Returns the most frequent value in x."""
    return np.argmax(np.bincount(x))


def compute_labels(X, rank, median_size, bound_idxs, iterations=300):
    """Computes the labels using the bounds."""

    print "Computing Labels."
    try:
        F, G = cnmf(X, rank, iterations=iterations)
    except:
        return [1]

    label_frames = filter_activation_matrix(G.T, median_size)
    label_frames = np.asarray(label_frames, dtype=int)

    labels = []
    bound_intervals = zip(bound_idxs[:-1], bound_idxs[1:])
    for bound_inter in bound_intervals:
        if bound_inter[1] - bound_inter[0] <= 0:
            labels.append(np.max(label_frames) + 1)
        else:
            labels.append(most_frequent(
                label_frames[bound_inter[0]: bound_inter[1]]))

    return labels


def filter_activation_matrix(G, median_size):
    """Filters the activation matrix G, and returns a flattened copy."""
    idx = np.argmax(G, axis=1)
    max_idx = np.arange(G.shape[0])
    max_idx = (max_idx, idx.flatten())
    G[:, :] = 0
    G[max_idx] = idx + 1

    G = np.sum(G, axis=1)
    G = median_filter(G[:, np.newaxis], median_size)

    return G.flatten()


def get_segmentation(X, rank, median_size, rank_labels, R_labels, iterations=300, in_labels=None):
    """
    Gets the segmentation (boundaries and labels) from the factorization
    matrices.
    Parameters
    ----------
    X: np.array()
        Features matrix (e.g. chromagram)
    rank: int
        Rank of decomposition
    R: int
        Size of the median filter for activation matrix
    iterations: int
        Number of iterations for k-means
    in_labels : np.array()
        List of input labels (None to compute them)
    Returns
    -------
    bounds_idx: np.array
        Bound indeces found
    labels: np.array
        Indeces of the labels representing the similarity between segments.
    """


    # Find non filtered boundaries
    while True:

        try:
            F, G = cnmf(X, rank, iterations=iterations)
        except:
            print "Bounds failed."
            return np.empty(0), [1]

        # Filter G
        G = filter_activation_matrix(G.T, median_size)
        bound_idxs = np.where(np.diff(G) != 0)[0] + 1

        # Increase rank if we found too few boundaries
        if len(np.unique(bound_idxs)) <= 2:
            rank += 1
            bound_idxs = None
        else:
            break

    # Add first and last boundary
    bound_idxs = np.concatenate(([0], bound_idxs, [X.shape[1] - 1]))
    bound_idxs = np.asarray(bound_idxs, dtype=int)
    if in_labels is None:
        labels = compute_labels(X, rank_labels, R_labels, bound_idxs,
                                iterations=iterations)
    else:
        labels = np.ones(len(bound_idxs) - 1)

    return bound_idxs, labels


def intervals_to_times(intervals):
    """Given a set of intervals, convert them into times.
    Parameters
    ----------
    intervals: np.array(N-1, 2)
        A set of intervals.
    Returns
    -------
    times: np.array(N)
        A set of times.
    """
    return np.concatenate((intervals.flatten()[::2], [intervals[-1, -1]]), axis=0)


def remove_empty_segments(times, labels):
    """Removes empty segments if needed."""
    intervals = np.asarray(zip(times[:-1], times[1:]))
    new_intervals = []
    new_labels = []
    for inter, label in zip(intervals, labels):
        if inter[0] < inter[1]:
            new_intervals.append(inter)
            new_labels.append(label)
    return intervals_to_times(np.asarray(new_intervals)), new_labels


def process_segmentation_level(est_idxs, est_labels, N, frame_times, dur):
    """Processes a level of segmentation, and converts it into times.

    Parameters
    ----------
    est_idxs: np.array
        Estimated boundaries in frame indeces.
    est_labels: np.array
        Estimated labels.
    N: int
        Number of frames in the whole track.
    frame_times: np.array
        Time stamp for each frame.
    dur: float
        Duration of the audio track.

    Returns
    -------
    est_times: np.array
        Estimated segment boundaries in seconds.
    est_labels: np.array
        Estimated labels for each segment.
    """
    assert est_idxs[0] == 0 and est_idxs[-1] == N - 1

    # Add silences, if needed
    est_times = np.concatenate(([0], frame_times[est_idxs], [dur]))
    silence_label = np.max(est_labels) + 1
    est_labels = np.concatenate(([silence_label], est_labels, [silence_label]))

    # Remove empty segments if needed
    est_times, est_labels = remove_empty_segments(est_times, est_labels)

    return est_times, est_labels


def postprocess(est_idxs, est_labels):
    est_idxs, est_labels = remove_empty_segments(est_idxs, est_labels)
    # Make sure the indeces are integers
    est_idxs = np.asarray(est_idxs, dtype=int)
    return est_idxs, est_labels


def get_predominant(sampling_rate):

    hopSize = 512
    frameSize = 2048
    run_predominant_melody = PredominantMelody(frameSize=frameSize,
                                               hopSize=hopSize);

    # Load audio file, apply equal loudness filter, and compute predominant melody
    audio = MonoLoader(filename = "1000.mp3")()
    audio = EqualLoudness()(audio)
    pitch, confidence = run_predominant_melody(audio)


    n_frames = len(pitch)
    print "number of frames:", n_frames
    return pitch


def extract_features():

    frame_size = 2048
    hop_size = 512
    n_mels = 128
    mfcc_coeff = 14
    sampling_rate = 11025

    print("Loading the file.")
    waveform, _ = librosa.load("1000.mp3", sr=11025)
    print("HPSS.")
    waveform_harmonic, waveform_percussive = librosa.effects.hpss(waveform)

    print("Beats.")
    tempo, beats_idx = librosa.beat.beat_track(y=waveform_percussive, sr=sampling_rate, hop_length=hop_size)
    #frame_time = librosa.frames_to_time(beats_idx, sr=sampling_rate, hop_length=hop_size)

    print("Melspectrogram.")
    S = librosa.feature.melspectrogram(waveform,
                                       sr=sampling_rate,
                                       n_fft=frame_size,
                                       hop_length=hop_size,
                                       n_mels=n_mels)

    print("Predominant.")
    pitch = get_predominant(sampling_rate)

    print("MFCCs.")
    log_S = librosa.logamplitude(S, ref_power=np.max)
    mfcc = librosa.feature.mfcc(S=log_S, n_mfcc=14).T
    print(len(mfcc))

    if os.path.isfile('data.json'):
        with open('data.json') as data_file:    
            print("HPCP 1")
            data = json.load(data_file)
            hpcp = np.array(data["hpcp"])
            print(len(hpcp))
    else:
        print("HPCP 2")
        hpcp = librosa.feature.chroma_cqt(y=waveform_harmonic, sr=sampling_rate,
                                          hop_length=hop_size).T
        print(len(hpcp))
        with open('data.json', 'w') as outfile:
            json.dump({"hpcp": hpcp.tolist()}, outfile)

    print("Beat synchronising.")
    bs_mfcc = librosa.feature.sync(mfcc.T, beats_idx, pad=False).T
    bs_hpcp = librosa.feature.sync(hpcp.T, beats_idx, pad=False).T

    return bs_mfcc, bs_hpcp, beats_idx, waveform.shape[0] / sampling_rate


def lognormalise_chroma(C):
    """Log-normalizes chroma such that each vector is between -80 to 0."""
    C += np.abs(C.min()) + 0.1
    C = C / C.max(axis=0)
    C = 80 * np.log10(C)  # Normalize from -80 to 0
    return C


def compute_ssm(X, metric="seuclidean"):
    """Computes the self-similarity matrix of X."""
    D = distance.pdist(X, metric='correlation')
    D = distance.squareform(D)
    D /= D.max()
    return 1 - D


def newfunction():

    print 'sdsds'
    frame_size = 2048
    hop_size = 512
    n_mels = 128
    mfcc_coeff = 14
    sampling_rate = 11025
    iterations = 500 
    H = 20

    #swapped
    hpcp, mfcc, beats, dur = extract_features()
    hpcp = lognormalise_chroma(hpcp)
    hpcp = compute_ssm(hpcp)

    if hpcp.shape[0] >= H:
        # Median filter
        hpcp = median_filter(hpcp, M=20)
        # Find the boundary indices and labels using matrix factorization
        print("Segmentation.")
        est_idxs, est_labels = get_segmentation(hpcp.T, 3, 16, 4, 16, iterations=iterations, in_labels=None)
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

newfunction()