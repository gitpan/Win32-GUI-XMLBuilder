use strict;

use Win32::TieRegistry( Delimiter=>"|", ArrayValues=>0 );
our $registry = &initRegistry();

use Win32::GUI::XMLBuilder;
&Win32::GUI::XMLBuilder::build(*DATA);
&Win32::GUI::Dialog;

sub W_Terminate {
	$registry->{width}  = $GUI{W}->ScaleWidth;
	$registry->{height} = $GUI{W}->ScaleHeight;
	$registry->{left}   = $GUI{W}->Left;
	$registry->{top}    = $GUI{W}->Top;
	$GUI{W}->PostQuitMessage(0);
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
	<Class name='C' icon='$GUI{I}'/>
	<Window name='W' show='1' left='$::registry->{left}' top='$::registry->{top}' width='$::registry->{width}' height='$::registry->{height}' title='Persistent Registry Settings Example' class='C'>
		<StatusBar name='S' text='Blair Sutton 2003' top='$GUI{W}->ScaleHeight-$GUI{S}->Height' left='0' width='$GUI{W}->ScaleWidth' height='$GUI{S}->Height'/>
	</Window>
</GUI>

