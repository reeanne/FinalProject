"""
These set of functions help the algorithms of MSAF to read and write files
of the Segmentation Dataset.
"""
from collections import Counter
import datetime
import glob
import json
import logging
import numpy as np
import os
from threading import Thread

# Local stuff
import msaf
from msaf import jams2
from msaf import utils


class FileStruct:
    def __init__(self, audio_file):
        """Creates the entire file structure given the audio file."""
        self.ds_path = os.path.dirname(os.path.dirname(audio_file))
        self.audio_file = audio_file
        self.est_file = self._get_dataset_file(msaf.Dataset.estimations_dir,
                                               msaf.Dataset.estimations_ext)
        self.features_file = self._get_dataset_file(msaf.Dataset.features_dir,
                                                    msaf.Dataset.features_ext)
        self.ref_file = self._get_dataset_file(msaf.Dataset.references_dir,
                                               msaf.Dataset.references_ext)

    def _get_dataset_file(self, dir, ext):
        """Gets the desired dataset file."""
        audio_file_ext = "." + self.audio_file.split(".")[-1]
        base_file = os.path.basename(self.audio_file).replace(
            audio_file_ext, ext)
        return os.path.join(self.ds_path, dir, base_file)

    def __repr__(self):
        """Prints the file structure."""
        return "FileStruct(\n\tds_path=%s,\n\taudio_file=%s,\n\test_file=%s," \
            "\n\tfeatures_file=%s,\n\tref_file=%s\n)" % (
                self.ds_path, self.audio_file, self.est_file,
                self.features_file, self.ref_file)


def has_same_parameters(est_params, boundaries_id, labels_id, params):
    """Checks whether the parameters in params are the same as the estimated
    parameters in est_params."""
    K = 0
    for param_key in params.keys():
        if param_key in est_params.keys() and \
                est_params[param_key] == params[param_key] and \
                est_params["boundaries_id"] == boundaries_id and \
                (labels_id is None or est_params["labels_id"] == labels_id):
            K += 1
    return K == len(params.keys())


def find_estimation(all_estimations, boundaries_id, labels_id, params,
                    est_file):
    """Finds the correct estimation from all the estimations contained in a
    JAMS file given the specified arguments.

    Parameters
    ----------
    all_estimations : list
        List of section Range Annotations from a JAMS file.
    boundaries_id : str
        Identifier of the algorithm used to compute the boundaries.
    labels_id : str
        Identifier of the algorithm used to compute the labels.
    params : dict
        Additional search parameters. E.g. {"feature" : "hpcp"}.
    est_file : str
        Path to the estimated file (JAMS file).

    Returns
    -------
    correct_est : RangeAnnotation
        Correct estimation found in all the estimations.
        None if it couldn't be found.
    corect_i : int
        Index of the estimation in the all_estimations list.
    """
    correct_est = None
    correct_i = -1
    found = False
    for i, estimation in enumerate(all_estimations):
        est_params = estimation.sandbox
        if has_same_parameters(est_params, boundaries_id, labels_id,
                               params) and not found:
            correct_est = estimation
            correct_i = i
            found = True
        elif has_same_parameters(est_params, boundaries_id, labels_id,
                                 params) and found:
            logging.warning("Multiple estimations match your parameters in "
                            "file %s" % est_file)
            correct_est = estimation
            correct_i = i
    return correct_est, correct_i


def read_estimations(est_file, boundaries_id, labels_id=None, **params):
    """Reads the estimations (boundaries and/or labels) from a jams file
    containing the estimations of an algorithm.

    Parameters
    ----------
    est_file : str
        Path to the estimated file (JAMS file).
    boundaries_id : str
        Identifier of the algorithm used to compute the boundaries.
    labels_id : str
        Identifier of the algorithm used to compute the labels.
    params : dict
        Additional search parameters. E.g. {"feature" : "hpcp"}.

    Returns
    -------
    boundaries : np.array((N,2))
        Array containing the estimated boundaries in intervals.
    labels : np.array(N)
        Array containing the estimated labels.
        Empty array if labels_id is None.
    """

    # Open file and read jams
    try:
        jam = jams2.load(est_file)
    except:
        logging.error("Could not open JAMS file %s" % est_file)
        return np.array([]), np.array([])

    # Get all the estimations for the sections
    all_estimations = jam.sections

    # Find correct estimation
    correct_est, i = find_estimation(all_estimations, boundaries_id, labels_id,
                                     params, est_file)
    if correct_est is None:
        logging.error("Could not find estimation in %s" % est_file)
        return np.array([]), np.array([])

    # Retrieve unique levels of segmentation
    levels = []
    for range in correct_est.data:
        levels.append(range.label.context)
    levels = list(set(levels))

    # Retrieve data
    all_boundaries = []
    all_labels = []
    for level in levels:
        boundaries = []
        labels = []
        for range in correct_est.data:
            if level == range.label.context:
                boundaries.append([range.start.value, range.end.value])
                if labels_id is not None:
                    labels.append(range.label.value)
        all_boundaries.append(np.asarray(boundaries))
        all_labels.append(np.asarray(labels, dtype=int))

    # If there is only one level, return np.arrays instead of lists
    if len(levels) == 1:
        all_boundaries = all_boundaries[0]
        all_labels = all_labels[0]

    return all_boundaries, all_labels


