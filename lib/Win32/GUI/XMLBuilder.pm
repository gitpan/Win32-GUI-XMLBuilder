###############################################################################
#
# Win32::GUI::XMLBuilder
#
# 14 Dec 2003 by Blair Sutton <b.sutton@odey.com>
#
# Version: 0.30 (6th June 2004)
#
# Copyright (c) 2004 Blair Sutton. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
###############################################################################

package Win32::GUI::XMLBuilder;

use strict;
require Exporter;
our $VERSION = 0.30;
our @ISA     = qw(Exporter);

our $AUTHOR = "Blair Sutton - 2004 - Win32::GUI::XMLBuilder - $VERSION";

use XML::Twig;
use Win32::GUI;
use Win32::GUI::TabFrame; # included with distribution

=head1 NAME

XMLBuilder - Build Win32::GUIs using XML.

=head1 SYNOPSIS

	use Win32::GUI::XMLBuilder;

	my $gui = Win32::GUI::XMLBuilder->new({file=>"file.xml"});
	my $gui = Win32::GUI::XMLBuilder->new(*DATA);

	Win32::GUI::Dialog;

	sub test {
	 $gui->{Status}->Text("testing 1 2 3..");
	}

	...

	__END__
	<GUI>
	
	..
	</GUI>

=head1 DEPENDENCIES

	XML::Twig
	Win32::GUI

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

can be called as $gui->{'MyButton'} and event subroutines called using MyButton_Click.
From within an XML string the element must be called by $self->{'MyButton'}.

Attributes can contain Perl code or variables and generally any attribute that
contains the variable '$self' or starts with 'exec:' will be evaluated. This is useful
when one wants to create dynamically sizing windows: -

	<Window name='W'
	 left='0' top='0' 
	 width='400' height='200' 
	 style='exec:WS_CLIPCHILDREN|WS_OVERLAPPEDWINDOW'
	>
	 <StatusBar name='S' 
	  left='0' top='$self->{W}->ScaleHeight-$self->{S}->Height' 
	  width='$self->{W}->ScaleWidth' height='$self->{S}->Height'
	 />
	</Window>

NOTE: pos and size attributes are supported but converted to top, left, height and width
attributes on parsing. I suggest using the attribute dim='left,top,width,height' instead
(not an array but an list with brackets).

=head1 AUTO-RESIZING

Win32::GUI::XMLBuilder will autogenerate an onResize NEM method by reading in values for top, left, height and width.
This will work sufficiently well provided you use values that are dynamic such as $self->{PARENT_WIDGET}->Width,
$self->{PARENT_WIDGET}->Height for width, height attributes respectively when creating new widget elements.

=head1 NEM Events

NEM events are supported. When specifying a NEM event such as onClick one must use $self syntax to specify current
Win32::GUI::XMLBuilder object in anonymous subroutines. An attribute of notify='1' is added automatically when an
NEM event is called. One can alo specify other named subroutines by name, but do not prefix with an ampersand! i.e.

	onClick='my_sub' [CORRECT]
	onClick='&my_sub' [INCORRECT]

=cut

# from GUI_Options.cpp, Window.xs, TabStrip.xs, TreeView.xs
#
my @_EVENTS_ = qw(
 MouseMove MouseOver MouseOut MouseDown MouseUp MouseDblClick MouseRightDown MouseRightUp MouseRightDblClick MouseMiddleDown MouseMiddleUp MouseMiddleDblClick
 KeyDown KeyUp
 Timer
 Paint
 Click RightClick DblClick DblRightClick
 GotFocus LostFocus
 DropFiles
 Char
 Deactivate Activate Terminate Minimize Maximize Resize Scroll InitMenu Paint
 Changing Change
 NodeClick Collapse Expand Collapsing Expanding BeginLabelEdit EndLabelEdit KeyDown
);

my %_EVENTS_;
foreach (@_EVENTS_) {
	$_EVENTS_{'on'.$_} = 1;
}

