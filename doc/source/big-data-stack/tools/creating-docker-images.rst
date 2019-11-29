.. _creating-docker-images:

Running Docker containers over YARN
===================================

Portus
------

Since its last versions YARN allows running Docker containers instead its
native containers. This is useful when we need some custom dependencies that
are not installed at the cluster. In order to launch your
custom images in EDI's Big Data Stack, you must upload them into EDI's private
registry. This registry is managed by Portus tool at `<http://portus.edincubator.eu/>`_.

There are two default namespaces at Portus: a global namespace
(i.e. registry.edincubator.eu) and a personal namespace for every user. The
global namespace hosts all public images created by EDI technical support team,
in order to ease the deployment of some tasks. In your personal namespace you
should upload your private images for running your code. In addition to those
default namespaces, you can create aditional namespaces, even team namespaces
for sharing with your team colleagues. Namespaces can be easily managed through
Portus web interface at `<http://portus.edincubator.eu/>`_.


Create a new Docker image
-------------------------

In this tutorial we explain how to create an image for running the
`Text classification with movie reviews <https://www.tensorflow.org/tutorials/keras/basic_text_classification>`_
Tensorflow tutorial at YARN. This image includes the Tensorflow library, not
included at the cluster. As a requirement, you must install Docker
following instructions at `<https://docs.docker.com/install/>`_.

.. note::

    You must execute the following steps at your personal computer locally.

First, clone the repository with EDI stack-examples and enter into
`dockerexamples` examples:

.. code-block:: console

    # git clone https://github.com/edincubator/stack-examples
    # cd stack-examples/dockerexamples

At this folder there are two variants of our example: `tf_cpu` and `tf_gpu`.
The first one executes the Tensorflow code at CPU, while the latter uses GPU.

TensorFlow CPU example
......................

Enter at `tf_cpu` directory:

.. code-block:: console

    # cd tf_cpu

Here, we can find two files: `Dockerfile` and `tf_example.py`. Let's see the
first one:

.. code-block:: dockerfile

    FROM tensorflow/tensorflow:1.12.0

    RUN mkdir /source
    ADD tf_example.py /source

This image is quite simple. It imports Tensorflow 1.12.0 and adds our code.

.. warning::

    The maximum Tensorflow version supported by Hadoop 3.1.0 is 1.12.0, as it is
    the last version build on Cuda 9.0.

The `tf_example.py` file contains the source code of the imdb example. You
can find more details about this example at `Text classification with movie reviews <https://www.tensorflow.org/tutorials/keras/basic_text_classification>`_

.. code-block:: python

    import tensorflow as tf
    from tensorflow import keras

    imdb = keras.datasets.imdb

    (train_data, train_labels), (test_data, test_labels) = imdb.load_data(num_words=10000)

    print("Training entries: {}, labels: {}".format(len(train_data), len(train_labels)))

    # A dictionary mapping words to an integer index
    word_index = imdb.get_word_index()

    # The first indices are reserved
    word_index = {k:(v+3) for k,v in word_index.items()}
    word_index["<PAD>"] = 0
    word_index["<START>"] = 1
    word_index["<UNK>"] = 2  # unknown
    word_index["<UNUSED>"] = 3

    reverse_word_index = dict([(value, key) for (key, value) in word_index.items()])

    def decode_review(text):
        return ' '.join([reverse_word_index.get(i, '?') for i in text])


    train_data = keras.preprocessing.sequence.pad_sequences(train_data,
                                                            value=word_index["<PAD>"],
                                                            padding='post',
                                                            maxlen=256)

    test_data = keras.preprocessing.sequence.pad_sequences(test_data,
                                                        value=word_index["<PAD>"],
                                                        padding='post',
                                                        maxlen=256)
    # input shape is the vocabulary count used for the movie reviews (10,000 words)
    vocab_size = 10000

    model = keras.Sequential()
    model.add(keras.layers.Embedding(vocab_size, 16))
    model.add(keras.layers.GlobalAveragePooling1D())
    model.add(keras.layers.Dense(16, activation=tf.nn.relu))
    model.add(keras.layers.Dense(1, activation=tf.nn.sigmoid))

    model.summary()

    model.compile(optimizer='adam',
                loss='binary_crossentropy',
                metrics=['acc'])

    x_val = train_data[:10000]
    partial_x_train = train_data[10000:]

    y_val = train_labels[:10000]
    partial_y_train = train_labels[10000:]

    history = model.fit(partial_x_train,
                        partial_y_train,
                        epochs=40,
                        batch_size=512,
                        validation_data=(x_val, y_val),
                        verbose=1)

    results = model.evaluate(test_data, test_labels)
    print(results)