def get_algo_ids(est_file):
    """Gets the algorithm ids that are contained in the est_file."""
    with open(est_file, "r") as f:
        est_data = json.load(f)
        algo_ids = est_data["boundaries"].keys()
    return algo_ids


def read_references(audio_path):
    """Reads the boundary times and the labels.

    Parameters
    ----------
    audio_path : str
        Path to the audio file

    Returns
    -------
    ref_times : list
        List of boundary times
    ref_labels : list
        List of labels
    """
    # Dataset path
    ds_path = os.path.dirname(os.path.dirname(audio_path))

    # Read references
    jam_path = os.path.join(ds_path, msaf.Dataset.references_dir,
                            os.path.basename(audio_path)[:-4] +
                            msaf.Dataset.references_ext)
    ds_prefix = os.path.basename(audio_path).split("_")[0]

    # Get context
    if ds_prefix in msaf.prefix_dict.keys():
        context = msaf.prefix_dict[ds_prefix]
    else:
        context = "function"

    try:
        ref_inters, ref_labels = jams2.converters.load_jams_range(
            jam_path, "sections", context=context)
    except:
        logging.warning("Reference not found in %s" % jam_path)
        return []

    # Intervals to times
    ref_times = utils.intervals_to_times(ref_inters)

    return ref_times, ref_labels


def read_ref_labels(audio_path):
    """Reads the annotated labels from the given audio path."""
    ref_times, ref_labels = read_references(audio_path)
    return ref_labels


def read_ref_int_labels(audio_path):
    """Reads the annotated labels using unique integers as identifiers
    instead of strings."""
    ref_labels = read_ref_labels(audio_path)
    labels = []
    label_dict = {}
    k = 1
    for ref_label in ref_labels:
        if ref_label in label_dict.keys():
            labels.append(label_dict[ref_label])
        else:
            label_dict[ref_label] = k
            labels.append(k)
            k += 1
    return labels


def align_times(times, frames):
    """Aligns the times to the closes frame times (e.g. beats)."""
    dist = np.minimum.outer(times, frames)
    bound_frames = np.argmax(np.maximum(0, dist), axis=1)
    return np.unique(bound_frames)


def read_ref_bound_frames(audio_path, beats):
    """Reads the corresponding references file to retrieve the boundaries
        in frames."""
    ref_times, ref_labels = read_references(audio_path)
    # align with beats
    bound_frames = align_times(ref_times, beats)
    return bound_frames


