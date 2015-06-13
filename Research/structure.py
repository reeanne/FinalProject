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
import operator
from collections import Counter
from threading import Thread
from Queue import Queue

frames = []


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


def compute_labels_simple_vocals(X, pitch, rank, median_size, bound_indexes, iterations=300):
    """ Computes labels based only on the vocal extent. """
    labels = []
    bound_intervals = zip(bound_indexes[:-1], bound_indexes[1:])
    for interval in bound_intervals:
        labels.append(compute_vocal_extent(pitch, interval))
    return labels


def compute_numeric_labels(X, rank, median_size, bound_indexes, iterations=300):
    """ Computes the labels using the bounds. """

    print "Computing Labels."
    try:
        W, H = cnmf(X, rank, iterations=iterations)
    except:
        return [1]

    label_frames = filter_cluster_matrix(W.T, median_size)    # get the border frames. Again. Need to change it.
    label_frames = np.asarray(label_frames, dtype=int)        # convert to numpy array

    labels = []
    bound_intervals = zip(bound_indexes[:-1], bound_indexes[1:])

    for interval in bound_intervals:
        if interval[1] - interval[0] <= 0:
            labels.append(np.max(label_frames) + 1)
        else:
            labels.append(most_frequent(
                label_frames[interval[0]: interval[1]]))

    return labels


def find_label_relation(dictionary, labels):
    c = Counter(labels)
    most_common = c.most_common(2)
    chorus, verse, intro, outro, intro_outro = None, None, None, None, None

    if len(most_common) < 2:
        return chorus, verse, intro, outro, intro_outro

    if dictionary[most_common[0][0]] > dictionary[most_common[1][0]]:
        chorus = most_common[0][0]
        verse = most_common[1][0]
    else:
        chorus = most_common[1][0]
        verse = most_common[0][0]
    if labels[0] != chorus and labels[0] != verse and c[labels[0]] == 1:
        intro = labels[0]
    if labels[-1] != chorus and labels[-1] != verse and c[labels[-1]] == 1:
        outro = labels[-1]
    if labels[0] != chorus and labels[0] != verse and c[labels[0]] == 2 and labels[0] == labels[1]:
        intro_outro = labels[1]
    return chorus, verse, intro, outro, intro_outro


def reassign_labels(chorus, verse, intro, outro, intro_outro, labels):
    new_labels = []
    for label in labels:
        if intro is not None and label == intro:
            new_labels.append("intro")
        elif verse is not None and label == verse:
            new_labels.append("verse")
        elif chorus is not None and label == chorus:
            new_labels.append("chorus")
        elif outro is not None and label == outro:
            new_labels.append("outro")
        elif intro_outro is not None and label == intro_outro:
            new_labels.append("intro/outro")
        else:
            new_labels.append("bridge")
    return new_labels


def numeric_to_vocal_labels(labels, pitch, bound_indexes):

    dictionary = {}
    bound_intervals = zip(bound_indexes[:-1], bound_indexes[1:])
    for (index, interval) in enumerate(bound_intervals):
        label = compute_vocal_extent(pitch, interval)
        if not labels[index] in dictionary:
            dictionary[labels[index]] = []
        dictionary[labels[index]].append(label)

    for label in dictionary.keys():
        occurences = dictionary[label]
        dictionary[label] = sum(occurences) / float(len(occurences))

    chorus, verse, intro, outro, intro_outro = find_label_relation(dictionary, labels)
    return reassign_labels(chorus, verse, intro, outro, intro_outro, labels)


def compute_vocal_extent(pitch, interval):
    """ Computes the fraction of frames containing main melody in them. """

    nonzero = np.count_nonzero(pitch[interval[0] : interval[1]])
    if interval[1] - interval[0] == 0:
        return 0
    return float(nonzero) / (interval[1] - interval[0])
    

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

        #bound_indexes = kmeans_bounds(H, W, rank+1)
        bound_indexes = straightforward_bounds(H, W, median_size)

        # Increase rank if we found too few boundaries
        if len(np.unique(bound_indexes)) <= 2:
            rank += 1
            bound_indexes = None
        else:
            break

    # Add first and last boundary
    print "before", bound_indexes
    bound_times = np.array([0.57, 6.84, 25.23, 46.34, 54.29, 76.38, 96.23, 104.28, 135.35])
    print "frames", frames
    bound_indexes = bound_times_to_indexes(bound_times, frames)
    print "after", bound_indexes
    bound_indexes = np.concatenate(([0], bound_indexes, [X.shape[1] - 1]))

    bound_indexes = np.asarray(bound_indexes, dtype=int)
    #labels = compute_labels_simple_vocals(X, pitch, rank_labels, R_labels, bound_idxs, iterations=iterations)
    labels = compute_numeric_labels(X, rank_labels, R_labels, bound_indexes, iterations=iterations)
    labels = numeric_to_vocal_labels(labels, pitch, bound_indexes)

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
    real_pitch, confidence = run_predominant_melody(audio)


    for (i, conf) in enumerate(confidence):
        if conf < 0:
            real_pitch[i] = 0;

    pitch = real_pitch[:]
    # Prope the pitches to make the data as small as the other.
    ratio = int(len(pitch) / size)
    pitch = pitch[::ratio]
    pitch = pitch[:-1] if len(pitch) > size else pitch
    return pitch, real_pitch


def extract_hpcp(queue, waveform_harmonic, sampling_rate, hop_size, beats_idx):
    hpcp = librosa.feature.chroma_cqt(y=waveform_harmonic, sr=sampling_rate,
                                      hop_length=hop_size).T    
    bs_hpcp = librosa.feature.sync(hpcp.T, beats_idx, pad=False).T
    queue.put((hpcp, bs_hpcp))


