from pybrain.supervised.trainers import BackpropTrainer
from pybrain.tools.validation import ModuleValidator, CrossValidator
from pybrain.structure import SigmoidLayer, TanhLayer
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
	ds = SupervisedDataSet(width - 2, 1)


	for i, row in enumerate(result):
	#	if i < length * 2 / 3:
		ds.addSample(row[:-2], row[-2])
		#else:
	#		test_data.append([row[:-2], row[-2:]])

	net = shortcuts.buildNetwork(width - 2, 5, 1, bias=True, hiddenclass=SigmoidLayer)
	trainer = BackpropTrainer(net, ds, verbose=True, learningrate = 0.0012, momentum=0.0, weightdecay=0.0) 
	# print trainer.trainEpochs(epochs=1000)
	print trainer.trainUntilConvergence()
	evaluation = ModuleValidator.classificationPerformance(trainer.module, ds)
	validator = CrossValidator(trainer=trainer, dataset=trainer.ds, n_folds=5, valfunc=evaluation)
	print(validator.validate())

if __name__ == '__main__':
    #demo()
    main()



# Total error:  0.636792088407



# 0.618 
# net = shortcuts.buildNetwork(width - 2, 4, 2, bias=True, hiddenclass=SigmoidLayer)
# trainer = BackpropTrainer(net, ds, verbose=True, learningrate = 0.0012, momentum=0.0, weightdecay=0.0) 

# 0.598
# net = shortcuts.buildNetwork(width - 2, 4, 2, bias=True, hiddenclass=SigmoidLayer)
# trainer = BackpropTrainer(net, ds, verbose=True, learningrate = 0.0012, momentum=0.001, weightdecay=0.0) 

