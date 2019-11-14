.. warning::

  Remember that for interacting with EDI Big Data Stack you must be
  authenticated at the system using `kinit` command. For more information, read
  the documentation at :ref:`authenticating-with-kerberos`.

.. _hbase:

HBase
=====

HBase is a random, realtime and read/write access database, which allows hosting
very large tables (billion rows x millons of columns). In this tutorial we are going
to show how to load data into HBase from a MapReduce job, and inspecting this data
from both HBase shell and a Python script.

Loading data into HBase
.......................

.. note::

  Before creating any table in HBase, you must contact with :ref:`technical-support` for
  creating your namespace and give you the proper permissions.

Before loading data we must create the database using Hbase shell. All databases
must follow the naming convention `workspace:database`. This database will be
structured into two column families: `info` and `stats`.

.. code-block:: console

  # hbase shell
  HBase Shell; enter 'help<RETURN>' for list of supported commands.
  Type "exit<RETURN>" to leave the HBase Shell
  Version 1.1.2.2.6.4.0-91, r2a88e694af7238290a5747f963a4fa0079c55bf9, Thu Jan  4 10:32:40 UTC 2018

Once the shell is started run the following command to create your database

.. code-block:: console

  hbase(main):001:0> create '<username>.yelp_business', 'info', 'stats'
  0 row(s) in 2.3740 seconds
  => Hbase::Table - <username>.yelp_business
  hbase(main):002:0> scan '<username>.yelp_business'
  ROW                                                   COLUMN+CELL
  0 row(s) in 0.0440 seconds

Move into hbaseexample dir.

.. code-block:: console

  $ cd ~/work/examples/hbaseexample

`HBaseLoadExample.java` contains the unique and main class of this MapReduce job.
`HBaseLoadExample` class contains only the `HBaseWriterMapper` class, as this
job doesn't need a reducer.

HBaseWriterMapper
-----------------

.. code-block:: java

  public static class HBaseWriterMapper extends Mapper<Object, Text, ImmutableBytesWritable, Put> {

        private long checkpoint = 100;
        private long count = 0;

        public void map(Object key, Text value, Context context) throws IOException, InterruptedException {
            // Extract state using opencsv library
            CSVReader reader = new CSVReader(new StringReader(value.toString()));
            String[] line;

            while ((line = reader.readNext()) != null) {
                // Check that current line is not CSV's header
                if (!line.equals("state")) {
                    context.setStatus("Creating row");
                    byte [] row = Bytes.toBytes(line[0]);
                    Put put = new Put(row);

                    // Insert info
                    byte [] family = Bytes.toBytes("info");

                    // name
                    byte [] qualifier = Bytes.toBytes("name");
                    byte [] hvalue = Bytes.toBytes(line[1]);
                    put.addColumn(family, qualifier, hvalue);

                    // neighborhood
                    qualifier = Bytes.toBytes("neighborhood");
                    hvalue = Bytes.toBytes(line[2]);
                    put.addColumn(family, qualifier, hvalue);

                    // Same with address, city, state, postal_code, latitude,
                    // longitude, is_open and categories
                    [...]

                    // Insert stats
                    family = Bytes.toBytes("stats");

                    // stars
                    qualifier = Bytes.toBytes("stars");
                    hvalue = Bytes.toBytes(line[9]);
                    put.addColumn(family, qualifier, hvalue);

                    // review_count
                    qualifier = Bytes.toBytes("review_count");
                    hvalue = Bytes.toBytes(line[10]);
                    put.addColumn(family, qualifier, hvalue);

                    context.write(new ImmutableBytesWritable(row), put);

                    // Set status every checkpoint lines for avoiding AM timeout
                    if(++count % checkpoint == 0) {
                        context.setStatus("Emitting Put " + count);
                    }
                }
            }
        }
    }

The `HBaseWriterMapper` class represents the mapper of our job. Its definition
is very simple. It extends the `Mapper` class, receiving a tuple formed by a
key of type `Object` and a value of type `Text` as input, and generating a tuple
formed by a key of type `ImmutableBytesWritable` and a value of type `Put` as
output.

The map method is who processes the input and generates the output to be passed
to the reducer. In this function, we take the value, representing a single CSV
line and we create an object of type `org.apache.hadoop.hbase.client.Put`. This
`Put` class represents a "put" action into the HBase database. Each column of
the database must have a family, a qualifier and a value.


main & run
----------

At last, check `main` and `run` method of the `HBaseLoadExample` class.

.. code-block:: java

  public int run(String[] otherArgs) throws Exception {
        Configuration conf = getConf();

        Job job = Job.getInstance(conf, "HBase load example");
        job.setJarByClass(HBaseLoadExample.class);

        FileInputFormat.setInputPaths(job, otherArgs[0]);
        job.setInputFormatClass(TextInputFormat.class);
        job.setMapperClass(HBaseWriterMapper.class);

        TableMapReduceUtil.initTableReducerJob(
                otherArgs[1],
                null,
                job
        );
        job.setNumReduceTasks(0);

        return (job.waitForCompletion(true) ? 0 : 1);
    }

    public static void main(String [] args) throws Exception {
        int status = ToolRunner.run(HBaseConfiguration.create(), new HBaseLoadExample(), args);
        System.exit(status);
    }

In the `run` method, the MapReduce job is configured. Concretely, in this example
mapper class, input directories and output table (taken from the CLI when
launching the job) are set.

pom.xml
-------

The `pom.xml` file compiles the project and generates the jar that we need to
submit to EDI Big Data Stack.

