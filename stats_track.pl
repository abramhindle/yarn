#!/usr/bin/perl
# GPL Version 2 or greater
# (c) 2007 Ahmed Hassan

use strict;
use warnings;

use Time::Local;

# $[0]: the file name storing all the historical data 
# 		(revisions are grouped in transactions)
# $[1]: symbol_table, name => type => file_name
sub readHistoryDB {
	my ($history_db_file, $time_interval, $start_time, $end_time) = @_;

	my ($num_commits, $num_files, $num_add_ent, $num_modify_ent, $num_remove_ent, $num_functions, $num_non_functions, $num_ent);
	my ($total_commits, $total_files, $total_add_ent, $total_modify_ent, $total_remove_ent, $total_functions, $total_non_functions, $total_ent);

	my (%hash_time, %hash_commits, %hash_files, %hash_add_ent, %hash_modify_ent, %hash_remove_ent, %hash_functions, %hash_non_functions, %hash_ent);


	my ($stop, $index, $line, @contents, $file_count, $time, $hash, $author, $type, $keywords);

	open (HISTORY_DB, "$history_db_file") or die "Cannot open $history_db_file, reason: $!";

	@contents = <HISTORY_DB>;
	$index = 0;

	$num_commits = 0;
	$num_files = 0;
	$num_add_ent = 0;
   	$num_modify_ent = 0;
	$num_remove_ent = 0;
	$num_functions = 0;
	$num_non_functions = 0;
	$num_ent = 0;

	$total_commits = 0;
	$total_files = 0;
	$total_add_ent = 0;
   	$total_modify_ent = 0;
	$total_remove_ent = 0;
	$total_functions = 0;
	$total_non_functions = 0;
	$total_ent = 0;

	%hash_time = ();
	%hash_commits = ();
	%hash_files = ();
	%hash_add_ent = ();
   	%hash_modify_ent = ();
	%hash_remove_ent = ();
	%hash_functions = ();
	%hash_non_functions = ();
	%hash_ent = ();

	while ($index <= $#contents) {
		$line = $contents[$index];
		if ($line =~ m/<ADD_TYPE NAME=\"([^\"]*)\" TYPE=\"([^\"]*)\" FILE=\"([^\"]*)\">/) {
			# symbol table
			$index++;
		} elsif ($line =~ m/<CHANGELIST_DETAILS FILE_COUNT=\"([^\"]*)\" TIME=\"([^\"]*)\" HASH=\"([^\"]*)\" AUTHOR=\"([^\"]*)\" TYPE=\"([^\"]*)\" KEYWORDS=\"([^\"]*)\">/) {
			$file_count = $1;
			$time = $2;
			$hash = $3;
			$author = $4;
			$type = $5;
			$keywords = $6;
# print STDERR "1111 $rev_file_count=$rev_time=$rev_hash=$rev_author=$rev_type=$rev_keywords\n";

			$index++;
			$stop = 0;

			$num_files = $file_count;
			$num_commits = 1;
			$num_add_ent = 0;
		   	$num_modify_ent = 0;
			$num_remove_ent = 0;
			$num_functions = 0;
			$num_non_functions = 0;
			$num_ent = 0;

			while ($index <=$#contents and $stop <= 0) {
				$line = $contents[$index];
				if ($line =~ m/<\/CHANGELIST_DETAILS>/) {
					$stop++;
				} else {
					if ($line =~ m/<ADD_ENT/) {
						$num_add_ent++;
					} elsif ($line =~ m/<MODIFY_ENT/) {
						$num_modify_ent++;
					} elsif ($line =~ m/<REMOVE_ENT/) {
						$num_remove_ent++;
					} 
					$num_ent++;
		
					if ($line =~ m/TYPE="function"/) {
						$num_functions++;
					} else {
						$num_non_functions++;
					}
				}
				$index++;
			}

			$hash_time{$time}{$hash}++;
			$hash_files{$hash} = $num_files;
			$hash_commits{$hash} = $num_commits;
			$hash_add_ent{$hash} = $num_add_ent;
		   	$hash_modify_ent{$hash} = $num_modify_ent;
			$hash_remove_ent{$hash} = $num_remove_ent;
			$hash_functions{$hash} = $num_functions;
			$hash_non_functions{$hash} = $num_non_functions;
			$hash_ent{$hash} = $num_ent;
		} elsif ($line =~ /[^\s]+/) {
			die "Bad data: $line\n";
		} else {
			chomp $line;
			# a blank line maybe??
			$index++;
		}
	}

	close HISTORY_DB;

	my ($before_time, $after_time, %rev_time_hash, $rev_time, $temp_hash, $temp_count, $count);

	my @name_sort_by_rev_time = sort {$a <=> $b} keys %hash_time;

	foreach $rev_time (@name_sort_by_rev_time) {
		$rev_time_hash{$rev_time}++;
	}

	$before_time = $start_time;
	$after_time = $before_time + $time_interval;

	while ($before_time <= $end_time) {
		$total_files = 0; 
		$total_commits = 0;
		$total_add_ent = 0;
		$total_modify_ent = 0;
		$total_remove_ent = 0;
		$total_functions = 0;
		$total_non_functions = 0;
		$total_ent = 0;

		while (($rev_time, $count) = (each %rev_time_hash)) {
			if ($rev_time <= $after_time and $rev_time >= $before_time) {
				$temp_hash = $hash_time{$rev_time};
				while (($hash, $temp_count) = (each %$temp_hash)) {
					$total_files = $total_files + $hash_files{$hash};
					$total_commits = $total_commits + $hash_commits{$hash};
					$total_add_ent = $total_add_ent + $hash_add_ent{$hash};
				   	$total_modify_ent = $total_modify_ent + $hash_modify_ent{$hash};
					$total_remove_ent = $total_remove_ent + $hash_remove_ent{$hash};
					$total_functions = $total_functions + $hash_functions{$hash};
					$total_non_functions = $total_non_functions + $hash_non_functions{$hash};
					$total_ent = $total_ent + $hash_ent{$hash};
				}
			}
		}

		print "$total_files, $total_commits, $total_add_ent, $total_modify_ent, $total_remove_ent, $total_functions, $total_non_functions, $total_ent\n";
		$before_time = $after_time;
		$after_time = $before_time + $time_interval;
	}
}

