#!/opt/perl5/bin/perl

package grind;

%mesh = loadxito();
for (keys %mesh) {
    delete $mesh{$_} if /_[^_]+_/;
}

%lex = loadxlxcl();

sub new {
    my $type = shift;
    my $it = {};
    $it->{mesh} = {%mesh};
    $it->{meshlist} = [sort { $it->{mesh}{$b} <=> $it->{mesh}{$a} }
		       keys %{$it->{mesh}}];
    $it->{lex} = [keys %lex];
    return bless $it, $type;
}

# takes a mesh and a list of lexes
# returns a sublist of lexes that have the mesh
sub getlexes {
    my ($mesh, @lex) = @_;
    my @tlex;
    for $lex (@lex) {
	push @tlex, $lex if grep { $_ eq $mesh } @{$lex{$lex}};
    }
    @tlex;
}

sub printvectors {
    my $it = shift;
    my %ml, %ll, $numm, $numl;
    for $m (keys %{$it->{vector}}) {
	%ml = %{$it->{vector}{$m}{mesh}};
	%ll = %{$it->{vector}{$m}{lex}};
	$numm = keys %ml;
	$numl = keys %ll;
	print '-' x 75;
	print "\n";
	print "class   $m   $numm meshes, $numl lexes\n";
	print "\n";
	print map { "$_ $ml{$_}\n" } sort { $ml{$b} <=> $ml{$a} } keys %ml;
	print "\n";
	print map { "$_ $ll{$_}\n" } sort { $ll{$b} <=> $ll{$a} } keys %ll;
	print "\n";
    }
}

sub loadvectors {
    my $it = shift;
    my $m, %ml, %ll, $k, $v;
    open (F, shift || 'x9_clasp') || return;
    while (<F>) {
	next if /--------/;
	chop;
	next unless $_;
	if (/^class   ([^ ]+) /) {
	    if ($m) {
		$it->{vector}{$m}{mesh} = {%ml};
		$it->{vector}{$m}{lex} = {%ll};
		%ml = ();
		%ll = ();
	    }
	    $m = $1;
	} elsif (/#/) {
	     ($k, $v) = split;
	     $ml{$k} = $v;
	} else {
	     ($k, $v) = split;
	     $ll{$k} = $v;
	}
    }

    $it->{vector}{$m}{mesh} = {%ml};
    $it->{vector}{$m}{lex} = {%ll};

    close F;
}

sub squashvectors {
    my $it = shift;

    my %ml, %ll, $numm, $numl, %oml, $ms, $oms, %ol;

    MESH: for $m (sort {
        keys %{$it->{vector}{$a}{mesh}} <=> keys %{$it->{vector}{$b}{mesh}}
	    ||
	keys %{$it->{vector}{$a}{lex}} <=> keys %{$it->{vector}{$b}{lex}} }
	    keys %{$it->{vector}}) {
	%ml = %{$it->{vector}{$m}{mesh}};
	$numm = keys %ml;
	$ms = join ' ', sort keys %ml, $m;
	%ll = %{$it->{vector}{$m}{lex}};
	$numl = keys %ll;

	for $om (sort {
	    keys %{$it->{vector}{$b}{mesh}} <=> keys %{$it->{vector}{$a}{mesh}}
	        ||
	    keys %{$it->{vector}{$b}{lex}} <=> keys %{$it->{vector}{$a}{lex}} }
	    keys %{$it->{vector}}) {
	    next if $om eq $m;
	    %oml = %{$it->{vector}{$om}{mesh}};
	    next if keys %oml < $numm;
	    $oms = join ' ', sort keys %oml, $om;
	    if (index($oms, $ms) > -1) {
		%ol = %{$it->{vector}{$om}{lex}};
		# load lexes into om so we can dump m
		for $l (keys %{$it->{vector}{$m}{lex}}) {
		    $it->{vector}{$om}{lex}{$l} = $it->{vector}{$m}{lex}{$l}
		        unless grep { $l eq $_ } keys %ol;
		}
		delete $it->{vector}{$m};
		next MESH;
	    }
	}
    }
}