def get_features(audio_path, annot_beats=False, framesync=False,
                 pre_features=None):
    """
    Gets the features of an audio file given the audio_path.

    Parameters
    ----------
    audio_path: str
        Path to the audio file.
    annot_beats: bool
        Whether to use annotated beats or not.
    framesync: bool
        Whether to use framesync features or not.
    pre_features: dict
        Pre computed features as a dictionary.
        `None` for reading them form the json file.

    Return
    ------
    C: np.array((N, 12))
        (Beat-sync) Chromagram
    M: np.array((N, 13))
        (Beat-sync) MFCC
    T: np.array((N, 6))
        (Beat-sync) Tonnetz
    beats: np.array(T)
        Beats in seconds
    dur: float
        Song duration
    analysis : dict
        Parameters of analysis of track (e.g. sampling rate)
    """
    if pre_features is None:
        # Dataset path
        ds_path = os.path.dirname(os.path.dirname(audio_path))

        # Read Estimations
        features_path = os.path.join(ds_path, msaf.Dataset.features_dir,
            os.path.basename(audio_path)[:-4] + msaf.Dataset.features_ext)
        with open(features_path, "r") as f:
            feats = json.load(f)

        # Beat Synchronous Feats
        if framesync:
            feat_str = "framesync"
            beats = None
        else:
            if annot_beats:
                # Read references
                try:
                    annotation_path = os.path.join(
                        ds_path, msaf.Dataset.references_dir,
                        os.path.basename(audio_path)[:-4] +
                        msaf.Dataset.references_ext)
                    jam = jams2.load(annotation_path)
                except:
                    raise RuntimeError("No references found in file %s" %
                                    annotation_path)

                feat_str = "ann_beatsync"
                beats = []
                beat_data = jam.beats[0].data
                if beat_data == []:
                    raise ValueError
                for data in beat_data:
                    beats.append(data.time.value)
                beats = np.unique(beats)
            else:
                feat_str = "est_beatsync"
                beats = np.asarray(feats["beats"]["times"])
        C = np.asarray(feats[feat_str]["hpcp"])
        M = np.asarray(feats[feat_str]["mfcc"])
        T = np.asarray(feats[feat_str]["tonnetz"])
        analysis = feats["analysis"]
        dur = analysis["dur"]

        # Frame times might be shorter than the actual number of features.
        if framesync:
            frame_times = utils.get_time_frames(dur, analysis)
            C = C[:len(frame_times)]
            M = M[:len(frame_times)]
            T = T[:len(frame_times)]

    else:
        feat_prefix = ""
        if not framesync:
            feat_prefix = "bs_"
        C = pre_features["%shpcp" % feat_prefix]
        M = pre_features["%smfcc" % feat_prefix]
        T = pre_features["%stonnetz" % feat_prefix]
        beats = pre_features["beats"]
        dur = pre_features["anal"]["dur"]
        analysis = pre_features["anal"]

    return C, M, T, beats, dur, analysis


def safe_write(jam, out_file):
    """This method is suposed to be called in a safe thread in order to
    avoid interruptions and corrupt the file."""
    try:
        f = open(out_file, "w")
        json.dump(jam, f, indent=2)
    finally:
        f.close()


def save_estimations(out_file, times, labels, boundaries_id, labels_id,
                     **params):
    """Saves the segment estimations in a JAMS file.close

    Parameters
    ----------
    out_file : str
        Path to the output JAMS file in which to save the estimations.
    times : np.array or list
        Estimated boundary times.
        If `list`, estimated hierarchical boundaries.
    labels : np.array(N, 2)
        Estimated labels (None in case we are only storing boundary
        evaluations).
    boundaries_id : str
        Boundary algorithm identifier.
    labels_id : str
        Labels algorithm identifier.
    params : dict
        Dictionary with additional parameters for both algorithms.
    """
    # Convert to intervals and sanity check
    if 'numpy' in str(type(times)):
        inters = utils.times_to_intervals(times)
        assert len(inters) == len(labels), "Number of boundary intervals " \
            "(%d) and labels (%d) do not match" % (len(inters), len(labels))
        # Put into lists to simplify the writing process later
        inters = [inters]
        labels = [labels]
    else:
        inters = []
        for level in range(len(times)):
            est_inters = utils.times_to_intervals(times[level])
            inters.append(est_inters)
            assert len(inters[level]) == len(labels[level]), \
            "Number of boundary intervals (%d) and labels (%d) do not match" % \
                (len(inters[level]), len(labels[level]))

    curr_estimation = None
    curr_i = -1

    # Find estimation in file
    if os.path.isfile(out_file):
        jam = jams2.load(out_file)
        all_estimations = jam.sections
        curr_estimation, curr_i = find_estimation(
            all_estimations, boundaries_id, labels_id, params, out_file)
    else:
        # Create new JAMS if it doesn't exist
        jam = jams2.Jams()
        jam.metadata.title = os.path.basename(out_file).replace(
            msaf.Dataset.estimations_ext, "")

    # Create new annotation if needed
    if curr_estimation is None:
        curr_estimation = jam.sections.create_annotation()

    # Save metadata and parameters
    curr_estimation.annotation_metadata.attribute = "sections"
    curr_estimation.annotation_metadata.version = msaf.__version__
    curr_estimation.annotation_metadata.origin = "MSAF"
    sandbox = {}
    sandbox["boundaries_id"] = boundaries_id
    sandbox["labels_id"] = labels_id
    sandbox["timestamp"] = \
        datetime.datetime.today().strftime("%Y/%m/%d %H:%M:%S")
    for key in params:
        sandbox[key] = params[key]
    curr_estimation.sandbox = sandbox

    # Save actual data
    curr_estimation.data = []
    for i, (level_inters, level_labels) in enumerate(zip(inters, labels)):
        if level_labels is None:
            label = np.ones(len(inters)) * -1
        for bound_inter, label in zip(level_inters, level_labels):
            segment = curr_estimation.create_datapoint()
            segment.start.value = float(bound_inter[0])
            segment.start.confidence = 0.0
            segment.end.value = float(bound_inter[1])
            segment.end.confidence = 0.0
            segment.label.value = label
            segment.label.confidence = 0.0
            segment.label.context = "level_%d" % i

    # Place estimation in its place
    if curr_i != -1:
        jam.sections[curr_i] = curr_estimation

    # Write file and do not let users interrupt it
    my_thread = Thread(target=safe_write, args=(jam, out_file,))
    my_thread.start()
    my_thread.join()


