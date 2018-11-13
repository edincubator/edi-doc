.. _basicconcepts:

EDI client's basic concepts
===========================

.. note::

  If you use OSX, please read :ref:`stack-client-osx`.

Connect to Big Data Stack's VPN
-------------------------------

All services provided by EDI's Big Data Stack are only accessible through its
own VPN. This VPN network is restricted to Big Data Stack's private network and
it has not access to the public Internet. For this reason, if you connect to the
VPN using the client provided by your SO, you will be only enable to connect to
EDI services, without Internet access. For avoinding this situation, we provide instructions
for launching OpenVPN client in a `Docker <http://docker.io>`_ container, to allow
stack-client container and a custom Firefox browser connecting to the VPN, while
the rest of your SO remained connected to your default network with Internet access.

.. note::

  You can also launch Big Data Stack's client at FI-WARE. See
  :ref:`deploying-stack-client` for more information.

For installing Docker in your SO, follow instructions at `<https://docs.docker.com/install/>`_.

At first, you must store your OpenVPN config file (`edi.ovpn`) into a folder in
your system. In this example we suppose that this config file is in `/some/path`
folder. Use the following commands for launching the OpenVPN client:

.. code-block:: console

  $ docker run -it --cap-add=NET_ADMIN --device /dev/net/tun --name vpn \
            -v /some/path:/vpn --dns 192.168.1.11 --dns-search edincubator.eu \
            -d dperson/openvpn-client
  $ docker restart vpn

For connecting other containers to the VPN, you can use the `--net=container:vpn`
parameter, as explained later.

.. warning::

  Big Data Stack's VPN only allow one connection by user, so be sure that you
  don't run more than one VPN client containers at the same time. If you need
  additional VPN accounts for working in parallel with other people from your
  company, please contact with :ref:`technical-support`.

Big Data Stack's Client
-----------------------

EDI provides a `Docker <http://docker.io>`_ image with a set of already installed
tools for interacting with the Big Data Stack . In order to create a Docker
container using this image, you must perform the following steps:

1. Pull the docker image from Docker Hub:

.. code-block:: console

  $ docker pull edincubator/stack-client

2. Run and access to the container:

.. code-block :: console

  $ docker run -ti --net=container:vpn -v <workdir>:/workdir --name stack-client edincubator/stack-client /bin/bash
  Enter your username : <username>
  $

Being `<workdir>` the directory where your source code, scripts, etc. are.
The `-v` param creates a Docker volume mounted at `/workdir` inside the container,
from which you can access to your files.

If you need an additional CLI window, you can run:

.. code-block :: console

  $ docker exec -ti --user <username> stack_client /bin/bash

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

.. code-block:: console

  # kinit <user>
  Password for <user>@EDINCUBATOR.EU: <enter your password>
  #


You can check the status of your Kerberos ticket using the `klist` command:

.. code-block:: console

  # klist
  Ticket cache: FILE:/tmp/krb5cc_0
  Default principal: <user>@EDINCUBATOR.EU

  Valid starting     Expires            Service principal
  04/12/18 09:53:28  04/13/18 09:53:28  krbtgt/EDINCUBATOR.EU@EDINCUBATOR.EU


Once you have a valid ticket, you can work at EDI Big Data Stack until the
ticket expires. If the ticket expires, you must execute again `kinit` command.


.. _firefox:

Launching a Firefox browser
---------------------------

For accessing to :ref:`ambari-views` and other web-based tools provided by the
Big Data Stack you must be connected to the VPN. As explained before, connecting
to the VPN at a system level will restrict your connectivity to EDI's Big Data Stack
private network. To avoid this, you can launch a Firefox browser into a Docker
container connected to the VPN this way:

.. note::

  You must allow connections to your X11 server with the following command:

  $ xhost local:root

.. code-block:: console

  $ docker run -it --net=container:vpn --cpuset-cpus 0 --memory 512mb -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY --name firefox jess/firefox

Once the container is created, you can re-open firefox using `docker restart firefox`
commnad.


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
