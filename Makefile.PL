use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	'NAME'         => 'Win32::GUI::XMLBuilder',
	'VERSION_FROM' => 'lib/Win32/GUI/XMLBuilder.pm',
	'PM' => {
		'lib/Win32/GUI/XMLBuilder.pm' => '$(INST_LIBDIR)/XMLBuilder.pm',
		'lib/Win32/GUI/Frame.pm'      => '$(INST_LIBDIR)/Frame.pm',
		'lib/Win32/GUI/TabFrame.pm'   => '$(INST_LIBDIR)/TabFrame.pm',
	},
	PREREQ_PM   => {
		'Win32::GUI'	=> '0',
		'XML::Twig'		=> '0',
	},
	($] ge '5.005') ?
	(
		'AUTHOR'   => 'Sutton Blair (blair@odey.com)',
		'ABSTRACT' => 'Build Win32::GUIs using XML',
	)
	: (),
);


