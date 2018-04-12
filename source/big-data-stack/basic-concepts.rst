EDI client's basic concepts
===========================

EDI provides a `Docker <http://docker.io>`_ image with all required tools for
interacting with the Big Data Stack already installed. For creating a Docker
container using this image, you must fill the following steps:

#. Install Docker in your system following the `instructions <https://docs.docker.com/install/>`_.
#. Download `EDI stack-client Docker image <http://foo/bar>`_.
#. Import the docker image:

.. code-block:: console

  $ docker load -i stack-client.tar

4. Run and access to the container:

.. code-block :: console

  $ docker run -ti -v <workdir>:/workdir edincubator/stack-client /bin/bash

Being `<workdir>` the directory where your source code, scripts, etc. are.
`-v` param creates a Docker volume mounted at `/workdir` inside the container,
from which you can access to your files.

.. todo::

  Upload the image to somewhere or use a Docker registry and fix step #2.

.. todo::

  Test step #2, because VPN we can't test it.

Authenticating with Kerberos
----------------------------

Before doing anything at EDI Big Data Stack, you must be authenticated using
your `Kerberos <https://web.mit.edu/kerberos/>`_ credentials. Kerberos is a
network authentication protocol which provides strong authentication for
client/server applications by using secret-key cryptography.

For authenticating yourself you must introduce the following command:

.. code-block:: console

  # kinit <user>@REALM
  Password for mikel@GAUSS.RES.ENG.IT: <enter your password>
  #

You can check the status of your Kerberos ticket using the `klist` command:

.. code-block:: console

  # klist
  Ticket cache: FILE:/tmp/krb5cc_0
  Default principal: <user>@<REALM>

  Valid starting     Expires            Service principal
  04/12/18 09:53:28  04/13/18 09:53:28  krbtgt/<REALM>@<REALM>


.. todo::

  Replace REALM by production realm.