sub evalhash {
	my ($self, $e) = @_;
	#my $parent = $e->parent()->{'att'}->{'name'};

	my %in = %{$e->{'att'}};
	my %out;

	if (exists $in{pos}) {
		if ($in{pos} =~ m/^\[\s*(.+)\s*,\s*(.+)\s*\]$/) {
			($in{top}, $in{left}) = ($1, $2);
			delete $in{pos};
		} else {
			$self->debug("Failed to parse pos '$in{pos}', should have format '[top, left]'");
		}
	}
	
	if (exists $in{size}) {
		if ($in{size} =~ m/^\[\s*(.+)\s*,\s*(.+)\s*\]$/) {
			($in{width}, $in{height}) = ($1, $2);
			delete $in{size};
		} else {
			$self->debug("Failed to parse size '$in{size}', should have format '[width, height]'");
		}
	}
	
	if (exists $in{dim}) {
		if ($in{dim} =~ m/^\s*(.+)\s*,\s*(.+)\s*,\s*(.+)\s*,\s*(.+)\s*$/) {
			($in{left}, $in{top}, $in{width}, $in{height}) = ($1, $2, $3, $4);
			delete $in{dim};
		} else {
			$self->debug("Failed to parse dim '$in{dim}', should have format 'left, top, width, height'");
		}
	}
	
	foreach my $k (sort keys %in) {
		if (exists $_EVENTS_{$k}) {
			$out{-notify} = 1;
			if ($in{$k} =~ /^\s*sub\s*\{.*\}\s*/) {
				$out{-$k} = eval "{ package main; no strict; use Win32::GUI; ".$in{$k}."}"; print STDERR $@ if $@;
			} else {
				$out{-$k} = $in{$k};
			}
		} elsif ($in{$k} =~ /\$self|(^\s*exec:)/) {
			(my $eval = $in{$k}) =~ s/(^\s*exec:)//;
			$out{-$k} = eval "{ package main; no strict; use Win32::GUI; ".$eval."}"; print STDERR $@ if $@;
		} else {
			$out{-$k} = $in{$k};
		}

		$self->debug("\t-$k : $in{$k} -> $out{-$k}");
	}
	
	if ($in{width} ne '' && $in{height} ne '') {
		$self->{_size_}{$self->{_context_}}{$out{-name}} = [$in{width}, $in{height}];
		push @{$self->{_sorder_}{$self->{_context_}}}, $out{-name};
	} # else take parents size?
	
	if ($in{top} ne '' && $in{left} ne '') {
		$self->{_pos_}{$self->{_context_}}{$out{-name}} = [$in{left}, $in{top}];
		push @{$self->{_porder_}{$self->{_context_}}}, $out{-name};
	}
	
	return %out;
}

=head1 AUTO WIDGET NAMING

Win32::GUI::XMLBuilder will autogenerate a name for a wiget if a 'name' attribute is not
provided. The current naming convention is Widget_Class_N where N is a number. For example
Button_1, Window_23, etc...

=cut

sub genname {
	my ($self, $e) = @_;
	if ($e->{'att'}->{'name'} eq '') {
		my $i = 0;
		while () { 
			if (!exists $self->{$e->gi.'_'.$i}) {
				$e->set_att(name=>$e->gi.'_'.$i);
				last;
			}
			$i++;
		}
	}
	return $e->{'att'}->{'name'};
}

=head1 ENVIRONMENT VARIABLES

=over 4

=item WIN32GUIXMLBUILDER_DEBUG

Setting this to 1 will produce logging. 

=cut

sub debug {
	my $self = shift;
	print "$_[0]\n" if $ENV{WIN32GUIXMLBUILDER_DEBUG};
}

sub error {
	my $self = shift;
	$self->debug("Win32:GUI::XMLBuilder error: $^E $!");
	print STDERR "Win32:GUI::XMLBuilder error: $^E $!\n";
}

=head1 METHODS

=over 4

=item new({file=>$file}) or new($xmlstring)

=cut

