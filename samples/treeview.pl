use strict;
use Win32::GUI::XMLBuilder;
&Win32::GUI::XMLBuilder::build(*DATA);
&Win32::GUI::Dialog;

sub W_Terminate {
	$GUI{W}->PostQuitMessage(0);
	return -1;
}

__END__
<GUI>
	<Icon name='I' file='XMLBuilder.ico'/>
	<Class name='C' icon='$GUI{I}' color='2'/>
	<Window name='W' show='1' left='0' top='0' width='200' height='200' title='Treeview Example' class='C'>
		<StatusBar name='S' text='Blair Sutton 2003' top='$GUI{W}->ScaleHeight-$GUI{S}->Height' left='0' width='$GUI{W}->ScaleWidth' height='$GUI{S}->Height'/>
		<TreeView name='TV' width='$GUI{W}->ScaleWidth' height='$GUI{W}->ScaleHeight-$GUI{S}->Height' lines='1' rootlines='1' buttons='1' visible='1'>
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