.. code-block:: xml

  <?xml version="1.0" encoding="UTF-8"?>
  <project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>eu.edincubator.stack.examples</groupId>
    <artifactId>hbaseexample</artifactId>
    <version>1.0-SNAPSHOT</version>

    <dependencies>
        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-mapreduce-client-core</artifactId>
            <version>${hadoop.version}</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-common</artifactId>
            <version>${hadoop.version}</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>com.opencsv</groupId>
            <artifactId>opencsv</artifactId>
            <version>4.1</version>
        </dependency>
        <dependency>
            <groupId>org.apache.hbase</groupId>
            <artifactId>hbase-common</artifactId>
            <version>${hbase.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.hbase</groupId>
            <artifactId>hbase-client</artifactId>
            <version>${hbase.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.hbase</groupId>
            <artifactId>hbase-protocol</artifactId>
            <version>${hbase.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.hbase</groupId>
            <artifactId>hbase-server</artifactId>
            <version>${hbase.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.hbase</groupId>
            <artifactId>hbase-thrift</artifactId>
            <version>${hbase.version}</version>
        </dependency>
    </dependencies>

    <properties>
        <hadoop.version>3.0.0</hadoop.version>
        <hbase.version>2.0.0</hbase.version>
    </properties>
  </project>

Opposite to the `pom.xml` presented at :ref:`mapreduce`, this one doesn't
generate a "fat jar", so we have to add third party libraries (com.opencsv) when
submitting the job.

Compiling and submitting the job
--------------------------------

At first, you must create the java package:

.. code-block:: console

  $ mvn clean package

Before launching the job, we must download required third party libraries:

.. code-block:: console

  $ mkdir libjars
  $ cd libjars
  $ wget http://central.maven.org/maven2/com/opencsv/opencsv/4.1/opencsv-4.1.jar


Next, we can submit the job using the
`hadoop jar` command. Notice the `-libjars` parameter:

.. code-block:: console

  # cd ..
  # yarn jar target/hbaseexample-1.0-SNAPSHOT.jar eu.edincubator.stack.examples.hbase.HBaseLoadExample -libjars=libjars/opencsv-4.1.jar /samples/yelp/yelp_business/yelp_business.csv <username>.yelp_business

.. code-block:: console

  18/10/10 13:41:01 INFO zookeeper.RecoverableZooKeeper: Process identifier=hconnection-0x482d776b connecting to ZooKeeper ensemble=master.edincubator.eu:2181,worker1.edincubator.eu:2181,worker2.edincubator.eu:2181,worker3.edincubator.eu:2181,worker4.edincubator.eu:2181
  18/10/10 13:41:01 INFO zookeeper.ZooKeeper: Client environment:zookeeper.version=3.4.6-292--1, built on 05/11/2018 06:40 GMT
  18/10/10 13:41:01 INFO zookeeper.ZooKeeper: Client environment:host.name=2c8b28d2fe62
  18/10/10 13:41:01 INFO zookeeper.ZooKeeper: Client environment:java.version=1.8.0_181
  18/10/10 13:41:01 INFO zookeeper.ZooKeeper: Client environment:java.vendor=Oracle Corporation
  18/10/10 13:41:01 INFO zookeeper.ZooKeeper: Client environment:java.home=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.181-3.b13.el7_5.x86_64/jre
  [...]
  18/10/10 13:41:01 INFO zookeeper.ZooKeeper: Client environment:java.library.path=:/usr/hdp/2.6.5.0-292/hadoop/lib/native/Linux-amd64-64:/usr/hdp/2.6.5.0-292/hadoop/lib/native
  18/10/10 13:41:01 INFO zookeeper.ZooKeeper: Client environment:java.io.tmpdir=/tmp
  18/10/10 13:41:01 INFO zookeeper.ZooKeeper: Client environment:java.compiler=<NA>
  18/10/10 13:41:01 INFO zookeeper.ZooKeeper: Client environment:os.name=Linux
  18/10/10 13:41:01 INFO zookeeper.ZooKeeper: Client environment:os.arch=amd64
  18/10/10 13:41:01 INFO zookeeper.ZooKeeper: Client environment:os.version=4.15.0-34-generic
  18/10/10 13:41:01 INFO zookeeper.ZooKeeper: Client environment:user.name=<username>
  18/10/10 13:41:01 INFO zookeeper.ZooKeeper: Client environment:user.home=/home/<username>
  18/10/10 13:41:01 INFO zookeeper.ZooKeeper: Client environment:user.dir=/workdir/stack-examples/hbaseexample/target
  18/10/10 13:41:01 INFO zookeeper.ZooKeeper: Initiating client connection, connectString=master.edincubator.eu:2181,worker1.edincubator.eu:2181,worker2.edincubator.eu:2181,worker3.edincubator.eu:2181,worker4.edincubator.eu:2181 sessionTimeout=90000 watcher=org.apache.hadoop.hbase.zookeeper.PendingWatcher@4eed46ee
  18/10/10 13:41:01 INFO zookeeper.ClientCnxn: Opening socket connection to server worker3.edincubator.eu/192.168.1.23:2181. Will not attempt to authenticate using SASL (unknown error)
  18/10/10 13:41:01 INFO zookeeper.ClientCnxn: Socket connection established, initiating session, client: /192.168.255.10:37824, server: worker3.edincubator.eu/192.168.1.23:2181
  18/10/10 13:41:01 INFO zookeeper.ClientCnxn: Session establishment complete on server worker3.edincubator.eu/192.168.1.23:2181, sessionid = 0x46644dd3ff70063, negotiated timeout = 60000
  18/10/10 13:41:02 INFO zookeeper.RecoverableZooKeeper: Process identifier=TokenUtil-getAuthToken connecting to ZooKeeper ensemble=master.edincubator.eu:2181,worker1.edincubator.eu:2181,worker2.edincubator.eu:2181,worker3.edincubator.eu:2181,worker4.edincubator.eu:2181
  18/10/10 13:41:02 INFO zookeeper.ZooKeeper: Initiating client connection, connectString=master.edincubator.eu:2181,worker1.edincubator.eu:2181,worker2.edincubator.eu:2181,worker3.edincubator.eu:2181,worker4.edincubator.eu:2181 sessionTimeout=90000 watcher=org.apache.hadoop.hbase.zookeeper.PendingWatcher@c65a5ef
  18/10/10 13:41:02 INFO zookeeper.ClientCnxn: Opening socket connection to server worker1.edincubator.eu/192.168.1.21:2181. Will not attempt to authenticate using SASL (unknown error)
  18/10/10 13:41:02 INFO zookeeper.ClientCnxn: Socket connection established, initiating session, client: /192.168.255.10:41372, server: worker1.edincubator.eu/192.168.1.21:2181
  18/10/10 13:41:02 INFO zookeeper.ClientCnxn: Session establishment complete on server worker1.edincubator.eu/192.168.1.21:2181, sessionid = 0x26644dd3ff80050, negotiated timeout = 60000
  18/10/10 13:41:02 INFO zookeeper.ZooKeeper: Session: 0x26644dd3ff80050 closed
  18/10/10 13:41:02 INFO zookeeper.ClientCnxn: EventThread shut down
  18/10/10 13:41:03 INFO client.ConnectionManager$HConnectionImplementation: Closing zookeeper sessionid=0x46644dd3ff70063
  18/10/10 13:41:03 INFO zookeeper.ZooKeeper: Session: 0x46644dd3ff70063 closed
  18/10/10 13:41:03 INFO zookeeper.ClientCnxn: EventThread shut down
  18/10/10 13:41:03 INFO client.RMProxy: Connecting to ResourceManager at master.edincubator.eu/192.168.1.12:8050
  18/10/10 13:41:04 INFO client.AHSProxy: Connecting to Application History server at master.edincubator.eu/192.168.1.12:10200
  18/10/10 13:41:05 INFO hdfs.DFSClient: Created HDFS_DELEGATION_TOKEN token 491 for <username> on 192.168.1.12:8020
  18/10/10 13:41:05 INFO security.TokenCache: Got dt for hdfs://master.edincubator.eu:8020; Kind: HDFS_DELEGATION_TOKEN, Service: 192.168.1.12:8020, Ident: (HDFS_DELEGATION_TOKEN token 491 for <username>)
  18/10/10 13:41:35 INFO input.FileInputFormat: Total input paths to process : 1
  18/10/10 13:41:36 INFO mapreduce.JobSubmitter: number of splits:1
  18/10/10 13:41:37 INFO mapreduce.JobSubmitter: Submitting tokens for job: job_1539159936594_0013
  18/10/10 13:41:37 INFO mapreduce.JobSubmitter: Kind: HDFS_DELEGATION_TOKEN, Service: 192.168.1.12:8020, Ident: (HDFS_DELEGATION_TOKEN token 491 for <username>)
  18/10/10 13:41:37 INFO mapreduce.JobSubmitter: Kind: HBASE_AUTH_TOKEN, Service: a5fb7077-f1b8-49d0-abdc-8d73fe4e0ef5, Ident: (org.apache.hadoop.hbase.security.token.AuthenticationTokenIdentifier@0)
  18/10/10 13:41:44 INFO impl.TimelineClientImpl: Timeline service address: http://master.edincubator.eu:8188/ws/v1/timeline/
  18/10/10 13:41:46 INFO impl.YarnClientImpl: Submitted application application_1539159936594_0013
  18/10/10 13:41:46 INFO mapreduce.Job: The url to track the job: http://master.edincubator.eu:8088/proxy/application_1539159936594_0013/
  18/10/10 13:41:46 INFO mapreduce.Job: Running job: job_1539159936594_0013
  18/10/10 13:41:54 INFO mapreduce.Job: Job job_1539159936594_0013 running in uber mode : false
  18/10/10 13:41:54 INFO mapreduce.Job:  map 0% reduce 0%
  18/10/10 13:42:05 INFO mapreduce.Job:  map 45% reduce 0%
  18/10/10 13:42:08 INFO mapreduce.Job:  map 71% reduce 0%
  18/10/10 13:42:11 INFO mapreduce.Job:  map 100% reduce 0%
  18/10/10 13:42:11 INFO mapreduce.Job: Job job_1539159936594_0013 completed successfully
  18/10/10 13:42:12 INFO mapreduce.Job: Counters: 30
  	File System Counters
  		FILE: Number of bytes read=0
  		FILE: Number of bytes written=195824
  		FILE: Number of read operations=0
  		FILE: Number of large read operations=0
  		FILE: Number of write operations=0
  		HDFS: Number of bytes read=31760817
  		HDFS: Number of bytes written=0
  		HDFS: Number of read operations=2
  		HDFS: Number of large read operations=0
  		HDFS: Number of write operations=0
  	Job Counters
  		Launched map tasks=1
  		Data-local map tasks=1
  		Total time spent by all maps in occupied slots (ms)=494370
  		Total time spent by all reduces in occupied slots (ms)=0
  		Total time spent by all map tasks (ms)=16479
  		Total vcore-milliseconds taken by all map tasks=16479
  		Total megabyte-milliseconds taken by all map tasks=506234880
  	Map-Reduce Framework
  		Map input records=174568
  		Map output records=174568
  		Input split bytes=143
  		Spilled Records=0
  		Failed Shuffles=0
  		Merged Map outputs=0
  		GC time elapsed (ms)=123
  		CPU time spent (ms)=17670
  		Physical memory (bytes) snapshot=1843146752
  		Virtual memory (bytes) snapshot=28693168128
  		Total committed heap usage (bytes)=2084569088
  	File Input Format Counters
  		Bytes Read=31760674
  	File Output Format Counters
  		Bytes Written=0
  #


If we return to HBase shell, we can check that the table has been filled with
data:

.. code-block:: console

  hbase(main):004:0> scan '<username>.yelp_business', {'LIMIT' => 5}

.. code-block:: console

  ROW                                                   COLUMN+CELL
  --6MefnULPED_I942VcFNA                               column=info:address, timestamp=1524485480078, value="328 Highway 7 E, Chalmers Gate 11, Unit 10"
  --6MefnULPED_I942VcFNA                               column=info:categories, timestamp=1524485480078, value=Chinese;Restaurants
  --6MefnULPED_I942VcFNA                               column=info:city, timestamp=1524485480078, value=Richmond Hill
  --6MefnULPED_I942VcFNA                               column=info:is_open, timestamp=1524485480078, value=1
  --6MefnULPED_I942VcFNA                               column=info:longitude, timestamp=1524485480078, value=-79.3996044
  --6MefnULPED_I942VcFNA                               column=info:name, timestamp=1524485480078, value="John's Chinese BBQ Restaurant"
  --6MefnULPED_I942VcFNA                               column=info:neighborhood, timestamp=1524485480078, value=
  --6MefnULPED_I942VcFNA                               column=info:postal_code, timestamp=1524485480078, value=43.840905
  --6MefnULPED_I942VcFNA                               column=info:state, timestamp=1524485480078, value=ON
  --6MefnULPED_I942VcFNA                               column=stats:review_count, timestamp=1524485480078, value=37
  --6MefnULPED_I942VcFNA                               column=stats:stars, timestamp=1524485480078, value=3.0
  --7zmmkVg-IMGaXbuVd0SQ                               column=info:address, timestamp=1524485499306, value="16432 Old Statesville Rd"
  --7zmmkVg-IMGaXbuVd0SQ                               column=info:categories, timestamp=1524485499306, value=Food;Breweries
  --7zmmkVg-IMGaXbuVd0SQ                               column=info:city, timestamp=1524485499306, value=Huntersville
  --7zmmkVg-IMGaXbuVd0SQ                               column=info:is_open, timestamp=1524485499306, value=1
  --7zmmkVg-IMGaXbuVd0SQ                               column=info:longitude, timestamp=1524485499306, value=-80.843688
  --7zmmkVg-IMGaXbuVd0SQ                               column=info:name, timestamp=1524485499306, value="Primal Brewery"
  --7zmmkVg-IMGaXbuVd0SQ                               column=info:neighborhood, timestamp=1524485499306, value=
  --7zmmkVg-IMGaXbuVd0SQ                               column=info:postal_code, timestamp=1524485499306, value=35.437086
  --7zmmkVg-IMGaXbuVd0SQ                               column=info:state, timestamp=1524485499306, value=NC
  --7zmmkVg-IMGaXbuVd0SQ                               column=stats:review_count, timestamp=1524485499306, value=47
  --7zmmkVg-IMGaXbuVd0SQ                               column=stats:stars, timestamp=1524485499306, value=4.0
  --8LPVSo5i0Oo61X01sV9A                               column=info:address, timestamp=1524485503877, value="3941 E Baseline Rd, Ste 102"
  --8LPVSo5i0Oo61X01sV9A                               column=info:categories, timestamp=1524485503877, value=Orthopedists;Weight Loss Centers;Sports Medicine;Health & Medical;Doctors
  --8LPVSo5i0Oo61X01sV9A                               column=info:city, timestamp=1524485503877, value=Gilbert
  --8LPVSo5i0Oo61X01sV9A                               column=info:is_open, timestamp=1524485503877, value=1
  --8LPVSo5i0Oo61X01sV9A                               column=info:longitude, timestamp=1524485503877, value=-111.7283941
  --8LPVSo5i0Oo61X01sV9A                               column=info:name, timestamp=1524485503877, value="Valley Bone and Joint Specialists"
  --8LPVSo5i0Oo61X01sV9A                               column=info:neighborhood, timestamp=1524485503877, value=
  --8LPVSo5i0Oo61X01sV9A                               column=info:postal_code, timestamp=1524485503877, value=33.3795094
  --8LPVSo5i0Oo61X01sV9A                               column=info:state, timestamp=1524485503877, value=AZ
  --8LPVSo5i0Oo61X01sV9A                               column=stats:review_count, timestamp=1524485503877, value=3
  --8LPVSo5i0Oo61X01sV9A                               column=stats:stars, timestamp=1524485503877, value=4.5
  --9QQLMTbFzLJ_oT-ON3Xw                               column=info:address, timestamp=1524485481330, value="1835 E Guadalupe Rd, Ste 106"
  --9QQLMTbFzLJ_oT-ON3Xw                               column=info:categories, timestamp=1524485481330, value=Hair Salons;Beauty & Spas
  --9QQLMTbFzLJ_oT-ON3Xw                               column=info:city, timestamp=1524485481330, value=Tempe
  --9QQLMTbFzLJ_oT-ON3Xw                               column=info:is_open, timestamp=1524485481330, value=1
  --9QQLMTbFzLJ_oT-ON3Xw                               column=info:longitude, timestamp=1524485481330, value=-111.9096233
  --9QQLMTbFzLJ_oT-ON3Xw                               column=info:name, timestamp=1524485481330, value="Great Clips"
  --9QQLMTbFzLJ_oT-ON3Xw                               column=info:neighborhood, timestamp=1524485481330, value=
  --9QQLMTbFzLJ_oT-ON3Xw                               column=info:postal_code, timestamp=1524485481330, value=33.3616642
  --9QQLMTbFzLJ_oT-ON3Xw                               column=info:state, timestamp=1524485481330, value=AZ
  --9QQLMTbFzLJ_oT-ON3Xw                               column=stats:review_count, timestamp=1524485481330, value=11
  --9QQLMTbFzLJ_oT-ON3Xw                               column=stats:stars, timestamp=1524485481330, value=3.5
  --9e1ONYQuAa-CB_Rrw7Tw                               column=info:address, timestamp=1524485488519, value="3355 Las Vegas Blvd S"
  --9e1ONYQuAa-CB_Rrw7Tw                               column=info:categories, timestamp=1524485488519, value=Cajun/Creole;Steakhouses;Restaurants
  --9e1ONYQuAa-CB_Rrw7Tw                               column=info:city, timestamp=1524485488519, value=Las Vegas
  --9e1ONYQuAa-CB_Rrw7Tw                               column=info:is_open, timestamp=1524485488519, value=1
  --9e1ONYQuAa-CB_Rrw7Tw                               column=info:longitude, timestamp=1524485488519, value=-115.16919
  --9e1ONYQuAa-CB_Rrw7Tw                               column=info:name, timestamp=1524485488519, value="Delmonico Steakhouse"
  --9e1ONYQuAa-CB_Rrw7Tw                               column=info:neighborhood, timestamp=1524485488519, value=The Strip
  --9e1ONYQuAa-CB_Rrw7Tw                               column=info:postal_code, timestamp=1524485488519, value=36.123183
  --9e1ONYQuAa-CB_Rrw7Tw                               column=info:state, timestamp=1524485488519, value=NV
  --9e1ONYQuAa-CB_Rrw7Tw                               column=stats:review_count, timestamp=1524485488519, value=1451
  --9e1ONYQuAa-CB_Rrw7Tw                               column=stats:stars, timestamp=1524485488519, value=4.0
  5 row(s) in 0.0200 seconds


Reading data from Hbase
.......................

In this example, we read the data previously loaded into HBase `yelp_business`
table, compute it and write it into an HDFS folder. For that, we are going to
reproduce the example shown at :ref:`mapreduce`, but reading data from HBase
instead of a CSV file.

This example is developed at `HBaseReadExample.java`. Its structure is similar
to previous examples, even the reducer is the same reducer explained at
:ref:`mapreduce`. The mapper is coded as follows:

.. code-block:: java

  public static class HBaseReadMapper extends TableMapper<Text, IntWritable> {

       private final static IntWritable one = new IntWritable(1);

       public void map(ImmutableBytesWritable row, Result value, Context context) throws IOException, InterruptedException {
           byte[] cell = value.getValue(Bytes.toBytes("info"), Bytes.toBytes("state"));
           context.write(new Text(Bytes.toString(cell)), one);
       }
   }

As you can notice, `HBaseReadMapper` extends from
`org.apache.hadoop.hbase.mapreduce.TableMapper` instead of
`org.apache.hadoop.mapreduce.Mapper`. In `TableMapper` class we only have to
define output key and value types of the mapper, as input key and value types
are fixed as they are read from HBase. `map` method receives a row id of
`org.apache.hadoop.hbase.io.ImmutableBytesWritable` type and a value of type
`org.apache.hadoop.hbase.client.Result`. Similar to the example shown at
:ref:`mapreduce`, we take the value at column family `info` and qualifier `state`
as output key and the value of `one` as output value. The reducer class is a
replica of `StateSumReducer` that we coded at :ref:`mapreduce`, which aggregates
all values for each key (state).

main & run
----------

.. code-block:: java

  public int run(String[] otherArgs) throws Exception {
          Configuration conf = getConf();

          Job job = Job.getInstance(conf, "HBase read example");
          job.setJarByClass(HBaseReadExample.class);

          Scan scan = new Scan();
          scan.setCaching(500);
          scan.setCacheBlocks(false);

          TableMapReduceUtil.initTableMapperJob(
                  otherArgs[0],
                  scan,
                  HBaseReadMapper.class,
                  Text.class,
                  IntWritable.class,
                  job
          );

          job.setReducerClass(StateSumReducer.class);
          job.setOutputKeyClass(Text.class);
          job.setOutputValueClass(IntWritable.class);

          FileOutputFormat.setOutputPath(job, new Path(otherArgs[1]));

          return (job.waitForCompletion(true) ? 0 : 1);
      }

      public static void main(String [] args) throws Exception {
          int status = ToolRunner.run(HBaseConfiguration.create(), new HBaseReadExample(), args);
          System.exit(status);
    }

As can be seen, `run` method has some differences regarding to previous example.
In this case, an instance of `org.apache.hadoop.hbase.client.Scan` class must be
set for reading the database. In the same way, the mapper is set using the
`initTableMapperJob` method from
`org.apache.hadoop.hbase.mapreduce.TableMapReduceUtil`. The reducer class is set
in the same way as we saw in other examples.

Compiling and submitting the job
--------------------------------

The package is compiled as we saw in the previous example:

.. code-block:: console

  $ mvn clean package

Next, at stack-client docker cointainer, we can submit the job using the
`hadoop jar` command.

.. code-block:: console

  # yarn jar target/hbaseexample-1.0-SNAPSHOT.jar eu.edincubator.stack.examples.hbase.HBaseReadExample <username>.yelp_business /user/<username>/hbase-output

.. code-block:: console

  18/10/10 13:46:36 INFO zookeeper.RecoverableZooKeeper: Process identifier=hconnection-0x2b58f754 connecting to ZooKeeper ensemble=master.edincubator.eu:2181,worker1.edincubator.eu:2181,worker2.edincubator.eu:2181,worker3.edincubator.eu:2181,worker4.edincubator.eu:2181
  18/10/10 13:46:36 INFO zookeeper.ZooKeeper: Client environment:zookeeper.version=3.4.6-292--1, built on 05/11/2018 06:40 GMT
  18/10/10 13:46:36 INFO zookeeper.ZooKeeper: Client environment:host.name=2c8b28d2fe62
  18/10/10 13:46:36 INFO zookeeper.ZooKeeper: Client environment:java.version=1.8.0_181
  18/10/10 13:46:36 INFO zookeeper.ZooKeeper: Client environment:java.vendor=Oracle Corporation
  18/10/10 13:46:36 INFO zookeeper.ZooKeeper: Client environment:java.home=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.181-3.b13.el7_5.x86_64/jre
  [...]
  18/10/10 13:46:36 INFO zookeeper.ZooKeeper: Client environment:java.library.path=:/usr/hdp/2.6.5.0-292/hadoop/lib/native/Linux-amd64-64:/usr/hdp/2.6.5.0-292/hadoop/lib/native
  18/10/10 13:46:36 INFO zookeeper.ZooKeeper: Client environment:java.io.tmpdir=/tmp
  18/10/10 13:46:36 INFO zookeeper.ZooKeeper: Client environment:java.compiler=<NA>
  18/10/10 13:46:36 INFO zookeeper.ZooKeeper: Client environment:os.name=Linux
  18/10/10 13:46:36 INFO zookeeper.ZooKeeper: Client environment:os.arch=amd64
  18/10/10 13:46:36 INFO zookeeper.ZooKeeper: Client environment:os.version=4.15.0-34-generic
  18/10/10 13:46:36 INFO zookeeper.ZooKeeper: Client environment:user.name=<username>
  18/10/10 13:46:36 INFO zookeeper.ZooKeeper: Client environment:user.home=/home/<username>
  18/10/10 13:46:36 INFO zookeeper.ZooKeeper: Client environment:user.dir=/workdir/stack-examples/hbaseexample/target
  18/10/10 13:46:36 INFO zookeeper.ZooKeeper: Initiating client connection, connectString=master.edincubator.eu:2181,worker1.edincubator.eu:2181,worker2.edincubator.eu:2181,worker3.edincubator.eu:2181,worker4.edincubator.eu:2181 sessionTimeout=90000 watcher=org.apache.hadoop.hbase.zookeeper.PendingWatcher@3954d008
  18/10/10 13:46:36 INFO zookeeper.ClientCnxn: Opening socket connection to server worker2.edincubator.eu/192.168.1.22:2181. Will not attempt to authenticate using SASL (unknown error)
  18/10/10 13:46:36 INFO zookeeper.ClientCnxn: Socket connection established, initiating session, client: /192.168.255.10:47266, server: worker2.edincubator.eu/192.168.1.22:2181
  18/10/10 13:46:36 INFO zookeeper.ClientCnxn: Session establishment complete on server worker2.edincubator.eu/192.168.1.22:2181, sessionid = 0x36644dd41af0055, negotiated timeout = 60000
  18/10/10 13:46:36 INFO zookeeper.RecoverableZooKeeper: Process identifier=TokenUtil-getAuthToken connecting to ZooKeeper ensemble=master.edincubator.eu:2181,worker1.edincubator.eu:2181,worker2.edincubator.eu:2181,worker3.edincubator.eu:2181,worker4.edincubator.eu:2181
  18/10/10 13:46:36 INFO zookeeper.ZooKeeper: Initiating client connection, connectString=master.edincubator.eu:2181,worker1.edincubator.eu:2181,worker2.edincubator.eu:2181,worker3.edincubator.eu:2181,worker4.edincubator.eu:2181 sessionTimeout=90000 watcher=org.apache.hadoop.hbase.zookeeper.PendingWatcher@1b0a7baf
  18/10/10 13:46:36 INFO zookeeper.ClientCnxn: Opening socket connection to server worker2.edincubator.eu/192.168.1.22:2181. Will not attempt to authenticate using SASL (unknown error)
  18/10/10 13:46:37 INFO zookeeper.ClientCnxn: Socket connection established, initiating session, client: /192.168.255.10:47268, server: worker2.edincubator.eu/192.168.1.22:2181
  18/10/10 13:46:37 INFO zookeeper.ClientCnxn: Session establishment complete on server worker2.edincubator.eu/192.168.1.22:2181, sessionid = 0x36644dd41af0056, negotiated timeout = 60000
  18/10/10 13:46:37 INFO zookeeper.ZooKeeper: Session: 0x36644dd41af0056 closed
  18/10/10 13:46:37 INFO zookeeper.ClientCnxn: EventThread shut down
  18/10/10 13:46:38 INFO client.ConnectionManager$HConnectionImplementation: Closing zookeeper sessionid=0x36644dd41af0055
  18/10/10 13:46:38 INFO zookeeper.ZooKeeper: Session: 0x36644dd41af0055 closed
  18/10/10 13:46:38 INFO zookeeper.ClientCnxn: EventThread shut down
  18/10/10 13:46:38 INFO client.RMProxy: Connecting to ResourceManager at master.edincubator.eu/192.168.1.12:8050
  18/10/10 13:46:38 INFO client.AHSProxy: Connecting to Application History server at master.edincubator.eu/192.168.1.12:10200
  18/10/10 13:46:39 INFO hdfs.DFSClient: Created HDFS_DELEGATION_TOKEN token 492 for <username> on 192.168.1.12:8020
  18/10/10 13:46:39 INFO security.TokenCache: Got dt for hdfs://master.edincubator.eu:8020; Kind: HDFS_DELEGATION_TOKEN, Service: 192.168.1.12:8020, Ident: (HDFS_DELEGATION_TOKEN token 492 for <username>)
  18/10/10 13:47:07 INFO zookeeper.RecoverableZooKeeper: Process identifier=hconnection-0x2bc9a775 connecting to ZooKeeper ensemble=master.edincubator.eu:2181,worker1.edincubator.eu:2181,worker2.edincubator.eu:2181,worker3.edincubator.eu:2181,worker4.edincubator.eu:2181
  18/10/10 13:47:07 INFO zookeeper.ZooKeeper: Initiating client connection, connectString=master.edincubator.eu:2181,worker1.edincubator.eu:2181,worker2.edincubator.eu:2181,worker3.edincubator.eu:2181,worker4.edincubator.eu:2181 sessionTimeout=90000 watcher=org.apache.hadoop.hbase.zookeeper.PendingWatcher@27b000f7
  18/10/10 13:47:08 INFO zookeeper.ClientCnxn: Opening socket connection to server worker2.edincubator.eu/192.168.1.22:2181. Will not attempt to authenticate using SASL (unknown error)
  18/10/10 13:47:08 INFO zookeeper.ClientCnxn: Socket connection established, initiating session, client: /192.168.255.10:47476, server: worker2.edincubator.eu/192.168.1.22:2181
  18/10/10 13:47:08 INFO zookeeper.ClientCnxn: Session establishment complete on server worker2.edincubator.eu/192.168.1.22:2181, sessionid = 0x36644dd41af0057, negotiated timeout = 60000
  18/10/10 13:47:08 INFO util.RegionSizeCalculator: Calculating region sizes for table "<username>.yelp_business".
  18/10/10 13:47:10 INFO client.ConnectionManager$HConnectionImplementation: Closing master protocol: MasterService
  18/10/10 13:47:10 INFO client.ConnectionManager$HConnectionImplementation: Closing zookeeper sessionid=0x36644dd41af0057
  18/10/10 13:47:10 INFO zookeeper.ZooKeeper: Session: 0x36644dd41af0057 closed
  18/10/10 13:47:10 INFO zookeeper.ClientCnxn: EventThread shut down
  18/10/10 13:47:12 INFO mapreduce.JobSubmitter: number of splits:1
  18/10/10 13:47:12 INFO Configuration.deprecation: io.bytes.per.checksum is deprecated. Instead, use dfs.bytes-per-checksum
  18/10/10 13:47:13 INFO mapreduce.JobSubmitter: Submitting tokens for job: job_1539159936594_0014
  18/10/10 13:47:13 INFO mapreduce.JobSubmitter: Kind: HDFS_DELEGATION_TOKEN, Service: 192.168.1.12:8020, Ident: (HDFS_DELEGATION_TOKEN token 492 for <username>)
  18/10/10 13:47:13 INFO mapreduce.JobSubmitter: Kind: HBASE_AUTH_TOKEN, Service: a5fb7077-f1b8-49d0-abdc-8d73fe4e0ef5, Ident: (org.apache.hadoop.hbase.security.token.AuthenticationTokenIdentifier@1)
  18/10/10 13:47:19 INFO impl.TimelineClientImpl: Timeline service address: http://master.edincubator.eu:8188/ws/v1/timeline/
  18/10/10 13:47:21 INFO impl.YarnClientImpl: Submitted application application_1539159936594_0014
  18/10/10 13:47:21 INFO mapreduce.Job: The url to track the job: http://master.edincubator.eu:8088/proxy/application_1539159936594_0014/
  18/10/10 13:47:21 INFO mapreduce.Job: Running job: job_1539159936594_0014
  18/10/10 13:47:28 INFO mapreduce.Job: Job job_1539159936594_0014 running in uber mode : false
  18/10/10 13:47:28 INFO mapreduce.Job:  map 0% reduce 0%
  18/10/10 13:47:38 INFO mapreduce.Job:  map 100% reduce 0%
  18/10/10 13:47:44 INFO mapreduce.Job:  map 100% reduce 100%
  18/10/10 13:47:45 INFO mapreduce.Job: Job job_1539159936594_0014 completed successfully
  18/10/10 13:47:45 INFO mapreduce.Job: Counters: 60
  	File System Counters
  		FILE: Number of bytes read=1575775
  		FILE: Number of bytes written=3543441
  		FILE: Number of read operations=0
  		FILE: Number of large read operations=0
  		FILE: Number of write operations=0
  		HDFS: Number of bytes read=98
  		HDFS: Number of bytes written=425
  		HDFS: Number of read operations=5
  		HDFS: Number of large read operations=0
  		HDFS: Number of write operations=2
  	Job Counters
  		Launched map tasks=1
  		Launched reduce tasks=1
  		Rack-local map tasks=1
  		Total time spent by all maps in occupied slots (ms)=234570
  		Total time spent by all reduces in occupied slots (ms)=140700
  		Total time spent by all map tasks (ms)=7819
  		Total time spent by all reduce tasks (ms)=4690
  		Total vcore-milliseconds taken by all map tasks=7819
  		Total vcore-milliseconds taken by all reduce tasks=4690
  		Total megabyte-milliseconds taken by all map tasks=240199680
  		Total megabyte-milliseconds taken by all reduce tasks=144076800
  	Map-Reduce Framework
  		Map input records=174568
  		Map output records=174568
  		Map output bytes=1226633
  		Map output materialized bytes=1575775
  		Input split bytes=98
  		Combine input records=0
  		Combine output records=0
  		Reduce input groups=69
  		Reduce shuffle bytes=1575775
  		Reduce input records=174568
  		Reduce output records=69
  		Spilled Records=349136
  		Shuffled Maps =1
  		Failed Shuffles=0
  		Merged Map outputs=1
  		GC time elapsed (ms)=466
  		CPU time spent (ms)=11300
  		Physical memory (bytes) snapshot=3156611072
  		Virtual memory (bytes) snapshot=57440337920
  		Total committed heap usage (bytes)=3908042752
  	HBase Counters
  		BYTES_IN_REMOTE_RESULTS=134504069
  		BYTES_IN_RESULTS=134504069
  		MILLIS_BETWEEN_NEXTS=3048
  		NOT_SERVING_REGION_EXCEPTION=0
  		NUM_SCANNER_RESTARTS=0
  		NUM_SCAN_RESULTS_STALE=0
  		REGIONS_SCANNED=1
  		REMOTE_RPC_CALLS=352
  		REMOTE_RPC_RETRIES=0
  		RPC_CALLS=352
  		RPC_RETRIES=0
  	Shuffle Errors
  		BAD_ID=0
  		CONNECTION=0
  		IO_ERROR=0
  		WRONG_LENGTH=0
  		WRONG_MAP=0
  		WRONG_REDUCE=0
  	File Input Format Counters
  		Bytes Read=0
  	File Output Format Counters
  		Bytes Written=425
  #

We can see the output at HDFS:

.. code-block:: console

  # hdfs dfs -ls /user/<username>/hbase-output

.. code-block:: console

  Found 2 items
  -rw-r--r--   3 <username> <username>          0 2018-04-24 08:06 /user/<username>/hbase-output/_SUCCESS
  -rw-r--r--   3 <username> <username>        425 2018-04-24 08:06 /user/<username>/hbase-output/part-r-00000

.. code-block:: console

  # hdfs dfs -cat /user/<username>/hbase-output/part-r-00000

.. code-block:: console

  1
  01	10
  3	1
  30	1
  6	3
  AB	1
  ABE	3
  AK	1
  AL	1
  AR	2
  AZ	52214
  B	1
  BW	3118
  BY	4
  C	28
  CA	5
  CHE	143
  CMA	2
  CO	2
  CS	1
  DE	1
  EDH	3795
  ELN	47
  ESX	12
  FAL	1
  FIF	85
  FL	1
  FLN	2
  GA	1
  GLG	3
  HLD	179
  HU	1
  IL	1852
  IN	3
  KHL	1
  KY	1
  MLN	208
  MN	1
  MT	1
  NC	12956
  NE	1
  NI	10
  NLK	1
  NTH	2
  NV	33086
  NY	18
  NYK	152
  OH	12609
  ON	30208
  PA	10109
  PKN	1
  QC	8169
  RCC	1
  SC	679
  SCB	5
  SL	1
  ST	11
  STG	1
  TAM	1
  VA	1
  VS	7
  VT	2
  WA	1
  WHT	1
  WI	4754
  WLN	38
  XGL	4
  ZET	1

As you can see, those results are the same obtained at :ref:`mapreduce` example.

.. _phoenix:

Querying HBase using Apache Phoenix
...................................

Another option for querying HBase provided by EDI's Big Data Stack is Apache
Phoenix. Apache Phoenix allows querying HBase tables using SQL queries.

.. note::

  For security issues, users can't create new tables or views in Apache Phoenix.
  If you need a new table or view, provide this table or view definition to
  :ref:`technical-support`.

For querying the table created previously in this tutorial, we must define
a table view in Phoenix. **Remember that this step has to be requested to EDI's
Technical Support**:

For example, the following command, which will create the table view, must be sent
to admins and executed by them:

.. code-block:: console

   CREATE VIEW "<username>"."yelp_business" (ROWKEY VARCHAR PRIMARY KEY, "info"."address" VARCHAR, "info"."categories" VARCHAR, "info"."city" VARCHAR, "info"."is_open" VARCHAR, "info"."longitude" VARCHAR, "info"."name" VARCHAR, "info"."neighborhood" VARCHAR, "info"."postal_code" VARCHAR, "info"."state" VARCHAR, "stats"."review_count" VARCHAR, "stats"."stars" VARCHAR) as select * from "<username>"."yelp_business";


.. code-block:: console

  # phoenix-sqlline
  Setting property: [incremental, false]
  Setting property: [isolation, TRANSACTION_READ_COMMITTED]
  issuing: !connect jdbc:phoenix: none none org.apache.phoenix.jdbc.PhoenixDriver
  Connecting to jdbc:phoenix:
  SLF4J: Class path contains multiple SLF4J bindings.
  SLF4J: Found binding in [jar:file:/usr/hdp/2.6.5.0-292/phoenix/phoenix-4.7.0.2.6.5.0-292-client.jar!/org/slf4j/impl/StaticLoggerBinder.class]
  SLF4J: Found binding in [jar:file:/usr/hdp/2.6.5.0-292/hadoop/lib/slf4j-log4j12-1.7.10.jar!/org/slf4j/impl/StaticLoggerBinder.class]
  SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
  18/07/09 12:41:47 WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
  18/07/09 12:41:50 WARN shortcircuit.DomainSocketFactory: The short-circuit local reads feature cannot be used because libhadoop cannot be loaded.
  Connected to: Phoenix (version 4.7)
  Driver: PhoenixEmbeddedDriver (version 4.7)
  Autocommit status: true
  Transaction isolation: TRANSACTION_READ_COMMITTED
  Building list of tables and columns for tab-completion (set fastconnect to true to skip)...
  96/96 (100%) Done
  Done
  sqlline version 1.1.8
  0: jdbc:phoenix:> !tables
  +------------+---------------+------------------------+---------------+----------+------------+----------------------------+-----------------+--------------+-----------------+---------------+---------------+---+
  | TABLE_CAT  |  TABLE_SCHEM  |       TABLE_NAME       |  TABLE_TYPE   | REMARKS  | TYPE_NAME  | SELF_REFERENCING_COL_NAME  | REF_GENERATION  | INDEX_STATE  | IMMUTABLE_ROWS  | SALT_BUCKETS  | MULTI_TENANT  | V |
  +------------+---------------+------------------------+---------------+----------+------------+----------------------------+-----------------+--------------+-----------------+---------------+---------------+---+
  |            | SYSTEM        | CATALOG                | SYSTEM TABLE  |          |            |                            |                 |              | false           | null          | false         |   |
  |            | SYSTEM        | FUNCTION               | SYSTEM TABLE  |          |            |                            |                 |              | false           | null          | false         |   |
  |            | SYSTEM        | SEQUENCE               | SYSTEM TABLE  |          |            |                            |                 |              | false           | null          | false         |   |
  |            | SYSTEM        | STATS                  | SYSTEM TABLE  |          |            |                            |                 |              | false           | null          | false         |   |
  |            | <username>    | yelp_business          | VIEW          |          |            |                            |                 |              | false           | null          | false         |   |
  +------------+---------------+------------------------+---------------+----------+------------+----------------------------+-----------------+--------------+-----------------+---------------+---------------+---+
  0: jdbc:phoenix:>

Next, you can query the database using SQL queries:

.. code-block:: console

  0: jdbc:phoenix:> select * from "<username>"."yelp_business" limit 10;
  +-------------------------+-----------------------------------------------+----------------------------------------------------------------------------+----------------+----------+---------------+--------------+
  |         ROWKEY          |                    address                    |                                 categories                                 |      city      | is_open  |   longitude   |              |
  +-------------------------+-----------------------------------------------+----------------------------------------------------------------------------+----------------+----------+---------------+--------------+
  | --6MefnULPED_I942VcFNA  | "328 Highway 7 E, Chalmers Gate 11, Unit 10"  | Chinese;Restaurants                                                        | Richmond Hill  | 1        | -79.3996044   | "John's Chin |
  | --7zmmkVg-IMGaXbuVd0SQ  | "16432 Old Statesville Rd"                    | Food;Breweries                                                             | Huntersville   | 1        | -80.843688    | "Primal Brew |
  | --8LPVSo5i0Oo61X01sV9A  | "3941 E Baseline Rd, Ste 102"                 | Orthopedists;Weight Loss Centers;Sports Medicine;Health & Medical;Doctors  | Gilbert        | 1        | -111.7283941  | "Valley Bone |
  | --9QQLMTbFzLJ_oT-ON3Xw  | "1835 E Guadalupe Rd, Ste 106"                | Hair Salons;Beauty & Spas                                                  | Tempe          | 1        | -111.9096233  | "Great Clips |
  | --9e1ONYQuAa-CB_Rrw7Tw  | "3355 Las Vegas Blvd S"                       | Cajun/Creole;Steakhouses;Restaurants                                       | Las Vegas      | 1        | -115.16919    | "Delmonico S |
  | --DaPTJW3-tB1vP-PfdTEg  | "1218 Saint Clair Avenue W"                   | Restaurants;Breakfast & Brunch                                             | Toronto        | 1        | -79.4446742   | "Sunnyside G |
  | --DdmeR16TRb3LsjG0ejrQ  | "3645 Las Vegas Blvd S"                       | Arts & Entertainment;Festivals                                             | Las Vegas      | 1        | -115.1709748  | "World Food  |
  | --EF5N7P70J_UYBTPypYlA  | "24139 Lorain Rd"                             | Beauty & Spas;Nail Salons                                                  | North Olmsted  | 1        | -81.889223    | "MV Nail Spa |
  | --EX4rRznJrltyn-34Jz1w  | "6801 Northlake Mall Dr, Ste 172"             | Shopping;Cosmetics & Beauty Supply;Beauty & Spas                           | Charlotte      | 1        | -80.8512352   | "Bath & Body |
  | --FBCX-N37CMYDfs790Bnw  | "11624 Bermuda Rd"                            | Food;American (New);Nightlife;Bars;Beer;Wine & Spirits;Restaurants         | Henderson      | 1        | -115.1550159  | "The Bar At  |
  +-------------------------+-----------------------------------------------+----------------------------------------------------------------------------+----------------+----------+---------------+--------------+
  10 rows selected (0,234 seconds)
  0: jdbc:phoenix:>