For executing this example at the cluster, we must build the Docker image:

.. code-block:: console

    # docker build -t registry.edincubator.eu/<username>/tf:cpu-v1
    Sending build context to Docker daemon   5.12kB
    Step 1/3 : FROM tensorflow/tensorflow:1.12.0
    ---> 2715d5fd677a
    Step 2/3 : RUN mkdir /source
    ---> Using cache
    ---> c8343caf0221
    Step 3/3 : ADD tf_example.py /source
    ---> efaad7db19e4
    Successfully built efaad7db19e4
    Successfully tagged registry.edincubator.eu/<username>/tf:cpu-v1


.. note::

    Always tag your Docker images its version. If you modify an image and you
    use the same tag as the previous version of the image, the cluster won't
    be able to notice that it must pull a new version of the image.

Once the image is built we need to push it to our private repository. For that,
we need to login into repository:

.. code-block:: console

    # docker login registry.edincubator.eu
    Username: <username>
    Password:
    WARNING! Your password will be stored unencrypted in /home/<username>/.docker/config.json.
    Configure a credential helper to remove this warning. See
    https://docs.docker.com/engine/reference/commandline/login/#credentials-store

    Login Succeeded

Next, we must push the image into repository:

.. code-block:: console

    # docker push registry.edincubator.eu/<username>/tf:cpu-v1 .


You must access to your :ref:`JupyterLab <jupyterhub-section>` environment to
launch the job. Open a terminal, :ref:`login with your Kerberos keytab <authenticating-with-kerberos>`
and execute the following command:

.. code-block:: console

    # yarn jar /opt/hadoop/share/hadoop/yarn/hadoop-yarn-applications-distributedshell-3.1.1.jar \
        -jar /opt/hadoop/share/hadoop/yarn/hadoop-yarn-applications-distributedshell-3.1.1.jar \
        -shell_env YARN_CONTAINER_RUNTIME_TYPE=docker \
        -shell_env YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=registry.edincubator.eu/<username>/tf:cpu-v1 \
        -shell_env YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS=/etc/passwd:/etc/passwd:ro,/etc/group:/etc/group:ro \
        -shell_command python \
        -shell_args "/source/tf_example.py"

The YARN Distributed Shell allows us launching processes over YARN. Next, we
explain required parameters:

    * YARN_CONTAINER_RUNTIME_TYPE: we set `docker` as container runtime instead
      `yarn`.
    * YARN_CONTAINER_RUNTIME_DOCKER_IMAGE: the Docker image that we want to
      run.
    * YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS: directories that Docker must know
      to work properly. You shouldn't modify this parameter.
    * -shell_command: the command to launch inside the container.
    * -shell_args: the arguments for that command.

If the application completed successfully, you can check results inspecting
application's logs:

