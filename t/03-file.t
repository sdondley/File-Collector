#/usr/bin/env perl
use Test::Most;
use Log::Log4perl::Shortcuts qw(:all);
use Dondley::WestfieldVote::File;












my $tests = 1; # keep on line 17 for ,i (increment and ,d (decrement)
plan tests => $tests;
diag( "Running my tests" );

my $file;
lives_ok {
  $file = Dondley::WestfieldVote::File->new('/Users/stevedondley/Library/Application Support/Dondley-WestfieldVote/voter_files/westfield/test/unmodified/munis/2009-11-03-muni.csv');
} 'can create object';

logd $file->short_path;
logd $file->suffix;
logd $file->dirs;
logd $file->election_type;
logd $file->election_label;
logd $file->modified_path;
logd $file->unmodified_path;
