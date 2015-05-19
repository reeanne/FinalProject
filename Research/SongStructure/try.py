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



from pylab import *

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
    nmf_mdl.factorize(niter=niter)
    F = np.asarray(nmf_mdl.W)
    G = np.asarray(nmf_mdl.H)
    return F, G


def most_frequent(x):
    """Returns the most frequent value in x."""
    return np.argmax(np.bincount(x))


def compute_labels(X, rank, R, bound_idxs, niter=300):
    """Computes the labels using the bounds."""

    try:
        F, G = cnmf(X, rank, niter=niter, hull=False)
    except:
        return [1]

    label_frames = filter_activation_matrix(G.T, R)
    label_frames = np.asarray(label_frames, dtype=int)

    #labels = [label_frames[0]]
    labels = []
    bound_inters = zip(bound_idxs[:-1], bound_idxs[1:])
    for bound_inter in bound_inters:
        if bound_inter[1] - bound_inter[0] <= 0:
            labels.append(np.max(label_frames) + 1)
        else:
            labels.append(most_frequent(
                label_frames[bound_inter[0]: bound_inter[1]]))
        #print bound_inter, labels[-1]
    #labels.append(label_frames[-1])

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

    # TODO: Order matters?
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

    #import pylab as plt
    #plt.imshow(X, interpolation="nearest", aspect="auto")
    #plt.show()

    # Find non filtered boundaries
    compute_bounds = True if bound_idxs is None else False
    while True:
        #import pdb; pdb.set_trace()  # XXX BREAKPOINT

        if bound_idxs is None:
            try:
                F, G = cnmf(X, rank, niter=niter, hull=False)
            except:
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

    #plt.imshow(G[:, np.newaxis], interpolation="nearest", aspect="auto")
    #for b in bound_idxs:
        #plt.axvline(b, linewidth=2.0, color="k")
    #plt.show()

    return bound_idxs, labels



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


def lognormalize_chroma(C):

    """Log-normalizes chroma such that each vector is between -80 to 0."""
    C += np.abs(C.min()) + 0.1
    C = C / C.max(axis=0)
    C = 80 * np.log10(C)  # Normalize from -80 to 0
    return C

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

    if os.path.isfile('data.json'):
        with open('data.json') as data_file:    
            data = json.load(data_file)
            hpcp = data["hpcp"]
    else:
        print "HPCP."
        hpcp = librosa.feature.chroma_cqt(y=waveform_harmonic, sr=sampling_rate, hop_length=hop_size).T
        with open('data.json', 'w') as outfile:
            json.dump({"hpcp": hpcp}, outfile)

    print "Tonnetz."
    #tonnetz = chroma_to_tonnetz(hpcp)

    print "Beat synchronising."
    bs_mfcc = librosa.feature.sync(mfcc.T, beats_idx, pad=False).T
    bs_hpcp = librosa.feature.sync(hpcp.T, beats_idx, pad=False).T
    bs_tonnetz = []
    #bs_tonnetz = librosa.feature.sync(tonnetz.T, beats_idx, pad=False).T
    #bs_hpcp = []
    print "before plotting"
    #plot(bs_tonnetz)

    return bs_mfcc, bs_hpcp, bs_tonnetz

def newfunction():

    niter = 500 
    mfcc, hpcp, tonnetz = extract_features_librosa2()

    print "Median filter."
    hpcp = median_filter(hpcp, M=20)

    print "Segmentation."
    est_idxs, est_labels = get_segmentation(hpcp.T, 3, 16, 4, 16, niter=niter, bound_idxs=None, in_labels=None)

    print "Removing duplicates."
    indices = np.unique(np.asarray(est_idxs, dtype = int))

    print "Postprocess."
    idxs, labels = postprocess(indices, est_labels)
    print indx, labels

newfunction()