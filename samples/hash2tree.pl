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
	<Icon name='I' file='XMLBuilder.ico'/>
	<Class name='C' icon='$self->{I}'/>
	<Window name='W'
		dim='0, 0, 300, 250'
		title='Hash to Treeview Example'
		class='$self->{C}'
	>
		<StatusBar name='S'
			dim='0, $self->{W}->ScaleHeight - $self->{S}->Height, $self->{W}->ScaleWidth, $self->{S}->Height'
			text='exec:$Win32::GUI::XMLBuilder::AUTHOR'
		/>
		<TreeView
			width='$self->{W}->ScaleWidth' height='$self->{W}->ScaleHeight-$self->{S}->Height'
			lines='1' rootlines='1' buttons='1' visible='1'
		>
			<PreExec>
				return hashwalk(\%R, 2)
			</PreExec>
		</TreeView>
	</Window>
</GUI>

