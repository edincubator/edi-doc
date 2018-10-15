.. _oozie:

Oozie
=====

`Apache Oozie <http://oozie.apache.org/>`_ is a workflow scheduler for Hadoop. Oozie allow defining worflows,
coordinators and bundles:

* **Workflow:** It is a sequence of actions. It is written in xml and the
  actions can be map reduce, hive, pig etc.
* **Coordinator:** It is a program that triggers actions (commonly workflow
  jobs) when a set of conditions are met. Conditions can be a time frequency,
  other external events etc.
* **Bundle:** It is defined as a higher level oozie abstraction that batches a
  set of coordinator jobs.We can specify the time for bundle job to start as
  well.

In this tutorial we explain how to create an execute an Oozie workflow. This
workflow will launch the Pig job presented at :ref:`pig` and read generated
results by a Spark job.

.. note::

  You can design and run Oozie jobs easily using :ref:`workflow`.

Oozie Workflow
--------------

Oozie workflows, coordinators and bundles are defined in XML files. You can
find the following example at `stack-examples/oozieexmaple/workflow.xml` file
at stack-examples repository:

.. code-block :: console

  $ git clone https://github.com/edincubator/stack-examples
  $ cd stack-examples/oozieexmaple

This workflow defines three actions:

* The first action defines a file system action (fs) for clearing the output
  paths and avoid future errors.
* The second one defines the Pig script for aggregating data (
  `stack-examples/pigexample/yelp_business.pig`).
* The third one defines the Spark job for filtering data
  (`stack-examples/oozieexample/spark.py`).


File System action
..................

This action clears paths used by other tasks as output to avoid errors.

.. code-block:: xml

  <action name="fs_1">
    <fs>
      <name-node>${nameNode}</name-node>
      <delete path="/user/docuser/pig-output"></delete>
      <delete path="/user/docuser/spark-oozie-output"></delete>
    </fs>
    <ok to="pig_1"/>
    <error to="pig_1"/>
  </action>

As can be seen, every action has certain XML nodes and attributes:

* **action**: represents the action to be defined. It has to be named using
  `name` attribute.
* **type**: the type of action, in this case `fs`.
* **ok** and **error**: they represent the flow in case of a successful or a
  failed result.

In addition to those properties and the ones owned by the specific action,
if the action needs to interact with other components like HDFS Namenode or
YARN Jobtracker, they must be defined too.

Pig action
..........

This action executes a Pig script.

.. code-block:: xml

  <action name="pig_1">
    <pig>
      <job-tracker>${jobTracker}</job-tracker>
      <name-node>${nameNode}</name-node>
      <script>/user/docuser/pig/scripts/yelpbusiness-2018-06-07_12-45.pig</script>
    </pig>
    <ok to="spark_1"/>
    <error to="kill"/>
  </action>


Spark action
............

This action executes a Spark script.

.. warning::

  The Spark2 Oozie action is a Technical Preview, so its usage is not
  recommended for production environments.

.. code-block:: xml

  <action name="spark_1">
    <spark
      xmlns="uri:oozie:spark-action:0.2">
      <job-tracker>${jobTracker}</job-tracker>
      <name-node>${nameNode}</name-node>
      <master>yarn-cluster</master>
      <name>SparkOozieTest</name>
      <jar>hdfs://gauss.res.eng.it:8020/user/docuser/workflows/spark.py</jar>
    </spark>
    <ok to="end"/>
    <error to="kill"/>
  </action>

In addition to the action, you must declare the following global configuration
atributes.

.. code-block:: xml

  <global>
    <configuration>
      <property>
        <name>oozie.use.system.libpath</name>
        <value>true</value>
      </property>
      <property>
        <name>oozie.action.sharelib.for.spark</name>
        <value>spark2</value>
      </property>
    </configuration>
  </global>


Oozie Job Properties
--------------------

In addition to the `workflow.xml` file, the `job.properties` file declares the
parameters and variables used by the Oozie job:

.. code-block:: properties

  nameNode=hdfs://gauss.res.eng.it:8020
  jobTracker=gauss.res.eng.it:8050
  master=yarn-cluster
  examplesRoot=oozie-example
  oozie.use.system.libpath=true
  oozie.wf.application.path=${nameNode}/user/${user.name}/${examplesRoot}/


Executing the workflow
----------------------

For executing the workflow, you must follow those steps:

.. code-block:: console

  # cd stack-examples
  # hdfs dfs -mkdir /user/<username>/oozie-example
  # hdfs dfs -put stack-examples/oozieexample/workflow.xml /user/<username>/oozie-example
  # hdfs dfs -put stack-examples/pigexample/yelp_business.pig /user/<username>/oozie-example
  # hdfs dfs -put stack-examples/oozieexample/spark.py /user/<username>/oozie-example
  # oozie job -oozie http://master.edincubator.eu:11000/oozie -config stack-examples/oozieexample/job.properties -run
  job: 0000007-180608111137903-oozie-oozi-W