def get_all_est_boundaries(est_file, annot_beats, algo_ids=None):
    """Gets all the estimated boundaries for all the algorithms.

    Parameters
    ----------
    est_file: str
        Path to the estimated file (JSON file)
    annot_beats: bool
        Whether to use the annotated beats or not.
    algo_ids : list
        List of algorithm ids to to read boundaries from.
        If None, all algorithm ids are read.

    Returns
    -------
    all_boundaries: list
        A list of np.arrays containing the times of the boundaries, one array
        for each algorithm
    """
    all_boundaries = []

    # Get GT boundaries
    jam_file = os.path.dirname(est_file) + "/../references/" + \
        os.path.basename(est_file).replace("json", "jams")
    ds_prefix = os.path.basename(est_file).split("_")[0]
    ann_inter, ann_labels = jams2.converters.load_jams_range(jam_file,
                        "sections", context=msaf.prefix_dict[ds_prefix])
    ann_times = utils.intervals_to_times(ann_inter)
    all_boundaries.append(ann_times)

    # Estimations
    if algo_ids is None:
        algo_ids = get_algo_ids(est_file)
    for algo_id in algo_ids:
        est_inters = read_estimations(est_file, algo_id, annot_beats,
                                      feature=msaf.feat_dict[algo_id])
        if len(est_inters) == 0:
            logging.warning("no estimations for algorithm: %s" % algo_id)
            continue
        boundaries = utils.intervals_to_times(est_inters)
        all_boundaries.append(boundaries)
    return all_boundaries


def get_all_est_labels(est_file, annot_beats, algo_ids=None):
    """Gets all the estimated boundaries for all the algorithms.

    Parameters
    ----------
    est_file: str
        Path to the estimated file (JSON file)
    annot_beats: bool
        Whether to use the annotated beats or not.
    algo_ids : list
        List of algorithm ids to to read boundaries from.
        If None, all algorithm ids are read.

    Returns
    -------
    gt_times:  np.array
        Ground Truth boundaries in times.
    all_labels: list
        A list of np.arrays containing the labels corresponding to the ground
        truth boundaries.
    """
    all_labels = []

    # Get GT boundaries and labels
    jam_file = os.path.dirname(est_file) + "/../" + \
        msaf.Dataset.references_dir + "/" + \
        os.path.basename(est_file).replace("json", "jams")
    ds_prefix = os.path.basename(est_file).split("_")[0]
    ann_inter, ann_labels = jams2.converters.load_jams_range(
        jam_file, "sections", context=msaf.prefix_dict[ds_prefix])
    gt_times = utils.intervals_to_times(ann_inter)
    all_labels.append(ann_labels)

    # Estimations
    if algo_ids is None:
        algo_ids = get_algo_ids(est_file)
    for algo_id in algo_ids:
        est_labels = read_estimations(est_file, algo_id, annot_beats,
                                      annot_bounds=True, bounds=False,
                                      feature=msaf.feat_dict[algo_id])
        if len(est_labels) == 0:
            logging.warning("no estimations for algorithm: %s" % algo_id)
            continue
        all_labels.append(est_labels)
    return gt_times, all_labels


def get_all_boundary_algorithms(algorithms):
    algo_ids = []
    for name in algorithms.__all__:
        module = eval(algorithms.__name__ + "." + name)
        if module.is_boundary_type:
            algo_ids.append(module.algo_id)
    return algo_ids


def get_all_label_algorithms(algorithms):
    algo_ids = []
    for name in algorithms.__all__:
        module = eval(algorithms.__name__ + "." + name)
        if module.is_label_type:
            algo_ids.append(module.algo_id)
    return algo_ids


def get_configuration(feature, annot_beats, framesync, boundaries_id,
                      labels_id):
    """Gets the configuration dictionary from the current parameters of the
    algorithms to be evaluated."""
    config = {}
    config["annot_beats"] = annot_beats
    config["feature"] = feature
    config["framesync"] = framesync
    if boundaries_id != "gt":
        bound_config = \
            eval(msaf.algorithms.__name__ + "." + boundaries_id).config
        config.update(bound_config)
    if labels_id is not None:
        label_config = \
            eval(msaf.algorithms.__name__ + "." + labels_id).config
        config.update(label_config)
    return config