sub new {
	my $this = shift;
	my $self = {};
	$self->{_context_} = undef; # holds current proginitor Window name
	$self->{_show_}    = undef; # $self->{_show_}{progenitor} = COMMAND
	$self->{_size_}    = undef; # $self->{_size_}{progenitor}{child} - widget sizes for _resize
	$self->{_sorder_}  = undef; # $self->{_sorder_}{progenitor} = (child1, child2, ...) - order of widgets to be resized
	$self->{_pos_}     = undef; # $self->{_pos_}{progenitor}{child} - widget positions for _resize
	$self->{_porder_}  = undef; # $self->{_porder_}{progenitor} = (child1, child2, ...) - order of widgets to be resized

	bless($self, (ref($this) || $this));

	my $s = new XML::Twig(
		TwigHandlers => { 
			Script     => sub { $self->PreExec(@_) },
			PreExec    => sub { $self->PreExec(@_) },
		}
	);

	if (ref($_[0]) eq 'HASH') {
		$self->debug("processing file ${$_[0]}{file}");
		$s->parsefile(${$_[0]}{file})
	}
	else {
		$s->parse($_[0])
	}

	my $t = new XML::Twig( 
		TwigHandlers => { 
			Icon      => sub { $self->_GenericFile(@_) },
			Bitmap    => sub { $self->_GenericFile(@_) },
			Cursor    => sub { $self->_GenericFile(@_) },
			ImageList => sub { $self->ImageList(@_) },
			Font      => sub { $self->Font(@_) },
			Class     => sub { $self->Class(@_) },
			Menu      => sub { $self->Menu(@_) },
			Window    => sub { $self->Window(@_) }, 
		}
	);

	$t->parse($s->sprint);

	foreach (sort keys %{$self->{_show_}}) {
		$self->debug("show widget $_ with command ${$self->{_show_}}{$_}");
		$self->{$_}->Show(${$self->{_show_}}{$_});
	}

	my $u = new XML::Twig(
		TwigHandlers => { 
			PostExec    => sub { $self->PostExec(@_) },
		}
	);

	$u->parse($t->sprint);

	return $self;
}


=head1 SUPPORTED WIDGETS - ELEMENTS

Most Win32::GUI widgets are supported and general type widgets can added without any modification
being added to this module.

=over 4

=item <PreExec>

The <PreExec> element is parsed before GUI construction and is useful for defining subroutines
and global variables. Code is wrapped in a { package main; no strict; .. } so that if subroutines
are created they can contain variables in your program including Win32::GUI::XMLBuilder instances.
The current Win32::GUI::XMLBuilder instance can also be accessed outside subroutines as $self.

Since you may need to use a illegal XML characters within this element such as
	
	<  less than      (&lt;) 
	>  greater than   (&gt;)
	&  ampersand      (&amp;)
	'  apostrophe     (&apos;)
	"  quotation mark (&quot;)

you can use the alternative predefined entity reference or enclose this data in a "<![CDATA[" "]]>" section. 
Please look at the samples and read http://www.w3schools.com/xml/xml_cdata.asp.

The <PreExec> element was previously called as <Script> and is deprecated. The <Script> tage remains
only for backward compatibility and will be removed in a later release.

=cut

sub PreExec {
	my ($self, $t, $e) = @_;

	$self->debug($e->text);
	my $ret = eval "{ package main; no strict; ".$e->text."}";
	print STDERR "$@" if $@;
	$self->debug($ret);
	$e->set_text('');
	my $pcdata= XML::Twig::Elt->new(XML::Twig::ENT, $ret);
	$pcdata->paste($e);
	$e->erase();
}

=item <PostExec>

The <PostExec> element is parsed after GUI construction and allows code to be included at the end of an XML file.
It otherwise behaves exactly the same as <PreExec> and can be used to place _Resize subroutines.

=cut

sub PostExec {
	my ($self, $t, $e) = @_;

	$self->debug($e->text);
	my $ret = eval "{ package main; no strict; ".$e->text."}";
	print STDERR "$@" if $@;
	$self->debug($ret);
}

=item <Icon>

The <Icon> element allows you to specify an Icon for your program.

	<Icon file="myicon.ico" name='MyIcon' />

The <Bitmap> element allows you to specify an Bitmap for your program.

	<Bitmap file="bitmap.bmp" name='Image' />

The <Cursor> element allows you to specify an Cursor for your program.

	<Icon file="mycursor.cur" name='Cursor' />

=cut

sub _GenericFile {
	my ($self, $t, $e) = @_;
	my $widget = $e->gi;
	my $name = $self->genname($e);
	my $file = $e->{'att'}->{'file'} !~ /\$/ ? $e->{'att'}->{'file'} : eval $e->{'att'}->{'file'};;

	$self->debug("\n$widget (_GenericFile): $name");
	$self->debug("file -> $file");
	$self->{$name} = eval "new Win32::GUI::$widget('$file')"  || $self->error;
}

