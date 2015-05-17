#!/usr/bin/perl
#GPL V2 Or Later
#(C) 2007 Abram Hindle
use XML::Parser;
use POSIX;
use Data::Dumper;
use Contains;
use ModuleGraph;
use Fatal qw(open close);
use strict;

my $default_depth = 3;


warn "READ SYMBOLS";
my $symbols = readSymbols("../data/symbol_table.txt",function=>1);

warn "MODULE TREE";
my $contains = readModules($symbols,"../data/modules.txt");
{
	open(my $fd,">","tree");
	print $fd $contains->getTree;
	close($fd);
}
{
	open(my $fd,">","contains");
	print $fd join($/,$contains->getContain);
	close($fd);
}
#die Dumper($contains);
containsTest($contains);

warn "CHANGES";
my $changes = readChangeList(symbols=>$symbols,contains=>$contains,filename=>"../data/history.txt");
open(FILE,">","changes");
print FILE Dumper($_) foreach (@$changes);
close(FILE);
my @exclusions = qw( /include/ .h);
#my @exclusions; #= qw( /include/ .h);

warn "FILTERING CHANGES";
my @filtered = grep { isValuableChangeUpperCase($contains,$symbols,$_,@exclusions) > 0.1 } @$changes;
open(FILE,">","filteredchanges");
print FILE Dumper($_) foreach (@filtered);
close(FILE);

#setDebug(1);

warn "HISTODIFF.ALLORNONE";
#histoDiff($contains,$symbols,$changes,"histodiff");
histoDiff(
	contains=>$contains,
	symbols=>$symbols,
	changes=>$changes,
	outfile=>"histodiff.allornone",
	scorefunction=>\&allOrNoneScoring,
);
warn "HISTODIFF.ALLORNONEDOUBLE";
my $doubles = histoDiff(
	contains=>$contains,
	symbols=>$symbols,
	changes=>$changes,
	outfile=>"histodiff.allornonedouble",
	scorefunction=>\&allOrNoneDoubleScoring,
);

saveoutDoubles($doubles); 

