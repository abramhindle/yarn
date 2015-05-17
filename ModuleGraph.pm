package ModuleGraph;
use strict;

sub new {
	my $type = shift;
	my $hidden = undef;
	my $self = \$hidden;
	bless($self,$type);
	$self->init(@_);

	return $self;
}
sub init {
	my $self = shift;
	$self->setGraph({});
	$self->setScore(0);
}
sub getEdge {
	my ($self,$a,$b) = @_;
	return $self->getGraph()->{$a}->{$b};
}
sub setEdge {
	my ($self,$a,$b,$c) = @_;
	return $self->getGraph()->{$a}->{$b} = $c;
}
sub modifyEdge {
	my ($self,$a,$b,$c) = @_;
	$c = (defined $c)?$c:1;
	$self->getGraph()->{$a}->{$b} += $c;
	return $self->getGraph()->{$a}->{$b};
}
sub getEdges {
	my ($self) = @_;
	my $graph =  $self->getGraph();
	my @keys = keys %$graph;
	my @out = ();
	foreach my $key (@keys) {
		my @keys = keys %{$graph->{$key}};
		foreach my $skey (@keys) {
			push @out,[$key,$skey, $graph->{$key}->{$skey}];
		}
	}
	return @out;
}
sub copy {
	my $self = shift;
	my $n = new ModuleGraph();
	my $graph =  $self->getGraph();
	my @keys = keys %$graph;
	foreach my $key (@keys) {
		my @keys = keys %{$graph->{$key}};
		foreach my $skey (@keys) {
			$n->modifyEdge($key,$skey,$graph->{$key}->{$skey});
		}
	}
	return $n;
}
sub unDump {
	my $self = shift;
	foreach my $str (@_) {
		my @lines = split($/,$str);
		foreach my $line (@lines) {
			next unless $line;
			next if $line =~ /^\s*$/;
			$line =~ s/^\s*//;
			my ($a,$b,$v) = split(/\s+/,$line);
			next unless ($a && $b);
			$self->setEdge(	$a, $b, $v);
		}
	}
	return $self;
}
sub dumpRSF {
	my $self = shift;
	my @out = ();
	my $graph =  $self->getGraph();
	my @keys = keys %$graph;
	foreach my $key (@keys) {
		my @keys = keys %{$graph->{$key}};
		foreach my $skey (@keys) {
			push @out,"use $key $skey";
		}
	}
	return join("\n",@out)."\n";
}
sub dump {
	my $self = shift;
	my @out = ();
	my $graph =  $self->getGraph();
	my @keys = keys %$graph;
	foreach my $key (@keys) {
		my @keys = keys %{$graph->{$key}};
		foreach my $skey (@keys) {
			push @out,"$key $skey ".($graph->{$key}->{$skey} || 0);
		}
	}
	return "\t".join("\n\t",@out)."\n";
}
{
	my %graph = ();
	my %score = ();
	my %changes = ();
	my %diff = ();
	my %time = ();
	my %scoringgraph = ();
	sub getGraph {
		return $graph{$_[0]};
	}
	sub setGraph {
		return $graph{$_[0]} = $_[1];
	}
	sub getScore {
		return $score{$_[0]};
	}
	sub setScore {
		return $score{$_[0]} = $_[1];
	}
	sub getChanges {
		return $changes{$_[0]};
	}
	sub setChanges {
		return $changes{$_[0]} = $_[1];
	}
	sub getDiff {
		return $diff{$_[0]};
	}
	sub setDiff {
		return $diff{$_[0]} = $_[1];
	}
	sub getTime {
		return $time{$_[0]};
	}
	sub setTime {
		return $time{$_[0]} = $_[1];
	}
	sub getScoringGraph {
		return $scoringgraph{$_[0]};
	}
	sub setScoringGraph {
		return $scoringgraph{$_[0]} = $_[1];
	}
	sub DESTROY {
		$graph{$_[0]} = undef;
		delete $graph{$_[0]};
		$score{$_[0]} = undef;
		delete $score{$_[0]};
		$changes{$_[0]} = undef;
		delete $changes{$_[0]};
		$diff{$_[0]} = undef;
		delete $diff{$_[0]};
		$time{$_[0]} = undef;
		delete $time{$_[0]};
		$scoringgraph{$_[0]} = undef;
		delete $scoringgraph{$_[0]};
	}
}
1;
