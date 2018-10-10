.. warning::

  Remember that for interacting with EDI Big Data Stack you must be
  authenticated at the system using `kinit` command. For more information, read
  the documentation at :ref:`authenticating-with-kerberos`.

..  _hdfs:


HDFS
====

Hadoop Distributed File System (HDFS) is the de-facto file system used at
Hadoop environments, and is the one available at EDI Big Data Stack.
At this guide, we explain basic commands to manipulate files and directories in
HDFS.

**From inside the Docker container**, you can create and upload files to your HDFS workspace.
Every selected team at EDI has its own workspace at `/user/<username>` directory.

.. code-block :: console

  # cd /workdir
  # hdfs dfs -mkdir /user/<username>/test
  # hdfs dfs -ls /user/<username>
  Found 1 items
  drwxr-xr-x   - <username> hdfs          0 2018-10-10 06:55 /user/<username>/test
  # touch foo
  # hdfs dfs -put foo /user/<username>/test
  # hdfs dfs -ls /user/<username>/test
  Found 1 items
  -rw-r--r--   3 <username> hdfs          0 2018-10-10 07:03 /user/<username>/test/foo
  # rm foo
  # hdfs dfs -get /user/<username>/test/foo .
  # ls
  foo
  #

As you can see, the command for manipulating files and directories at HDFS is
`hdfs dfs`. Indistinctly, you can use `hadoop fs` command too. The complete
description of all the operations provided by this command is available at
`Apache Hadoop File System Shell Guide <https://hadoop.apache.org/docs/r2.7.3/hadoop-project-dist/hadoop-common/FileSystemShell.html>`_.

.. note::

  You can also manage files and folders at HDFS using the :ref:`webhdfs`.
