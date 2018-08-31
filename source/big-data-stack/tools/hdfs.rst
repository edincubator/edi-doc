.. warning::

  Remember that for interacting with EDI Big Data Stack you must be
  authenticated at the system using `kinit` command. For more information, read
  the documentation at :ref:`authenticating-with-kerberos`.

..  _hdfs:


HDFS
====

Hadoop Distributed File System (HDFS) is the de-facto file system used at
Hadoop environments, and is the one available at EDI Big Data Stack.
At this guide, we explain how to load the
`Yelp Dataset from Kaggle <https://www.kaggle.com/yelp-dataset/yelp-dataset>`_
at EDI Big Data Stack.


At first you must download the
`Yelp Dataset from Kaggle <https://www.kaggle.com/yelp-dataset/yelp-dataset>`_
and uncompress it to your working directory.

.. code-block :: console

  $ cd <workdir>
  $ unzip yelp-dataset.zip
  Archive:  yelp-dataset.zip
  inflating: yelp_business.csv
  inflating: yelp_checkin.csv
  inflating: Dataset_Challenge_Dataset_Agreement.pdf
  inflating: yelp_tip.csv
  inflating: yelp_business_attributes.csv
  inflating: yelp_review.csv
  inflating: yelp_user.csv
  inflating: yelp_business_hours.csv

**From inside the Docker container**, you can copy those files to your HDFS workspace.
Every selected team at EDI has its own workspace at /user/<username> directory.

.. code-block :: console

  # cd /workdir
  # hdfs dfs -mkdir /user/<username>/samples
  # hdfs dfs -put *.csv /user/<username>/samples/
  # hdfs dfs -ls /user/<username>/samples
  Found 7 items
  -rw-------   3 <username> <username>   31760674 2018-04-12 12:07 /user/<username>/samples/yelp_business.csv
  -rw-------   3 <username> <username>   41377121 2018-04-12 12:07 /user/<username>/samples/yelp_business_attributes.csv
  -rw-------   3 <username> <username>   13866351 2018-04-12 12:07 /user/<username>/samples/yelp_business_hours.csv
  -rw-------   3 <username> <username>  135964892 2018-04-12 12:07 /user/<username>/samples/yelp_checkin.csv
  -rw-------   3 <username> <username> 3791120545 2018-04-12 12:09 /user/<username>/samples/yelp_review.csv
  -rw-------   3 <username> <username>  148085910 2018-04-12 12:09 /user/<username>/samples/yelp_tip.csv
  -rw-------   3 <username> <username> 1363176944 2018-04-12 12:10 /user/<username>/samples/yelp_user.csv


As you can see, the command for manipulating files and directories at HDFS is
`hdfs dfs`. Indistinctly, you can use `hadoop fs` command too. The complete
description of all the operations provided by this command is available at
`Apache Hadoop File System Shell Guide <https://hadoop.apache.org/docs/r2.7.3/hadoop-project-dist/hadoop-common/FileSystemShell.html>`_.

.. note::

  You can also manage files and folders at HDFS using the :ref:`webhdfs`.
