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

Here, there are two files: `Dockerfile` and `tf_cpu.py`. Let's see the first
one:

.. code-block:: dockerfile

    FROM tensorflow/tensorflow:1.12.3

    RUN mkdir /source
    ADD tf_cpu.py /source

    CMD ["python", "/source/tf_cpu.py"]



docker login registry.edincubator.eu
docker build -t registry.edincubator.eu/<username>/tf:cpu


