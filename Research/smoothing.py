import sys
import os
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.contour import ContourSet
import matplotlib.cm as cm
from scipy.ndimage import filters



def rectangular_smooth(array, width, skipzeros=True):
	if width % 2 != 0:
		length = len(array)
		print "length", length
		result = [0] * length
		result[0] = array[0]
		result[length-1] = array[length-1]

		for i in range(width / 2, length-(width /2 + 1)):
			if array[i] == 0 and skipzeros:
				continue
			suma = array[i]
			for j in range(1, width/2+1):
				suma += (array[i-j] + array[i+j])
			suma = suma / width
			result[i] = suma
		print len(result)
		return result

	else:
		print "Window width should be an odd number."
		return []


def triangular_smooth(array, width, skipzeros=True):
	if width % 2 != 0:
		length = len(array)
		print "length", length
		result = [0] * length
		result[0] = array[0]
		result[length-1] = array[length-1]

		for i in range(width / 2, length-(width /2 + 1)):
			if array[i] == 0 and skipzeros:
				continue
			suma = array[i]
			for j in range(1, width/2+1):
				suma += (width/2 + 2 - j) *(array[i-j] + array[i+j])
			suma = suma / width
			result[i] = suma
		print len(result)
		return result

	else:
		print "Window width should be an odd number."
		return []


def plot(array1, array3):
	y_axis = np.arange(len(array1)).tolist()
	plt.plot(y_axis, array1, y_axis, array3)
	plt.ylabel('some numbers')
	plt.show()


def plot2(array1):
	y_axis = np.arange(len(array1)).tolist()
	plt.plot(y_axis, array1)
	plt.ylabel('some numbers')
	plt.show()


def filterzeros(array):
	for i in range(0, len(array)):
		if array[i] == 0:
			array[i] = float('nan')
	return array


def retrieve_array(file):
	name = os.path.splitext(file)[0]
	result = []
	with open(file) as input:
		for line in input:
			result.append(float(line.strip().split('\t')[1]))
	return result

def median_filter(our_array, window):
	median_f = filters.median_filter(our_array, window)
	for i in range(0, len(median_f)):
		if our_array[i] == 0 or our_array[i] == float('nan'):
			median_f[i] = 0

	return median_f.tolist()


def main():

	ours = sys.argv[1]
	reference = sys.argv[2]

	our_array = retrieve_array(ours)
	ref_array = retrieve_array(reference)

	our_arrayfiltered = filterzeros(our_array)
	new_ours = triangular(our_array, 101)

	#plot(our_array, new_ours)
	plot2(new_ours)
	plot2(ref_array)
	plot2(our_array)
	
	plot2(filteres) 

main()