=item <ImageList>

	<ImageList name='IL' width='16' height='16' maxsize='10'>
	 <Item bitmap='one.bmp'/>
	 <Item bitmap='two.bmp'/>
	 <Item bitmap='$self->{Bitmap}'/>
	</ImageList>

=cut

sub ImageList {
	my ($self, $t, $e) = @_;
	my $name = $self->genname($e);
	my $width   = $e->{'att'}->{'width'}  || 16;
	my $height  = $e->{'att'}->{'height'} || 16;
	my $initial = $e->children_count();
	my $growth  = $e->{'att'}->{'growth'} || (2 * $initial);

	$self->debug("\nImageList: $name");
	$self->{$name} = new Win32::GUI::ImageList($width, $height, 0, $initial, $growth) || $self->error;

	foreach ($e->children()) { 
		$self->{$name}->Add($_->{'att'}->{'bitmap'}, $_->{'att'}->{'mask'});
		$self->debug($_->{'att'}->{'bitmap'});
	}
}

=item <Font>
	
Allows you to create a font for use in your program.

	<Font name='Bold' 
	 size='8' 
	 face='Arial' 
	 bold='1' 
	 italic='0'
	/>

You might call this in a label element using something like this: - 

	<label 
	 text='some text' 
	 font='$self->{Bold}' 
	 ... 
	/>.

=cut

sub Font {
	my ($self, $t, $e) = @_;
	my $name = $self->genname($e);

	$self->debug("\nFont: $name");
	$self->{$name} = new Win32::GUI::Font($self->evalhash($e)) || $self->error;
}

=item <Class>

You can create a <Class> element,

	<Class name='MyClass' icon='$self->{MyIcon}'/> 

that can be applied to a <Window .. class='$self->{MyClass}'>. The name of a class must be unique
over all instances of Win32::GUI::XMLBuilder instances!

=cut

sub Class {
	my ($self, $t, $e) = @_;
	my $name = $self->genname($e);

	$self->debug("\nClass: $name");
	$self->{$name} = new Win32::GUI::Class($self->evalhash($e)) || $self->error;
}

=item <Menu>

Creates a menu system. The amount of '>'s prefixing a text label specifies the menu items
depth. A value of text '-' (includes '>-', '>>-', etc) creates a separator line. To access
named menu items one must use the menu widgets name, i.e. $gui->{PopupMenu}->{SelectAll}, 
although one can access an event by its name, i.e. SelectAll_Click. One can also use NEM
events directly as attributes such as onClick, etc..

	<Menu name='PopupMenu'>
	 <Item text='ContextMenu'/>
	 <Item  name='OnEditCut' text='>Cut'/>
	 <Item name='OnEditCopy' text='>Copy'/>
	 <Item name='OnEditPaste' text='>Paste'/>
	 <item text='>-' />
	 <Item name='SelectAll' text='>Select All'/>
	 <item text='>-' />
	 <Item name='Mode' text='>Mode' checked='1'/>
	</Menu>

See the menus.xml example in the samples/ directory.

=cut

sub Menu {
	my ($self, $t, $e) = @_;
	my $name = $self->genname($e);

	my @m;
	foreach ($e->children()) {
		$_->{'att'}->{'name'} = '0' if ! exists $_->{'att'}->{'name'};
		my $label = $_->{'att'}->{'text'};
		$self->debug("$label:");
		delete $_->{'att'}->{'text'}; # prevents preformated text becoming label
		push @m, $label, { $self->evalhash($_) };
	}
	$self->debug("\nMenu: $name");
	$self->{$name} = Win32::GUI::MakeMenu(@m) || $self->error;
}

=item <Window>

The <Window> element creates a top level widget. In addition to standard
Win32::GUI::Window attributes it also has a 'show=n' attribute. This instructs XMLBuilder
to give the window a Show(n) command on invocation.

	<Window show='0' ... />

NOTE: Since the onResize event is defined automatically for the this element one must set
the attribute 'eventmodel' to 'both' to allow <Window_Name>_Event events to be caught!

=cut

