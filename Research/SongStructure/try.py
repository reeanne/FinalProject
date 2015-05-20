import os
import sys
import subprocess
import numpy as np
import essentia
import essentia.standard as ES
import librosa
from scipy.ndimage import filters
import json
import os.path
import pymf
import sys, csv
from essentia import *
from essentia.standard import *
from pylab import *

from pylab import *

in_bound_idxs = None

def median_filter(X, M=8):
    """Median filter along the first axis of the feature matrix X."""
    for i in xrange(X.shape[1]):
        X[:, i] = filters.median_filter(X[:, i], size=M)
    return X


def cnmf(S, rank, niter=500, hull=False):
    """(Convex) Non-Negative Matrix Factorization.
    Parameters
    ----------
    S: np.array(p, N)
        Features matrix. p row features and N column observations.
    rank: int
        Rank of decomposition
    niter: int
        Number of iterations to be used
    Returns
    -------
    F: np.array
        Cluster matrix (decomposed matrix)
    G: np.array
        Activation matrix (decomposed matrix)
        (s.t. S ~= F * G)
    """
    if hull:
        nmf_mdl = pymf.CHNMF(S, num_bases=rank)
    else:
        nmf_mdl = pymf.CNMF(S, num_bases=rank)
    mdl.factorize(niter=niter)
    F = np.asarray(nmf_mdl.W)
    G = np.asarray(nmf_mdl.H)
    return F, G



def most_frequent(x):
    """Returns the most frequent value in x."""
    return np.argmax(np.bincount(x))


def compute_labels(X, rank, R, bound_idxs, niter=300):
    """Computes the labels using the bounds."""

    print "Computing Labels."
    try:
        F, G = cnmf(X, rank, niter=niter, hull=False)
    except:
        return [1]

    label_frames = filter_activation_matrix(G.T, R)
    label_frames = np.asarray(label_frames, dtype=int)

    labels = []
    bound_inters = zip(bound_idxs[:-1], bound_idxs[1:])
    for bound_inter in bound_inters:
        if bound_inter[1] - bound_inter[0] <= 0:
            labels.append(np.max(label_frames) + 1)
        else:
            labels.append(most_frequent(
                label_frames[bound_inter[0]: bound_inter[1]]))

    return labels


def filter_activation_matrix(G, R):
    """Filters the activation matrix G, and returns a flattened copy."""

    #import pylab as plt
    #plt.imshow(G, interpolation="nearest", aspect="auto")
    #plt.show()

    idx = np.argmax(G, axis=1)
    max_idx = np.arange(G.shape[0])
    max_idx = (max_idx, idx.flatten())
    G[:, :] = 0
    G[max_idx] = idx + 1

    G = np.sum(G, axis=1)
    G = median_filter(G[:, np.newaxis], R)

    return G.flatten()


def get_segmentation(X, rank, R, rank_labels, R_labels, niter=300,
                     bound_idxs=None, in_labels=None):
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
    niter: int
        Number of iterations for k-means
    bound_idxs : list
        Use previously found boundaries (None to detect them)
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
    compute_bounds = True if bound_idxs is None else False
    while True:

        if bound_idxs is None:
            try:
                F, G = cnmf(X, rank, niter=niter, hull=False)
            except:
                print "Bounds failed."
                return np.empty(0), [1]

            # Filter G
            G = filter_activation_matrix(G.T, R)
            if bound_idxs is None:
                bound_idxs = np.where(np.diff(G) != 0)[0] + 1

        # Increase rank if we found too few boundaries
        if compute_bounds and len(np.unique(bound_idxs)) <= 2:
            rank += 1
            bound_idxs = None
        else:
            break

    # Add first and last boundary
    bound_idxs = np.concatenate(([0], bound_idxs, [X.shape[1] - 1]))
    bound_idxs = np.asarray(bound_idxs, dtype=int)
    if in_labels is None:
        labels = compute_labels(X, rank_labels, R_labels, bound_idxs,
                                niter=niter)
    else:
        labels = np.ones(len(bound_idxs) - 1)

    return bound_idxs, labels


def times_to_intervals(times):
    """Given a set of times, convert them into intervals.
    Parameters
    ----------
    times: np.array(N)
        A set of times.
    Returns
    -------
    inters: np.array(N-1, 2)
        A set of intervals.
    """
    return np.asarray(zip(times[:-1], times[1:]))


def intervals_to_times(inters):
    """Given a set of intervals, convert them into times.
    Parameters
    ----------
    inters: np.array(N-1, 2)
        A set of intervals.
    Returns
    -------
    times: np.array(N)
        A set of times.
    """
    return np.concatenate((inters.flatten()[::2], [inters[-1, -1]]), axis=0)


