.. _stack-client-osx:

Launching EDI's Big Data Stack Client in OSX
============================================

.. note::

  If you are not intended to use the web apps (Zeppelin, NiFi and Ambari Views)
  provided by the Big Data Stack, you can follow the :ref:`basicconcepts`.


Docker for OSX have a limitation when launching desktop applications that avoids
working with the VPN connection. If you want to access to web apps provided by
EDI's Big Data Stack, you must follow this workaround:

1. Install TunnelBlick VPN client: https://tunnelblick.net/
2. Modify your `edi.ovpn` file and add the following line to the top of the file:

.. code-block:: vim

  dhcp-option DNS 192.168.1.11



3. Open TunnelBlick and drag and drop your ovpn file. Connect to the vpn and in a browser open https://manager.edincubator.eu:8443.

This way, your host computer is connected to the VPN. If you use this workaround,
you must launch the CLI stack-client with `--net=host` option instead
`--net=container:vpn` option and the vpn-client container must be stopped.
