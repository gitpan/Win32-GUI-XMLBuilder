use strict;
use Win32::GUI::XMLBuilder;
$ARGV[0] eq '' ? &Win32::GUI::XMLBuilder::build(*DATA) : &Win32::GUI::XMLBuilder::buildfile($ARGV[0]);
&Win32::GUI::Dialog;

sub _W_Terminate {
	$GUI{_W}->PostQuitMessage(0);
	return -1;
}

sub _B_Click {
	my $f = GUI::GetOpenFileName(
		-title     => 'Choose XML file...',
		-directory => '.',
		-filter    => [ 
			"XMLBuilder (*.xml)" => "*.xml", 
			"All files", 
			"*.*",	
		],
	);

	if ($f ne '') {
		&Win32::GUI::XMLBuilder::buildfile($f);
	}
}

__END__
<GUI>
	<Icon name='_I' file='XMLBuilder.ico'/>
	<Class name='_C' icon='$GUI{_I}' />
	<Window name='_W' show='1' left='100' top='100' width='250' height='100' title='Buildfile Example' class='_C'>
		<Label text='Usage: buildfile.pl &lt;xmlfile>...' left='20' top='10' width='$GUI{_W}->Width-50' height='$GUI{_W}->Height-50'/>
		<Button name='_B' text='Open XML file...' left='20' top='$GUI{_W}->Height-70' width='100' height='20'/>
	</Window>
</GUI>

