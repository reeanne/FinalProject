from pybrain.supervised.trainers import BackpropTrainer
from pybrain.structure import TanhLayer
import pybrain.tools.shortcuts as shortcuts
from pybrain.datasets import SupervisedDataSet
import sys
import csv
import numpy



def main():
	file = sys.argv[1]
	reader = csv.reader(open(file,"rb"),delimiter=',')
	x = list(reader)
	result = numpy.array(x).astype('float')
	length = len(result)
	width = len(result[0])
	ds = SupervisedDataSet(width - 2, 2)


	for i, row in enumerate(result):
	#	if i < length * 2 / 3:
		ds.addSample(row[:-2], row[-2:])
		#else:
	#		test_data.append([row[:-2], row[-2:]])

	net = shortcuts.buildNetwork(width - 2, 4, 2, bias=True, hiddenclass=TanhLayer)
	trainer = BackpropTrainer(net, ds, verbose=True) # learningrate = 0.9, momentum=0.0, weightdecay=0.0, verbose=True) 
	print trainer.trainEpochs(epochs=1000)


if __name__ == '__main__':
    #demo()
    main()