sub saveoutDoubles {
	my $doubles = shift;
	my @grepped = grep {$_->getScore() > 0} @$doubles;
	my $len = @grepped;
	my $total = POSIX::ceil($len / 3);
	my  @doubles = ([@grepped[0..($total-1)]],
			[@grepped[$total..(2*$total-1)]],
			[@grepped[(2*$total)..($len-1)]]
	);
	my $d = 0;
	foreach my $double (@doubles) {
		open(my $fd,">","doubles.$d");
		foreach my $curr (@$double) {
			dumpGraph($fd,$curr->getChanges(),$curr);
		}
		close($fd);
		$d++;
	}
}
sub getAllChanges {
	my $change = shift;
	my @changes = @{$change->{modify}};
	push @changes , @{$change->{add}};
	push @changes , @{$change->{remove}};
	return @changes;
}
sub allOrNoneScoring {
	my ($oedge,$nedge,$curr,$last,$points) = @_;
	if ($nedge != $oedge && $nedge <= 0 || $oedge <= 0 ) {
		$points++;
	}
	return $points;
}
sub allOrNoneDoubleScoring {
	my ($oedge,$nedge,$curr,$last,$points) = @_;
	if ($nedge != $oedge && $nedge <= 0 || $oedge <= 0 || $nedge <= $oedge / 2 || $nedge >= $oedge * 2) {
		$points++;
	}
	return $points;
}
sub getOrDie {
	my ($key,%hash) = @_;
	die "$key not defined" if (!defined($key));
	return $hash{$key};
}
sub histoDiff {
	my %hash = @_;
	my $contains = getOrDie('contains',%hash);
	my $symbols = getOrDie('symbols',%hash);
	my $changes = getOrDie('changes',%hash);
	my $outfile = getOrDie('outfile',%hash);
	my $scorefunction = $hash{scorefunction} || \&allOrNoneScoring;
	my @exclude = @{($hash{exclude}||[])} || ();

	my $last = undef;
	my $curr = ModuleGraph->new();
	my @graphs = ();
	open(my $fd,">",$outfile);
	open(my $fdg,">",$outfile.".graphs");
	print $fdg "<history>$/";
	my $cnt = 0;
	my $fgraph = ModuleGraph->new();
	foreach my $change (@$changes) {
		$last = $curr;
		$curr = $last->copy();
		my $points = 0;
		my @changes = getAllChanges($change);
		my $dgraph = ModuleGraph->new();
		my $sgraph = undef;
		foreach my $a (@changes) {
			my $afile = fileFilter($a->{FILE_NAME});
			#my ($cb) = $contains->findUpperCaseParent(fileFilter($afile));
			my $cb = findUpperAndVivify($contains,$afile);
			warn "No Upper Case Parent?? $afile $cb" if !$cb;
			my ($deps,$udeps) = resolveUpperDep($contains,$a,@exclude);
			while (my ($k,$v) = each %$deps) {
				$fgraph->modifyEdge($afile,$k,$v);
			}
			while (my ($k,$v) = each %$udeps) {
				my $oedge = $last->getEdge($cb,$k);
				debugwarn("[$cb] [$k] [$v]");
				warn "[$cb] [$k] [$v] [$afile]"  if ($cb eq 'ROOT');
				$curr->modifyEdge($cb,$k,$v);
				$dgraph->modifyEdge($cb,$k,$v);
				my $nedge = $curr->getEdge($cb,$k);
				my $npoints = &$scorefunction($oedge,$nedge,$last,$curr,$points);
				my $dp = $npoints - $points;
				if ($dp) {
					$sgraph = ModuleGraph->new() unless $sgraph;
					$sgraph->modifyEdge($cb,$k,$v);
				}
				$points = $npoints;
			}
		}
		$curr->setChanges($change);
		$curr->setDiff($dgraph);
		$curr->setScoringGraph($sgraph) if $sgraph;
		$curr->setScore($points);
		dumpGraph($fd,$change,$curr);
		lightGraph($fdg,$change,$curr);
		open(my $ffd,">","$outfile.$cnt.rsf");
		print $ffd $fgraph->dumpRSF();
		close($ffd);
		push @graphs,$curr;
		$cnt++;
	}
	close($fd);
	print $fdg "$/</history>$/";
	close($fdg);
	return \@graphs;
}
sub dumpGraph {
	my ($fd,$change,$curr) = @_;
	print $fd "<arch>$/";
	print $fd "<change>$/";
	print $fd Dumper($change);
	print $fd "</change>$/";
	print $fd "<score>".$curr->getScore()."</score>$/";
	print $fd "<scoreGraph>".$curr->getScoringGraph()->dump()."</scoreGraph>$/" if $curr->getScoringGraph();
	print $fd "<diff>$/".$curr->getDiff()->dump()."</diff>$/";
	print $fd $curr->dump;
	print $fd "</arch>$/";
}
#dump a lighter format
sub lightGraph {
	my ($fd,$change,$curr) = @_;
	print $fd "<arch>$/";
	print $fd "<time>".$change->{'time'}."</time>$/";
	print $fd "<score>".$curr->getScore()."</score>$/";
	print $fd "<scoreGraph>$/".$curr->getScoringGraph()->dump()."</scoreGraph>$/" if $curr->getScoringGraph();
	print $fd "<diff>$/".$curr->getDiff()->dump()."</diff>$/";
	print $fd "<graph>$/";
	print $fd $curr->dump;
	print $fd "</graph>$/";
	print $fd "</arch>$/";
}

