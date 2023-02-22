#!/usr/bin/env python

"""
Adaptation of an adaptation of VGG16 on CIFAR10 workload. 

As the 17 of February 2023, SMAUG has a bug where feature maps equal (or lower)
in size to convolution kernels cause a loop in the simulation of systolic arrays. 
I currently don't have time to fix the source code, so I will avoid having 
feature sizes of this troubling size.

The net I'm adapting from is an adaptation of VGG16 on CIFAR10 workload; 
it reaches 93.56% of validation accuracy with this trained network: 
https://github.com/geifmany/cifar-vgg
The model was based on this paper: 10.1109/ACPR.2015.7486599
For sake of correctness it shouldn't be called VGG16 but just VGG because of
the adaptation to input 32x32 and the use of different FC layers in the end.

I remove the last 3 3x3x512 convolutions and one 2x2 maxpooling.
I change the last maxpooling to 4x4 to have the same FC layer at the end.
Pretty radical changes, but my work focuses on the comparison of digital systems
using an nvdla dataflow vs a systolic array dataflow, so the network really 
doesn't matter much... given it does meaningful operations of course.

Filippo Landi
"""

import numpy as np
import smaug as sg

def generate_random_data(shape):
  r = np.random.RandomState(1234)
  return (r.rand(*shape) * 0.005).astype(np.float16)

def create_vgg_model():
  with sg.Graph(name="vgg", backend="SMV") as graph:
    input_tensor = sg.Tensor(
        data_layout=sg.NHWC, tensor_data=generate_random_data((1, 32, 32, 3)))
    conv0_tensor = sg.Tensor(
        data_layout=sg.NHWC, tensor_data=generate_random_data((64, 3, 3, 3)))
    conv1_tensor = sg.Tensor(
        data_layout=sg.NHWC, tensor_data=generate_random_data((64, 3, 3, 64)))
    conv2_tensor = sg.Tensor(
        data_layout=sg.NHWC, tensor_data=generate_random_data((128, 3, 3, 64)))
    conv3_tensor = sg.Tensor(
        data_layout=sg.NHWC, tensor_data=generate_random_data((128, 3, 3, 128)))
    conv4_tensor = sg.Tensor(
        data_layout=sg.NHWC, tensor_data=generate_random_data((256, 3, 3, 128)))
    conv5_tensor = sg.Tensor(
        data_layout=sg.NHWC, tensor_data=generate_random_data((256, 3, 3, 256)))
    conv6_tensor = sg.Tensor(
        data_layout=sg.NHWC, tensor_data=generate_random_data((256, 3, 3, 256)))
    conv7_tensor = sg.Tensor(
        data_layout=sg.NHWC, tensor_data=generate_random_data((512, 3, 3, 256)))
    conv8_tensor = sg.Tensor(
        data_layout=sg.NHWC, tensor_data=generate_random_data((512, 3, 3, 512)))
    conv9_tensor = sg.Tensor(
        data_layout=sg.NHWC, tensor_data=generate_random_data((512, 3, 3, 512)))
    fc0_tensor = sg.Tensor(
        data_layout=sg.NC, tensor_data=generate_random_data((512, 512)))
    fc1_tensor = sg.Tensor(
        data_layout=sg.NC, tensor_data=generate_random_data((10, 512)))

    act = sg.input_data(input_tensor)
    act = sg.nn.convolution(
        act, conv0_tensor, stride=[1, 1], padding="same", activation="relu")
    act = sg.nn.convolution(
        act, conv1_tensor, stride=[1, 1], padding="same", activation="relu")
    act = sg.nn.max_pool(act, pool_size=[2, 2], stride=[2, 2])
    act = sg.nn.convolution(
        act, conv2_tensor, stride=[1, 1], padding="same", activation="relu")
    act = sg.nn.convolution(
        act, conv3_tensor, stride=[1, 1], padding="same", activation="relu")
    act = sg.nn.max_pool(act, pool_size=[2, 2], stride=[2, 2])
    act = sg.nn.convolution(
        act, conv4_tensor, stride=[1, 1], padding="same", activation="relu")
    act = sg.nn.convolution(
        act, conv5_tensor, stride=[1, 1], padding="same", activation="relu")
    act = sg.nn.convolution(
        act, conv6_tensor, stride=[1, 1], padding="same", activation="relu")
    act = sg.nn.max_pool(act, pool_size=[2, 2], stride=[2, 2])
    act = sg.nn.convolution(
        act, conv7_tensor, stride=[1, 1], padding="same", activation="relu")
    act = sg.nn.convolution(
        act, conv8_tensor, stride=[1, 1], padding="same", activation="relu")
    act = sg.nn.convolution(
        act, conv9_tensor, stride=[1, 1], padding="same", activation="relu")
    act = sg.nn.max_pool(act, pool_size=[4, 4], stride=[4, 4])
    act = sg.nn.mat_mul(act, fc0_tensor, activation="relu")
    act = sg.nn.mat_mul(act, fc1_tensor)
    return graph

if __name__ != "main":
  graph = create_vgg_model()
  graph.print_summary()
  graph.write_graph()