def filter_by_artist(file_structs, artist_name="The Beatles"):
    """Filters data set files by artist name."""
    new_file_structs = []
    for file_struct in file_structs:
        jam = jams2.load(file_struct.ref_file)
        if jam.metadata.artist == artist_name:
            new_file_structs.append(file_struct)
    return new_file_structs


def get_SALAMI_internet(file_structs):
    """Gets the SALAMI Internet subset from SALAMI (bit of a hack...)"""
    new_file_structs = []
    for file_struct in file_structs:
        num = int(os.path.basename(file_struct.est_file).split("_")[1].
                  split(".")[0])
        if num >= 956 and num <= 1498:
            new_file_structs.append(file_struct)
    return new_file_structs


def get_dataset_files(in_path, ds_name="*"):
    """Gets the files of the dataset with a prefix of ds_name."""

    # All datasets
    ds_dict = {
        "Beatles"   : "Isophonics",
        "Cerulean"  : "Cerulean",
        "Epiphyte"  : "Epiphyte",
        "Isophonics": "Isophonics",
        "SALAMI"    : "SALAMI",
        "SALAMI-i"  : "SALAMI",
        "*"         : "*"
    }

    try:
        prefix = ds_dict[ds_name]
    except KeyError:
        raise RuntimeError("Dataset %s is not valid. Valid datasets are: %s" %
                           (ds_name, ds_dict.keys()))

    # Get audio files
    audio_files = []
    for ext in msaf.Dataset.audio_exts:
        audio_files += glob.glob(os.path.join(in_path, msaf.Dataset.audio_dir,
                                              ("%s_*" + ext) % prefix))

    # Check for datasets with different prefix
    if len(audio_files) == 0:
        for ext in msaf.Dataset.audio_exts:
            audio_files += glob.glob(os.path.join(in_path,
                                                  msaf.Dataset.audio_dir,
                                                  "*" + ext))

    # Make sure directories exist
    utils.ensure_dir(os.path.join(in_path, msaf.Dataset.features_dir))
    utils.ensure_dir(os.path.join(in_path, msaf.Dataset.estimations_dir))
    utils.ensure_dir(os.path.join(in_path, msaf.Dataset.references_dir))

    # Get the file structs
    file_structs = []
    for audio_file in audio_files:
        file_structs.append(FileStruct(audio_file))

    # Filter by the beatles
    if ds_name == "Beatles":
        file_structs = filter_by_artist(file_structs, "The Beatles")

    # Salami Internet hack
    if ds_name == "SALAMI-i":
        file_structs = get_SALAMI_internet(file_structs)

    return file_structs


def read_hier_references(jams_file, annotation_id=0):
    """Reads hierarchical references from a jams file.

    Parameters
    ----------
    jams_file : str
        Path to the jams file.
    annotation_id : int > 0
        Identifier of the annotator to read from.

    Returns
    -------
    hier_bounds : list
        List of the segment boundary times in seconds for each level.
    hier_labels : list
        List of the segment labels for each level.
    hier_levels : list
        List of strings for the level identifiers.
    """
    def get_levels():
        """Obtains the set of unique levels contained in the jams
            sorted by the number of segments they contain.

        Returns
        -------
        levels : np.array
            Level identifiers for the entire hierarchy.
        """
        levels = []
        jam = jams2.load(jams_file)
        annotation = jam.sections[annotation_id]
        [levels.append(segment.label.context)
            for segment in annotation.data]
        c = Counter(levels)     # Count frequency
        return np.asarray(c.keys())[np.argsort(c.values())]     # Sort

    def get_segments_in_level(level):
        """Gets the segments of a specific level.

        Paramters
        ---------
        level : str
            Indentifier of the level within the jams file.

        Returns
        -------
        times : np.array
            Boundary times in seconds for the given level.
        labels : np.array
            Labels for the given level.
        """
        intervals, labels = jams2.converters.load_jams_range(jams_file,
                "sections", annotator=annotation_id, context=level)
        times = utils.intervals_to_times(intervals)
        return np.array(times), np.array(labels)

    # Get the levels of the annotations in the jams file
    hier_levels = get_levels()

    # Get the boundaries and labels for each level
    hier_bounds = []
    hier_labels = []
    for level in hier_levels:
        bound_times, labels = get_segments_in_level(level)
        hier_bounds.append(bound_times)
        hier_labels.append(labels)

    return hier_bounds, hier_labels, hier_levels


