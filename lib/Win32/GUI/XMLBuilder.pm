###############################################################################
#
# Win32::GUI::XMLBuilder
#
# 14 Dec 2003 by Blair Sutton <b.sutton@odey.com>
#
# Version: 0.21 (29 Feb 2004)
#
# Copyright (c) 2004 Blair Sutton. All rights reserved.
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

=head1 XML SYNTAX

XMLBuilder will parse an XML file or string that contains elements
that describe a Win32::GUI object.

All XML documents must be enclosed in <GUI>..</GUI> elements and each
separate GUI window must be enclosed in <Window>..</Window> elements.
To create a N-tier window system one might use a construction similar to: -

	<GUI>
		<Window name="W_1">
			...
		</Window>
		<Window name="W_2">
			...
		</Window>
			...
		<Window name="W_N">
			...
		</Window>
	</GUI>

=head1 ATTRIBUTES

Elements can additionally be supplemented with attributes that describe its
corresponding Win32::GUI object's properties such as top, left, height and
width. These properties usually include those provided as standard in each
Win32::GUI class. I.e.

	<Window height="200" width="200" title="My Window"/>

Elements that require referencing in your code should be given a name attribute.
An element with attribute: -

	<Button name="MyButton"/>

can be called as $GUI{'name'} and event subroutines called using MyButton_Click.

Attributes can contain Perl code or variables and generally any attribute that
contains a '$' symbol or begins with 'WS_' will be evaluated. This is useful
when one wants to create dynamically sizing windows: -

	<Window 
		name='W'
		left='0' top='0' 
		width='400' height='200' 
		style='WS_CLIPCHILDREN|WS_OVERLAPPEDWINDOW'
	>
		<StatusBar 
			name='S' 
			top='$GUI{W}->ScaleHeight-$GUI{S}->Height' left='0' 
			width='$GUI{W}->ScaleWidth' height='$GUI{S}->Height'
		/>
	</Window>

=head1 AUTO-RESIZING

Win32::GUI::XMLBuilder will autogenerate an _Resize subroutine by reading in values for top, left, height and width.
This will work sufficiently well provided you use values that are dynamic such as $GUI{PARENT_WIDGET}->Width,
$GUI{PARENT_WIDGET}->Height for width, height attributes respectively.

=head1 SUPPORTED WIDGETS

Most Win32::GUI widgets are supported and general type widgets can added without any modification
being added to this module.

=over 4

=item Win32::GUI::TabFrame

<TabFrame ... >

</TabFrame>

=cut

use strict;

require Exporter;

our $VERSION = 0.21;
our @ISA     = qw(Exporter);
our @EXPORT  = qw(%GUI);

