## PostgreSQL large object to bytea converter

### Description

Program used to convert large objects columns in a PostgreSQL database into
bytea. Two migration modes are supported: local and remote.

#### local

The corresponding large objects data stored in the pg_largeobject table
will be moved into a newly created bytea column and the old oid column will be
removed. If no table list to convert is provided all columns with the oid data
type will be converted to bytea otherwise all oid columns of the table list
will be converted to bytea. 
```
	ALTER TABLE tb1 ADD COLUMN bytea_col bytea;
	UPDATE tb1 SET bytea_col = lo_get(lo_col);
	UPDATE tb1 AS t1 SET bytea_col = lo_get(lo_col)
		FROM pg_largeobject_metadata t2
		WHERE t2.oid = t1.lo_col;
	ALTER TABLE tb1 DROP COLUMN lo_col;
	ALTER TABLE tb1 RENAME COLUMN bytea_col TO lo_col;
```
Once all large objects are migrated the tool runs the vacuumlo command to
remove all orphan large objects from the database.

Note that all missing large object will not report error due to the JOIN in the
update statement but you can find them look for NULL in the bytea column.

WARNING: the large object data will be duplicated until the `vacuumlo` command
is run, be sure to have enough free space.

You may want to run a VACUUM FULL on modified tables to recover space from
the oid column(s).

Also take care in your application that the bytea column(s) are appended at end
of the table so their attribute position number change.

Be adviszd to make a backup of your tables with large objects oid columns before
running this tool. They will be dropped unless you use the `--no-drop` option.

#### Remote

in this mode oid2bytea will migrate the local oid column to a remote database
with the same structure except that the oid column have been replaced by a bytea
column of the same name. To use the remote mode you just have to set the remote
command line options (`-D`, `-H`, `-P`, `-U`). The all the data of the table with the oid
column(s) will be moved and the oid replaced by the content of the large object
before being sent to the remote database.

Note that missing large objects will throw an error and the data migration will
be aborted for the table. To verify first if the table has no missing large
objects run the command with the `--missing` option.

### Multiprocess

The two modes can benefit of high speed migration by parallelizing tables
migration using the `-j` option. With table with huge amount of rows it is also
possible to parallelize rows export of a single table by using the `-J` option.
The value for these option is the number of processes/CPUs you want to use to
process the data.  Take care that the resulting number of processes/CPUs used
is `-j * -J`.

### Transform function

Using the `-f` option it is possible to use a function to process the data before
inserting in the new column. For example, if all your large objects data have
been compressed using gzip, you may want to uncompress the bytea data to benefit
of the PostgreSQL native toast compression. In this case, install extension
[psql-gzip](https://github.com/pramsey/pgsql-gzip) in the source database and
use `-f gunzip` at command line.

Another example of use is to convert the large objects to a text column if all
the data are text data. In this case use `-f "encode(%, 'escape')"` at command
line and oid2bytea will replace the % placeholder by the call to `lo_get()` with
the name of the column processed.

### Requirements

oid2bytea is a Perl program that require the following Perl modules:

- Time::HiRes
- DBI
- DBD::Pg

Your Linux distribution must already have binary packages but all Perl modules
are available on [CPAN](https://www.cpan.org/)

### Tests

Just execute the following command: `prove`

### Utilization

```
Usage: oid2bytea -d dbname [options]

options:

  -d, --database DBNAME      database where the migration job must be done.
  -D, --dest-database DBNAME database where the migration data must be sent.
  -f, --function FCTNAME     use this function to process the bytea returned
                             by the call to lo_get(). It must return a bytea
			     or the data type of the destination column.
  -h, --host HOSTNAME        database server host or socket directory.
  -H, --dest-host HOSTNAME   remote database server host or socket directory.
  -j, --job NUM              use this many parallel jobs to process all tables.
  -J, --job-split NUM        use this many parallel jobs to process single table
  -m, --missing              show missing large objects for a table and do not
                             perform any migration.
  -n, --namespace NAME       process tables created under the given schema.
                             Can be used multiple time.
  -p, --port PORT            database server port number, default: 5432.
  -P, --dest-port PORT       database server port number, default: 5432.
  -q, --quiet                don't display messages issued with the LOG level.
  -t, --table TABLE          migrate oid column(s) of the named relation. Can
                             be used multiple time.
  -u, --user NAME            connect as specified database user.
  -U, --dest-user NAME       remote connect as specified database user.
  -v, --version              show program version.
  -V, --no-vacuumlo          do not run vacuumlo at end to remove orphan large
                             objects.
  --help                     show usage.
  --no-drop                  don't drop the oid column, rename it to oid_colN
                             instead. N depends on the number of the oid column.
  --no-time                  don't show timestamp in log output.
  --dry-run                  do not do anything, just show what will be done.
```

### Authors

Created and maintained by Gilles Darold

### License

This extension is free software distributed under the PostgreSQL Licence.

- Copyright (c) 2025, HexaCluster

