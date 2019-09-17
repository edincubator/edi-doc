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
Enter at `tf_cpu` directory:

.. code-block:: console

    # cd tf_cpu

Here, we can find two files: `Dockerfile` and `tf_example.py`. Let's see the
first one:

.. code-block:: dockerfile

    FROM tensorflow/tensorflow:1.12.3

    RUN mkdir /source
    ADD tf_example.py /source

This image is quite simple. It imports Tensorflow 1.12.3 and adds our code.

.. warning::

    The maximum Tensorflow version supported by Hadoop 3.0 is 1.12.3, as it is
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
    Step 1/3 : FROM tensorflow/tensorflow:1.12.3
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

    # docker push registry.edincubator.eu/<username>/tf:cpu-v1


You must access to your :ref:`JupyterLab <jupyterhub-section>` environment to launch the job. Open a
terminal, login with your Kerberos keytab and execute the following command: