###############################################################################
#
# Win32::GUI::XMLBuilder
#
# 14 Dec 2003 by Blair Sutton <b.sutton@odey.com>
#
# Version: 0.1 (14 Dec 2003)
#
# Copyright (c) 2003 Blair Sutton. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
###############################################################################

package Win32::GUI::XMLBuilder;

=head1 NAME

XMLBuilder - Build Win32::GUIs using XML

=head1 SYNOPSIS

	use XMLBuilder;
	&Win32::GUI::XMLBuilder::build(*DATA);
	&Win32::GUI::XMLBuilder::buildfile("file.xml");
	&Win32::GUI::Dialog;
	...
	
	__END__
	<GUI>
	
	..
	</GUI>

=head1 DESCRIPTION

This module allows Win32::GUIs to be built using XML.
For examples on usage please look in samples/ directory.

=cut

use strict;

require Exporter;

our $VERSION = 0.01;
our @ISA     = qw(Exporter);
our @EXPORT  = qw(%GUI);

=head1 DEPENDENCIES

	XML::Twig
	Win32::GUI
	Win32::GUI::TabFrame (see http://perso.club-internet.fr/rocherl/Win32GUI.html)

=cut

use XML::Twig;

use Win32::GUI;
use Win32::GUI::TabFrame;

our $DEBUG = 0;

my $context; # holds current proginitor Window name.
our %GUI;    # holds all widgets via unique name
# $GUI{_SIZE}{progenitor}{child} - widget sizes for _resize
# $GUI{_SORDER}{progenitor} = (child1, child2, ...) - order of widgets to be resized
# $GUI{_POS}{progenitor}{child} - widget positions for _resize
# $GUI{_PORDER}{progenitor} = (child1, child2, ...) - order of widgets to be resized

my @SHOW;  # all windows shown

sub build {
	my $xml = $_[0];

	my $s = new XML::Twig(
		TwigHandlers => { 
			Script     => \&Script,
		}
	);

	$s->parse($xml);

	my $t = new XML::Twig( 
		TwigHandlers => { 
			Icon     => \&Icon,
			Font     => \&Font,
			Class    => \&Class,
			Menu     => \&Menu,
			Window   => \&Window, 
		}
	);

	$t->parse($s->sprint);

	foreach (@SHOW) {
		$GUI{$_}->Show;
	}
}

sub buildfile {
	my $file = $_[0];

	my $s = new XML::Twig(
		TwigHandlers => { 
			Script     => \&Script,
		}
	);

	$s->parsefile($file);

	my $t = new XML::Twig( 
		TwigHandlers => { 
			Icon     => \&Icon,
			Font     => \&Font,
			Class    => \&Class,
			Menu     => \&Menu,
			Window   => \&Window, 
		}
	);

	$t->parse($s->sprint);

	foreach (@SHOW) {
		$GUI{$_}->Show;
	}
}

sub Script {
	my ($t, $e) = @_;

	&debug($e->text);
	my $ret = eval $e->text;
	&debug($@) if $@;
	$e->set_text('');
	my $pcdata= XML::Twig::Elt->new(XML::Twig::ENT, $ret);
	$pcdata->paste( $e);
	$e->erase();
}

sub evalhash {
	my ($e) = @_;
	my $parent = $e->parent()->{'att'}->{'name'};
	my %in = %{$e->{'att'}};
	my %out;
	foreach my $k (sort keys %in) {
		$out{-$k} = $in{$k} !~ /\$|(^WS_)/ ? $in{$k} : eval $in{$k}; # better to check for perl vars (instead of $k = class|icon|menu)
		&debug("\t-$k : $in{$k} -> $out{-$k}");
	}
	if ($in{width} ne '' && $in{height} ne '') {
		$GUI{_SIZE}{$context}{$out{-name}} = [$in{width}, $in{height}];
		push @{$GUI{_SORDER}{$context}}, $out{-name};
	} # else take parents size?
	if ($in{top} ne '' && $in{left} ne '') {
		$GUI{_POS}{$context}{$out{-name}} = [$in{left}, $in{top}];
		push @{$GUI{_PORDER}{$context}}, $out{-name};
	}
	return %out;
}

sub gename {
	my ($e) = @_;
	if ($e->{'att'}->{'name'} eq '') {
		my $i = 0;
		while () { 
			if (!exists $GUI{$e->gi.'_'.$i}) {
				$e->set_att(name=>$e->gi.'_'.$i);
				last;
			}
			$i++;
		}
	}
	return $e->{'att'}->{'name'};
}

sub Icon {
	my ($t, $e) = @_;
	my $name = $e->{'att'}->{'name'};
	my $file = $e->{'att'}->{'file'} !~ /\$/ ? $e->{'att'}->{'file'} : eval $e->{'att'}->{'file'};;

	&debug("\nIcon: $name");
	&debug("file -> $file");
	$GUI{$name} = new Win32::GUI::Icon($file) || &error;
}

sub Font {
	my ($t, $e) = @_;
	my $name = $e->{'att'}->{'name'};

	&debug("\nFont: $name");
	$GUI{$name} = new Win32::GUI::Font(&evalhash($e)) || &error;
}

sub Class {
	my ($t, $e) = @_;
	my $name = $e->{'att'}->{'name'};

	&debug("\nClass: $name");
	$GUI{$name} = new Win32::GUI::Class(&evalhash($e)) || &error;
}

sub Menu {
	my ($t, $e) = @_;
	my $name = &gename($e);

	my @m;
	foreach ($e->children()) { 
		push @m, $_->{'att'}->{'label'}, $_->{'att'}->{'sub'};
		&debug("$_->{'att'}->{'label'}, $_->{'att'}->{'sub'}");
	}
	&debug("\nMenu: $name");
	$GUI{$name} = Win32::GUI::MakeMenu(@m) || &error;
}

sub Window { 
	my ($t, $e) = @_;
	my $name = &gename($e); # should this be allowed?
	my $show = $e->{'att'}->{'show'};

	$context = $name;

	&debug("\nWindow: $name");
	$GUI{$name} = new Win32::GUI::Window(&evalhash($e)) || &error;
	push @SHOW, $name if $show;

	foreach ($e->children()) {
		&debug($_->{'att'}->{'name'});
		&debug($_->gi);

		if (exists &{$_->gi}) {
			&{\&{$_->gi}}($t, $_) if exists &{$_->gi};
		}	else {
			&_Generic($t, $_);
		}
	}

	eval  "
	sub \::${name}_Resize {
		foreach (\@{\$GUI{_SORDER}{$name}}) {
			&debug(\"\$_ -> Resize[\$GUI{_SIZE}{$name}{\$_}[0], \$GUI{_SIZE}{$name}{\$_}[1]]\"); 
			\$GUI{\$_}->Resize(eval \$GUI{_SIZE}{$name}{\$_}[0], eval \$GUI{_SIZE}{$name}{\$_}[1]) if \$_ ne '$name'; 
		}
		foreach (\@{\$GUI{_PORDER}{$name}}) {
			&debug(\"\$_ -> Move[\$GUI{_POS}{$name}{\$_}[0], \$GUI{_POS}{$name}{\$_}[1]]\"); 
			\$GUI{\$_}->Move(eval \$GUI{_POS}{$name}{\$_}[0], eval \$GUI{_POS}{$name}{\$_}[1]) if \$_ ne '$name'; 
		}
	}
	";
}

sub TabFrame {
	my ($t, $e) = @_;
	my $name = &gename($e);
	my $parent = $e->parent()->{'att'}->{'name'};
	$e->{'att'}->{'panel'} = 'Page';

	&debug("\nTabFrame $name; Parent: $parent");
	$GUI{$name} = $GUI{$parent}->AddTabFrame(&evalhash($e)) || &error;
	my $i = 0;
	foreach my $item ($e->children()) { 
		my $iname = $item->{'att'}->{'name'};
		&debug("Item $i: $iname");
		$GUI{$name}->InsertItem(&evalhash($item));
		$GUI{$iname} = ${$GUI{$name}}{"Page$i"}; # need to be verbose here!
		$GUI{_SIZE}{$context}{$iname} = [$GUI{_SIZE}{$context}{$name}[0], $GUI{_SIZE}{$context}{$name}[1]]; # set Page size to parents
		$i++;

		foreach ($item->children()) {
			&debug($_->{'att'}->{'name'});
			&debug($_->gi);

			if (exists &{$_->gi}) {
				&{\&{$_->gi}}($t, $_) if exists &{$_->gi};
			}	else {
				&_Generic($t, $_);
			}
		}

	}
}

sub TreeView {
	my ($t, $e) = @_;
	my $name = &gename($e);
	my $parent = $e->parent()->{'att'}->{'name'};

	&debug("\nTreeView: $name; Parent: $parent");
	$GUI{$name} = $GUI{$parent}->AddTreeView(&evalhash($e))  || &error;

	if($e->children_count()) {
		&TVitems($e, $name);
	}
}

sub TVitems {
	my ($e, $parent) = @_;

	my $name = $e->{'att'}->{'name'};
	foreach my $item ($e->children()) { 
		next if $item->gi ne 'Item';
		my $iname = $item->{'att'}->{'name'};
		&debug("Item: $iname; Parent: $name");
		$item->{'att'}->{'parent'} = "\$GUI{$name}" if $name ne $parent;
		$GUI{$iname} = $GUI{$parent}->InsertItem(&evalhash($item)) || &error;
		if($item->children_count()) {
			&TVitems($item, $parent);
		}
	}
}

sub Combobox {
	my ($t, $e) = @_;
	my $name = &gename($e);
	my $parent = $e->parent()->{'att'}->{'name'};

	&debug("\nCombobox: $name; Parent: $parent");
	$GUI{$name} = $GUI{$parent}->AddCombobox(&evalhash($e))  || &error;

	if($e->children_count()) {
		foreach my $item ($e->children()) { 
			next if $item->gi ne 'Item';
			my $text = $item->{'att'}->{'text'};
			&debug("Item: $text");
			$GUI{$name}->InsertItem($text) || &error;
		}
	}
}

sub _Generic {
	my ($t, $e) = @_;
	my $widget = $e->gi;
	my $name = &gename($e);
	my $parent = $e->parent()->{'att'}->{'name'};

#	eval "require Win32::GUI::$widget"; # is this needed?
	&debug("\n$widget: $name; Parent: $parent");
	$e->{'att'}->{'parent'} = "\$GUI{$parent}";
	$GUI{$name} = eval "new Win32::GUI::$widget(&evalhash(\$e))"  || &error;
#	$GUI{$name} = eval "\$GUI{\$parent}->Add$widget(&evalhash(\$e))"  || &error; # this method not always implemented!
}


sub debug { print "$_[0]\n" if $DEBUG > 0 }

sub error { &debug("error: ".Win32::GetLastError()." $!"); }

1;
