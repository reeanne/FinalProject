"train a regression MLP"

import numpy as np
import cPickle as pickle
from math import sqrt
from pybrain.datasets.supervised import SupervisedDataSet as SDS
from pybrain.tools.shortcuts import buildNetwork
from pybrain.supervised.trainers import BackpropTrainer

train_file = 'data2.csv'
validation_file = 'data2.csv'
output_model_file = 'model.pkl'

hidden_size = 5
epochs = 1000000

# load data

train = np.loadtxt( train_file, delimiter = ',' )
validation = np.loadtxt( validation_file, delimiter = ',' )
train = np.vstack(( train, validation ))

ds = SDS(5, 2)                                                       

for row in train:
	#print row[6]
	ds.addSample(row[0:5].tolist(), row[-4:-2])
#x_train = train[:,0:-2]
#y_train = train[:,-2:]

#input_size = x_train.shape[1]
#target_size = y_train.shape[1]

# prepare dataset

#ds = SDS( input_size, target_size )
#ds.setField( 'input', x_train )
#ds.setField( 'target', y_train )

# init and train

net = buildNetwork( 5, hidden_size, 2, bias = True )
net.randomize()
trainer = BackpropTrainer( net,ds, verbose=True)

print "training for {} epochs...".format( epochs )

for i in range( epochs ):
	mse = trainer.train()
	rmse = sqrt( mse )
	print "training RMSE, epoch {}: {}".format( i + 1, rmse )
	
pickle.dump( net, open( output_model_file, 'wb' ))





