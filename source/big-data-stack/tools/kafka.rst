.. warning::

  Remember that for interacting with EDI Big Data Stack you must be
  authenticated at the system using `kinit` command. For more information, read
  the documentation at :ref:`authenticating-with-kerberos`.

Kafka
=====

Kafka is used for building real-time data pipelines and streaming apps. EDI Big
Data Stack provides a cluster of Kafka Brokers that allows you working with
Kafka topics.

Basic functionalities
---------------------

.. warning::

  Before creating a Kafka topic, you must contact with EDI Technical Support for
  giving you the proper permissions. Once you have your topic set, you can
  continue with this tutorial.

.. todo::

  Link to EDI Technical Support.

For interacting with Kafka, you must point at its directory, located at
`/usr/hdp/current/kafka-broker`. From here you can list existing topics:

.. code-block:: console

  # cd /usr/hdp/current/kafka-broker
  # bin/kafka-topics.sh --list --zookeeper gauss.res.eng.it:2181
  [...]
  <username>_yelp_business


Launch a message producer and start typing messages:

.. code-block:: console

  # bin/kafka-console-producer.sh --broker-list gauss.res.eng.it:6667,heidi.res.eng.it:6667 --security-protocol SASL_PLAINTEXT --topic <username>_test
  Hi!
  How are you?

In another terminal, launch a message consumer:

.. code-block:: console

  # bin/kafka-console-consumer.sh --bootstrap-server gauss.res.eng.it:6667,heidi.res.eng.it:6667 --security-protocol SASL_PLAINTEXT --topic <username>_test --from-beginning
  Hi!
  How are you?

You can see that messages typed in the message producer appear in the consumer.

.. todo::

  Replace gauss, heidi and peter by production servers

You can find how to code your own message producers and consumers at
`​Producing Events/Messages to Kafka on a Secured Cluster <https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.6.4/bk_security/content/secure-kafka-produce-events.html>`_
and
`​Consuming Events/Messages from Kafka on a Secured Cluster <https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.6.4/bk_security/content/secure-kafka-consume-events.html>`_
.
