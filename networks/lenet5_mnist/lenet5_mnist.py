#!/usr/bin/env python

"""
LeNet5 inspired network, MNIST database of course.

As the 17 of February 2023, SMAUG has a bug where feature maps equal (or lower)
in size to convolution kernels cause a loop in the simulation of systolic arrays. 
I currently don't have time to fix the source code, so I will avoid having 
feature sizes of this troubling size.

Difference from the original network:
1) The original net drops some connection, this net doesn't.
2) Because of the bug SMAUG as the 17 February 2023, 
simulation hangs with the systolic configuration I use a FC layer
instead of the third convolutional layer (C5 in the original paper).
Many sites talking about LeNet5 put this fc layer, but they are all wrong, 
as said I do it for necessity.

Filippo Landi
"""

import numpy as np
import smaug as sg

def generate_random_data(shape):
  r = np.random.RandomState(1234)
  return (r.rand(*shape) * 0.005).astype(np.float16)

def create_lenet5_model():
  with sg.Graph(name="lenet5", backend="SMV") as graph:
    # Tensors and kernels are initialized as NCHW layout.
    input_tensor = sg.Tensor(
        data_layout=sg.NHWC, tensor_data=generate_random_data((1, 32, 32, 1)))
    conv0_tensor = sg.Tensor(
        data_layout=sg.NHWC, tensor_data=generate_random_data((6, 5, 5, 1)))
    conv1_tensor = sg.Tensor(
        data_layout=sg.NHWC, tensor_data=generate_random_data((16, 5, 5, 6)))
    fc0_tensor = sg.Tensor(
        data_layout=sg.NC, tensor_data=generate_random_data((120, 400)))
    fc1_tensor = sg.Tensor(
        data_layout=sg.NC, tensor_data=generate_random_data((84, 120)))
    fc2_tensor = sg.Tensor(
        data_layout=sg.NC, tensor_data=generate_random_data((10, 84)))

    # Input 32x32 
    act = sg.input_data(input_tensor)
    # Convolution C1
    act = sg.nn.convolution(
        act, conv0_tensor, stride=[1, 1], padding="valid", activation="tanh")
    # Subsampling S2
    act = sg.nn.max_pool(act, pool_size=[2, 2], stride=[2, 2])
    # Convolution C3
    act = sg.nn.convolution(
        act, conv1_tensor, stride=[1, 1], padding="valid", activation="tanh")
    # Subsampling S4
    act = sg.nn.max_pool(act, pool_size=[2, 2], stride=[2, 2])
    # Convolution C5 (replaced with Fully Connected)
    act = sg.nn.mat_mul(act, fc0_tensor, activation="tanh")
    # Fully Connected F6
    act = sg.nn.mat_mul(act, fc1_tensor, activation="tanh")
    # Output
    act = sg.nn.mat_mul(act, fc2_tensor)
    return graph

if __name__ != "main":
  graph = create_lenet5_model()
  graph.print_summary()
  graph.write_graph()
