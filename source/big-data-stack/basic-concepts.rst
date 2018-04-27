.. _basicconcepts:

EDI client's basic concepts
===========================

EDI provides a `Docker <http://docker.io>`_ image with all required tools for
interacting with the Big Data Stack already installed. For creating a Docker
container using this image, you must fill the following steps:

#. Install Docker in your system following the `instructions <https://docs.docker.com/install/>`_.
#. Download `EDI stack-client Docker image <http://foo/bar>`_.
#. Pull docker image from EDI registry:

.. code-block:: console

  $ docker pull registry.edincubator.eu/stack-client

4. Run and access to the container:

.. code-block :: console

  $ docker run -ti -v <workdir>:/workdir registry.edincubator.eu/stack-client /bin/bash

Being `<workdir>` the directory where your source code, scripts, etc. are.
`-v` param creates a Docker volume mounted at `/workdir` inside the container,
from which you can access to your files.

.. note::

  We differentiate commands launched from the host machine using `$` symbol and
  commands launched from inside the Docker container using `#` symbol.

.. todo::

  At this moment, stack-client image is at an insecure private registry. We must
  decide if we are going to use a custom registry for uploading EDI images or
  if we are going to user Docker Hub.

.. _authenticating-with-kerberos:

Authenticating with Kerberos
----------------------------

Before doing anything at EDI Big Data Stack, you must be authenticated using
your `Kerberos <https://web.mit.edu/kerberos/>`_ credentials. Kerberos is a
network authentication protocol which provides strong authentication for
client/server applications by using secret-key cryptography.

For authenticating yourself you must introduce the following command:

.. code-block:: console

  # kinit <user>@<REALM>
  Password for <user>@<REALM>: <enter your password>
  #

You can check the status of your Kerberos ticket using the `klist` command:

.. code-block:: console

  # klist
  Ticket cache: FILE:/tmp/krb5cc_0
  Default principal: <user>@<REALM>

  Valid starting     Expires            Service principal
  04/12/18 09:53:28  04/13/18 09:53:28  krbtgt/<REALM>@<REALM>

Once you have a valid ticket, you can work at EDI Big Data Stack until the
ticket expires. If the ticket expires, you must execute again `kinit` command.

.. todo::

  Replace REALM by production realm.

Tools provided by EDI Big Data Stack
------------------------------------

For illustrating the different tools provided by EDI Big Data Stack this
documentations follows a workflow using the
`Yelp Dataset from Kaggle <https://www.kaggle.com/yelp-dataset/yelp-dataset>`_.
We recommend following proposed workflow from beggining to the end for getting
a global view of tools provided by EDI Big Data Stack.

.. toctree::
   :maxdepth: 1

   tools/hdfs
   tools/map-reduce
   tools/spark2
   tools/hive
   tools/hbase
   tools/kafka
   tools/pig
