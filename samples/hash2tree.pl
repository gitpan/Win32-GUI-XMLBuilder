#
# demonstrates how to create a treeview from a hash
#
use strict;

our %R; # this variable must be global to Win32::GUI::XMLBuilder!
use Win32::TieRegistry(Delimiter=>"|", ArrayValues=>0, TiedHash=>\%R);

use Win32::GUI::XMLBuilder;
$ENV{WIN32GUIXMLBUILDER_DEBUG} = 0;
my $gui = Win32::GUI::XMLBuilder->new(*DATA);
Win32::GUI::Dialog;

sub hashwalk {
	my ($href, $n) = @_;
	my $o;
	$n == 0 ? return : $n--;
	foreach my $key (keys %$href) {
		$key =~ s/\|//;
    (my $txt  = $key) =~ s/(?:'|"|&|<|>)//;
		$o .= ref($$href{$key}) ne "SCALAR" ? 
			"<Item name='$txt' text='$txt'>".&hashwalk($$href{$key}, $n)."</Item>" :
			"<Item name='$txt' text='$txt'/>" ; 
	}
	return $o;
}

__END__
<GUI>
	<Class name='C' icon='exec:$Win32::GUI::XMLBuilder::ICON'/>
	<Window name='W'
		dim='0, 0, 300, 250'
		title='Hash to Treeview Example'
		class='$self->{C}'
	>
		<StatusBar name='S'
			top='exec:$self->{W}->ScaleHeight - $self->{S}->Height if defined $self->{S}'
			height='exec:$self->{S}->Height if defined $self->{S}'
			text='exec:$Win32::GUI::XMLBuilder::AUTHOR'
		/>
		<TreeView
			height='$self->{W}->ScaleHeight - $self->{S}->Height'
			lines='1' rootlines='1' buttons='1' visible='1'
		>
			<WGXPre>return hashwalk(\%R, 2)</WGXPre>
		</TreeView>
	</Window>
</GUI>