sub isValuableChange {
	my ($contains,$symbols,$change) = @_;
	my @changes = getAllChanges($change);
	my %deps = ();
	foreach my $a (@changes) {
		my $afile = $a->{FILE_NAME};
		my ($cb) = $contains->containedBy(fileFilter($afile));
		my $adeps = $a->{depend};
		die unless $adeps;
		#warn Dumper($adeps);
		#warn "$cb $afile";
		foreach my $file (keys %$adeps) {
			$file = fileFilter($file);
			my ($fb) = $contains->containedBy($file);
			#warn "[$cb $afile] [$fb $file]";
			next if ($file eq $afile);
			next if ($file eq $cb);
			next if ($fb eq $cb);
			$deps{$file}++;
		}
	}
	return scalar(keys %deps);
}
sub debug {
	return $::debug;
}
sub debugwarn {
	if (debug()) { warn @_; }
}
sub setDebug {
	return ($::debug = $_[0]);
}
sub findUpperAndVivify {
	my ($contains,$file) = @_;
	my $file = fileFilter($file);
	unless ($contains->has($file)) {
		$contains->moduleVivify($file);
	}
	my ($cb) = $contains->findUpperCaseParent($file);
	if (!$cb) {
		warn "$file hadn't been vivified ["
			.$contains->has($file)."]"
			.join(" ",$contains->containedBy($file))
			.join(" ",$contains->contains($file));
		$contains->moduleVivify($file);
		($cb) = $contains->findUpperCaseParent(fileFilter($file));
		die "$file could not resolve parent after vivification" unless $cb;
	}
	return $cb;
}
sub resolveUpperDep {
	my ($contains,$change,@exclude) = @_;
	my %deps = ();
	my %udeps = ();
	my $a = $change;
	my $afile = fileFilter($a->{FILE_NAME});
	my $cb = findUpperAndVivify($contains,$afile);
	my $adeps = $a->{depend};
	die unless $adeps;
	while (my ($file,$count) = each %$adeps) {
		$file = fileFilter($file);
		my $next = 0;
		foreach (@exclude) {
			if (-1 != index($file,$_)) {
				$next = 1; last;
			}
		}
		next if $next;
		#my ($fb) = $contains->findUpperCaseParent($file);
		my $fb = findUpperAndVivify($contains,$file);

		next if ($file eq $afile);
		next if ($file eq $cb);
		next if ($fb eq $cb);
		if (debug()) {
			warn "[$file] [$fb] $count";
		}
		$deps{$file}+=$count;
		$udeps{$fb}+=$count;
	}
	return (\%deps,\%udeps);
}
sub getChangeDeps {
	my ($contains,$change,@exclude) = @_;
	my @changes = getAllChanges($change);
	my %deps = ();
	my %udeps = ();
	foreach my $a (@changes) {
		my ($deps2,$udeps2) = resolveUpperDep($contains,$a,@exclude);
		while (my ($k,$v) = each %$deps2) {
			$deps{$k} += $v;
		}
		while (my ($k,$v) = each %$udeps2) {
			$udeps{$k} += $v;
		}
	}
	return (\%deps,\%udeps);
}
sub isValuableChangeUpperCase {
	my ($contains,$symbols,$change,@exclude) = @_;
	#warn $change->{TIME};
	my ($deps,$udeps) = getChangeDeps($contains,$change,@exclude);
	$change->{totaldeps} = $deps;
	$change->{totalUpperDeps} = $udeps;
	my @keys = keys %$deps;
	return @keys if wantarray;
	return scalar(@keys);
}


