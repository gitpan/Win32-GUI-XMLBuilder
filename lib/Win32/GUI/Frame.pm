#
# by Laurent Rocher
# 
# http://perso.club-internet.fr/rocherl/Win32GUI.html
#
package Win32::GUI::Frame;

my $VERSION = "0.02";

use Win32::GUI;

@ISA = qw(Win32::GUI::Window);

#
#  _FilterOptions :
#
sub _FilterOptions {
  my $class = shift;
  my %in    = @_;
  my %out  ;

  $out{-name}    = $in{-name}      if exists $in{-name};
  $out{-text}    = $in{-text}      if exists $in{-text};
  $out{-left}    = $in{-left}      if exists $in{-left};
  $out{-top}     = $in{-top}       if exists $in{-top};
  $out{-width}   = $in{-width}     if exists $in{-width};
  $out{-pos}     = $in{-pos}       if exists $in{-pos};
  $out{-size}    = $in{-size}      if exists $in{-size};
  $out{-visible} = $in{-visible}   if exists $in{-visible};
  $out{-font}    = $in{-font}      if exists $in{-font};

  $out{-border}  = $in{-border}    if exists $in{-border};

  return %out;
}

#
#  new : Create a new Frame object
#
sub new {

  my $class   = shift;
  my $parent  = shift;
  my %options = Win32::GUI::Frame->_FilterOptions(@_);

  ### Default window
  my $constant = Win32::GUI::constant("WIN32__GUI__WINDOW", 0);
  $options{-style}     = WS_CHILD | DS_CONTROL ;
  $options{-exstyle}   = WS_EX_CONTROLPARENT;

  ### Window visible

  $options{-style} |= WS_VISIBLE unless exists $options{-visible} && $options{-visible} == 0;

  ### Window style border

  if (exists $options{-border} ) {

    if ($options{-border} == 1) {
      $options{-style}       |= BS_GROUPBOX;
      $constant = Win32::GUI::constant("WIN32__GUI__GROUPBOX", 0);
    }
    elsif ($options{-border} == 2) {
      $options{-style}       |= WS_BORDER;
    }
    elsif ($options{-border} == 3) {
      $options{-exstyle}     |= WS_EX_STATICEDGE;
    }
    elsif ($options{-border} == 4) {
      $options{-exstyle}     |= WS_EX_CLIENTEDGE;
    }
    elsif ($options{-border} == 5) {
      $options{-style}       |= WS_DLGFRAME;
    }
    elsif ($options{-border} == 6) {
      $options{-style}       |= WS_BORDER;
      $options{-style}       |= WS_SIZEBOX ;
    }
    elsif ($options{-border} == 7) {
      $options{-style}       |= WS_SIZEBOX ;
      $options{-exstyle}     |= WS_EX_STATICEDGE;
    }
    elsif ($options{-border} == 8) {
      $options{-style}       |= WS_SIZEBOX ;
      $options{-exstyle}     |= WS_EX_CLIENTEDGE;
    }
  }

  ### Create window

  return Win32::GUI->_new($constant, $class, $parent, %options);;
}

#
#  Change filter options
#
sub Change {

   my $self    = shift;

   return $self->SUPER::Change(Win32::GUI::Frame->_FilterOptions(@_));
}

#
#  Win32::GUI::Window::AddFrame
#
sub Win32::GUI::Window::AddFrame {

    return Win32::GUI::Frame->new(@_);
}

