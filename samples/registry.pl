use strict;

use Win32::TieRegistry(Delimiter=>"|", ArrayValues=>0);
our $registry = &initRegistry();

use Win32::GUI::XMLBuilder;
$ENV{WIN32GUIXMLBUILDER_DEBUG} = 0;
my $gui = Win32::GUI::XMLBuilder->new(*DATA);
Win32::GUI::Dialog;

sub W_Terminate {
	print STDERR "Saving registry...\n";
	$registry->{width}  = $gui->{W}->ScaleWidth;
	$registry->{height} = $gui->{W}->ScaleHeight;
	$registry->{left}   = $gui->{W}->Left;
	$registry->{top}    = $gui->{W}->Top;
	print STDERR "$registry->{width} x $registry->{height} @ ($registry->{left}, $registry->{top})\n";
	$gui->{W}->PostQuitMessage(0);
	return -1;
}

sub initRegistry {
	my $registry = $Registry->{"CUser|Software|BlairSutton|XMLBuilder|"};
	if ($registry eq '') {
		print STDERR "no BlairSutton|XMLBuilder registry, creating...\n";
		$Registry->{"CUser|Software|"} = {
			"BlairSutton|" => {
				"XMLBuilder|" => {
					"|top"    => "0",
					"|left"   => "0",
					"|width"  => "200",
					"|height" => "200",
				}
			}
		};
		$registry = $Registry->{"CUser|Software|BlairSutton|XMLBuilder|"};
	}
	return $registry;
}

__END__
<GUI>
	<Icon name='I' file='XMLBuilder.ico'/>
	<Class name='C' icon='$self->{I}'/>
	<Window name='W'
		dim='exec:$registry->{left}, exec:$registry->{top}, exec:$registry->{width}, exec:$registry->{height}'
		title='Persistent Registry Settings Example'
		class='$self->{C}'
		eventmodel='both'
	>
		<StatusBar name='S'
			dim='0, $self->{W}->ScaleHeight-$self->{S}->Height, $self->{W}->ScaleWidth, $self->{S}->Height'
			text='exec:$Win32::GUI::XMLBuilder::AUTHOR'
		/>
	</Window>
</GUI>