=head1 DEPENDENCIES

	XML::Twig
	Win32::GUI
	Win32::GUI::TabFrame 
		(see http://perso.club-internet.fr/rocherl/Win32GUI.html)

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

=head1 METHODS

=over 4

=item Win32::GUI::XMLBuilder::build($xml_string)

Parses $xml_string and constructs a Win32::GUI from its attributes.

=cut

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

=item Win32::GUI::XMLBuilder::buildfile("file.xml")

Parses "file.xml" and constructs a Win32::GUI from its attributes.

=cut

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

# internal helper functions
#

sub evalhash {
	my ($e) = @_;
	my $parent = $e->parent()->{'att'}->{'name'};
	my %in = %{$e->{'att'}};
	my %out;
	foreach my $k (sort keys %in) {
		$out{-$k} = $in{$k} !~ /\$|(^WS_)/ ? $in{$k} : eval $in{$k};
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

sub debug { print "$_[0]\n" if $DEBUG > 0 }

sub error { &debug("XMLBuilder crash!: ".Win32::GetLastError()." $!"); }

=head1 ELEMENTS

=over 4

=item <Script>

The <Script> element is parsed before an GUI construction and is useful for defining subroutines
and global variables. Variables must be declared using 'our' keyword to be accessible in <Script>
elements.

=cut

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

=item <Icon>

The <Icon> element allows you to specify an Icon for your program.

	<Icon file="myicon.ico" name='MyIcon' />

=cut

sub Icon {
	my ($t, $e) = @_;
	my $name = $e->{'att'}->{'name'};
	my $file = $e->{'att'}->{'file'} !~ /\$/ ? $e->{'att'}->{'file'} : eval $e->{'att'}->{'file'};;

	&debug("\nIcon: $name");
	&debug("file -> $file");
	$GUI{$name} = new Win32::GUI::Icon($file) || &error;
}

=item <Font>
	
Allows you to create a font for use in your program.

	<Font 
		name='Bold' 
		size='8' 
		face='Arial' 
		bold='1' 
		italic='0'
	/>

You might call this in a label element using something like this: - 

	<label 
		text='some text' 
		font='$GUI{Bold}' 
		... />.

=cut

sub Font {
	my ($t, $e) = @_;
	my $name = $e->{'att'}->{'name'};

	&debug("\nFont: $name");
	$GUI{$name} = new Win32::GUI::Font(&evalhash($e)) || &error;
}

=item <Class>

You can create a <Class> element,

	<Class name='MyClass' icon='$GUI{MyIcon}'/> 

that can be applied to a <Window .. class='$GUI{MyClass}'>

=cut

sub Class {
	my ($t, $e) = @_;
	my $name = $e->{'att'}->{'name'};

	&debug("\nClass: $name");
	$GUI{$name} = new Win32::GUI::Class(&evalhash($e)) || &error;
}

=item <Menu>

Creates a menu system. The amount of '>'s prefixing a label specifies the menu items
depth. A label '-' (includes '>-', '>>-', etc) creates a separator line.	

	<Menu name='PopupMenu'>
		<Item label='ContextMenu' sub='0'/>
		<Item label='>Cut' sub='OnEditCut'/>
		<Item label='>Copy' sub='OnEditCopy'/>
		<Item label='>Paste' sub='OnEditPaste'/>
		<item label='>-' sub='0' />
		<Item label='>Select All' sub='SelectAll'/>
	</Menu>

See the menus.xml example in the samples/ directory.

=cut

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

=item <Window>

The <Window> element creates a top level widget. In addition to standard
Win32::GUI::Window attributes it also has 'show'. This tells the XMLBuilder
to make the Window visible on startup.

	<Window show='1' ... />

=cut

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

=item <TabFrame>

Uses Laurent Rocher's Win32::GUI::TabFrame module. A Tab strip can be created using the following structure: -

	<TabFrame ...>
		<Item name='P0' text='Zero'>
			<Label text='Tab 1' .... />
		</Item>
		<Item name='P1' text='One'>
			<Label text='Tab 2' .... />
			..other elements, etc...
		</Item>
	</TabFrame>

See the wizard.pl example in the samples/ directory.

=cut

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

=item <TreeView>

Creates a TreeView. These can be nested deeply using the sub element <Item>. Please look at the
treeview.pl example in the samples/ directory.

	<TreeView ..>
		<Item .. />
		<Item ..>
			<Item .. />
			<Item .. />
				etc...
		</item>
		...
	</TreeView>

=cut

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

=item <Combobox>

Generate a combobox with drop down items specified with the <Items> elements. In addition
to standard attributes for Win32::GUI::Combobox there is also a 'dropdown' attribute that
automatically sets the 'style' to 'WS_VISIBLE|2'. In 'dropdown' mode an <Item> element has
the additional attribute 'default'.

=cut

sub Combobox {
	my ($t, $e) = @_;
	my $name = &gename($e);
	my $parent = $e->parent()->{'att'}->{'name'};

	&debug("\nCombobox: $name; Parent: $parent");
	$e->{'att'}->{'style'} = 'WS_VISIBLE|2' if $e->{'att'}->{'dropdown'};
	$GUI{$name} = $GUI{$parent}->AddCombobox(&evalhash($e))  || &error;

	my $default;
	if($e->children_count()) {
		foreach my $item ($e->children()) { 
			next if $item->gi ne 'Item';
			my $text = $item->{'att'}->{'text'};
			$default = $text if $item->{'att'}->{'default'};
			&debug("Item: $text");
			$GUI{$name}->InsertItem($text) || &error;
		}
	}

	$GUI{$name}->Select($GUI{$name}->FindStringExact($default)) if $default;
}

=item <Rebar>

See rebar.xml example in samples/ directory.

=cut

sub Rebar {
	my ($t, $e) = @_;
	my $name = &gename($e);
	my $parent = $e->parent()->{'att'}->{'name'};

	&debug("\nRebar: $name; Parent: $parent");
	$GUI{$name} = $GUI{$parent}->AddRebar(&evalhash($e)) || &error;
	foreach my $item ($e->children()) { 
		my $bname = &gename($item);
		&debug("Band: $bname");

		if ($item->children) {
			$e->{'att'}->{'parent'} = $GUI{$context};
			$e->{'att'}->{'popstyle'} = 'WS_CAPTION|WS_SIZEBOX';
			$e->{'att'}->{'pushstyle'} = 'WS_CHILD';
			&debug("Window: $bname");
			$GUI{$bname} = new Win32::GUI::Window(&evalhash($e)) || &error;
			$item->{'att'}->{'child'} = $GUI{$bname};
		}

		foreach ($item->children()) {
			&debug($_->{'att'}->{'name'});
			&debug($_->gi);
		
			if (exists &{$_->gi}) {
				&{\&{$_->gi}}($t, $_) if exists &{$_->gi};
			}	else {
				&_Generic($t, $_);
			}
		}

		$GUI{$name}->InsertBand(&evalhash($item));

	}
}

=item Generic Elements

Any widget not explicitly mentioned above can be generated by using its name
as an element id. For example a Button widget can be created using: -

	<Button 
		name='B' 
		text='Push Me' 
		left='20' top='0' 
		width='80' height='20'
	/>

=cut

sub _Generic {
	my ($t, $e) = @_;
	my $widget = $e->gi;
	my $name = &gename($e);
	my $parent = $e->parent()->{'att'}->{'name'};

	&debug("\n$widget: $name; Parent: $parent");
	$e->{'att'}->{'parent'} = "\$GUI{$parent}";
	$GUI{$name} = eval "new Win32::GUI::$widget(&evalhash(\$e))"  || &error;
}

1;
