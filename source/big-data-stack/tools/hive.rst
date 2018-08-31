.. warning::

  Remember that for interacting with EDI Big Data Stack you must be
  authenticated at the system using `kinit` command. For more information, read
  the documentation at :ref:`authenticating-with-kerberos`.

Hive
====

Hive allows executing querying files stored at a distributed storage with a
SQL-like language name HQL (Hive Query Language). In this tutorial we explain
how to use Hive with sample files introduced in :ref:`hdfs` within EDI Big Data
Stack.

.. note::
  If you need a new Hive database, you need to contact with :ref:`technical-support` for
  creating the database and give you the proper permissions. Once you have your
  database set, you can continue with this tutorial. For avoiding conflicts, all
  databases must follow the `username_databasename` convention.


For connecting to the Hive database `test_yelp`, we must execute the `beeline` client with the following
parameters:

.. code-block:: console

  # beeline -u "jdbc:hive2://<hive_host>:10000/test_yelp;principal=hive/<hive_host>@HDP.REALM;"
  Connecting to jdbc:hive2://<hive_host>:10000/test_yelp;principal=hive/<hive-hist>@HDP.REALM;
  Connected to: Apache Hive (version 1.2.1000.2.6.4.0-91)
  Driver: Hive JDBC (version 1.2.1000.2.6.4.0-91)
  Transaction isolation: TRANSACTION_REPEATABLE_READ
  Beeline version 1.2.1000.2.6.4.0-91 by Apache Hive
  0: jdbc:hive2://<hive_host>:10000/test_yelp>

.. warning::
  For security reasons, `hive` client is not available for its usage on EDI
  Big Data Stack, being the new client `beeline` the one to be used.

Before creating the Hive table, we must copy the desired CSV to an independent
folder, as Hive ingests all files in a folder:

.. code-block:: console

  # hdfs dfs -mkdir /user/<username>/samples/hive/
  # hdfs dfs -mkdir /user/<username>/samples/hive/yelp_business
  # hdfs dfs -cp /user/<username>/samples/yelp_business.csv /user/<username>/samples/hive/yelp_business

First we need to create table `yelp_business`. As we want to ingest CSV data, we
are going to use `Hive CSV Serde <https://cwiki.apache.org/confluence/display/Hive/CSV+Serde>`_:

.. code-block:: SQL

    CREATE EXTERNAL TABLE IF NOT EXISTS yelp_business (
      business_id string,
      name string,
      neighborhood string,
      address string,
      city string,
      state string,
      postal_code int,
      latitude double,
      longitude double,
      stars float,
      review_count int,
      is_open boolean,
      categories string
    )
    ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
    WITH SERDEPROPERTIES (
       "separatorChar" = ",",
       "quoteChar"     = '"',
       "escapeChar"    = '"'
    )
    STORED AS TEXTFILE
    LOCATION '/user/<username>/samples/hive/yelp_business'
    TBLPROPERTIES("skip.header.line.count"="1");


Once the data has been imported from the CSV into the table you can execute SQL
commands to query the data

.. code-block:: SQL

  select business_id, name, city, state from yelp_business limit 20;

.. code-block:: console

  No rows affected (0.412 seconds)
  0: jdbc:hive2://<hive_host>:10000/test_y>
  +-------------------------+-------------------------------+-----------------+--------+--+
  |       business_id       |             name              |      city       | state  |
  +-------------------------+-------------------------------+-----------------+--------+--+
  | FYWN1wneV18bWNgQjJ2GNg  | "Dental by Design"            | Ahwatukee       | AZ     |
  | He-G7vWjzVUysIKrfNbPUQ  | "Stephen Szabo Salon"         | McMurray        | PA     |
  | KQPW8lFf1y5BT2MxiSZ3QA  | "Western Motor Vehicle"       | Phoenix         | AZ     |
  | 8DShNS-LuFqpEWIp0HxijA  | "Sports Authority"            | Tempe           | AZ     |
  | PfOCPjBrlQAnz__NXj9h_w  | "Brick House Tavern + Tap"    | Cuyahoga Falls  | OH     |
  | o9eMRCWt5PkpLDE0gOPtcQ  | "Messina"                     | Stuttgart       | BW     |
  | kCoE3jvEtg6UVz5SOD3GVw  | "BDJ Realty"                  | Las Vegas       | NV     |
  | OD2hnuuTJI9uotcKycxg1A  | "Soccer Zone"                 | Las Vegas       | NV     |
  | EsMcGiZaQuG1OOvL9iUFug  | "Any Given Sundae"            | Wexford         | PA     |
  | TGWhGNusxyMaA4kQVBNeew  | "Detailing Gone Mobile"       | Henderson       | NV     |
  | XOSRcvtaKc_Q5H1SAzN20A  | "East Coast Coffee"           | Houston         | PA     |
  | Y0eMNa5C-YU1RQOZf9XvVA  | "CubeSmart Self Storage"      | Chandler        | AZ     |
  | xcgFnd-MwkZeO5G2HQ0gAQ  | "T & T Bakery and Cafe"       | Markham         | ON     |
  | NmZtoE3v8RdSJEczYbMT9g  | "Complete Dental Care"        | Homestead       | PA     |
  | fNMVV_ZX7CJSDWQGdOM8Nw  | "Showmars Government Center"  | Charlotte       | NC     |
  | l09JfMeQ6ynYs5MCJtrcmQ  | "Alize Catering"              | Toronto         | ON     |
  | IQSlT5jGE6CCDhSG0zG3xg  | "T & Y Nail Spa"              | Peoria          | AZ     |
  | b2I2DXtZVnpUMCXp1JON7A  | "Meineke Car Care Center"     | Sun Prairie     | WI     |
  | 0FMKDOU8TJT1x87OKYGDTg  | "Senior's Barber Shop"        | Goodyear        | AZ     |
  | Gu-xs3NIQTj3Mj2xYoN2aw  | "Maxim Bakery & Restaurant"   | Richmond Hill   | ON     |
  +-------------------------+-------------------------------+-----------------+--------+--+
  20 rows selected (0.115 seconds)
  0: jdbc:hive2://<hive_host>:10000/test_y>