#updateSymbols($symbols,$modules);
#my @keys = keys %{$symbols};
#my $key = $keys[rand(scalar @keys)];
#print Dumper($symbols);
sub fileFilter {
	my ($a,$prefix) = @_;
	$prefix = $prefix || "./";
	if (0 == index($a,$prefix)) {
		$a = substr($a,length($prefix));
	}
	$a =~ s/^\\/\//;
	return $a;
}
#READ SYMBOL TABLE
sub readSymbols {
	my ($filename,%types) = @_;
	if (!keys %types) {
		foreach (qw( DEAD externvar function INDENT INITIAL macro NEW prototype struct typedef UNKNOWN variable)) {
			$types{$_} = 1;
		}
	}
	my %symbols = ();
	my $start = sub {
		#(Expat, Element [, Attr, Val [,...]])
		my ($parser,$elm,%attr) = @_;
		#ADD_TYPE NAME,WRONG,TYPE,macro,FILE,./postgres/pgsql/src/timezone/localtime.c
		#print "$elm ".join(",",@what).$/;
		return unless ($elm eq "ADD_TYPE");
		#$symbols{$attr{NAME}}->{$attr{TYPE}} = fileFilter($attr{FILE});
		if ($attr{TYPE} eq "function") {
			$symbols{$attr{NAME}}->{$attr{TYPE}} = fileFilter($attr{FILE});
		}
	};
	my $end = sub {};
	my $char = sub {};
	my $parser = new XML::Parser( Handlers => {
			Start => $start,
			End   => $end,
			Char  => $char,
		}
	);
	eval {
		$parser->parsefile($filename);
	};
	if ($@) {
		warn "PARSER: $@";
	}
	return \%symbols;
}
#assume ./ prefix
sub readModules {
	my ($symbols,$file,$prefix) = @_;
	$prefix = $prefix || "./";
	my $contains = Contains->new();
	my $adder;
	$adder = sub {
		$contains->addContains(@_);
	};
	open(my $fd,$file);
	while(<$fd>) {
		if (/^(.*)\s+contains\s+(.*)$/) {
			my ($container,$containee) = ($1,$2);
			my $line = $_;
			$container = fileFilter($container);
			$containee = fileFilter($containee);
			&$adder($container,$containee);
		}
	}
	#add containers to ROOT
	updateSymbols($symbols,$contains);
	return $contains
}
sub getFile { my $a = shift; return $a->{FILE}; }
sub updateSymbols {
	my ($symbols,$contains) = @_;
	while (my ($symbol,$shash) = each %$symbols) {
		while (my ($type,$file) = each %$shash) {
			#warn "$symbol : $type : $file";
			#my $file = getFile($hash);
			$contains->moduleVivify($file);
		}
	}
	$contains->rootifyUncontained();
}