sub Window { 
	my ($self, $t, $e) = @_;
	my $name = $self->genname($e); # should this be allowed?
	my $show = $e->{'att'}->{'show'};

	$self->{_context_} = $name;
	
	$e->{'att'}->{'onResize'} = eval "{
		package main; no strict;
		sub {
			foreach (\@{\$self->{_sorder_}{$name}}) {
				\$self->debug(\"\$_ -> Resize[\$self->{_size_}{$name}{\$_}[0], \$self->{_size_}{$name}{\$_}[1]]\"); 
				\$self->{\$_}->Resize(eval \$self->{_size_}{$name}{\$_}[0], eval \$self->{_size_}{$name}{\$_}[1]) if \$_ ne '$name'; 
			}
			foreach (\@{\$self->{_porder_}{$name}}) {
				\$self->debug(\"\$_ -> Move[\$self->{_pos_}{$name}{\$_}[0], \$self->{_pos_}{$name}{\$_}[1]]\"); 
				\$self->{\$_}->Move(eval \$self->{_pos_}{$name}{\$_}[0], eval \$self->{_pos_}{$name}{\$_}[1]) if \$_ ne '$name'; 
			}
		}
	}";	print STDERR $@ if $@;

	$self->debug("\nWindow: $name");
	$self->{$name} = new Win32::GUI::Window($self->evalhash($e)) || $self->error;
	${$self->{_show_}}{$name} = $show eq '' ? 1 : $show;

	foreach ($e->children()) {
		$self->debug($_->{'att'}->{'name'});
		if (exists &{$_->gi}) {
			&{\&{$_->gi}}($self, $t, $_);
		}	else {
			$self->_Generic($t, $_);
		}
	}
}

=item <TabFrame>

A Tab strip can be created using the following structure: -

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
	my ($self, $t, $e) = @_;
	my $name = $self->genname($e);
	my $parent = $e->parent()->{'att'}->{'name'};
	$e->{'att'}->{'panel'} = 'Page';

	$self->debug("\nTabFrame $name; Parent: $parent");
	$self->{$name} = $self->{$parent}->AddTabFrame($self->evalhash($e)) || $self->error;
	my $i = 0;
	foreach my $item ($e->children()) { 
		my $iname = $item->{'att'}->{'name'};
		$self->debug("Item $i: $iname");
		$self->{$name}->InsertItem($self->evalhash($item));
		$self->{$iname} = ${$self->{$name}}{"Page$i"}; # need to be verbose here!
		$self->{_size_}{$self->{_context_}}{$iname} = [$self->{_size_}{$self->{_context_}}{$name}[0], $self->{_size_}{$self->{_context_}}{$name}[1]]; # set Page size to parents
		$i++;

		foreach ($item->children()) {
			$self->debug($_->{'att'}->{'name'});
			$self->debug($_->gi);

			if (exists &{$_->gi}) {
				&{\&{$_->gi}}($self, $t, $_);
			}	else {
				$self->_Generic($t, $_);
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
	my ($self, $t, $e) = @_;
	my $name = $self->genname($e);
	my $parent = $e->parent()->{'att'}->{'name'};

	$self->debug("\nTreeView: $name; Parent: $parent");
	$self->{$name} = $self->{$parent}->AddTreeView($self->evalhash($e))  || $self->error;

	if($e->children_count()) {
		$self->TreeView_Item($e, $name);
	}
}

sub TreeView_Item {
	my ($self, $e, $parent) = @_;
	my $name = $e->{'att'}->{'name'};
	foreach my $item ($e->children()) { 
		next if $item->gi ne 'Item';
		my $iname = $item->{'att'}->{'name'};
		$self->debug("Item: $iname; Parent: $name");
		$item->{'att'}->{'parent'} = "\$self->{$name}" if $name ne $parent;
		$self->{$iname} = $self->{$parent}->InsertItem($self->evalhash($item)) || $self->error;
		if($item->children_count()) {
			$self->TreeView_Item($item, $parent);
		}
	}
}

=item <Combobox>

Generate a combobox with drop down items specified with the <Items> elements. In addition
to standard attributes for Win32::GUI::Combobox there is also a 'dropdown' attribute that
automatically sets the 'style' to 'exec:WS_VISIBLE|0x3|WS_VSCROLL|WS_TABSTOP'. In 'dropdown'
mode an <Item> element has the additional attribute 'default'.

=cut

sub Combobox {
	my ($self, $t, $e) = @_;
	my $name = $self->genname($e);
	my $parent = $e->parent()->{'att'}->{'name'};

	$self->debug("\nCombobox: $name; Parent: $parent");
    
	$e->{'att'}->{'style'} = 'exec:WS_VISIBLE|0x3|WS_VSCROLL|WS_TABSTOP' if $e->{'att'}->{'dropdown'};
    
	$self->{$name} = $self->{$parent}->AddCombobox($self->evalhash($e))  || $self->error;

	my $default;
	if($e->children_count()) {
		foreach my $item ($e->children()) { 
			next if $item->gi ne 'Item';
			my $text = $item->{'att'}->{'text'};
			$default = $text if $item->{'att'}->{'default'};
			$self->debug("Item: $text");
			$self->{$name}->InsertItem($text) || $self->error;
		}
	}

	$self->{$name}->Select($self->{$name}->FindStringExact($default)) if $default;
}

=item <Listbox>

Generate a listbox with drop down items specified with the <Items> elements. In addition
to standard attributes for Win32::GUI::Listbox there is also a 'dropdown' attribute that
automatically sets the 'style' to 'exec:WS_CHILD|WS_VISIBLE|1'. In 'dropdown' mode an <Item> element has
the additional attribute 'default'.

=cut

sub Listbox {
	my ($self, $t, $e) = @_;
	my $name = $self->genname($e);
	my $parent = $e->parent()->{'att'}->{'name'};

	$self->debug("\nListbox: $name; Parent: $parent");
	$e->{'att'}->{'style'} = $e->{'att'}->{'dropdown'} ? 'exec:WS_VSCROLL|WS_CHILD|WS_VISIBLE|1' : 'exec:WS_VSCROLL|WS_VISIBLE|WS_CHILD';
	$self->{$name} = $self->{$parent}->AddListbox($self->evalhash($e))  || $self->error;

 # $self->{$name}->SendMessage(0x0195, 201, 0);

	my $default;
	if($e->children_count()) {
		foreach my $item ($e->children()) { 
			next if $item->gi ne 'Item';
			my $text = $item->{'att'}->{'text'};
			$default = $text if $item->{'att'}->{'default'};
			$self->debug("Item: $text");
			$self->{$name}->AddString($text) || $self->error;
		}
	}

	$self->{$name}->Select($self->{$name}->FindStringExact($default)) if $default;
}

=item <Rebar>

See rebar.xml example in samples/ directory.

=cut

sub Rebar {
	my ($self, $t, $e) = @_;
	my $name = $self->genname($e);
	my $parent = $e->parent()->{'att'}->{'name'};

	$self->debug("\nRebar: $name; Parent: $parent");
	$self->{$name} = $self->{$parent}->AddRebar($self->evalhash($e)) || $self->error;
	foreach my $item ($e->children()) { 
		my $bname = $self->genname($item);
		$self->debug("Band: $bname");

		if ($item->children) {
			$e->{'att'}->{'parent'} = $self->{$self->{_context_}};
			$e->{'att'}->{'popstyle'} = 'exec:WS_CAPTION|WS_SIZEBOX';
			$e->{'att'}->{'pushstyle'} = 'exec:WS_CHILD';
			$self->debug("Window: $bname");
			$self->{$bname} = new Win32::GUI::Window($self->evalhash($e)) || $self->error;
			$item->{'att'}->{'child'} = $self->{$bname};
		}

		foreach ($item->children()) {
			$self->debug($_->{'att'}->{'name'});
			$self->debug($_->gi);
		
			if (exists &{$_->gi}) {
				&{\&{$_->gi}}($self, $t, $_);
			}	else {
				$self->_Generic($t, $_);
			}
		}

		$self->{$name}->InsertBand($self->evalhash($item));

	}
}

=item Generic Elements

Any widget not explicitly mentioned above can be generated by using its name
as an element id. For example a Button widget can be created using: -

	<Button name='B' 
	 text='Push Me' 
	 left='20' top='0' 
	 width='80' height='20'
	/>

=cut

sub _Generic {
	my ($self, $t, $e) = @_;
	my $widget = $e->gi;
	my $name = $self->genname($e);
	my $parent = $e->parent()->{'att'}->{'name'};

	$self->debug("\n$widget (_Generic): $name; Parent: $parent");
	$e->{'att'}->{'parent'} = "\$self->{$parent}";
	$self->{$name} = eval "new Win32::GUI::$widget(\$self->evalhash(\$e))"  || $self->error;
}

1;