sub makevectors {
    my $it = shift;
    my @lex, %ml, %hc, %ll;

    for $m (@{$it->{meshlist}}) {
	@lex = getlexes($m, keys %lex);	# set of lexes with top mesh
	%ml = ();		# mesh list
	%ll = ();		# lex list
	%hc = ();		# mesh counts
	@mu = ($m);		# used meshes
	# loop while lexes remain in the vector
	while (@lex > 1) {
	    # find the highest scoring mesh for these lexes
	    for $l (@lex) { map { $hc{$_}++ } @{$lex{$l}} }
	    map { delete $hc{$_} } @mu;
	    ($nextm) = sort { $hc{$b} <=> $hc{$a} } keys %hc;
	    %hc = ();
	    @lex = getlexes($nextm, @lex);
	    map { $ll{$_}++ } @lex if @lex;
	    $ml{$nextm} += @lex if @lex;
	    push @mu, $nextm;
	}

	$numm = keys %ml;
	next unless $numm;

	$it->{vector}{$m}{mesh} = {%ml};
	$it->{vector}{$m}{lex} = {%ll};

#	last if $ccc++ > 10;
    }

}


sub vector {
    my $it = shift;
    my @tmp = ();
    my $topmesh;
    my @oldml;

    while (1) {
	$topmesh = shift @{$it->{meshlist}};
	@oldml = @{$it->{meshlist}};
	print "at top of vector with mesh $topmesh and ".@{$it->{lex}}."\n";
	$it->{oldlex} = $it->{lex};
	while (1) {
	    @tmp = ();
	    for (@{$it->{lex}}) {
		push @tmp, $_ if isin($topmesh, @{$lex{$_}});
	    }
	    last unless @tmp;
	    $it->{lex} = [@tmp];
	    for (@tmp) { $it->{class}{$_}++ }
	    $it->{classmesh}{$topmesh} = @tmp;
	    $topmesh = $it->nextmesh();
	}
#create new class
	$topmember = (sort { $it->{class}{$b} <=> $it->{class}{$a} }
		      keys %{$it->{class}})[0];
	last unless $topmember;
	$it->{classes}{$topmember} = wordclass->new($topmember,
						    \%{$it->{classmesh}},
						    \%{$it->{class}});
	$it->{classes}{$topmember}->printclass();

#reset itlex without new class members
	$it->{lex} = [];
	for (@{$it->{oldlex}}) {
	    push @{$it->{lex}}, $_
		unless isin($_, $it->{classes}{$topmember}->getlexes());
	}
#loop until no itlex
	last unless @{$it->{lex}};
#reset itclassmesh, itclass
	$it->{classmesh} = {};
	$it->{class} = {};
#reset meshlist
	$it->{meshlist} = [sort { $it->{mesh}{$b} <=> $it->{mesh}{$a} }
			   @oldml];
	last unless @{$it->{meshlist}};
    }
}

sub nextmesh {
    my $it = shift;
    my %m;
    for $mesh (@{$it->{meshlist}}) {
	for $lex (@{$it->{lex}}) {
	    $m{$mesh}++ if isin($mesh, @{$lex{$lex}});
	}
    }
    $it->{meshlist} = [sort { $m{$b} <=> $m{$a} } keys %m];
    shift @{$it->{meshlist}};
}

sub getsuper {
#    my %md = @_;
    my (@sup, %tm);

    for $mc (sort { $md{$b} <=> $md{$a} } keys %md) {
	@sup = ();
	for $lx (sort keys %lxcl) {
	    push @sup, $lx if isin($mc, @{$lxcl{$lx}});
	}
#	map { print "$_\n" } @sup;
	for $sup (@sup) {
	    for $m (@{$lxcl{$sup}}) {
		next if $m eq $mc;
		$tm{$m}++;
	    }
	}
#	for (sort { $tm{$b} <=> $tm{$a} } keys %tm) {
#	    print "$_\t$tm{$_}\n";
#	}
	last;
    }
}

sub isin {
    my ($it, @li) = @_;
    for (@li) {	return 1 if $it eq $_ }
    return '';
}