def remove_empty_segments(times, labels):
    """Removes empty segments if needed."""
    inters = times_to_intervals(times)
    new_inters = []
    new_labels = []
    for inter, label in zip(inters, labels):
        if inter[0] < inter[1]:
            new_inters.append(inter)
            new_labels.append(label)
    return intervals_to_times(np.asarray(new_inters)), new_labels


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
    audio = MonoLoader(filename = "Houses.mp3")()
    audio = EqualLoudness()(audio)
    pitch, confidence = run_predominant_melody(audio)


    n_frames = len(pitch)
    print "number of frames:", n_frames

    # Visualize output pitch values
    fig = plt.figure()
    plot(range(n_frames), pitch, 'b')
    n_ticks = 10
    xtick_locs = [i * (n_frames / 10.0) for i in range(n_ticks)]
    xtick_lbls = [i * (n_frames / 10.0) * hopSize / sampling_rate for i in range(n_ticks)]
    xtick_lbls = ["%.2f" % round(x,2) for x in xtick_lbls]
    plt.xticks(xtick_locs, xtick_lbls)
    ax = fig.add_subplot(111)
    ax.set_xlabel('Time (s)')
    ax.set_ylabel('Pitch (Hz)')
    suptitle("Predominant melody pitch")

    # Visualize output pitch confidence
    fig = plt.figure()
    plot(range(n_frames), confidence, 'b')
    n_ticks = 10
    xtick_locs = [i * (n_frames / 10.0) for i in range(n_ticks)]
    xtick_lbls = [i * (n_frames / 10.0) * hopSize / sampling_rate for i in range(n_ticks)]
    xtick_lbls = ["%.2f" % round(x,2) for x in xtick_lbls]
    plt.xticks(xtick_locs, xtick_lbls)
    ax = fig.add_subplot(111)
    ax.set_xlabel('Time (s)')
    ax.set_ylabel('Confidence')
    suptitle("Predominant melody pitch confidence")
    return pitch


def extract_features_librosa2():

    frame_size = 2048
    hop_size = 512
    n_mels = 128
    mfcc_coeff = 14

    print "Loading the file."
    waveform, sampling_rate = librosa.load("Houses.mp3")
    print "HPSS."
    waveform_harmonic, waveform_percussive = librosa.effects.hpss(waveform)

    #plot(waveform[1*44100:2*44100])
    #show()
    print "Beats."
    tempo, beats_idx = librosa.beat.beat_track(y=waveform_percussive, sr=sampling_rate, hop_length=hop_size)

    print len (beats_idx)
    #frame_time = librosa.frames_to_time(beats_idx, sr=sampling_rate, hop_length=hop_size)

    print "Melspectrogram."
    S = librosa.feature.melspectrogram(waveform, sr=sampling_rate, n_fft=frame_size, hop_length=hop_size, n_mels=n_mels)

    print "Predominant."
    pitch = get_predominant(sampling_rate)
    print len(pitch)


    print "MFCCs."
    log_S = librosa.logamplitude(S, ref_power=np.max)
    mfcc = librosa.feature.mfcc(S=log_S, n_mfcc=12).T
    print len(mfcc)

    if os.path.isfile('data.json'):
        with open('data.json') as data_file:    
            data = json.load(data_file)
            hpcp = np.array(data["hpcp"])
            print len(hpcp)
    else:
        print "HPCP."
        hpcp = librosa.feature.chroma_cqt(y=waveform_harmonic, sr=sampling_rate, hop_length=hop_size).T
        print len(hpcp)
        with open('data.json', 'w') as outfile:
            json.dump({"hpcp": hpcp.tolist()}, outfile)


    print "Beat synchronising."
    bs_mfcc = librosa.feature.sync(mfcc.T, beats_idx, pad=False).T
    bs_hpcp = librosa.feature.sync(hpcp.T, beats_idx, pad=False).T

    return bs_mfcc, bs_hpcp


def compute_ssm(X, metric="seuclidean"):
    """Computes the self-similarity matrix of X."""
    D = distance.pdist(X, metric=metric)
    D = distance.squareform(D)
    D /= D.max()
    return 1 - D


def normalise_chroma(C):
    """Normalizes chroma such that each vector is between 0 to 1."""
    C += np.abs(C.min())
    C = C/C.max(axis=0)
    return C



def newfunction():

    niter = 500 
    H = 20
    mfcc, hpcp = extract_features_librosa2()
    hpcp = normalise_chroma(hpcp)

    if hpcp.shape[0] >= H:
        # Median filter
        hpcp = median_filter(hpcp, M=20)
        # Find the boundary indices and labels using matrix factorization
        print "Segmentation."
        est_idxs, est_labels = get_segmentation(hpcp.T, 3, 16, 4, 16, niter=niter, bound_idxs=in_bound_idxs, in_labels=None)
        est_idxs = np.unique(np.asarray(est_idxs, dtype=int))
    else:
        # The track is too short. We will only output the first and last
        # time stamps
        if in_bound_idxs is None:
            est_idxs = np.array([0, F.shape[0]-1])
            est_labels = [1]
        else:
            est_idxs = in_bound_idxs

    # Post process estimations
    est_idxs, est_labels = postprocess(est_idxs, est_labels)

    print est_idxs, est_labels

newfunction()