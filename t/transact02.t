#!/usr/bin/perl -w
#
#	@(#)$Id: transact02.t,v 57.1 1997/07/29 01:24:32 johnl Exp $ 
#
#	Test AutoCommit On for DBD::Sqlflex
#
#	Copyright (C) 1996,1997 Jonathan Leffler

# AutoCommit On => Each statement is a self-contained transaction

use DBD::SqlflexTest;

# Test install...
$dbh = &connect_to_test_database(1);

if ($dbh->{ix_LoggedDatabase} == 0)
{
	&stmt_note("1..1\n");
	&stmt_note("# No transactions on unlogged database '$dbh->{Name}'\n");
	&stmt_ok(0);
	&all_ok();
}

&stmt_note("1..13\n");
&stmt_ok();
if ($dbh->{ix_ModeAnsiDatabase})
{ &stmt_note("# This is a MODE ANSI database\n"); }
else
{ &stmt_note("# This is a regular logged database\n"); }

$ac = $dbh->{AutoCommit} ? "On" : "Off";
print "# Default AutoCommit is $ac\n";
$dbh->{AutoCommit} = 1;
$ac = $dbh->{AutoCommit} ? "On" : "Off";
print "# AutoCommit was set to $ac\n";

$trans01 = "DBD_IX_Trans01";
$select = "SELECT * FROM $trans01";

stmt_test $dbh, qq{
CREATE TEMP TABLE $trans01
(
	Col01	SERIAL NOT NULL,
	Col02	CHAR(20) NOT NULL,
	Col03	DATE NOT NULL,
	Col04	DATETIME NOT NULL YEAR TO FRACTION(5)
)
};

# How to insert date values even when you can't be bothered to sort out
# what DBDATE will do...  You cannot insert an MDY() expression directly.
$sel1 = "SELECT '12/12/1996' FROM informix.SysTables WHERE Tabid = 1";
&stmt_fail() unless ($st1 = $dbh->prepare($sel1));
&stmt_fail() unless ($st1->execute);
&stmt_fail() unless (@row = $st1->fetchrow);
undef $st1;

# Confirm that table exists but is empty (the rollback cancels an empty
# transaction in a MODE ANSI database, but fails on a ordinary logged DB).
&stmt_fail() unless ($dbh->{ix_ModeAnsiDatabase} == 0 || $dbh->rollback());
select_zero_data $dbh, $select;

$date = $row[0];
$tag1  = 'Elfdom';
$insert01 = qq{INSERT INTO $trans01
VALUES(0, '$tag1', '$date', '1997-01-01 12:12:12.12345')};

stmt_test $dbh, $insert01;

select_some_data $dbh, 1, $select;

# Insert two more rows of data.
stmt_test $dbh, $insert01;
$tag2 = 'Santa Claus Home';
$insert01 =~ s/$tag1/$tag2/;
stmt_test $dbh, $insert01;

# Check that there is some data
select_some_data $dbh, 3, $select;

# Insert another two rows of data.
stmt_test $dbh, $insert01;
$tag2 = 'Santa Claus Home';
$insert01 =~ s/$tag2/$tag1/;
stmt_test $dbh, $insert01;

# Check that there is some data
select_some_data $dbh, 5, $select;

# Delete the data.
stmt_test $dbh, "DELETE FROM $trans01";

# Check that there is no data
select_zero_data $dbh, $select;

&all_ok();