# NEED RESOLVE MODULE
sub readChangeList {
	my %hash = @_;
	my $symbols = $hash{symbols} || die "NO SYMBOLS";
	my $contains = $hash{contains} || die "NO CONTAINS";
	my $filename = $hash{filename} || die "NO FILENAME";
	my @changes = ();
	my $currentChange;
	my $getFiles = sub  {
		my ($symbol) = @_;
		my @out = ();
		return @out if !exists $symbols->{$symbol};
		while (my ($type,$file) = each %{$symbols->{$symbol}}) {
			push @out,$file;
		}
		return @out;
	};
	my $resolveModules = sub  {
		my ($symbol) = @_;
		return () unless exists $symbols->{$symbol};
		my %modules = ();
		my @files = &$getFiles($symbol);
		#foreach my $file (@files) {
		#	my $file = fileFilter($file);
		#	unless ($contains->has($file)) {
		#		$contains->moduleVivify($file); #fixing a lame bug
		#		die "DOESN'T HAVE $file" unless $contains->has($file);
		#	}
		#	my @containers = $contains->containedBy($file);
		#	#warn "$file @containers";
		#	foreach (@containers) { $modules{$_}++; }
		#}
		foreach my $file (@files) {
			unless ($contains->has($file)) {
				warn "ADDING $file ???";
				$contains->moduleVivify($file); #fixing a lame bug
				die "DOESN'T HAVE $file" unless $contains->has($file);
			}
			#$file = $contains->resolveDepth($file,$default_depth);
			$modules{$file}++;
		}
		return keys %modules;
	};
	my  $getDepends = sub {
		my ($dep) = @_;
		my @deps = split(",",$dep);
		@deps = map { [split(/\s+/,$_)] } @deps;
		my %dep = ();
		foreach (@deps) {
			my ($symbol,$count) = @$_;
			next unless exists $symbols->{$symbol};
			my @modules = &$resolveModules($symbol);
			#warn join(" ",@modules);
			foreach (@modules) {
				$dep{$_} += $count;
			}
		}
		return \%dep;
	};
	my $makeChange = sub {
		my ($symbols,%attr) = @_;
		my $change = {%attr};
		my $depends = &$getDepends($attr{DEPENDENCY_KEYWORDS});
		$change->{depend} = $depends;
		return $change;
	};
	

	my $start = sub {
		my ($parser,$elm,%attr) = @_;
		#return unless ($elm eq "ADD_TYPE");
		if ($elm eq "CHANGELIST_DETAILS") {
			#warn $elm;
			$currentChange = {%attr};
			$currentChange->{modify} = [];
			$currentChange->{add} = [];
			$currentChange->{remove} = [];
			$currentChange->{'time'} = localtime($currentChange->{'TIME'});
			push @changes, $currentChange;
		} 
		elsif ($elm eq "MODIFY_ENT") {
			push @{$currentChange->{modify}}, &$makeChange($symbols,%attr);
		}
		elsif ($elm eq "ADD_ENT") {
			push @{$currentChange->{add}}, &$makeChange($symbols,%attr);
		}
		elsif ($elm eq "REMOVE_ENT") {
			push @{$currentChange->{remove}}, &$makeChange($symbols,%attr);
		} else {
			warn "$elm NOT HANDLED";
		}
	};
	my $end = sub {
		my ($self,$elm) = @_;
		#warn $elm;
	};
	my $char = sub {};
	my $parser = new XML::Parser( Handlers => {
			Start => $start,
			End   => $end,
			Char  => $char,
		}
	);
	eval {
		$parser->parsefile($filename);
	};
	if ($@) {
		warn "PARSER: $@";
	}
	return \@changes;
}
sub test {
	my $m = ModuleGraph->new();
	$m->modifyEdge("a","b",1);
	$m->modifyEdge("a","d",1);
	$m->modifyEdge("a","c",2);
	$m->modifyEdge("a","b",1);
	print $m->dump,$/;
	print $m->copy->dump,$/;
	print $m->getEdge("a","b"),$/;
}
sub containsTest {
	my $contains = shift;
	my @tests = qw(
		postgres/pgsql/src/backend/main/main.c
		postgres/pgsql/src/include/c.h
		postgres/pgsql/src/include/fmgr.h
		postgres/pgsql/src/include/funcapi.h
		postgres/pgsql/src/include/libpq/be-fsstubs.h
		postgres/pgsql/src/include/libpq/libpq.h
		postgres/pgsql/src/include/libpq/pqcomm.h
		postgres/pgsql/src/include/libpq/pqformat.h
		postgres/pgsql/src/include/libpq/pqsignal.h
		postgres/pgsql/src/include/miscadmin.h
		postgres/pgsql/src/include/optimizer/Attic/xfunc.h
		postgres/pgsql/src/include/optimizer/_deadcode/Attic/xfunc.h
		postgres/pgsql/src/include/optimizer/geqo_random.h
		postgres/pgsql/src/include/port.h
		postgres/pgsql/src/include/postgres.h
		postgres/pgsql/src/lextest/Attic/lextest.c
	);
	foreach my $file (@tests) {
		#warn "HAS" if $contains->has($file);
		#$contains->moduleVivify($file);
		#my ($a) = $contains->containedBy($file);
		#my ($a2) = $contains->containedBy($a);
		#my ($a3) = $contains->containedBy($a2);
		#warn "PARENT NOT HAS" unless $contains->has($a);
	 	my $cb = findUpperAndVivify($contains,$file);
	 	#my $cb2 = findUpperAndVivify($contains,$a);
	 	#my $cb3 = findUpperAndVivify($contains,$a2);
	 	#my $cb4 = findUpperAndVivify($contains,$a3);
		warn "$file -> $cb" if $cb eq "ROOT";
		#warn "$a -> $cb2";
		#warn "$a2 -> $cb3";
		#warn "$a3 -> $cb4";
	}

}
