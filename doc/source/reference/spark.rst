.. _spark_reference:

Spark
=====

This section compiles references to external resources that contain further
information about the Spark framework.

The goal of this section is to provide a general knowledge about the involved
paradigms and technologies, which can be used to improve the implementation of
the different solutions. However, this section is not intended to be a detailed
manual of all the involved aspects.

The official page of the `Apache Spark <http://spark.apache.org/>`_ project is
good starting point to learn about the technology, API and related tools.


Architecture overview
---------------------

The following resource provides a general view of the Spark
`architecture <https://jaceklaskowski.gitbooks.io/mastering-apache-spark/spark-architecture.html>`_.
Although all this processes are transparently managed by Spark framework, it is
important to understand the relation between the different components in order
to develop solutions that behave efficiently and use all the resources in a
correct manner.

Resilient Distributed Dataset
-----------------------------

The main abstraction provided by Spark is the RDD (Resilient Distributed Dataset),
which is a collection of elements partitioned across the nodes of the cluster
that can be operated on in parallel. RDDs are created by starting with a file in
the Hadoop file system (or any other Hadoop-supported file system), or an
existing Scala collection in the driver program, and transforming it.

I/O formats
~~~~~~~~~~~

Spark can create distributed datasets from any storage source supported by Hadoop,
including your local file system, HDFS, Cassandra, HBase, Amazon S3, etc. Spark supports text files,
SequenceFiles, and any other Hadoop InputFormat. The following link provides
information about how to manage `external datasets <https://spark.apache.org/docs/latest/rdd-programming-guide.html#external-datasets>`
within Spark.

Transformations
~~~~~~~~~~~~~~~

Transformations are operations on a RDD than result in a new RDD. The following
link provides a list of some of the available
`transformations <https://spark.apache.org/docs/latest/rdd-programming-guide.html#transformations>`_ in Spark.

Transformations do not trigger any parallel computation process by themselves,
however, they are concatenated until an action is performed on the constructed
graph, which triggers all the required transformations in sequence.

Actions
~~~~~~~

On the other hand, actions are operations that result in a value that is not a
new RDD (i.e. arrays, integers, etc). The following link contains a list of the
some of the available `actions <https://spark.apache.org/docs/latest/rdd-programming-guide.html#actions>`_ in Spark.

Shuffle operations
~~~~~~~~~~~~~~~~~~

Some of the operations that can be performed on a RDD result in the process
known as shuffling, which is the redistribution of the RDD data among different
partitions. As it usually involves communication among different machines, it
is an operation that should be minimized as possible to reduce computation times.

Partitioning
------------

An important concept to improve computation efficiency in Spark are the concepts
of partition and partitioning. Spark distributes data among partitions to improve
parallelization.

A partition (aka split) is a logical chunk of a large distributed data set.
Spark tries to read data into an RDD from the nodes that are close to it. By default,
a partition is created for each HDFS partition.

Although partition is created automatically by Spark, it is useful to undersand
the mechanism followed by Spark because it can be improved for some specific
applications.

In addition, some transformations broke the existing partition, requiring a
shuffle, so the selection of the transformations and actions to obtain the
desired result can have a high impact in the performance of the computation.

The following link provides information about
`partitioning <https://jaceklaskowski.gitbooks.io/mastering-apache-spark/spark-rdd-partitions.html>`_ in Spark.


Spark SQL
---------

Sparks provide a language known as Spark SQL, similar to the language for
relational databases, that allows to perform queries in a parallized way on
distributed data.

The following link provides information about the
`Spark SQL <https://spark.apache.org/docs/latest/sql-programming-guide.html>`_ language.

Development process
-------------------

This section includes some comments and advices about how to improve the
development of jobs withing the Spark framework.

Building
~~~~~~~~

Aplications developed for Spark are usually bundled together with their
required libraries before submitting them to the cluster.

As the framework supports various development languages (i.e. Scala, Python, Java),
the specific instructions to build the bundle and include the libraries depend on
the selected language.

The following link provides a basic example about how to
`build applications <https://spark.apache.org/docs/latest/quick-start.html#self-contained-applications>`_
for Spark in the different languages.

Testing
~~~~~~~

As any other software development, developed code should be tested before
launching the job with real data.

First, Spark provides libraries to facilitate the testing of the developed code
before the execution with real data. The following resources provides information
about how to perform `unit testing <http://www.jesse-anderson.com/2016/04/unit-testing-spark-with-java/>`_
within Spark.

Debugging
~~~~~~~~~

On the other hand, jobs must be tested with sample data using the
`standalone mode <https://spark.apache.org/docs/latest/spark-standalone.html#spark-standalone-mode>`_
before launching the a real job in the cluster. Testing the jobs thoroughly
reduces the development time and the detection of errors in production.