You can check the status of the job using `oozie jobs` command:

.. code-block:: console

  # oozie jobs -oozie http://gauss.res.eng.it:11000/oozie
  Job ID                                   App Name     Status    User      Group     Started                 Ended
  ------------------------------------------------------------------------------------------------------------------------------------
  0000008-180608111137903-oozie-oozi-W     Test workflowRUNNING   docuser   -         2018-06-11 10:19 GMT    -
  ------------------------------------------------------------------------------------------------------------------------------------

You can check logs from a job using `oozie job -log` command

.. code-block:: console

  # oozie job -oozie http://gauss.res.eng.it:11000/oozie -log 0000008-180608111137903-oozie-oozi-W
  2018-06-11 12:19:33,185  INFO ActionStartXCommand:520 - SERVER[gauss.res.eng.it] USER[docuser] GROUP[-] TOKEN[] APP[Test workflow] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@:start:] Start action [0000008-180608111137903-oozie-oozi-W@:start:] with user-retry state : userRetryCount [0], userRetryMax [0], userRetryInterval [10]
  2018-06-11 12:19:33,185  INFO ActionStartXCommand:520 - SERVER[gauss.res.eng.it] USER[docuser] GROUP[-] TOKEN[] APP[Test workflow] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@:start:] [***0000008-180608111137903-oozie-oozi-W@:start:***]Action status=DONE
  2018-06-11 12:19:33,186  INFO ActionStartXCommand:520 - SERVER[gauss.res.eng.it] USER[docuser] GROUP[-] TOKEN[] APP[Test workflow] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@:start:] [***0000008-180608111137903-oozie-oozi-W@:start:***]Action updated in DB!
  2018-06-11 12:19:33,246  INFO WorkflowNotificationXCommand:520 - SERVER[gauss.res.eng.it] USER[-] GROUP[-] TOKEN[-] APP[-] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@:start:] No Notification URL is defined. Therefore nothing to notify for job 0000008-180608111137903-oozie-oozi-W@:start:
  2018-06-11 12:19:33,246  INFO WorkflowNotificationXCommand:520 - SERVER[gauss.res.eng.it] USER[-] GROUP[-] TOKEN[-] APP[-] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[] No Notification URL is defined. Therefore nothing to notify for job 0000008-180608111137903-oozie-oozi-W
  2018-06-11 12:19:33,279  INFO ActionStartXCommand:520 - SERVER[gauss.res.eng.it] USER[docuser] GROUP[-] TOKEN[] APP[Test workflow] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@fs_1] Start action [0000008-180608111137903-oozie-oozi-W@fs_1] with user-retry state : userRetryCount [0], userRetryMax [0], userRetryInterval [10]
  2018-06-11 12:19:33,296  INFO ActionStartXCommand:520 - SERVER[gauss.res.eng.it] USER[docuser] GROUP[-] TOKEN[] APP[Test workflow] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@fs_1] [***0000008-180608111137903-oozie-oozi-W@fs_1***]Action status=DONE
  2018-06-11 12:19:33,296  INFO ActionStartXCommand:520 - SERVER[gauss.res.eng.it] USER[docuser] GROUP[-] TOKEN[] APP[Test workflow] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@fs_1] [***0000008-180608111137903-oozie-oozi-W@fs_1***]Action updated in DB!
  2018-06-11 12:19:33,408  INFO ActionStartXCommand:520 - SERVER[gauss.res.eng.it] USER[docuser] GROUP[-] TOKEN[] APP[Test workflow] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@pig_1] Start action [0000008-180608111137903-oozie-oozi-W@pig_1] with user-retry state : userRetryCount [0], userRetryMax [0], userRetryInterval [10]
  2018-06-11 12:19:35,322  INFO PigActionExecutor:520 - SERVER[gauss.res.eng.it] USER[docuser] GROUP[-] TOKEN[] APP[Test workflow] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@pig_1] Trying to get job [job_1528449029285_0023], attempt [1]
  2018-06-11 12:19:35,362  INFO PigActionExecutor:520 - SERVER[gauss.res.eng.it] USER[docuser] GROUP[-] TOKEN[] APP[Test workflow] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@pig_1] checking action, hadoop job ID [job_1528449029285_0023] status [RUNNING]
  2018-06-11 12:19:35,367  INFO ActionStartXCommand:520 - SERVER[gauss.res.eng.it] USER[docuser] GROUP[-] TOKEN[] APP[Test workflow] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@pig_1] [***0000008-180608111137903-oozie-oozi-W@pig_1***]Action status=RUNNING
  2018-06-11 12:19:35,367  INFO ActionStartXCommand:520 - SERVER[gauss.res.eng.it] USER[docuser] GROUP[-] TOKEN[] APP[Test workflow] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@pig_1] [***0000008-180608111137903-oozie-oozi-W@pig_1***]Action updated in DB!
  2018-06-11 12:19:35,374  INFO WorkflowNotificationXCommand:520 - SERVER[gauss.res.eng.it] USER[-] GROUP[-] TOKEN[-] APP[-] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@pig_1] No Notification URL is defined. Therefore nothing to notify for job 0000008-180608111137903-oozie-oozi-W@pig_1
  2018-06-11 12:19:35,375  INFO WorkflowNotificationXCommand:520 - SERVER[gauss.res.eng.it] USER[-] GROUP[-] TOKEN[-] APP[-] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@fs_1] No Notification URL is defined. Therefore nothing to notify for job 0000008-180608111137903-oozie-oozi-W@fs_1
  2018-06-11 12:21:12,576  INFO CallbackServlet:520 - SERVER[gauss.res.eng.it] USER[-] GROUP[-] TOKEN[-] APP[-] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@pig_1] callback for action [0000008-180608111137903-oozie-oozi-W@pig_1]
  2018-06-11 12:21:12,733  INFO PigActionExecutor:520 - SERVER[gauss.res.eng.it] USER[docuser] GROUP[-] TOKEN[] APP[Test workflow] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@pig_1] Trying to get job [job_1528449029285_0023], attempt [1]
  2018-06-11 12:21:12,838  INFO PigActionExecutor:520 - SERVER[gauss.res.eng.it] USER[docuser] GROUP[-] TOKEN[] APP[Test workflow] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@pig_1] Hadoop Jobs launched : [job_1528449029285_0024]
  2018-06-11 12:21:12,840  INFO PigActionExecutor:520 - SERVER[gauss.res.eng.it] USER[docuser] GROUP[-] TOKEN[] APP[Test workflow] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@pig_1] action completed, external ID [job_1528449029285_0023]
  2018-06-11 12:21:13,038  INFO ActionStartXCommand:520 - SERVER[gauss.res.eng.it] USER[docuser] GROUP[-] TOKEN[] APP[Test workflow] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@spark_1] Start action [0000008-180608111137903-oozie-oozi-W@spark_1] with user-retry state : userRetryCount [0], userRetryMax [0], userRetryInterval [10]
  2018-06-11 12:21:13,372  INFO SparkActionExecutor:520 - SERVER[gauss.res.eng.it] USER[docuser] GROUP[-] TOKEN[] APP[Test workflow] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@spark_1] Added into spark action configuration mapred.child.env=SPARK_HOME=.,HDP_VERSION=2.6.5.0-292
  2018-06-11 12:21:15,967  INFO SparkActionExecutor:520 - SERVER[gauss.res.eng.it] USER[docuser] GROUP[-] TOKEN[] APP[Test workflow] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@spark_1] Trying to get job [job_1528449029285_0025], attempt [1]
  2018-06-11 12:21:16,100  INFO SparkActionExecutor:520 - SERVER[gauss.res.eng.it] USER[docuser] GROUP[-] TOKEN[] APP[Test workflow] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@spark_1] checking action, hadoop job ID [job_1528449029285_0025] status [RUNNING]
  2018-06-11 12:21:16,104  INFO ActionStartXCommand:520 - SERVER[gauss.res.eng.it] USER[docuser] GROUP[-] TOKEN[] APP[Test workflow] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@spark_1] [***0000008-180608111137903-oozie-oozi-W@spark_1***]Action status=RUNNING
  2018-06-11 12:21:16,104  INFO ActionStartXCommand:520 - SERVER[gauss.res.eng.it] USER[docuser] GROUP[-] TOKEN[] APP[Test workflow] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@spark_1] [***0000008-180608111137903-oozie-oozi-W@spark_1***]Action updated in DB!
  2018-06-11 12:21:16,160  INFO WorkflowNotificationXCommand:520 - SERVER[gauss.res.eng.it] USER[-] GROUP[-] TOKEN[-] APP[-] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@spark_1] No Notification URL is defined. Therefore nothing to notify for job 0000008-180608111137903-oozie-oozi-W@spark_1
  2018-06-11 12:21:16,160  INFO WorkflowNotificationXCommand:520 - SERVER[gauss.res.eng.it] USER[-] GROUP[-] TOKEN[-] APP[-] JOB[0000008-180608111137903-oozie-oozi-W] ACTION[0000008-180608111137903-oozie-oozi-W@pig_1] No Notification URL is defined. Therefore nothing to notify for job 0000008-180608111137903-oozie-oozi-W@pig_1


When Oozie job finishes, you can check its results at
`/user/docuser/spark-oozie-output`.
