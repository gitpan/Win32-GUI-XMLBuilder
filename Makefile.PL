use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'         => 'Win32::GUI::XMLBuilder',
    'VERSION_FROM' => 'lib/Win32/GUI/XMLBuilder.pm',
     ($] ge '5.005')
     ? (
      'AUTHOR'   => 'Sutton Blair (blair@odey.com)',
      'ABSTRACT' => 'Build Win32::GUIs using XML',
     )
     : (),
);


