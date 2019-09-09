.. warning::

  Remember that for interacting with EDI Big Data Stack you must be
  authenticated at the system using `kinit` command. For more information, read
  the documentation at :ref:`authenticating-with-kerberos`.

.. _pig:


Pig
---

Apache Pig is a platform for analyzing large data sets that consists of a
high-level language for expressing data analysis programs, coupled with
infrastructure for evaluating these programs. The salient property of Pig
programs is that their structure is amenable to substantial parallelization,
which in turns enables them to handle very large data sets.

In this tutorial we explain how to reproduce the example that we have been working
with (counting how many businesses each USA state has from Yelp) using Pig. For
starting a Pig shell you must type `pig` command:


.. code-block:: console

  # pig
  18/10/10 15:16:43 INFO pig.ExecTypeProvider: Trying ExecType : LOCAL
  18/10/10 15:16:43 INFO pig.ExecTypeProvider: Trying ExecType : MAPREDUCE
  18/10/10 15:16:43 INFO pig.ExecTypeProvider: Trying ExecType : TEZ_LOCAL
  18/10/10 15:16:43 INFO pig.ExecTypeProvider: Trying ExecType : TEZ
  18/10/10 15:16:43 INFO pig.ExecTypeProvider: Picked TEZ as the ExecType
  2018-10-10 15:16:43,214 [main] INFO  org.apache.pig.Main - Apache Pig version 0.16.0.2.6.5.0-292 (rUnversioned directory) compiled May 11 2018, 07:56:28
  2018-10-10 15:16:43,215 [main] INFO  org.apache.pig.Main - Logging error messages to: /workdir/pig_1539184603214.log
  2018-10-10 15:16:43,235 [main] INFO  org.apache.pig.impl.util.Utils - Default bootup file /home/test23/.pigbootup not found
  2018-10-10 15:16:43,790 [main] INFO  org.apache.hadoop.conf.Configuration.deprecation - mapred.job.tracker is deprecated. Instead, use mapreduce.jobtracker.address
  2018-10-10 15:16:43,791 [main] INFO  org.apache.hadoop.conf.Configuration.deprecation - fs.default.name is deprecated. Instead, use fs.defaultFS
  2018-10-10 15:16:43,791 [main] INFO  org.apache.pig.backend.hadoop.executionengine.HExecutionEngine - Connecting to hadoop file system at: hdfs://master.edincubator.eu:8020
  2018-10-10 15:16:44,563 [main] INFO  org.apache.pig.PigServer - Pig Script ID for the session: PIG-default-31e0e22b-9d25-423f-adda-0e3e0ebda301
  2018-10-10 15:16:44,994 [main] INFO  org.apache.hadoop.yarn.client.api.impl.TimelineClientImpl - Timeline service address: http://master.edincubator.eu:8188/ws/v1/timeline/
  2018-10-10 15:16:45,855 [main] INFO  org.apache.pig.backend.hadoop.PigATSClient - Created ATS Hook
  2018-10-10 15:16:45,885 [main] INFO  org.apache.hadoop.conf.Configuration.deprecation - fs.default.name is deprecated. Instead, use fs.defaultFS
  grunt>

Next, we can load and operate over sample data:

.. code-block:: console

  grunt> REGISTER /opt/pig/lib/piggybank.jar
  grunt> define CSVLoader org.apache.pig.piggybank.storage.CSVLoader();


.. code-block:: console

    grunt> yelp_business = LOAD '/samples/yelp/yelp_business/yelp_business.csv' using CSVLoader AS (
      business_id:chararray,
      name:chararray,
      neighborhood:chararray,
      address:chararray,
      city:chararray,
      state:chararray,
      postal_code:int,
      latitude:double,
      longitude:double,
      stars:float,
      review_count:int,
      is_open:boolean,
      categories:chararray
    );

.. code-block:: console

  grunt> grouped_business = GROUP yelp_business BY state;

.. code-block:: console

  grunt> DESCRIBE grouped_business;

  grouped_business: {group: chararray,yelp_business: {(business_id: chararray,name: chararray,neighborhood: chararray,address: chararray,city: chararray,state: chararray,postal_code: int,latitude: double,longitude: double,stars: float,review_count: int,is_open: boolean,categories: chararray)}}

.. code-block:: console

  grunt> counted_business = FOREACH grouped_business GENERATE group, COUNT(yelp_business);

The code above is very intuitive. First, we load the
`Pig Piggybank <https://cwiki.apache.org/confluence/display/PIG/PiggyBank>`_.
Piggybank is a collection of functions developed by the Pig community
implementing a sort of very useful functions and tools. We define the
`CSVLoader` function from the Piggybank, and we use it for loading our sample
CSV file.

Next, we group data by `state` column. `DESCRIBE` command describes the structure
of an identifier. In this case, we can see that the identifier `grouped_business`
is a `bag` in which each element is formed by a `charrarray` called `group` and
a `bag` called `yelp_business`. `group` refers to the state and `yelp_business`
to each business belonging to this state. At last, we count how many businesses
are in `yelp_business` bag in each `group` (state).

.. warning::

  Another useful Pig command for inspecting data  is `ILLUSTRATE`. As in EDI
  Big Data Stack Pig is executed over Tez, and Tez doesn't support ILLUSTRATE
  command, it doesn't work in EDI's environment.

Next, we can dump the result into the shell.

