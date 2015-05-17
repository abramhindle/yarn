package Contains;
use strict;
use File::Basename;
use Carp qw(confess);

sub ROOT {
	return "ROOT";
}

sub new {
	my $type = shift;
	my $hidden = undef;
	my $self = \$hidden;
	bless($self,$type);
	$self->setContains({ROOT() => {}});
	$self->setContainedBy({ROOT() => {}});
	return $self;
}
sub dflPrefix { return $_[0] || "./"; }
sub fileFilter {
	my ($a,$prefix) = @_;
	$prefix = dflPrefix($prefix);
	if (0 == index $a,$prefix) {
		$a = substr($a,length($prefix));
	}
	$a =~ s/^\\/\//;
	return $a;
}
sub dirBase {
	my $file = shift;
	my $bfile = basename($file);
	if (!$bfile) {
		$file = fileFilter($file);
		$bfile = basename($file);
	}
	my $dfile = dirname($file);
	return ($dfile,$bfile,($dfile)?"$dfile/$bfile":$bfile);
}
sub dropPrefix {
	my ($prefix,$filename) = @_;
	$filename = fileFilter($filename);
	return $filename;
}
sub moduleVivify {
	my ($self,$file,$prefix) = @_;
	$prefix = dflPrefix($prefix);
	if (!$file || $file eq ROOT() || $file eq $prefix) {
		return ROOT();
	}
	my ($dirname,$basename,$path) = dirBase($file);
	if ($dirname eq ".") { $dirname = ""; }
	#warn "D: $dirname B: $basename P: $path";
	$path = dropPrefix($prefix,$path);
	#what about A contains B and B contains c/d/e
	if (!$path) { return ROOT(); }
	if ($self->has($path)) {
		return $path;
	}
	if ($dirname) {
		my $parent = $self->moduleVivify($dirname,$prefix);
		$self->addContain($parent,$path);
	} else {
		$self->addContain(ROOT(),$path);
	}
	return $path;
}
sub resolveDepth {
	my ($self,$symbol,$depth) = @_;
	$depth = (defined $depth)?$depth:3;
	my $sym = $symbol;
	my @syms = ($symbol);
	while ($sym && $sym ne ROOT()) {	
		($sym) = $self->containedBy($sym);
		unshift @syms,$sym;
	}
	my $last = undef;
	while ($depth-- > 0 && @syms) {
		$last = shift @syms;
	}
	return $last;
}
#
sub findUpperCaseParent {
	my ($self,$symbol,$depth) = @_;
	my $sym = $symbol;
	my @syms = ($symbol);
	while ($sym && $sym ne ROOT()) {	
		($sym) = $self->containedBy($sym);
		if ($sym && $sym eq uc($sym)) {
			return $sym;
		}
	}
	#if we're here there was no uppercase.. so lets return the first parent.
	warn "$symbol -- Uppercase not found";
	($sym) = $self->containedBy($symbol);
	$sym = ($sym)?ROOT():$sym;
	return $sym;
}
sub rootifyUncontained {
	my $self = shift;
	my $contains = $self->getContains();
	my $containedBy = $self->getContainedBy();
	while ( my ($symbol,$hash) = each %$containedBy) {
		next if $symbol eq ROOT();
		unless (keys %$hash) {	#not contained
			$self->addContains(ROOT(),$symbol);
		}
	}
	while (my ($symbol,$hash) = each %$contains) {
		next if $symbol eq ROOT();
		unless ($self->isContainedBy($symbol)) {
			$self->addContains(ROOT(),$symbol);
		}
	}
}
sub addContain {
	my ($self,@a) = @_;
	return $self->addContains(@a);
}
sub addContains {
	my ($self,$a,$b) = @_;
	confess "Empty Contains used" if (!$a || !$b);
	$self->getContains()->{$a}->{$b} = 1;
	$self->getContainedBy()->{$b}->{$a} = 1;
	return 1;
}
sub has {
	my ($self,$a,$b) = @_;
	return $self->isContainer($a,$b) || $self->isContainedBy($a,$b);
}
sub containedBy {
	my ($self,$a) = @_;
	confess "We don't have [$a]" unless $self->has($a);
	return keys %{$self->getContainedBy()->{$a}};
}
sub contains {
	my ($self,$a) = @_;
	die "We don't have [$a]" unless $self->has($a);
	return keys %{$self->getContains()->{$a}};
}

sub isContainer {
	my ($self,$a,$b) = @_;
	my $contains =  $self->getContains();
	if (!$b && !$a) {
		return 0;
	} elsif (!$b) {
		return exists $contains->{$a}
	}	
	return exists $contains->{$a} && exists $contains->{$a}->{$b};
}
sub isContainedBy {
	my ($self,$a,$b) = @_;
	my $contains =  $self->getContainedBy();
	if (!$b && !$a) {
		return 0;
	} elsif (!$b) {
		return exists $contains->{$a}
	}	
	return exists $contains->{$a} && exists $contains->{$a}->{$b};
}

{
	my %contains = ();
	my %containedby = ();
	sub getContains {
		return $contains{$_[0]};
	}
	sub setContains {
		return $contains{$_[0]} = $_[1];
	}
	sub getContainedBy {
		return $containedby{$_[0]};
	}
	sub setContainedBy {
		return $containedby{$_[0]} = $_[1];
	}
	sub DESTROY {
		$containedby{$_[0]} = undef;
		$contains{$_[0]} = undef;
		delete $containedby{$_[0]};
		delete $contains{$_[0]};
	}
}

sub getTree {
	my ($self,$top,$prefix) = @_;
	$prefix = $prefix || "";
	$top = $top || ROOT();
	my $ret = $prefix;
	if ($top eq ROOT()) {
		$ret = "";
	}
	my @contains = $self->contains($top);
	return "$prefix$top$/$prefix".join("\n$prefix",map { $self->getTree($_,"$prefix ")} @contains);
}
sub getContain {
	my ($self,$top) = @_;
	my $prefix = "contain ";
	$top = $top || ROOT();
	my $ret = $prefix;
	if ($top eq ROOT()) {
		$ret = "";
	}
	my @contains = $self->contains($top);
	my @out = map { "$prefix $top $_" } @contains;
	push @out , map { $self->getContain($_)  } @contains;
	return @out;
}
1;