.. code-block:: console

    # yarn logs -applicationId application_<application_id>
    [...]
    LogAggregationType: AGGREGATED
    ===================================================================================================
    LogType:stdout
    LogLastModifiedTime:Tue Sep 17 09:43:48 +0000 2019
    LogLength:85906
    LogContents:
    Downloading data from https://storage.googleapis.com/tensorflow/tf-keras-datasets/imdb.npz
    17465344/17464789 [==============================] - 1s 0us/step
    17473536/17464789 [==============================] - 1s 0us/step
    Training entries: 25000, labels: 25000
    Downloading data from https://storage.googleapis.com/tensorflow/tf-keras-datasets/imdb_word_index.json
    1646592/1641221 [==============================] - 0s 0us/step
    1654784/1641221 [==============================] - 0s 0us/step
    _________________________________________________________________
    Layer (type)                 Output Shape              Param #   
    =================================================================
    embedding (Embedding)        (None, None, 16)          160000    
    _________________________________________________________________
    global_average_pooling1d (Gl (None, 16)                0         
    _________________________________________________________________
    dense (Dense)                (None, 16)                272       
    _________________________________________________________________
    dense_1 (Dense)              (None, 1)                 17        
    =================================================================
    Total params: 160,289
    Trainable params: 160,289
    Non-trainable params: 0
    _________________________________________________________________
    Train on 15000 samples, validate on 10000 samples
    Epoch 1/40
    15000/15000 [==============================] - 1s 88us/step - loss: 0.6918 - acc: 0.6215 - val_loss: 0.6900 - val_acc: 0.6926
    Epoch 2/40
    15000/15000 [==============================] - 1s 46us/step - loss: 0.6867 - acc: 0.7142 - val_loss: 0.6823 - val_acc: 0.6879
    Epoch 3/40
    15000/15000 [==============================] - 1s 47us/step - loss: 0.6744 - acc: 0.7388 - val_loss: 0.6667 - val_acc: 0.7412
    Epoch 4/40
    15000/15000 [==============================] - 1s 49us/step - loss: 0.6529 - acc: 0.7459 - val_loss: 0.6429 - val_acc: 0.7704
    Epoch 5/40
    15000/15000 [==============================] - 1s 50us/step - loss: 0.6216 - acc: 0.7899 - val_loss: 0.6091 - val_acc: 0.7818
    Epoch 6/40
    15000/15000 [==============================] - 1s 49us/step - loss: 0.5816 - acc: 0.8078 - val_loss: 0.5701 - val_acc: 0.7944
    Epoch 7/40
    15000/15000 [==============================] - 1s 44us/step - loss: 0.5365 - acc: 0.8285 - val_loss: 0.5283 - val_acc: 0.8159
    Epoch 8/40
    15000/15000 [==============================] - 1s 53us/step - loss: 0.4905 - acc: 0.8439 - val_loss: 0.4874 - val_acc: 0.8283
    Epoch 9/40
    15000/15000 [==============================] - 1s 52us/step - loss: 0.4469 - acc: 0.8569 - val_loss: 0.4502 - val_acc: 0.8419
    Epoch 10/40
    15000/15000 [==============================] - 1s 50us/step - loss: 0.4072 - acc: 0.8699 - val_loss: 0.4183 - val_acc: 0.8491
    Epoch 11/40
    15000/15000 [==============================] - 1s 51us/step - loss: 0.3736 - acc: 0.8790 - val_loss: 0.3943 - val_acc: 0.8543
    Epoch 12/40
    15000/15000 [==============================] - 1s 44us/step - loss: 0.3456 - acc: 0.8856 - val_loss: 0.3710 - val_acc: 0.8619
    Epoch 13/40
    15000/15000 [==============================] - 1s 47us/step - loss: 0.3205 - acc: 0.8927 - val_loss: 0.3546 - val_acc: 0.8664
    Epoch 14/40
    15000/15000 [==============================] - 1s 43us/step - loss: 0.2998 - acc: 0.8994 - val_loss: 0.3403 - val_acc: 0.8703
    Epoch 15/40
    15000/15000 [==============================] - 1s 50us/step - loss: 0.2820 - acc: 0.9034 - val_loss: 0.3292 - val_acc: 0.8733
    Epoch 16/40
    15000/15000 [==============================] - 1s 53us/step - loss: 0.2668 - acc: 0.9065 - val_loss: 0.3201 - val_acc: 0.8758
    Epoch 17/40
    15000/15000 [==============================] - 1s 46us/step - loss: 0.2522 - acc: 0.9133 - val_loss: 0.3125 - val_acc: 0.8762
    Epoch 18/40
    15000/15000 [==============================] - 1s 45us/step - loss: 0.2396 - acc: 0.9173 - val_loss: 0.3062 - val_acc: 0.8804
    Epoch 19/40
    15000/15000 [==============================] - 1s 50us/step - loss: 0.2279 - acc: 0.9214 - val_loss: 0.3012 - val_acc: 0.8810
    Epoch 20/40
    15000/15000 [==============================] - 1s 54us/step - loss: 0.2176 - acc: 0.9241 - val_loss: 0.2970 - val_acc: 0.8818
    Epoch 21/40
    15000/15000 [==============================] - 1s 56us/step - loss: 0.2075 - acc: 0.9291 - val_loss: 0.2933 - val_acc: 0.8826
    Epoch 22/40
    15000/15000 [==============================] - 1s 48us/step - loss: 0.1984 - acc: 0.9326 - val_loss: 0.2911 - val_acc: 0.8824
    Epoch 23/40
    15000/15000 [==============================] - 1s 57us/step - loss: 0.1900 - acc: 0.9358 - val_loss: 0.2892 - val_acc: 0.8835
    Epoch 24/40
    15000/15000 [==============================] - 1s 55us/step - loss: 0.1817 - acc: 0.9403 - val_loss: 0.2869 - val_acc: 0.8842
    Epoch 25/40
    15000/15000 [==============================] - 1s 48us/step - loss: 0.1743 - acc: 0.9438 - val_loss: 0.2858 - val_acc: 0.8847
    Epoch 26/40
    15000/15000 [==============================] - 1s 54us/step - loss: 0.1671 - acc: 0.9463 - val_loss: 0.2853 - val_acc: 0.8852
    Epoch 27/40
    15000/15000 [==============================] - 1s 55us/step - loss: 0.1609 - acc: 0.9499 - val_loss: 0.2855 - val_acc: 0.8852
    Epoch 28/40
    15000/15000 [==============================] - 1s 51us/step - loss: 0.1545 - acc: 0.9519 - val_loss: 0.2847 - val_acc: 0.8867
    Epoch 29/40
    15000/15000 [==============================] - 1s 52us/step - loss: 0.1486 - acc: 0.9534 - val_loss: 0.2850 - val_acc: 0.8865
    Epoch 30/40
    15000/15000 [==============================] - 1s 47us/step - loss: 0.1435 - acc: 0.9563 - val_loss: 0.2860 - val_acc: 0.8854
    Epoch 31/40
    15000/15000 [==============================] - 1s 51us/step - loss: 0.1373 - acc: 0.9593 - val_loss: 0.2869 - val_acc: 0.8860
    Epoch 32/40
    15000/15000 [==============================] - 1s 47us/step - loss: 0.1326 - acc: 0.9607 - val_loss: 0.2884 - val_acc: 0.8864
    Epoch 33/40
    15000/15000 [==============================] - 1s 53us/step - loss: 0.1271 - acc: 0.9639 - val_loss: 0.2899 - val_acc: 0.8864
    Epoch 34/40
    15000/15000 [==============================] - 1s 47us/step - loss: 0.1226 - acc: 0.9657 - val_loss: 0.2920 - val_acc: 0.8853
    Epoch 35/40
    15000/15000 [==============================] - 1s 57us/step - loss: 0.1186 - acc: 0.9664 - val_loss: 0.2933 - val_acc: 0.8852
    Epoch 36/40
    15000/15000 [==============================] - 1s 58us/step - loss: 0.1136 - acc: 0.9685 - val_loss: 0.2958 - val_acc: 0.8847
    Epoch 37/40
    15000/15000 [==============================] - 1s 67us/step - loss: 0.1097 - acc: 0.9699 - val_loss: 0.2984 - val_acc: 0.8847
    Epoch 38/40
    15000/15000 [==============================] - 1s 50us/step - loss: 0.1062 - acc: 0.9705 - val_loss: 0.3007 - val_acc: 0.8840
    Epoch 39/40
    15000/15000 [==============================] - 1s 52us/step - loss: 0.1018 - acc: 0.9724 - val_loss: 0.3028 - val_acc: 0.8839
    Epoch 40/40
    15000/15000 [==============================] - 1s 49us/step - loss: 0.0980 - acc: 0.9736 - val_loss: 0.3059 - val_acc: 0.8845
    25000/25000 [==============================] - 1s 41us/step
    [0.32565547265052797, 0.87288]

    End of LogType:stdout
    ***********************************************************************
    [...]


TensorFlow GPU example
......................

Next, we are going to execute the same example over GPU instead CPU. For that,
access to the `tf_gpu` folder:

.. code-block:: console

    # cd ~/work/examples/dockerexample/tf_gpu

In this folder we can find the `Dockerfile` and the `tf_example.py` files. As
`tf_example.py` is the same as the one in the CPU example, we will focus at the
Dockerfile:

.. code-block:: dockerfile

    FROM tensorflow/tensorflow:1.12.0-gpu

    RUN mkdir /source
    ADD tf_example.py /source

Notice that we only have changed the source image from `tensorflow:1.12.0` to
`tensorflow:1.12.0-gpu` for enabling GPU processing. Next, we can build and
push the image to the Docker registry:

.. code-block:: console

    # docker build -t registry.edincubator.eu/<username>/tf:gpu-v1 .
    # docker push registry.edincubator.eu/<username>/tf:gpu-v1

Next, from JupyterLab, we launch the job:

.. code-block:: console

    yarn jar /opt/hadoop/share/hadoop/yarn/hadoop-yarn-applications-distributedshell-3.1.1.jar \
    -jar /opt/hadoop/share/hadoop/yarn/hadoop-yarn-applications-distributedshell-3.1.1.jar \
    -shell_env YARN_CONTAINER_RUNTIME_TYPE=docker \
    -shell_env YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=registry.edincubator.eu/<username>/tf:gpu-v1 \
    -shell_env YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS=/etc/passwd:/etc/passwd:ro,/etc/group:/etc/group:ro \
    -shell_command python \
    -shell_args "/source/tf_example.py" \
    -container_resources yarn.io/gpu=1

Notice that we have added the `-container_resources yarn.io/gpu=1` for
requesting a GPU. Once the application has finished, we can see the output and
check that each step has been executed slightly quickly than in the CPU example:

.. code-block:: console

    # yarn logs -applicationId application_<application_id>
    [...]
    LogAggregationType: AGGREGATED
    ===============================================================================================
    LogType:stdout
    LogLastModifiedTime:Tue Sep 17 10:31:44 +0000 2019
    LogLength:63839
    LogContents:
    Downloading data from https://storage.googleapis.com/tensorflow/tf-keras-datasets/imdb.npz
    17465344/17464789 [==============================] - 2s 0us/step
    17473536/17464789 [==============================] - 2s 0us/step
    Training entries: 25000, labels: 25000
    Downloading data from https://storage.googleapis.com/tensorflow/tf-keras-datasets/imdb_word_index.json
    1646592/1641221 [==============================] - 0s 0us/step
    1654784/1641221 [==============================] - 0s 0us/step
    _________________________________________________________________
    Layer (type)                 Output Shape              Param #   
    =================================================================
    embedding (Embedding)        (None, None, 16)          160000    
    _________________________________________________________________
    global_average_pooling1d (Gl (None, 16)                0         
    _________________________________________________________________
    dense (Dense)                (None, 16)                272       
    _________________________________________________________________
    dense_1 (Dense)              (None, 1)                 17        
    =================================================================
    Total params: 160,289
    Trainable params: 160,289
    Non-trainable params: 0
    _________________________________________________________________
    Train on 15000 samples, validate on 10000 samples
    Epoch 1/40
    15000/15000 [==============================] - 1s 45us/step - loss: 0.6923 - acc: 0.5399 - val_loss: 0.6907 - val_acc: 0.6469
    Epoch 2/40
    15000/15000 [==============================] - 0s 32us/step - loss: 0.6878 - acc: 0.7119 - val_loss: 0.6846 - val_acc: 0.7418
    Epoch 3/40
    15000/15000 [==============================] - 0s 31us/step - loss: 0.6786 - acc: 0.7575 - val_loss: 0.6731 - val_acc: 0.7525
    Epoch 4/40
    15000/15000 [==============================] - 0s 30us/step - loss: 0.6619 - acc: 0.7644 - val_loss: 0.6540 - val_acc: 0.7580
    Epoch 5/40
    15000/15000 [==============================] - 0s 30us/step - loss: 0.6360 - acc: 0.7861 - val_loss: 0.6247 - val_acc: 0.7772
    Epoch 6/40
    15000/15000 [==============================] - 0s 30us/step - loss: 0.5993 - acc: 0.8001 - val_loss: 0.5872 - val_acc: 0.7899
    Epoch 7/40
    15000/15000 [==============================] - 0s 30us/step - loss: 0.5551 - acc: 0.8170 - val_loss: 0.5455 - val_acc: 0.8075
    Epoch 8/40
    15000/15000 [==============================] - 0s 31us/step - loss: 0.5085 - acc: 0.8334 - val_loss: 0.5035 - val_acc: 0.8222
    Epoch 9/40
    15000/15000 [==============================] - 0s 31us/step - loss: 0.4639 - acc: 0.8475 - val_loss: 0.4650 - val_acc: 0.8357
    Epoch 10/40
    15000/15000 [==============================] - 0s 31us/step - loss: 0.4231 - acc: 0.8631 - val_loss: 0.4316 - val_acc: 0.8435
    Epoch 11/40
    15000/15000 [==============================] - 0s 29us/step - loss: 0.3882 - acc: 0.8725 - val_loss: 0.4061 - val_acc: 0.8510
    Epoch 12/40
    15000/15000 [==============================] - 0s 31us/step - loss: 0.3588 - acc: 0.8812 - val_loss: 0.3813 - val_acc: 0.8582
    Epoch 13/40
    15000/15000 [==============================] - 0s 30us/step - loss: 0.3328 - acc: 0.8895 - val_loss: 0.3638 - val_acc: 0.8629
    Epoch 14/40
    15000/15000 [==============================] - 0s 31us/step - loss: 0.3113 - acc: 0.8950 - val_loss: 0.3483 - val_acc: 0.8687
    Epoch 15/40
    15000/15000 [==============================] - 0s 30us/step - loss: 0.2929 - acc: 0.8996 - val_loss: 0.3362 - val_acc: 0.8712
    Epoch 16/40
    15000/15000 [==============================] - 0s 32us/step - loss: 0.2771 - acc: 0.9025 - val_loss: 0.3264 - val_acc: 0.8733
    Epoch 17/40
    15000/15000 [==============================] - 0s 30us/step - loss: 0.2622 - acc: 0.9097 - val_loss: 0.3182 - val_acc: 0.8754
    Epoch 18/40
    15000/15000 [==============================] - 0s 30us/step - loss: 0.2492 - acc: 0.9143 - val_loss: 0.3113 - val_acc: 0.8787
    Epoch 19/40
    15000/15000 [==============================] - 0s 30us/step - loss: 0.2373 - acc: 0.9179 - val_loss: 0.3056 - val_acc: 0.8798
    Epoch 20/40
    15000/15000 [==============================] - 0s 29us/step - loss: 0.2268 - acc: 0.9213 - val_loss: 0.3010 - val_acc: 0.8809
    Epoch 21/40
    15000/15000 [==============================] - 0s 31us/step - loss: 0.2166 - acc: 0.9255 - val_loss: 0.2969 - val_acc: 0.8823
    Epoch 22/40
    15000/15000 [==============================] - 0s 32us/step - loss: 0.2073 - acc: 0.9288 - val_loss: 0.2941 - val_acc: 0.8826
    Epoch 23/40
    15000/15000 [==============================] - 0s 33us/step - loss: 0.1988 - acc: 0.9319 - val_loss: 0.2916 - val_acc: 0.8830
    Epoch 24/40
    15000/15000 [==============================] - 0s 31us/step - loss: 0.1903 - acc: 0.9356 - val_loss: 0.2889 - val_acc: 0.8845
    Epoch 25/40
    15000/15000 [==============================] - 0s 32us/step - loss: 0.1828 - acc: 0.9398 - val_loss: 0.2873 - val_acc: 0.8856
    Epoch 26/40
    15000/15000 [==============================] - 0s 31us/step - loss: 0.1754 - acc: 0.9424 - val_loss: 0.2864 - val_acc: 0.8851
    Epoch 27/40
    15000/15000 [==============================] - 0s 32us/step - loss: 0.1691 - acc: 0.9461 - val_loss: 0.2859 - val_acc: 0.8850
    Epoch 28/40
    15000/15000 [==============================] - 0s 32us/step - loss: 0.1625 - acc: 0.9477 - val_loss: 0.2849 - val_acc: 0.8855
    Epoch 29/40
    15000/15000 [==============================] - 0s 32us/step - loss: 0.1564 - acc: 0.9501 - val_loss: 0.2848 - val_acc: 0.8866
    Epoch 30/40
    15000/15000 [==============================] - 0s 32us/step - loss: 0.1511 - acc: 0.9523 - val_loss: 0.2853 - val_acc: 0.8853
    Epoch 31/40
    15000/15000 [==============================] - 0s 30us/step - loss: 0.1449 - acc: 0.9557 - val_loss: 0.2858 - val_acc: 0.8865
    Epoch 32/40
    15000/15000 [==============================] - 0s 30us/step - loss: 0.1400 - acc: 0.9577 - val_loss: 0.2868 - val_acc: 0.8867
    Epoch 33/40
    15000/15000 [==============================] - 0s 31us/step - loss: 0.1344 - acc: 0.9599 - val_loss: 0.2879 - val_acc: 0.8869
    Epoch 34/40
    15000/15000 [==============================] - 0s 31us/step - loss: 0.1297 - acc: 0.9619 - val_loss: 0.2892 - val_acc: 0.8861
    Epoch 35/40
    15000/15000 [==============================] - 0s 31us/step - loss: 0.1255 - acc: 0.9635 - val_loss: 0.2905 - val_acc: 0.8859
    Epoch 36/40
    15000/15000 [==============================] - 0s 30us/step - loss: 0.1204 - acc: 0.9663 - val_loss: 0.2926 - val_acc: 0.8859
    Epoch 37/40
    15000/15000 [==============================] - 0s 30us/step - loss: 0.1164 - acc: 0.9673 - val_loss: 0.2949 - val_acc: 0.8859
    Epoch 38/40
    15000/15000 [==============================] - 0s 31us/step - loss: 0.1128 - acc: 0.9679 - val_loss: 0.2963 - val_acc: 0.8853
    Epoch 39/40
    15000/15000 [==============================] - 0s 30us/step - loss: 0.1082 - acc: 0.9697 - val_loss: 0.2985 - val_acc: 0.8850
    Epoch 40/40
    15000/15000 [==============================] - 0s 32us/step - loss: 0.1043 - acc: 0.9713 - val_loss: 0.3010 - val_acc: 0.8850
    25000/25000 [==============================] - 0s 11us/step
    [0.3203085189342499, 0.87372]

    End of LogType:stdout
    ***********************************************************************
    [...]


Spark example
.............

.. note::

    For launching Spark using Docker containers, you must launch with the
    --deploy-mode client parameter. For that, you should request to the EDI
    technical staff to setup your environment.

It is possible to launch Spark jobs over Docker for including all your required
libraries. For that you should create an image with the required Spark
dependencies:

.. code-block:: Dockerfile

    FROM python:2

    ENV PYSPARK_PYTHON=/usr/bin/python2.7
    RUN pip install -U pip
    RUN pip install pyspark==2.3.2

Once you have built this image and pushed it to the repository, you must
create your python2.7 environment at JupyterLab and install your dependencies:

.. code-block:: console

    conda create --name py2 python=2.7
    source activate py2
    pip install <my-dependencies>


Next, you can submit your application to the cluster with the following
command:

.. code-block:: console

    # spark-submit --master yarn \
    --conf spark.driver.host=<username>.jupyter.edincubator.eu \
    --conf spark.driver.port=<your_driver_port> \
    --conf spark.driver.bindAddress=0.0.0.0 \
    --conf spark.blockManager.port=<your_blockmanager_port> \
    --conf spark.executorEnv.YARN_CONTAINER_RUNTIME_TYPE=docker \
    --conf spark.executorEnv.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=registry.edincubator.eu/<username>/spark-example:v0.0.3 \
    --conf spark.executorEnv.YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS=/etc/passwd:/etc/passwd:ro,/etc/group:/etc/group:ro,/etc/krb5.conf:/etc/krb5.conf:ro,/hadoopfs/fs1/yarn/nodemanager/log:/hadoopfs/fs1/yarn/nodemanager/log:ro,/usr/lib/jvm/java/:/usr/lib/jvm/java/:ro \
    examples/dockerexamples/spark/yelp_example.py /samples/yelp/yelp_business/yelp_business.csv /user/<username>/spark-csv-output --app_name <username>DockerYelpExample
