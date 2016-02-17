import 'dart:math';
import 'dart:typed_data';

Random _random = new Random();

/// A layer with Tan H neurons and two bias inputs (+1 and -1).
class Layer {
  final int neuronCount;
  final int inputNeuronCount;
  Float32List _weights;

  /// Creates a new neuron layer with [neuronCount] neurons which can connect
  /// to a previous layer of [inputNeuronCount] neurons.
  Layer(this.neuronCount, int inputNeuronCount)
      : inputNeuronCount = inputNeuronCount {
    _weights = new Float32List(weightsTotal);
  }

  int get weightsPerNeuron => inputNeuronCount + 2 /* bias inputs */;

  int get weightsTotal => neuronCount * weightsPerNeuron;

  void randomizeWeights() {
    for (int i = 0; i < _weights.length; i++) {
      _weights[i] = _random.nextDouble() * 2 - 1;
    }
  }

  void setWeights(List<num> weights) {
    assert(weights.length == weightsTotal);
    for (int i = 0; i < _weights.length; i++) {
      _weights[i] = weights[i].toDouble();
    }
  }

  List<double> use(List<double> inputs) {
    assert(inputs.length == inputNeuronCount);
    assert(_weights.every((w) => w != null));
    Float32List outputs = new Float32List(neuronCount);

    for (int i = 0; i < neuronCount; i++) {
      double value = 0.0;
      for (int j = 0; j < inputNeuronCount; j++) {
        value += inputs[j] * _weights[i * weightsPerNeuron + j];
      }
      // Biases
      value += 1 * _weights[i * weightsPerNeuron + inputNeuronCount];
      value += -1 * _weights[i * weightsPerNeuron + inputNeuronCount + 1];
      outputs[i] = _tanh(value);
    }
    return outputs;
  }

  num _tanh(num x) => -1.0 + 2.0 / (1 + pow(E, (-2 * x)));
}

/// Simple artificial neural network.
class Network {
  final int inputs;
  final int outputs;

  List<Layer> _layers;

  /// Creates a neural network.
  ///
  /// The synapse weights start uninitialized. Call [randomizeWeights()] or
  /// [setWeights()] before using the network.
  Network(this.inputs, this.outputs, {int hiddenLayers: 1}) {
    int hiddenLayerNeuronCount = (inputs + outputs) ~/ 2;
    _layers = new List<Layer>.generate(hiddenLayers + 1, (int index) {
      if (index == 0) {
        return new Layer(hiddenLayerNeuronCount, inputs);
      } else if (index < hiddenLayers) {
        return new Layer(hiddenLayerNeuronCount, hiddenLayerNeuronCount);
      } else {
        return new Layer(outputs, hiddenLayerNeuronCount);
      }
    });
  }

  List<num> get weights => new List.unmodifiable(
      _layers.map((layer) => layer._weights).expand((e) => e));

  void randomizeWeights() =>
      _layers.forEach((layer) => layer.randomizeWeights());

  void setWeights(List<num> weights) {
    int offset = 0;
    for (var layer in _layers) {
      var slice = weights.sublist(offset, offset + layer.weightsTotal);
      layer.setWeights(slice);
      offset += layer.weightsTotal;
    }
  }

  List<num> use(List<num> inputs) {
    return _layers.fold(inputs, (prev, layer) => layer.use(prev));
  }
}
