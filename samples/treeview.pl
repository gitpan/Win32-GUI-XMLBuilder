use strict;
use Win32::GUI::XMLBuilder;
$ENV{WIN32GUIXMLBUILDER_DEBUG} = 0;
my $gui = Win32::GUI::XMLBuilder->new(*DATA);
Win32::GUI::Dialog;

__END__
<GUI>
	<Icon name='I' file='XMLBuilder.ico'/>
	<Class name='C' icon='$self->{I}'/>
	<Window name='W'
		dim='0,0,200,200' 
		show='1'
		title='Treeview Example'
		class='$self->{C}'
	>
		<StatusBar name='S' text='exec:$Win32::GUI::XMLBuilder::AUTHOR' dim='0, $self->{W}->ScaleHeight-$self->{S}->Height, $self->{W}->ScaleWidth, $self->{S}->Height'/>
		<TreeView name='TV' width='$self->{W}->ScaleWidth' height='$self->{W}->ScaleHeight-$self->{S}->Height' lines='1' rootlines='1' buttons='1' visible='1'>
			<Item name='TV_0' text='TV_0' selectedimage='1'>
				<Item name='TV_0_0' text='TV_0_0'>
					<Item name='TV_0_0_0' text='TV_0_0_0'/>
					<Item name='TV_0_0_1' text='TV_0_0_1'/>
					<Item name='TV_0_0_2' text='TV_0_0_2'/>
				</Item>
				<Item name='TV_0_1' text='TV_0_1'/>
			</Item>
			<Item name='TV_1' text='TV_1' selectedimage='1'>
				<Item name='TV_1_0' text='TV_1_0'/>
				<Item name='TV_1_1' text='TV_1_1'/>
				<Item name='TV_1_2' text='TV_1_2'/>
				<Item name='TV_1_3' text='TV_1_3'/>
			</Item>
		</TreeView>
	</Window>
</GUI>

