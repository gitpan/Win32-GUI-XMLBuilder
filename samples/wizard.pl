use strict;
use Win32::GUI::XMLBuilder;
&Win32::GUI::XMLBuilder::build(*DATA);
&Win32::GUI::Dialog;

sub W_Terminate {
	$GUI{W}->PostQuitMessage(0);
	return -1;
}

sub Form_Changing {
	return 0;
}

sub B0_Click {
	$GUI{P0}->Hide();
	$GUI{P1}->Show();
	$GUI{Form}->Select(1);
}

sub B10_Click {
	$GUI{P1}->Hide();
	$GUI{P0}->Show();
	$GUI{Form}->Select(0);
}

sub B11_Click {
	$GUI{P1}->Hide();
	$GUI{P2}->Show();
	$GUI{Form}->Select(2);
}

sub B20_Click {
	$GUI{P2}->Hide();
	$GUI{P1}->Show();
	$GUI{Form}->Select(1);
}

sub B21_Click {
	$GUI{P2}->Hide();
	$GUI{P3}->Show();
	$GUI{Form}->Select(3);
}

sub B30_Click {
	$GUI{P3}->Hide();
	$GUI{P2}->Show();
	$GUI{Form}->Select(2);
}

sub B31_Click {
	$GUI{W}->PostQuitMessage(0);
	return -1;
}

__END__
<GUI>
	<Icon name='I' file='XMLBuilder.ico'/>
	<Class name='C' icon='$GUI{I}' color='2'/>
	<Window show='1' name='W' left='0' top='0' width='400' height='200' title='Wizard Example' style='WS_CLIPCHILDREN|WS_OVERLAPPEDWINDOW' class='$GUI{C}'>
		<StatusBar name='S' text='Blair Sutton 2003' top='$GUI{W}->ScaleHeight-$GUI{S}->Height' left='0' width='$GUI{W}->ScaleWidth' height='$GUI{S}->Height'/>
		<TabFrame name='Form' left='0' top='0' width='$GUI{W}->ScaleWidth' height='$GUI{W}->ScaleHeight-$GUI{S}->Height'>
			<Item name='P0' text='Zero'>
				<Label text='Please press "Next" to continue...' left='50' top='50' width='$GUI{P0}->Width-50' height='$GUI{P0}->Height-50'/>
				<Button name='B0' text='Next >' left='$GUI{P0}->Width-100' top='$GUI{P0}->Height-40' width='60' height='20'/>
			</Item>
			<Item name='P1' text='One'>
				<Label text='Page 2 - Please press "Next" to continue...' left='50' top='50' width='$GUI{P0}->Width-50' height='$GUI{P0}->Height-50'/>
				<Button name='B10' text='&lt; Back' left='$GUI{P1}->Width-170' top='$GUI{P1}->Height-40' width='60' height='20'/>
				<Button name='B11' text='Next >' left='$GUI{P1}->Width-100' top='$GUI{P1}->Height-40' width='60' height='20'/>
			</Item>
			<Item name='P2' text='Two'>
				<Label text='Page 3 - Please press "Next" to continue...' left='50' top='50' width='$GUI{P0}->Width-50' height='$GUI{P0}->Height-50'/>
				<Button name='B20' text='&lt; Back' left='$GUI{P2}->Width-170' top='$GUI{P2}->Height-40' width='60' height='20'/>
				<Button name='B21' text='Next >' left='$GUI{P2}->Width-100' top='$GUI{P2}->Height-40' width='60' height='20'/>
			</Item>
			<Item name='P3' text='Three'>
				<Label text='Please press "Finish" to complete.' left='50' top='50' width='$GUI{P0}->Width-50' height='$GUI{P0}->Height-50'/>
				<Button name='B30' text='&lt; Back' left='$GUI{P3}->Width-170' top='$GUI{P3}->Height-40' width='60' height='20'/>
				<Button name='B31' text='Finish' left='$GUI{P3}->Width-100' top='$GUI{P3}->Height-40' width='60' height='20'/>
			</Item>
		</TabFrame>
	</Window>
</GUI>

