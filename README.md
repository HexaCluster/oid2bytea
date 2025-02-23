## PostgreSQL large object to bytea converter

### Description
Program used to convert large objects columns in a PostgreSQL database into
bytea. The corresponding large objects data stored in the pg_largeobject table
will be moved into a newly created bytea column and the old oid column will be
removed. If no table list to convert is provided all columns with the oid data
type will be converted to bytea otherwise all oid columns of the table list
will be converted to bytea. 

```
	ALTER TABLE tb1 ADD COLUMN bytea_col bytea;
	UPDATE tb1 SET bytea_col = lo_get(lo_col);
	ALTER TABLE tb1 DROP COLUMN lo_col;
	ALTER TABLE tb1 rename column bytea_col TO lo_col;
```

Once all large objects are migrated the tool runs the `vacuumlo` command to
remove all orphan large objects from the database.

WARNING: the large object data will be duplicated until the `vacuumlo` command
is runu, be sure to have enough free space.

You may want to run a VACUUM FULL on modified tables to recover space from
the oid column(s).

Also take care in your application that the bytea column(s) are appended at end
of the table so their attribute position number change.

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
usage: oid2bytea -d dbname [options]

options:

  -d, --database DBNAME        database where the migration job must be done.
  -D, --dry-run                do not do anything, just show what will be done.
  -h, --host HOSTNAME          database server host or socket directory.
  -j, --job NUM                use this many parallel jobs to process tables.
  -n, --namespace NAME         process tables created under the given schema.
                               Can be used multiple time.
  -p, --port PORT              database server port number, default: 5432.
  -q, --quiet                  don't display messages issued with the LOG level.
  -t, --table TABLE            migrate oid column(s) of the named relation. Can
                               be used multiple time.
  -u, --user NAME              connect as specified database user.
  -v, --version                show program version.
  -V, --no-vacuumlo            do not run vacuumlo at end to remove orphan
                               large objects.
  --help                       show usage.
  --no-time                    don't show timestamp in log output.
```

### Authors

* Gilles Darold

### License

This extension is free software distributed under the PostgreSQL Licence.

- Copyright (c) 2025, HexaCluster