def extract_mfcc(queue, S, beats_idx, n_mfcc=14, ):
    log_S = librosa.logamplitude(S, ref_power=np.max)
    mfcc = librosa.feature.mfcc(S=log_S, n_mfcc=n_mfcc).T
    bs_mfcc = librosa.feature.sync(mfcc.T, beats_idx, pad=False).T
    queue.put((mfcc, bs_mfcc))


def find_closest_index(bound_time, frame_times):
    index = 0
    length = len(frame_times)
    while (index + 1 < length and frame_times[index + 1] < bound_time):
        index += 1
    return index


def bound_times_to_indexes(bound_times, frame_times):
    bounds = []
    for bound in bound_times:
        bounds.append(find_closest_index(bound, frame_times))
    return bounds


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
    tempo, beats_idx = librosa.beat.beat_track(y=waveform_percussive, sr=sampling_rate,
                                               hop_length=hop_size)

    print "Melspectrogram."
    S = librosa.feature.melspectrogram(waveform, sr=sampling_rate, n_fft=frame_size,
                                       hop_length=hop_size, n_mels=n_mels)

    #print "Parallel. " 
    #q1, q2 = Queue(), Queue()

    #Thread(target=extract_mfcc, args=(q1, S, beats_idx)).start()
    #Thread(target=extract_hpcp, args=(q2, waveform_harmonic, sampling_rate, hop_size, beats_idx)).start() 

    #mfcc, bs_mfcc = q1.get()
    #hpcp, bs_hpcp = q2.get()
    hpcp = librosa.feature.chroma_cqt(y=waveform_harmonic, sr=sampling_rate,
                                      hop_length=hop_size).T    
    bs_hpcp = librosa.feature.sync(hpcp.T, beats_idx, pad=False).T

    log_S = librosa.logamplitude(S, ref_power=np.max)
    mfcc = librosa.feature.mfcc(S=log_S, n_mfcc=mfcc_coeff).T
    bs_mfcc = librosa.feature.sync(mfcc.T, beats_idx, pad=False).T


    print "Predominant."
    pitch, real_pitch = get_predominant(audio, sampling_rate, len(mfcc))
    bs_pitch = librosa.feature.sync(pitch.T, beats_idx, pad=False).flatten()
    print len(pitch)

    #show_matrix(hpcp.T, "unsynched hpcp")
    #show_matrix(mfcc.T, "unsynched mfcc")


    #show_matrix(bs_hpcp.T, "synched hpcp")
    #show_matrix(bs_mfcc.T, "synched mfcc")
    
    #unsynchSSM = lognormalise_chroma(mfcc)
    #unsynchSSM = compute_ssm(unsynchSSM)
    #show_matrix(unsynchSSM, "unsynched ssm")

    return bs_mfcc, bs_hpcp, beats_idx, waveform.shape[0] / sampling_rate, pitch, real_pitch


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


def process_for_feature(queue, hpcp, pitch, iterations, sampling_rate, hop_size, dur, H, frames):
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
    est_times, est_labels = process_segmentation_level(est_idxs, est_labels,
                                                       hpcp.shape[0], frames, dur)
    queue.put((est_times, est_labels))


def process_track(path):
    """ Processes the file to get the section boundaries and labels. """
    frame_size = 2048
    hop_size = 512
    n_mels = 128
    mfcc_coeff = 14
    sampling_rate = 11025
    iterations = 500 
    H = 20

    mfcc, hpcp, beats, dur, pitch, real_pitch = extract_features(path)
    q1, q2 = Queue(), Queue()
    global frames
    frames = librosa.frames_to_time(beats, sr=sampling_rate, hop_length=hop_size)


    Thread(target=process_for_feature, args=(q1, mfcc, pitch, iterations, sampling_rate, hop_size, dur, H, frames)).start()
    Thread(target=process_for_feature, args=(q2, hpcp, pitch, iterations, sampling_rate, hop_size, dur, H, frames)).start() 

    mfcc_times, mfcc_labels = q1.get()
    hpcp_times, hpcp_labels = q2.get()

    print mfcc_times, mfcc_labels
    print hpcp_times, hpcp_labels

    mfcc_newtimes, mfcc_newlabels = merge_bounds(mfcc_times, mfcc_labels)
    hpcp_newtimes, hpcp_newlabels = merge_bounds(hpcp_times, hpcp_labels)

    if len(mfcc_newlabels) < len(hpcp_newlabels):
        est_times, est_labels = hpcp_times, hpcp_labels
    else:        
        est_times, est_labels = mfcc_times, mfcc_labels

    np.savetxt(sys.stdout, est_times, '%5.2f')
    print est_times, est_labels
    beat_times = librosa.frames_to_time(beats, sr=sampling_rate, hop_length=hop_size)
    return est_times, est_labels, real_pitch, beat_times


def merge_bounds(bounds, labels):
    """ Merges bounds if the neighbouring labels are the same. """

    new_bounds, new_labels = [bounds[0]], []
    prevlabel = None

    for i in range(1, len(bounds)-1):
        if prevlabel != labels[i-1]:
            new_labels.append(labels[i-2])
            new_bounds.append(bounds[i-1])
        prevlabel = labels[i-1]

    new_bounds.append(bounds[-1])
    new_labels.append(labels[-1])
    return new_bounds, new_labels


def main():    
    if len(sys.argv) > 1:
        path = sys.argv[1]
    else:
        path = "SongStructure/Titanic.mp3"
    bounds, labels, _, _ = process_track(path)
    print len(bounds)

main()