sub loadinlx {
    open (I, shift || 'x8_inlx') || return;
    while (<I>) {
	($lx, $fr, @ms) = split;
	next unless @ms;
	$ix{$lx}{freq} = $fr;
	@m = ();
	for (@ms) {
	    s/=[^_]+/\*/g;
	    push @m, $_ if /#/;
	}
	$ix{$lx}{mesh} = [ @m ];
    }
    close I;
}

sub getclass {
    my $c;
    for $lx (keys %ix) {
	for (@{$ix{$lx}{mesh}}) { $md{$_} ||= meshdist($_) }
    }
}

sub loadxito {
    my %md;
    open (C, shift || 'xito') || return;
    while (<C>) {
	chop;
	($mc, $d) = split;
	$md{$mc} = $d if $mc =~ /#/;
    }
    close C;
    %md;
}

sub fitclass {
    my $nc;
    $nx = grep { @{$ix{$_}{mesh}} } keys %ix;
    for $mc (sort {$md{$b} <=> $md{$a}} keys %md) {
	next if $mc =~ tr/_/_/ > 1;
	$re = $mc;
	$re =~ s/(\W)/\\$1/g;
	for $lx (keys %ix) {
	    $ix{$lx}{class}{$mc} = $md{$mc} if grep /^$re$/, @{$ix{$lx}{mesh}};
	}
	$oldnc = $nc;
	$nc = grep { ref $ix{$_}{class} eq 'HASH' } keys %ix;
	$class{$mc} = $md{$mc} if $nc != $oldnc;
	print "$mc\t$nx\t$nc\n";
	last if $nc == $nx;
    }
}

sub loadxlxcl {
    my ($lx, @cl, %lxcl);
    open (L, shift || 'xlxcl');
    while (<L>) {
	chop;
	($lx, @cl) = split;
	$lxcl{$lx} = [@cl];
    }
    close L;
    %lxcl;
}

sub printlex {
    my $out;
    for $lx (sort keys %lex) {
	$out .= "$lx ".join(' ', sort @{$lex{$lx}})."\n";
    }
    print $out;
}

sub printclass {
    my $tot;
    for (sort { $class{$b} <=> $class{$a} } keys %class) {
	$tot += $class{$_};
	print "$_\t$class{$_}\t$tot\t$nx\n";
    }
}

sub printnoclass {
    print "\nno class\n";
    for $lx (keys %ix) {
	print "$lx\n" unless keys %{$ix{$lx}{class}};
    }
}

sub printmesh {
    for (sort {$mesh{$b} <=> $mesh{$a}} keys %mesh) {
	print "$_\t$mesh{$_}\n";
    }
}

sub meshdist {
    my $mesh = shift;
    my $c;
    for (keys %ix) {
	$c++ if hasmesh($_, $mesh);
    }
    $c;
}

sub hasmesh {
    my ($ix, $mesh) = @_;
    my $gotone;
    for (@{$ix{$ix}{mesh}}) {
	$gotone++ if $_ eq $mesh;
   }
    $gotone;
}

sub printix {
    for (sort keys %ix) {
	print "$_ $ix{$_}{freq} ", join ' ', @{$ix{$_}{mesh}}, "\n";
    }
}


package wordclass;

sub new {
    my $type = shift;
    my $it = {};
    $it->{name} = shift;
    $it->{mesh} = shift;
    $it->{lex} = shift;
    return bless $it, $type;
}

sub getlexes {
    my $it = shift;
    sort { $it->{lex}{$b} <=> $it->{lex}{$a} } keys %{$it->{lex}};
}

sub printclass {
    my $it = shift;
    print "the class $it->{name}\n";
    print "meshes with scores\n";
    print map { "$_\t$it->{mesh}{$_}\n" } sort { $it->{mesh}{$b} <=> $it->{mesh}{$a} } keys %{$it->{mesh}};
    print "lexes with scores\n";
    print map { "$_\t$it->{lex}{$_}\n" } sort { $it->{lex}{$b} <=> $it->{lex}{$a} } keys %{$it->{lex}};

}

