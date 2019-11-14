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

  Before creating a Kafka topic, you must contact with :ref:`technical-support` for
  giving you the proper permissions. Once you have your topic set, you can
  continue with this tutorial.


For interacting with Kafka, you must point at its directory, located at
`/usr/hdp/current/kafka-broker`. From here you can list existing topics:


.. note::

  You will see some warnings that you can ignore.

.. code-block:: console

  # kafka-topics.sh --list --zookeeper edincubator-m-3-20191031113524.c.edi-call2.internal:2181
  [...]
  <username>_test

Launch a message producer on one of available brokers (see below) and start typing messages:

.. code-block:: console

  # kafka-console-producer.sh --broker-list edincubator-w-1-20191031113554.c.edi-call2.internal:6667 --producer-property security.protocol=SASL_PLAINTEXT --topic <username>_test
  Hi!
  How are you?

In another terminal, launch a message consumer:


.. code-block:: console

  # kafka-console-consumer.sh --bootstrap-server edincubator-w-1-20191031113554.c.edi-call2.internal:6667 --consumer-property security.protocol=SASL_PLAINTEXT --topic <username>_test --from-beginning
  Hi!
  How are you?


You can see that messages typed in the message producer appear in the consumer.

You can find how to code your own message producers and consumers at
`​Producing Events/Messages to Kafka on a Secured Cluster <https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.0.0/authentication-with-kerberos/content/kerberos_kafka_producing_events_or_messages_to_kafka_on_a_secured_cluster.html>`_
and
`​Consuming Events/Messages from Kafka on a Secured Cluster <https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.0.0/authentication-with-kerberos/content/kerberos_kafka_consuming_events_or_messages_from_kafka_on_a_secured_cluster.html>`_
.

Available Kafka Brokers
-----------------------
+--------------------------------------------------------------+
| Host                                                         |
+--------------------------------------------------------------+
| edincubator-w-[0-2]-20191031113554.c.edi-call2.internal:6667 |
+--------------------------------------------------------------+