.. _basicconcepts:

EDI client's basic concepts
===========================

EDI provides a `Docker <http://docker.io>`_ image with a set of already installed
tools for interacting with the Big Data Stack . In order to create a Docker
container using this image, you must perform the following steps:

#. Install Docker in your system according to the following `instructions <https://docs.docker.com/install/>`_.
#. Pull the docker image from EDI registry:

.. code-block:: console

  $ docker pull edincubator/stack-client

3. Run and access to the container:

.. code-block :: console

  $ docker run -ti -v <workdir>:/workdir registry.edincubator.eu/stack-client /bin/bash
  Enter your username : <username>
  $

Being `<workdir>` the directory where your source code, scripts, etc. are.
The `-v` param creates a Docker volume mounted at `/workdir` inside the container,
from which you can access to your files.

.. note::

  We differentiate commands launched from the host machine, identified by the
  `$` symbol, from those commands launched inside the Docker container, which
  are identified by the `#` symbol.


.. _authenticating-with-kerberos:

Authenticating with Kerberos
----------------------------

Before doing anything at EDI Big Data Stack, you must be authenticated using
your `Kerberos <https://web.mit.edu/kerberos/>`_ credentials. Kerberos is a
network authentication protocol which provides strong authentication for
client/server applications by using secret-key cryptography.

For authenticating yourself you must introduce the following command:

.. ifconfig:: releaselevel in ('dev')

  .. code-block:: console

    # kinit <user>@GAUSS.RES.ENG.IT
    Password for <user>@GAUSS.RES.ENG.IT: <enter your password>
    #

.. ifconfig:: releaselevel in ('prod')

  .. code-block:: console

    # kinit <user>@<REALM>
    Password for <user>@<REALM>: <enter your password>
    #

You can check the status of your Kerberos ticket using the `klist` command:

.. ifconfig:: releaselevel in ('dev')

  .. code-block:: console

    # klist
    Ticket cache: FILE:/tmp/krb5cc_0
    Default principal: <user>@GAUSS.RES.ENG.IT

    Valid starting     Expires            Service principal
    04/12/18 09:53:28  04/13/18 09:53:28  krbtgt/gauss.res.eng.it@GAUSS.RES.ENG.IT

.. ifconfig:: releaselevel in ('prod')

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
   tools/oozie
   tools/nifi
   tools/zeppelin
   tools/views
