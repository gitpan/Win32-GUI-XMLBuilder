#
# buildfile.pl <xml file>
#
# build pure XMLBuilder xml files
#
use strict;
use Win32::GUI::XMLBuilder;

my $_gui;
our $gui;

if ($ARGV[0] eq '') {
	$_gui = Win32::GUI::XMLBuilder->new(*DATA);
} else {
	$gui = Win32::GUI::XMLBuilder->new({file=>$ARGV[0]});
}

Win32::GUI::Dialog;

sub loadGUI {
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
		undef $gui;
		$gui = Win32::GUI::XMLBuilder->new({file=>$f});
	}
}

__END__
<GUI>
	<Icon name='I' file='XMLBuilder.ico'/>
	<Class name='__CLASS__' icon='$self->{I}' />
	<Window
		dim='100, 100, 250, 100'
		title='Build XMLBuilder File'
		class='$self->{__CLASS__}'
		onTerminate='sub { $_[0]->PostQuitMessage(0); return -1; }'
		show='1'
	>
		<Label
			dim='20, 10, 220, 30'
			text='CLI Usage: buildfile.pl &lt;xml file&gt;, or'
			/>
		<Button
			dim='20, 30, 100, 20'
			text='Open XML file...'
			onClick='loadGUI'
		/>
		<Checkbox
			dim='135, 30, 100, 20'
			text='Debug'
			onClick='sub { $ENV{WIN32GUIXMLBUILDER_DEBUG} = $_[0]->Checked; }'
		/>
	</Window>
</GUI>

