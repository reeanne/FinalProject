"train a regression MLP"

import numpy as np
import cPickle as pickle
from math import sqrt
from pybrain.datasets.supervised import SupervisedDataSet as SDS
from pybrain.tools.shortcuts import buildNetwork
from pybrain.supervised.trainers import BackpropTrainer

train_file = 'train.csv'
output_model_file = 'model.pkl'

hidden_size = 7
epochs = 1000

# load data

train = np.loadtxt( train_file, delimiter = ',' )

ds = SDS(8, 2)                                                       

for row in train:
	ds.addSample(row[10:-2].tolist(), row[-2:])


net = buildNetwork( 8, hidden_size, 2, bias = True )
net.randomize()
trainer = BackpropTrainer( net,ds, verbose=True, learningrate = 0.001)

print "training for {} epochs...".format( epochs )

for i in range( epochs ):
	mse = trainer.train()
	rmse = sqrt( mse )
	print "training RMSE, epoch {}: {}".format( i + 1, rmse )
	
pickle.dump( net, open( output_model_file, 'wb' ))