Next, we can execute SQL queries over the table. In our case, we want to get the
ordered list of states with most businesses:

.. code-block:: SQL

  select state, count(state) as count from yelp_business group by state order by count desc;

.. code-block:: console

  INFO  : Session is already open
  INFO  : Dag name: select state, count(state) as count f...desc(Stage-1)
  INFO  : Status: Running (Executing on YARN cluster with App id application_1523347765873_0016)

  --------------------------------------------------------------------------------
        VERTICES      STATUS  TOTAL  COMPLETED  RUNNING  PENDING  FAILED  KILLED
  --------------------------------------------------------------------------------
  Map 1 ..........   SUCCEEDED      1          1        0        0       0       0
  Reducer 2 ......   SUCCEEDED      1          1        0        0       0       0
  Reducer 3 ......   SUCCEEDED      1          1        0        0       0       0
  --------------------------------------------------------------------------------
  VERTICES: 03/03  [==========================>>] 100%  ELAPSED TIME: 4.04 s
  --------------------------------------------------------------------------------
  +--------+--------+--+
  | state  | count  |
  +--------+--------+--+
  | AZ     | 52214  |
  | NV     | 33086  |
  | ON     | 30208  |
  | NC     | 12956  |
  | OH     | 12609  |
  | PA     | 10109  |
  | QC     | 8169   |
  | WI     | 4754   |
  | EDH    | 3795   |
  | BW     | 3118   |
  | IL     | 1852   |
  | SC     | 679    |
  | MLN    | 208    |
  | HLD    | 179    |
  | NYK    | 152    |
  | CHE    | 143    |
  | FIF    | 85     |
  | ELN    | 47     |
  | WLN    | 38     |
  | C      | 28     |
  | NY     | 18     |
  | ESX    | 12     |
  | ST     | 11     |
  | NI     | 10     |
  | 01     | 10     |
  | VS     | 7      |
  | SCB    | 5      |
  | CA     | 5      |
  | BY     | 4      |
  | XGL    | 4      |
  | IN     | 3      |
  | ABE    | 3      |
  | GLG    | 3      |
  | 6      | 3      |
  | VT     | 2      |
  | CMA    | 2      |
  | NTH    | 2      |
  | FLN    | 2      |
  | CO     | 2      |
  | AR     | 2      |
  |        | 1      |
  | 3      | 1      |
  | 30     | 1      |
  | AB     | 1      |
  | AK     | 1      |
  | AL     | 1      |
  | B      | 1      |
  | CS     | 1      |
  | DE     | 1      |
  | FAL    | 1      |
  | FL     | 1      |
  | GA     | 1      |
  | HU     | 1      |
  | KHL    | 1      |
  | KY     | 1      |
  | MN     | 1      |
  | MT     | 1      |
  | NE     | 1      |
  | NLK    | 1      |
  | PKN    | 1      |
  | RCC    | 1      |
  | SL     | 1      |
  | STG    | 1      |
  | TAM    | 1      |
  | VA     | 1      |
  | WA     | 1      |
  | WHT    | 1      |
  | ZET    | 1      |
  +--------+--------+--+
  68 rows selected (6.436 seconds)
  0: jdbc:hive2://<hive_host>:10000/test_>

.. note::

  In addition to CLI tools, you can query Hive databases using :ref:`hiveview`.
