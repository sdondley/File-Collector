#/usr/bin/env perl
use Test::Most;
use Log::Log4perl::Shortcuts qw(:all);
use Dondley::WestfieldVote::Files;
#$| = 1;








#*STDOUT = *STDERR;


my $tests = 1; # keep on line 17 for ,i (increment and ,d (decrement)
diag( "Running my tests" );

`rm -rf t/test_data/add_headers`;
`cp -r t/test_data/add_headers_orig t/test_data/add_headers`;

set_dir('t/test_data/add_headers');
fix_files();
add_missing_key_headers();
