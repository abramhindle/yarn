#!/usr/bin/perl
#(c) abram hindle 2007
# License: GPL VERSION 2 or greater
use strict;
#
	my ($change,$diff,$scores) = (0,0,0);
	my @diff;
	my @scores;
	my @changes;
	while (my $line = <>) {
		if ($line =~ /^<arch>/) {
			warn "ARCH";
			$change = 1;
			($change,$diff,$scores) = (0,0,0);
			@diff = ();
			@scores = ();
			@changes = ();
			print "="x78,$/;
		} elsif ($line =~ /^<change>/) {
			warn "CHANGE";
			@changes = ();
			$change = 1;
		}
		elsif ($line =~ m#^<change/>#) {
			warn "/CHANGE";
			my $VAR1 = undef;
			my $code = join("",@changes);
			eval $code;
			if ($@) {
				warn $@;
			} else {
				printChange($VAR1);		
			}
			@changes = ();
			$change = 0;
		}
		elsif ($line =~ m#<score>(\d*)</score>#) {
			print "Score: $1$/";
		}
		elsif ($line =~ m#<scoreGraph>(.*)$#) {
			warn "SCOREGRAPH";
			push @scores,"$1$/";
			$scores = 1;
		}
		elsif ($line =~ m#<(/scoreGraph|scoreGraph/)>$#) {
			warn "/SCOREGRAPH @scores";
			printGraph("SCOREGRAPH",@scores);
			@scores = ();
			$scores = 0;
		}
		elsif ($line =~ m#<diff>$#) {
			warn "DIFF";
			@diff = ();
			$diff = 1;
		}
		elsif ($line =~ m#<(/diff|diff/)>(.*)$#) {
			warn "/DIFF @diff";
			printGraph("DIFF",@diff);
			@diff = ();
			$diff = 0;
		}
		elsif ($change) {
			push @changes, $line;
		}
		elsif ($diff) {
			push @diff, $line;
		}
		elsif ($scores) {
			push @scores, $line;
		} else {
			warn "WHAT $line";
		}
	}

sub printGraph {
	my ($title,@lines) = @_;
	print "$title$/";
	print @lines;
}
sub printChange {
	my $VAR1 = shift;
	my $hash = $VAR1->{'HASH'};
	my $time = $VAR1->{'time'};
	my $author = $VAR1->{'AUTHOR'};
	my %files = ();
	my @changes = ();
	my @add =  @{$VAR1->{'add'}};
	my @remove =  @{$VAR1->{'remove'}};
	my @modify =  @{$VAR1->{'modify'}};
	push @changes, @add if @add;
	push @changes, @remove if @remove;
	push @changes, @modify if @modify;
	foreach my $change (@changes) {
		$files{$change->{FILE_NAME}} = $change->{'REV_NUMBER'};
	}
	my %logs = ();
	my %patches = ();
	foreach my $file (keys %files) {
		my $rev = $files{$file};
		my $prev = revDec($rev);
		my $log = `rlog -r$rev $file,v`;
		$log = rlogstrip($log);
		my $cmd = "rcsdiff -r$prev -r$rev $file,v";
		warn $cmd;
		my $patch = `$cmd`;
		$patch = patchstrip($patch);
		$logs{$file} = $log;
		$patches{$file} = $patch;
	}
	my @files = sort keys %files;
	print "HASH: $hash$/";
	print "TIME: $time$/";
	print "AUTHOR: $author$/";
	print "FILES: $/\t".join("$/\t",map { "$_ ".$files{$_}  } @files).$/;
	print "LOGS:$/";
	foreach my $file (@files) {
		print "$file\t$files{$file}:$/";
		print $logs{$file};
		print "____________________$/";
	}
	print "PATCHES:$/";
	foreach my $file (@files) {
		print "$file\t$files{$file}:$/";
		print $patches{$file};
		print "____________________$/";
	}
}

sub revDec {
	my $rev = shift;
	my @rev = split(/\./,$rev);
	my $last = pop @rev;
	$last--;
	push @rev, $last;
	return join('.',@rev);
}
sub rlogstrip {
	my ($line) = @_;
	#$line =~ s/\r\n/\n/g;
	#$line =~ s/\n\r/\n/g;
	#$line =~ s/\r/\n/g;
	my @lines = split($/,$line);
	while (@lines) {
		my $line = shift @lines;
		if (index($line,'----------------------------')!=-1) {
			pop @lines;
			return join($/,@lines).$/;
		}
	}
	return  ();
}
sub patchstrip {
	my ($line) = @_;
	#$line =~ s/\r\n/\n/g;
	#$line =~ s/\n\r/\n/g;
	#$line =~ s/\r/\n/g;
	my @lines = split($/,$line);
	shift @lines; #get rid of ==============
	return join($/,@lines).$/;
}
