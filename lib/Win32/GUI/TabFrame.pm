#
# by Laurent Rocher
# 
# http://perso.club-internet.fr/rocherl/Win32GUI.html
#
package Win32::GUI::TabFrame;

my $VERSION = "0.02";

use Win32::GUI;
use Win32::GUI::Frame;

@ISA = qw(Win32::GUI::TabStrip);

my %Instance = {};

#
# new
#
sub new {

  my $class   = shift;
  my $parent  = shift;
  my %options = @_;

  my $panel   = "Panel";  # Default Panel Name

  $panel = $options{-panel} if exists $options{-panel};

  # New TabStrip
  my $self = new Win32::GUI::TabStrip ($parent, %options);


  # Init instance variable
  $self->{'#LastPanel'} = 0;
  $self->{'#Panel'}     = $panel;

  # Keep object reference
  $Instance{$options{-name}} = $self;

  # Add Click Event
  eval qq(

       sub main::$options{-name}_Click {
           return Win32::GUI::TabFrame->ClickEvent($options{-name});
       }
   );

  return bless $self, $class;
}

#
#  AddSSTab
#
sub Win32::GUI::Window::AddTabFrame {

    return Win32::GUI::TabFrame->new(@_);
}

#
# DisplayArea
#
sub DisplayArea {

    my $self = shift;
    my ($left,$top,$right,$botton) = $self->AdjustRect($self->GetClientRect());

    return ($left, $top, $right - $left, $botton - $top);
}

#
# Insert Element
#
sub InsertItem {

  my $self = shift;
  my %options = @_;

  # Add a panel
  my $count = $self->Count();
  my $name  = $self->{'#Panel'}.$count;

  my $border = 0;
  my $text   = "";

  if (exists $options{-border}) {
    $border = $options{-border}
  }

  if (exists $options{-paneltext}) {
    $text = $options{-paneltext}
  }

  my ($x,$y,$width,$height) = $self->DisplayArea();

  my $panel = $self->AddFrame (
     -name    => $name,
     -text    => $text,
     -pos     => [$x, $y],
     -size    => [$width, $height],
     -border  => $border,
  );

  # Only show first page
  $panel->Hide() unless ($count == 0);

  # Add TabStrip
  $self->SUPER::InsertItem(%options);

  return $panel;
}

#
#  Resize
#
sub Resize {

  my $self   = shift;
  my $width  = shift;
  my $height = shift;

  $self->SUPER::Resize ($width, $height);

  my ($ax,$ay,$awidth,$aheight) = $self->DisplayArea();

  my $count = $self->Count();

  for ($i = 0; $i < $count; $i++) {
    my $page = $self->{'#Panel'}.$i;
    $self->{$page}->Move  ($ax , $ay);
    $self->{$page}->Resize($awidth, $aheight);
  }

}

#
# Reset :
#
sub Reset {

  my $self   = shift;

  my $count = $self->Count();

  for ($i = 0; $i < $count; $i++) {
    my $page = $self->{'#Panel'}.$i;
    $self->{$page}->DestroyWindow();
  }

  $self->{'#LastPage'} = 0;
  return $self->SUPER::Reset();
}

#
# DeleteItem :
#
sub DeleteItem {

  die "Win32:GUI::TabFrame : Methode DeleteItem not working";
}

#
#  ClickEvent
#
sub ClickEvent {

  my $class   = shift;
  my $name    = shift;

  my $element = $Instance{$name};
  my $page    = $element->{'#Panel'}.$element->{'#LastPanel'};

  # Hide Last Page
  $element->{$page}->Hide();

  # Show New Page
  $element->{'#LastPanel'} = $element->SelectedItem();
  $page = $element->{'#Panel'}.$element->{'#LastPanel'};
  $element->{$page}->Show();

}

1;