.. code-block:: console

  grunt> DUMP counted_business;
  2018-04-24 15:19:46,891 [main] INFO  org.apache.hadoop.hdfs.DFSClient - Created HDFS_DELEGATION_TOKEN token 600 for <username> on 192.168.125.113:8020
  2018-04-24 15:19:47,000 [main] INFO  org.apache.hadoop.mapreduce.security.TokenCache - Got dt for hdfs://master.edincubator.eu:8020; Kind: HDFS_DELEGATION_TOKEN, Service: 192.168.125.113:8020, Ident: (HDFS_DELEGATION_TOKEN token 600 for <username>)
  2018-04-24 15:19:47,000 [main] INFO  org.apache.hadoop.mapreduce.security.TokenCache - Got dt for hdfs://master.edincubator.eu:8020; Kind: kms-dt, Service: 192.168.125.113:9292, Ident: (owner=<username>, renewer=yarn, realUser=, issueDate=1524583186940, maxDate=1525187986940, sequenceNumber=272, masterKeyId=62)
  2018-04-24 15:19:47,006 [main] INFO  org.apache.pig.tools.pigstats.ScriptState - Pig features used in the script: GROUP_BY
  2018-04-24 15:19:47,055 [main] INFO  org.apache.hadoop.conf.Configuration.deprecation - fs.default.name is deprecated. Instead, use fs.defaultFS
  2018-04-24 15:19:47,059 [main] INFO  org.apache.pig.data.SchemaTupleBackend - Key [pig.schematuple] was not set... will not generate code.
  2018-04-24 15:19:47,110 [main] INFO  org.apache.pig.newplan.logical.optimizer.LogicalPlanOptimizer - {RULES_ENABLED=[AddForEach, ColumnMapKeyPrune, ConstantCalculator, GroupByConstParallelSetter, LimitOptimizer, LoadTypeCastInserter, MergeFilter, MergeForEach, PartitionFilterOptimizer, PredicatePushdownOptimizer, PushDownForEachFlatten, PushUpFilter, SplitFilter, StreamTypeCastInserter]}
  2018-04-24 15:19:47,314 [main] INFO  org.apache.pig.impl.util.SpillableMemoryManager - Selected heap (PS Old Gen) of size 699400192 to monitor. collectionUsageThreshold = 489580128, usageThreshold = 489580128
  2018-04-24 15:19:47,421 [main] INFO  org.apache.hadoop.conf.Configuration.deprecation - fs.default.name is deprecated. Instead, use fs.defaultFS
  2018-04-24 15:19:47,435 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezLauncher - Tez staging directory is /tmp/root/staging and resources directory is /tmp/temp1168673119
  2018-04-24 15:19:47,502 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.plan.TezCompiler - File concatenation threshold: 100 optimistic? false
  2018-04-24 15:19:47,551 [main] INFO  org.apache.pig.backend.hadoop.executionengine.util.CombinerOptimizerUtil - Choosing to move algebraic foreach to combiner
  2018-04-24 15:19:47,616 [main] INFO  org.apache.hadoop.conf.Configuration.deprecation - mapreduce.inputformat.class is deprecated. Instead, use mapreduce.job.inputformat.class
  2018-04-24 15:19:47,686 [main] INFO  org.apache.hadoop.hdfs.DFSClient - Created HDFS_DELEGATION_TOKEN token 601 for <username> on 192.168.125.113:8020
  2018-04-24 15:19:47,712 [main] INFO  org.apache.hadoop.mapreduce.security.TokenCache - Got dt for hdfs://master.edincubator.eu:8020; Kind: HDFS_DELEGATION_TOKEN, Service: 192.168.125.113:8020, Ident: (HDFS_DELEGATION_TOKEN token 601 for <username>)
  2018-04-24 15:19:47,712 [main] INFO  org.apache.hadoop.mapreduce.security.TokenCache - Got dt for hdfs://master.edincubator.eu:8020; Kind: kms-dt, Service: 192.168.125.113:9292, Ident: (owner=<username>, renewer=yarn, realUser=, issueDate=1524583187706, maxDate=1525187987706, sequenceNumber=273, masterKeyId=62)
  2018-04-24 15:19:47,716 [main] INFO  org.apache.hadoop.mapreduce.lib.input.FileInputFormat - Total input paths to process : 1
  2018-04-24 15:19:47,717 [main] INFO  org.apache.pig.backend.hadoop.executionengine.util.MapRedUtil - Total input paths to process : 1
  2018-04-24 15:19:47,784 [main] INFO  org.apache.pig.backend.hadoop.executionengine.util.MapRedUtil - Total input paths (combined) to process : 1
  2018-04-24 15:19:48,351 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezJobCompiler - Local resource: joda-time-2.9.4.jar
  2018-04-24 15:19:48,351 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezJobCompiler - Local resource: pig-0.16.0.2.6.4.0-91-core-h2.jar
  2018-04-24 15:19:48,351 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezJobCompiler - Local resource: antlr-runtime-3.4.jar
  2018-04-24 15:19:48,351 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezJobCompiler - Local resource: automaton-1.11-8.jar
  2018-04-24 15:19:48,351 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezJobCompiler - Local resource: piggybank.jar
  2018-04-24 15:19:48,411 [main] INFO  org.apache.hadoop.conf.Configuration.deprecation - fs.default.name is deprecated. Instead, use fs.defaultFS
  2018-04-24 15:19:48,423 [main] INFO  org.apache.hadoop.conf.Configuration.deprecation - mapred.output.compress is deprecated. Instead, use mapreduce.output.fileoutputformat.compress
  2018-04-24 15:19:48,480 [main] INFO  org.apache.hadoop.conf.Configuration.deprecation - mapred.task.id is deprecated. Instead, use mapreduce.task.attempt.id
  2018-04-24 15:19:48,658 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezDagBuilder - For vertex - scope-52: parallelism=1, memory=1024, java opts=-XX:+PrintGCDetails -verbose:gc -XX:+PrintGCTimeStamps -XX:+UseNUMA -XX:+UseG1GC -XX:+ResizeTLAB
  2018-04-24 15:19:48,658 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezDagBuilder - Processing aliases: counted_business,grouped_business,yelp_business
  2018-04-24 15:19:48,658 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezDagBuilder - Detailed locations: yelp_business[2,16],yelp_business[-1,-1],counted_business[17,19],grouped_business[16,19]
  2018-04-24 15:19:48,658 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezDagBuilder - Pig features in the vertex:
  2018-04-24 15:19:48,797 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezDagBuilder - Set auto parallelism for vertex scope-53
  2018-04-24 15:19:48,797 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezDagBuilder - For vertex - scope-53: parallelism=1, memory=1024, java opts=-XX:+PrintGCDetails -verbose:gc -XX:+PrintGCTimeStamps -XX:+UseNUMA -XX:+UseG1GC -XX:+ResizeTLAB
  2018-04-24 15:19:48,797 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezDagBuilder - Processing aliases: counted_business
  2018-04-24 15:19:48,797 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezDagBuilder - Detailed locations: counted_business[17,19]
  2018-04-24 15:19:48,797 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezDagBuilder - Pig features in the vertex: GROUP_BY
  2018-04-24 15:19:48,926 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezJobCompiler - Total estimated parallelism is 2
  2018-04-24 15:19:49,057 [PigTezLauncher-0] INFO  org.apache.pig.tools.pigstats.tez.TezScriptState - Pig script settings are added to the job
  2018-04-24 15:19:49,083 [PigTezLauncher-0] INFO  org.apache.tez.client.TezClient - Tez Client Version: [ component=tez-api, version=0.7.0.2.6.4.0-91, revision=0daef967e122a98f83b824f3b14991e792f5dd4d, SCM-URL=scm:git:https://git-wip-us.apache.org/repos/asf/tez.git, buildTime=2018-01-04T09:08:42Z ]
  2018-04-24 15:19:49,155 [PigTezLauncher-0] INFO  org.apache.hadoop.yarn.client.RMProxy - Connecting to ResourceManager at master.edincubator.eu/192.168.125.113:8050
  2018-04-24 15:19:49,345 [PigTezLauncher-0] INFO  org.apache.hadoop.yarn.client.AHSProxy - Connecting to Application History server at master.edincubator.eu/192.168.125.113:10200
  2018-04-24 15:19:49,351 [PigTezLauncher-0] INFO  org.apache.tez.client.TezClient - Session mode. Starting session.
  2018-04-24 15:19:49,356 [PigTezLauncher-0] INFO  org.apache.tez.client.TezClientUtils - Using tez.lib.uris value from configuration: /hdp/apps/2.6.4.0-91/tez/tez.tar.gz
  2018-04-24 15:19:49,377 [PigTezLauncher-0] INFO  org.apache.hadoop.hdfs.DFSClient - Created HDFS_DELEGATION_TOKEN token 602 for <username> on 192.168.125.113:8020
  2018-04-24 15:19:49,411 [PigTezLauncher-0] INFO  org.apache.tez.common.security.TokenCache - Got dt for hdfs://master.edincubator.eu:8020; Kind: HDFS_DELEGATION_TOKEN, Service: 192.168.125.113:8020, Ident: (HDFS_DELEGATION_TOKEN token 602 for <username>)
  2018-04-24 15:19:49,412 [PigTezLauncher-0] INFO  org.apache.tez.common.security.TokenCache - Got dt for hdfs://master.edincubator.eu:8020; Kind: kms-dt, Service: 192.168.125.113:9292, Ident: (owner=<username>, renewer=yarn, realUser=, issueDate=1524583189407, maxDate=1525187989407, sequenceNumber=274, masterKeyId=62)
  2018-04-24 15:19:49,466 [PigTezLauncher-0] INFO  org.apache.tez.client.TezClient - Tez system stage directory hdfs://master.edincubator.eu:8020/tmp/root/staging/.tez/application_1523347765873_0043 doesn't exist and is created
  2018-04-24 15:19:49,473 [PigTezLauncher-0] INFO  org.apache.hadoop.conf.Configuration.deprecation - fs.default.name is deprecated. Instead, use fs.defaultFS
  2018-04-24 15:19:49,748 [PigTezLauncher-0] INFO  org.apache.hadoop.yarn.client.api.impl.TimelineClientImpl - Timeline service address: http://master.edincubator.eu:8188/ws/v1/timeline/
  2018-04-24 15:19:50,312 [PigTezLauncher-0] INFO  org.apache.hadoop.yarn.client.api.impl.YarnClientImpl - Submitted application application_1523347765873_0043
  2018-04-24 15:19:50,315 [PigTezLauncher-0] INFO  org.apache.tez.client.TezClient - The url to track the Tez Session: http://master.edincubator.eu:8088/proxy/application_1523347765873_0043/
  2018-04-24 15:19:59,550 [PigTezLauncher-0] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezJob - Submitting DAG PigLatin:DefaultJobName-0_scope-0
  2018-04-24 15:19:59,550 [PigTezLauncher-0] INFO  org.apache.tez.client.TezClient - Submitting dag to TezSession, sessionName=PigLatin:DefaultJobName, applicationId=application_1523347765873_0043, dagName=PigLatin:DefaultJobName-0_scope-0, callerContext={ context=PIG, callerType=PIG_SCRIPT_ID, callerId=PIG-default-6eddcb9e-3548-4424-8d82-ee8ad63e9b61 }
  2018-04-24 15:20:00,156 [PigTezLauncher-0] INFO  org.apache.tez.client.TezClient - Submitted dag to TezSession, sessionName=PigLatin:DefaultJobName, applicationId=application_1523347765873_0043, dagName=PigLatin:DefaultJobName-0_scope-0
  2018-04-24 15:20:00,258 [PigTezLauncher-0] INFO  org.apache.hadoop.yarn.client.RMProxy - Connecting to ResourceManager at master.edincubator.eu/192.168.125.113:8050
  2018-04-24 15:20:00,259 [PigTezLauncher-0] INFO  org.apache.hadoop.yarn.client.AHSProxy - Connecting to Application History server at master.edincubator.eu/192.168.125.113:10200
  2018-04-24 15:20:00,262 [PigTezLauncher-0] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezJob - Submitted DAG PigLatin:DefaultJobName-0_scope-0. Application id: application_1523347765873_0043
  2018-04-24 15:20:00,987 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezLauncher - HadoopJobId: job_1523347765873_0043
  2018-04-24 15:20:01,264 [Timer-0] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezJob - DAG Status: status=RUNNING, progress=TotalTasks: 2 Succeeded: 0 Running: 0 Failed: 0 Killed: 0, diagnostics=, counters=null
  2018-04-24 15:20:13,509 [PigTezLauncher-0] INFO  org.apache.tez.common.counters.Limits - Counter limits initialized with parameters:  GROUP_NAME_MAX=256, MAX_GROUPS=3000, COUNTER_NAME_MAX=64, MAX_COUNTERS=10000
  2018-04-24 15:20:13,516 [PigTezLauncher-0] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezJob - DAG Status: status=SUCCEEDED, progress=TotalTasks: 2 Succeeded: 2 Running: 0 Failed: 0 Killed: 0, diagnostics=, counters=Counters: 102
  	org.apache.tez.common.counters.DAGCounter
  		NUM_SUCCEEDED_TASKS=2
  		TOTAL_LAUNCHED_TASKS=2
  		DATA_LOCAL_TASKS=1
  		AM_CPU_MILLISECONDS=3050
  		AM_GC_TIME_MILLIS=0
  	File System Counters
  		FILE_BYTES_READ=709
  		FILE_BYTES_WRITTEN=677
  		HDFS_BYTES_READ=31760674
  		HDFS_BYTES_WRITTEN=772
  		HDFS_READ_OPS=4
  		HDFS_WRITE_OPS=2
  		HDFS_OP_CREATE=1
  		HDFS_OP_GET_FILE_STATUS=3
  		HDFS_OP_OPEN=1
  		HDFS_OP_RENAME=1
  	org.apache.tez.common.counters.TaskCounter
  		REDUCE_INPUT_GROUPS=69
  		REDUCE_INPUT_RECORDS=69
  		COMBINE_INPUT_RECORDS=0
  		SPILLED_RECORDS=138
  		NUM_SHUFFLED_INPUTS=1
  		NUM_SKIPPED_INPUTS=0
  		NUM_FAILED_SHUFFLE_INPUTS=0
  		MERGED_MAP_OUTPUTS=1
  		GC_TIME_MILLIS=186
  		CPU_MILLISECONDS=15810
  		PHYSICAL_MEMORY_BYTES=828375040
  		VIRTUAL_MEMORY_BYTES=5508820992
  		COMMITTED_HEAP_BYTES=828375040
  		INPUT_RECORDS_PROCESSED=174568
  		INPUT_SPLIT_LENGTH_BYTES=31760674
  		OUTPUT_RECORDS=174637
  		OUTPUT_BYTES=1750337
  		OUTPUT_BYTES_WITH_OVERHEAD=916
  		OUTPUT_BYTES_PHYSICAL=645
  		ADDITIONAL_SPILLS_BYTES_WRITTEN=0
  		ADDITIONAL_SPILLS_BYTES_READ=645
  		ADDITIONAL_SPILL_COUNT=0
  		SHUFFLE_CHUNK_COUNT=1
  		SHUFFLE_BYTES=645
  		SHUFFLE_BYTES_DECOMPRESSED=916
  		SHUFFLE_BYTES_TO_MEM=0
  		SHUFFLE_BYTES_TO_DISK=0
  		SHUFFLE_BYTES_DISK_DIRECT=645
  		NUM_MEM_TO_DISK_MERGES=0
  		NUM_DISK_TO_DISK_MERGES=0
  		SHUFFLE_PHASE_TIME=33
  		MERGE_PHASE_TIME=51
  		FIRST_EVENT_RECEIVED=24
  		LAST_EVENT_RECEIVED=24
  	MultiStoreCounters
  		Output records in _0_tmp-1627710868=69
  	Shuffle Errors
  		BAD_ID=0
  		CONNECTION=0
  		IO_ERROR=0
  		WRONG_LENGTH=0
  		WRONG_MAP=0
  		WRONG_REDUCE=0
  	Shuffle Errors_scope_53_INPUT_scope_52
  		BAD_ID=0
  		CONNECTION=0
  		IO_ERROR=0
  		WRONG_LENGTH=0
  		WRONG_MAP=0
  		WRONG_REDUCE=0
  	TaskCounter_scope_52_INPUT_scope_0
  		INPUT_RECORDS_PROCESSED=174568
  		INPUT_SPLIT_LENGTH_BYTES=31760674
  	TaskCounter_scope_52_OUTPUT_scope_53
  		ADDITIONAL_SPILLS_BYTES_READ=0
  		ADDITIONAL_SPILLS_BYTES_WRITTEN=0
  		ADDITIONAL_SPILL_COUNT=0
  		OUTPUT_BYTES=1750337
  		OUTPUT_BYTES_PHYSICAL=645
  		OUTPUT_BYTES_WITH_OVERHEAD=916
  		OUTPUT_RECORDS=174568
  		SHUFFLE_CHUNK_COUNT=1
  		SPILLED_RECORDS=69
  	TaskCounter_scope_53_INPUT_scope_52
  		ADDITIONAL_SPILLS_BYTES_READ=645
  		ADDITIONAL_SPILLS_BYTES_WRITTEN=0
  		COMBINE_INPUT_RECORDS=0
  		FIRST_EVENT_RECEIVED=24
  		LAST_EVENT_RECEIVED=24
  		MERGED_MAP_OUTPUTS=1
  		MERGE_PHASE_TIME=51
  		NUM_DISK_TO_DISK_MERGES=0
  		NUM_FAILED_SHUFFLE_INPUTS=0
  		NUM_MEM_TO_DISK_MERGES=0
  		NUM_SHUFFLED_INPUTS=1
  		NUM_SKIPPED_INPUTS=0
  		REDUCE_INPUT_GROUPS=69
  		REDUCE_INPUT_RECORDS=69
  		SHUFFLE_BYTES=645
  		SHUFFLE_BYTES_DECOMPRESSED=916
  		SHUFFLE_BYTES_DISK_DIRECT=645
  		SHUFFLE_BYTES_TO_DISK=0
  		SHUFFLE_BYTES_TO_MEM=0
  		SHUFFLE_PHASE_TIME=33
  		SPILLED_RECORDS=69
  	TaskCounter_scope_53_OUTPUT_scope_51
  		OUTPUT_RECORDS=69
  	org.apache.hadoop.mapreduce.TaskCounter
  		COMBINE_INPUT_RECORDS=69
  		COMBINE_OUTPUT_RECORDS=174568
  	org.apache.hadoop.mapreduce.TaskCounter_scope_52_OUTPUT_scope_53
  		COMBINE_INPUT_RECORDS=69
  		COMBINE_OUTPUT_RECORDS=174568
  	org.apache.hadoop.mapreduce.TaskCounter_scope_53_INPUT_scope_52
  		COMBINE_INPUT_RECORDS=0
  		COMBINE_OUTPUT_RECORDS=0
  	org.apache.pig.PigWarning
  		FIELD_DISCARDED_TYPE_CONVERSION_FAILED=42888
  2018-04-24 15:20:13,552 [PigTezLauncher-0] INFO  org.apache.hadoop.conf.Configuration.deprecation - fs.default.name is deprecated. Instead, use fs.defaultFS
  2018-04-24 15:20:13,992 [main] WARN  org.apache.pig.backend.hadoop.executionengine.tez.TezLauncher - Encountered Warning FIELD_DISCARDED_TYPE_CONVERSION_FAILED 42888 time(s).
  2018-04-24 15:20:13,998 [main] INFO  org.apache.pig.tools.pigstats.tez.TezPigScriptStats - Script Statistics:

         HadoopVersion: 2.7.3.2.6.4.0-91
            PigVersion: 0.16.0.2.6.4.0-91
            TezVersion: 0.7.0.2.6.4.0-91
                UserId: root
              FileName:
             StartedAt: 2018-04-24 15:19:47
            FinishedAt: 2018-04-24 15:20:13
              Features: GROUP_BY

  Success!


  DAG 0:
                                      Name: PigLatin:DefaultJobName-0_scope-0
                             ApplicationId: job_1523347765873_0043
                        TotalLaunchedTasks: 2
                             FileBytesRead: 709
                          FileBytesWritten: 677
                             HdfsBytesRead: 31760674
                          HdfsBytesWritten: 772
        SpillableMemoryManager spill count: 0
                  Bags proactively spilled: 0
               Records proactively spilled: 0

  DAG Plan:
  Tez vertex scope-52	->	Tez vertex scope-53,
  Tez vertex scope-53

  Vertex Stats:
  VertexId Parallelism TotalTasks   InputRecords   ReduceInputRecords  OutputRecords  FileBytesRead FileBytesWritten  HdfsBytesRead HdfsBytesWritten Alias	Feature	Outputs
  scope-52           1          1         174568                    0         174568             32              677       31760674                0 counted_business,grouped_business,yelp_business
  scope-53           1          1              0                   69             69            677                0              0              772 counted_business	GROUP_BY	hdfs://master.edincubator.eu:8020/tmp/temp-735280935/tmp-1627710868,

  Input(s):
  Successfully read 174568 records (31760674 bytes) from: "/user/<username>/samples/yelp_business.csv"

  Output(s):
  Successfully stored 69 records (772 bytes) in: "hdfs://master.edincubator.eu:8020/tmp/temp-735280935/tmp-1627710868"

  2018-04-24 15:20:14,010 [main] INFO  org.apache.hadoop.hdfs.DFSClient - Created HDFS_DELEGATION_TOKEN token 603 for <username> on 192.168.125.113:8020
  2018-04-24 15:20:14,033 [main] INFO  org.apache.hadoop.mapreduce.security.TokenCache - Got dt for hdfs://master.edincubator.eu:8020; Kind: HDFS_DELEGATION_TOKEN, Service: 192.168.125.113:8020, Ident: (HDFS_DELEGATION_TOKEN token 603 for <username>)
  2018-04-24 15:20:14,034 [main] INFO  org.apache.hadoop.mapreduce.security.TokenCache - Got dt for hdfs://master.edincubator.eu:8020; Kind: kms-dt, Service: 192.168.125.113:9292, Ident: (owner=<username>, renewer=yarn, realUser=, issueDate=1524583214028, maxDate=1525188014028, sequenceNumber=275, masterKeyId=62)
  2018-04-24 15:20:14,047 [main] INFO  org.apache.hadoop.mapreduce.lib.input.FileInputFormat - Total input paths to process : 1
  2018-04-24 15:20:14,047 [main] INFO  org.apache.pig.backend.hadoop.executionengine.util.MapRedUtil - Total input paths to process : 1
  (,1)
  (3,1)
  (6,3)
  (B,1)
  (C,28)
  (01,10)
  (30,1)
  (AB,1)
  (AK,1)
  (AL,1)
  (AR,2)
  (AZ,52214)
  (BW,3118)
  (BY,4)
  (CA,5)
  (CO,2)
  (CS,1)
  (DE,1)
  (FL,1)
  (GA,1)
  (HU,1)
  (IL,1852)
  (IN,3)
  (KY,1)
  (MN,1)
  (MT,1)
  (NC,12956)
  (NE,1)
  (NI,10)
  (NV,33086)
  (NY,18)
  (OH,12609)
  (ON,30208)
  (PA,10109)
  (QC,8169)
  (SC,679)
  (SL,1)
  (ST,11)
  (VA,1)
  (VS,7)
  (VT,2)
  (WA,1)
  (WI,4754)
  (ABE,3)
  (CHE,143)
  (CMA,2)
  (EDH,3795)
  (ELN,47)
  (ESX,12)
  (FAL,1)
  (FIF,85)
  (FLN,2)
  (GLG,3)
  (HLD,179)
  (KHL,1)
  (MLN,208)
  (NLK,1)
  (NTH,2)
  (NYK,152)
  (PKN,1)
  (RCC,1)
  (SCB,5)
  (STG,1)
  (TAM,1)
  (WHT,1)
  (WLN,38)
  (XGL,4)
  (ZET,1)
  (state,1)
  grunt>

Obtained output is the same than one obtained in previous examples. Finally, we
can store this output into HDFS as a CSV file:

.. code-block:: console

  grunt> STORE counted_business INTO '/user/<username>/pig-output' USING PigStorage(',');
  2018-04-24 15:44:10,488 [main] INFO  org.apache.hadoop.conf.Configuration.deprecation - fs.default.name is deprecated. Instead, use fs.defaultFS
  2018-04-24 15:44:10,500 [main] INFO  org.apache.hadoop.conf.Configuration.deprecation - mapred.textoutputformat.separator is deprecated. Instead, use mapreduce.output.textoutputformat.separator
  2018-04-24 15:44:10,504 [main] INFO  org.apache.hadoop.hdfs.DFSClient - Created HDFS_DELEGATION_TOKEN token 604 for <username> on 192.168.125.113:8020
  2018-04-24 15:44:10,765 [main] INFO  org.apache.hadoop.mapreduce.security.TokenCache - Got dt for hdfs://master.edincubator.eu:8020; Kind: HDFS_DELEGATION_TOKEN, Service: 192.168.125.113:8020, Ident: (HDFS_DELEGATION_TOKEN token 604 for <username>)
  2018-04-24 15:44:10,765 [main] INFO  org.apache.hadoop.mapreduce.security.TokenCache - Got dt for hdfs://master.edincubator.eu:8020; Kind: kms-dt, Service: 192.168.125.113:9292, Ident: (owner=<username>, renewer=yarn, realUser=, issueDate=1524584650761, maxDate=1525189450761, sequenceNumber=276, masterKeyId=62)
  2018-04-24 15:44:10,809 [main] INFO  org.apache.pig.tools.pigstats.ScriptState - Pig features used in the script: GROUP_BY
  2018-04-24 15:44:10,842 [main] INFO  org.apache.hadoop.conf.Configuration.deprecation - fs.default.name is deprecated. Instead, use fs.defaultFS
  2018-04-24 15:44:10,843 [main] INFO  org.apache.pig.data.SchemaTupleBackend - Key [pig.schematuple] was not set... will not generate code.
  2018-04-24 15:44:10,844 [main] INFO  org.apache.pig.newplan.logical.optimizer.LogicalPlanOptimizer - {RULES_ENABLED=[AddForEach, ColumnMapKeyPrune, ConstantCalculator, GroupByConstParallelSetter, LimitOptimizer, LoadTypeCastInserter, MergeFilter, MergeForEach, PartitionFilterOptimizer, PredicatePushdownOptimizer, PushDownForEachFlatten, PushUpFilter, SplitFilter, StreamTypeCastInserter]}
  2018-04-24 15:44:10,882 [main] INFO  org.apache.hadoop.conf.Configuration.deprecation - fs.default.name is deprecated. Instead, use fs.defaultFS
  2018-04-24 15:44:10,883 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezLauncher - Tez staging directory is /tmp/root/staging and resources directory is /tmp/temp1168673119
  2018-04-24 15:44:10,884 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.plan.TezCompiler - File concatenation threshold: 100 optimistic? false
  2018-04-24 15:44:10,887 [main] INFO  org.apache.pig.backend.hadoop.executionengine.util.CombinerOptimizerUtil - Choosing to move algebraic foreach to combiner
  2018-04-24 15:44:10,910 [main] INFO  org.apache.hadoop.hdfs.DFSClient - Created HDFS_DELEGATION_TOKEN token 605 for <username> on 192.168.125.113:8020
  2018-04-24 15:44:10,933 [main] INFO  org.apache.hadoop.mapreduce.security.TokenCache - Got dt for hdfs://master.edincubator.eu:8020; Kind: HDFS_DELEGATION_TOKEN, Service: 192.168.125.113:8020, Ident: (HDFS_DELEGATION_TOKEN token 605 for <username>)
  2018-04-24 15:44:10,933 [main] INFO  org.apache.hadoop.mapreduce.security.TokenCache - Got dt for hdfs://master.edincubator.eu:8020; Kind: kms-dt, Service: 192.168.125.113:9292, Ident: (owner=<username>, renewer=yarn, realUser=, issueDate=1524584650929, maxDate=1525189450929, sequenceNumber=277, masterKeyId=62)
  2018-04-24 15:44:10,935 [main] INFO  org.apache.hadoop.mapreduce.lib.input.FileInputFormat - Total input paths to process : 1
  2018-04-24 15:44:10,935 [main] INFO  org.apache.pig.backend.hadoop.executionengine.util.MapRedUtil - Total input paths to process : 1
  2018-04-24 15:44:10,938 [main] INFO  org.apache.pig.backend.hadoop.executionengine.util.MapRedUtil - Total input paths (combined) to process : 1
  2018-04-24 15:44:10,952 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezJobCompiler - Local resource: joda-time-2.9.4.jar
  2018-04-24 15:44:10,952 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezJobCompiler - Local resource: pig-0.16.0.2.6.4.0-91-core-h2.jar
  2018-04-24 15:44:10,952 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezJobCompiler - Local resource: antlr-runtime-3.4.jar
  2018-04-24 15:44:10,952 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezJobCompiler - Local resource: automaton-1.11-8.jar
  2018-04-24 15:44:10,952 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezJobCompiler - Local resource: piggybank.jar
  2018-04-24 15:44:10,988 [main] INFO  org.apache.hadoop.conf.Configuration.deprecation - fs.default.name is deprecated. Instead, use fs.defaultFS
  2018-04-24 15:44:11,040 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezDagBuilder - For vertex - scope-124: parallelism=1, memory=1024, java opts=-XX:+PrintGCDetails -verbose:gc -XX:+PrintGCTimeStamps -XX:+UseNUMA -XX:+UseG1GC -XX:+ResizeTLAB
  2018-04-24 15:44:11,040 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezDagBuilder - Processing aliases: counted_business,grouped_business,yelp_business
  2018-04-24 15:44:11,040 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezDagBuilder - Detailed locations: yelp_business[2,16],yelp_business[-1,-1],counted_business[17,19],grouped_business[16,19]
  2018-04-24 15:44:11,040 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezDagBuilder - Pig features in the vertex:
  2018-04-24 15:44:11,089 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezDagBuilder - Set auto parallelism for vertex scope-125
  2018-04-24 15:44:11,089 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezDagBuilder - For vertex - scope-125: parallelism=1, memory=1024, java opts=-XX:+PrintGCDetails -verbose:gc -XX:+PrintGCTimeStamps -XX:+UseNUMA -XX:+UseG1GC -XX:+ResizeTLAB
  2018-04-24 15:44:11,089 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezDagBuilder - Processing aliases: counted_business
  2018-04-24 15:44:11,089 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezDagBuilder - Detailed locations: counted_business[17,19]
  2018-04-24 15:44:11,089 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezDagBuilder - Pig features in the vertex: GROUP_BY
  2018-04-24 15:44:11,135 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezJobCompiler - Total estimated parallelism is 2
  2018-04-24 15:44:11,235 [PigTezLauncher-0] INFO  org.apache.pig.tools.pigstats.tez.TezScriptState - Pig script settings are added to the job
  2018-04-24 15:44:11,237 [PigTezLauncher-0] INFO  org.apache.tez.client.TezClient - Tez Client Version: [ component=tez-api, version=0.7.0.2.6.4.0-91, revision=0daef967e122a98f83b824f3b14991e792f5dd4d, SCM-URL=scm:git:https://git-wip-us.apache.org/repos/asf/tez.git, buildTime=2018-01-04T09:08:42Z ]
  2018-04-24 15:44:11,277 [PigTezLauncher-0] INFO  org.apache.hadoop.yarn.client.RMProxy - Connecting to ResourceManager at master.edincubator.eu/192.168.125.113:8050
  2018-04-24 15:44:11,278 [PigTezLauncher-0] INFO  org.apache.hadoop.yarn.client.AHSProxy - Connecting to Application History server at master.edincubator.eu/192.168.125.113:10200
  2018-04-24 15:44:11,279 [PigTezLauncher-0] INFO  org.apache.tez.client.TezClient - Session mode. Starting session.
  2018-04-24 15:44:11,279 [PigTezLauncher-0] INFO  org.apache.tez.client.TezClientUtils - Using tez.lib.uris value from configuration: /hdp/apps/2.6.4.0-91/tez/tez.tar.gz
  2018-04-24 15:44:11,289 [PigTezLauncher-0] INFO  org.apache.hadoop.hdfs.DFSClient - Created HDFS_DELEGATION_TOKEN token 606 for <username> on 192.168.125.113:8020
  2018-04-24 15:44:11,323 [PigTezLauncher-0] INFO  org.apache.tez.common.security.TokenCache - Got dt for hdfs://master.edincubator.eu:8020; Kind: HDFS_DELEGATION_TOKEN, Service: 192.168.125.113:8020, Ident: (HDFS_DELEGATION_TOKEN token 606 for <username>)
  2018-04-24 15:44:11,323 [PigTezLauncher-0] INFO  org.apache.tez.common.security.TokenCache - Got dt for hdfs://master.edincubator.eu:8020; Kind: kms-dt, Service: 192.168.125.113:9292, Ident: (owner=<username>, renewer=yarn, realUser=, issueDate=1524584651318, maxDate=1525189451318, sequenceNumber=278, masterKeyId=62)
  2018-04-24 15:44:11,335 [PigTezLauncher-0] INFO  org.apache.tez.client.TezClient - Tez system stage directory hdfs://master.edincubator.eu:8020/tmp/root/staging/.tez/application_1523347765873_0044 doesn't exist and is created
  2018-04-24 15:44:11,339 [PigTezLauncher-0] INFO  org.apache.hadoop.conf.Configuration.deprecation - fs.default.name is deprecated. Instead, use fs.defaultFS
  2018-04-24 15:44:11,555 [PigTezLauncher-0] INFO  org.apache.hadoop.yarn.client.api.impl.TimelineClientImpl - Timeline service address: http://master.edincubator.eu:8188/ws/v1/timeline/
  2018-04-24 15:44:11,872 [PigTezLauncher-0] INFO  org.apache.hadoop.yarn.client.api.impl.YarnClientImpl - Submitted application application_1523347765873_0044
  2018-04-24 15:44:11,874 [PigTezLauncher-0] INFO  org.apache.tez.client.TezClient - The url to track the Tez Session: http://master.edincubator.eu:8088/proxy/application_1523347765873_0044/
  2018-04-24 15:44:20,548 [PigTezLauncher-0] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezJob - Submitting DAG PigLatin:DefaultJobName-0_scope-2
  2018-04-24 15:44:20,548 [PigTezLauncher-0] INFO  org.apache.tez.client.TezClient - Submitting dag to TezSession, sessionName=PigLatin:DefaultJobName, applicationId=application_1523347765873_0044, dagName=PigLatin:DefaultJobName-0_scope-2, callerContext={ context=PIG, callerType=PIG_SCRIPT_ID, callerId=PIG-default-6eddcb9e-3548-4424-8d82-ee8ad63e9b61 }
  2018-04-24 15:44:21,111 [PigTezLauncher-0] INFO  org.apache.tez.client.TezClient - Submitted dag to TezSession, sessionName=PigLatin:DefaultJobName, applicationId=application_1523347765873_0044, dagName=PigLatin:DefaultJobName-0_scope-2
  2018-04-24 15:44:21,195 [PigTezLauncher-0] INFO  org.apache.hadoop.yarn.client.RMProxy - Connecting to ResourceManager at master.edincubator.eu/192.168.125.113:8050
  2018-04-24 15:44:21,198 [PigTezLauncher-0] INFO  org.apache.hadoop.yarn.client.AHSProxy - Connecting to Application History server at master.edincubator.eu/192.168.125.113:10200
  2018-04-24 15:44:21,198 [PigTezLauncher-0] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezJob - Submitted DAG PigLatin:DefaultJobName-0_scope-2. Application id: application_1523347765873_0044
  2018-04-24 15:44:22,179 [main] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezLauncher - HadoopJobId: job_1523347765873_0044
  2018-04-24 15:44:22,199 [Timer-1] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezJob - DAG Status: status=RUNNING, progress=TotalTasks: 2 Succeeded: 0 Running: 0 Failed: 0 Killed: 0, diagnostics=, counters=null
  2018-04-24 15:44:31,496 [PigTezLauncher-0] INFO  org.apache.pig.backend.hadoop.executionengine.tez.TezJob - DAG Status: status=SUCCEEDED, progress=TotalTasks: 2 Succeeded: 2 Running: 0 Failed: 0 Killed: 0, diagnostics=, counters=Counters: 102
  org.apache.tez.common.counters.DAGCounter
    NUM_SUCCEEDED_TASKS=2
    TOTAL_LAUNCHED_TASKS=2
    DATA_LOCAL_TASKS=1
    AM_CPU_MILLISECONDS=2680
    AM_GC_TIME_MILLIS=0
  File System Counters
    FILE_BYTES_READ=709
    FILE_BYTES_WRITTEN=677
    HDFS_BYTES_READ=31760674
    HDFS_BYTES_WRITTEN=425
    HDFS_READ_OPS=4
    HDFS_WRITE_OPS=2
    HDFS_OP_CREATE=1
    HDFS_OP_GET_FILE_STATUS=3
    HDFS_OP_OPEN=1
    HDFS_OP_RENAME=1
  org.apache.tez.common.counters.TaskCounter
    REDUCE_INPUT_GROUPS=69
    REDUCE_INPUT_RECORDS=69
    COMBINE_INPUT_RECORDS=0
    SPILLED_RECORDS=138
    NUM_SHUFFLED_INPUTS=1
    NUM_SKIPPED_INPUTS=0
    NUM_FAILED_SHUFFLE_INPUTS=0
    MERGED_MAP_OUTPUTS=1
    GC_TIME_MILLIS=250
    CPU_MILLISECONDS=16450
    PHYSICAL_MEMORY_BYTES=828375040
    VIRTUAL_MEMORY_BYTES=5503488000
    COMMITTED_HEAP_BYTES=828375040
    INPUT_RECORDS_PROCESSED=174568
    INPUT_SPLIT_LENGTH_BYTES=31760674
    OUTPUT_RECORDS=174637
    OUTPUT_BYTES=1750337
    OUTPUT_BYTES_WITH_OVERHEAD=916
    OUTPUT_BYTES_PHYSICAL=645
    ADDITIONAL_SPILLS_BYTES_WRITTEN=0
    ADDITIONAL_SPILLS_BYTES_READ=645
    ADDITIONAL_SPILL_COUNT=0
    SHUFFLE_CHUNK_COUNT=1
    SHUFFLE_BYTES=645
    SHUFFLE_BYTES_DECOMPRESSED=916
    SHUFFLE_BYTES_TO_MEM=0
    SHUFFLE_BYTES_TO_DISK=0
    SHUFFLE_BYTES_DISK_DIRECT=645
    NUM_MEM_TO_DISK_MERGES=0
    NUM_DISK_TO_DISK_MERGES=0
    SHUFFLE_PHASE_TIME=29
    MERGE_PHASE_TIME=53
    FIRST_EVENT_RECEIVED=18
    LAST_EVENT_RECEIVED=18
  MultiStoreCounters
    Output records in _0_pig-output=69
  Shuffle Errors
    BAD_ID=0
    CONNECTION=0
    IO_ERROR=0
    WRONG_LENGTH=0
    WRONG_MAP=0
    WRONG_REDUCE=0
  Shuffle Errors_scope_125_INPUT_scope_124
    BAD_ID=0
    CONNECTION=0
    IO_ERROR=0
    WRONG_LENGTH=0
    WRONG_MAP=0
    WRONG_REDUCE=0
  TaskCounter_scope_124_INPUT_scope_72
    INPUT_RECORDS_PROCESSED=174568
    INPUT_SPLIT_LENGTH_BYTES=31760674
  TaskCounter_scope_124_OUTPUT_scope_125
    ADDITIONAL_SPILLS_BYTES_READ=0
    ADDITIONAL_SPILLS_BYTES_WRITTEN=0
    ADDITIONAL_SPILL_COUNT=0
    OUTPUT_BYTES=1750337
    OUTPUT_BYTES_PHYSICAL=645
    OUTPUT_BYTES_WITH_OVERHEAD=916
    OUTPUT_RECORDS=174568
    SHUFFLE_CHUNK_COUNT=1
    SPILLED_RECORDS=69
  TaskCounter_scope_125_INPUT_scope_124
    ADDITIONAL_SPILLS_BYTES_READ=645
    ADDITIONAL_SPILLS_BYTES_WRITTEN=0
    COMBINE_INPUT_RECORDS=0
    FIRST_EVENT_RECEIVED=18
    LAST_EVENT_RECEIVED=18
    MERGED_MAP_OUTPUTS=1
    MERGE_PHASE_TIME=53
    NUM_DISK_TO_DISK_MERGES=0
    NUM_FAILED_SHUFFLE_INPUTS=0
    NUM_MEM_TO_DISK_MERGES=0
    NUM_SHUFFLED_INPUTS=1
    NUM_SKIPPED_INPUTS=0
    REDUCE_INPUT_GROUPS=69
    REDUCE_INPUT_RECORDS=69
    SHUFFLE_BYTES=645
    SHUFFLE_BYTES_DECOMPRESSED=916
    SHUFFLE_BYTES_DISK_DIRECT=645
    SHUFFLE_BYTES_TO_DISK=0
    SHUFFLE_BYTES_TO_MEM=0
    SHUFFLE_PHASE_TIME=29
    SPILLED_RECORDS=69
  TaskCounter_scope_125_OUTPUT_scope_123
    OUTPUT_RECORDS=69
  org.apache.hadoop.mapreduce.TaskCounter
    COMBINE_INPUT_RECORDS=69
    COMBINE_OUTPUT_RECORDS=174568
  org.apache.hadoop.mapreduce.TaskCounter_scope_124_OUTPUT_scope_125
    COMBINE_INPUT_RECORDS=69
    COMBINE_OUTPUT_RECORDS=174568
  org.apache.hadoop.mapreduce.TaskCounter_scope_125_INPUT_scope_124
    COMBINE_INPUT_RECORDS=0
    COMBINE_OUTPUT_RECORDS=0
  org.apache.pig.PigWarning
    FIELD_DISCARDED_TYPE_CONVERSION_FAILED=42888
  2018-04-24 15:44:31,503 [PigTezLauncher-0] INFO  org.apache.hadoop.conf.Configuration.deprecation - fs.default.name is deprecated. Instead, use fs.defaultFS
  2018-04-24 15:44:32,181 [main] WARN  org.apache.pig.backend.hadoop.executionengine.tez.TezLauncher - Encountered Warning FIELD_DISCARDED_TYPE_CONVERSION_FAILED 42888 time(s).
  2018-04-24 15:44:32,183 [main] INFO  org.apache.pig.tools.pigstats.tez.TezPigScriptStats - Script Statistics:

       HadoopVersion: 2.7.3.2.6.4.0-91
          PigVersion: 0.16.0.2.6.4.0-91
          TezVersion: 0.7.0.2.6.4.0-91
              UserId: root
            FileName:
           StartedAt: 2018-04-24 15:44:10
          FinishedAt: 2018-04-24 15:44:32
            Features: GROUP_BY

  Success!


  DAG 0:
                                    Name: PigLatin:DefaultJobName-0_scope-2
                           ApplicationId: job_1523347765873_0044
                      TotalLaunchedTasks: 2
                           FileBytesRead: 709
                        FileBytesWritten: 677
                           HdfsBytesRead: 31760674
                        HdfsBytesWritten: 425
      SpillableMemoryManager spill count: 0
                Bags proactively spilled: 0
             Records proactively spilled: 0

  DAG Plan:
  Tez vertex scope-124	->	Tez vertex scope-125,
  Tez vertex scope-125

  Vertex Stats:
  VertexId Parallelism TotalTasks   InputRecords   ReduceInputRecords  OutputRecords  FileBytesRead FileBytesWritten  HdfsBytesRead HdfsBytesWritten Alias	Feature	Outputs
  scope-124          1          1         174568                    0         174568             32              677       31760674                0 counted_business,grouped_business,yelp_business
  scope-125          1          1              0                   69             69            677                0              0              425 counted_business	GROUP_BY	/user/<username>/pig-output,

  Input(s):
  Successfully read 174568 records (31760674 bytes) from: "/user/<username>/samples/yelp_business.csv"

  Output(s):
  Successfully stored 69 records (425 bytes) in: "/user/<username>/pig-output"

  grunt>

We can check the result at HDFS:

.. code-block:: console

  # hdfs dfs -ls /user/<username>/pig-output
  Found 2 items
  -rw-------   3 <username> <username>          0 2018-04-24 15:44 /user/<username>/pig-output/_SUCCESS
  -rw-------   3 <username> <username>        425 2018-04-24 15:44 /user/<username>/pig-output/part-r-00000
  # hdfs dfs -cat /user/<username>/pig-output/part-r-00000
  ,1
  3,1
  6,3
  B,1
  C,28
  01,10
  30,1
  AB,1
  AK,1
  AL,1
  AR,2
  AZ,52214
  BW,3118
  BY,4
  CA,5
  CO,2
  CS,1
  DE,1
  FL,1
  GA,1
  HU,1
  IL,1852
  IN,3
  KY,1
  MN,1
  MT,1
  NC,12956
  NE,1
  NI,10
  NV,33086
  NY,18
  OH,12609
  ON,30208
  PA,10109
  QC,8169
  SC,679
  SL,1
  ST,11
  VA,1
  VS,7
  VT,2
  WA,1
  WI,4754
  ABE,3
  CHE,143
  CMA,2
  EDH,3795
  ELN,47
  ESX,12
  FAL,1
  FIF,85
  FLN,2
  GLG,3
  HLD,179
  KHL,1
  MLN,208
  NLK,1
  NTH,2
  NYK,152
  PKN,1
  RCC,1
  SCB,5
  STG,1
  TAM,1
  WHT,1
  WLN,38
  XGL,4
  ZET,1
  state,1
  #

You can get more details about Pig Latin syntax at
`Pig Latin Basics <http://pig.apache.org/docs/r0.16.0/basic.html>`_.

This job can be coded as a Pig file (`*.pig`):

.. code-block:: pig

  REGISTER /opt/pig/lib/piggybank.jar
  define CSVLoader org.apache.pig.piggybank.storage.CSVLoader();

  yelp_business = LOAD '/samples/yelp/yelp_business/yelp_business.csv' using CSVLoader AS (
    business_id:chararray,
    name:chararray,
    neighborhood:chararray,
    address:chararray,
    city:chararray,
    state:chararray,
    postal_code:int,
    latitude:double,
    longitude:double,
    stars:float,
    review_count:int,
    is_open:boolean,
    categories:chararray);

  grouped_business = GROUP yelp_business BY state;
  counted_business = FOREACH grouped_business GENERATE group, COUNT(yelp_business);
  STORE counted_business INTO '$output_dir' USING PigStorage(',');


And execute using `pig <script>.pig`, as you can see at `stack-examples/pigexample`:

.. code-block:: pig

  # pig -p output_dir=/user/<username>/pig-output yelp_business.pig

And the same result is generated.

.. note::

  You can also launch jobs using Ambari :ref:`pigview`.