my ($time_interval, $start_time, $end_time, $comment_decay_interval);
 
$start_time = &timelocal(0, 0, 0, 1, 1, 1996);
$end_time = &timelocal(0, 0, 0, 1, 9, 2005);

# after 3*90 days 
$time_interval = 3 * 30 * 24 * 60 * 60;

# after 30 days 
# $time_interval = 30 * 24 * 60 * 60;

my ($HISTORY_DB_FILE, %HISTORICAL_SYMBOL_TABLE, %NAME_TYPE,
	%REV_FILE_COUNT, %REV_TIME, %REV_HASH, %REV_AUTHOR, %REV_TYPE, %REV_KEYWORDS, 
	%ADD_ENT_NAME, %ADD_ENT_TYPE, %ADD_PARAM_KEYWORDS, %ADD_TYPE_INFO_KEYWORDS, 
		%ADD_COMMENT_KEYWORDS, %ADD_FILE_NAME, %ADD_CODE_KEYWORDS, %ADD_CONTROL_KEYWORDS,
		%ADD_REV_NUMBER,
	%MODIFY_ENT_NAME, %MODIFY_ENT_TYPE, %MODIFY_PARAM_KEYWORDS, %MODIFY_TYPE_INFO_KEYWORDS, 
		%MODIFY_COMMENT_KEYWORDS, %MODIFY_FILE_NAME, %MODIFY_CODE_KEYWORDS, %MODIFY_CONTROL_KEYWORDS,
		%MODIFY_REV_NUMBER,
	%REMOVE_ENT_NAME, %REMOVE_ENT_TYPE, %REMOVE_PARAM_KEYWORDS, %REMOVE_TYPE_INFO_KEYWORDS, 
		%REMOVE_COMMENT_KEYWORDS, %REMOVE_FILE_NAME, %REMOVE_CODE_KEYWORDS, %REMOVE_CONTROL_KEYWORDS,
		%REMOVE_REV_NUMBER);

$HISTORY_DB_FILE = $ARGV[0];

&readHistoryDB($HISTORY_DB_FILE, $time_interval, $start_time, $end_time);

