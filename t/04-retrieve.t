#/usr/bin/env perl
use Test::Most;
use Test::Warn;
use Log::Log4perl::Shortcuts qw(:all);
use Dondley::WestfieldVote::Files;
use Test::File::ShareDir::Object::Dist;
my $share_dir;
$share_dir = Test::File::ShareDir::Object::Dist->new( dists => { 'Dondley-WestfieldVote' => "share/" } );
$share_dir->install_all_dists;
$share_dir->register;






my $tests = 1; # keep on line 17 for ,i (increment and ,d (decrement)
plan tests => $tests;

diag( "Running my tests" );
set_city('westfield', 1);
#lives_ok { load_data_files(); } 'Can load files';

my $voter_list;
lives_ok { $voter_list = get_voter_list(); } 'Can get voter list';
logd $voter_list->voter_count;
$voter_list->get_agg_party_affiliation;
#logd $voter_list->voters;
#logd $voter_list->num_reg_munis;
#logd $voter_list->num_pri_munis;
#logd $voter_list->num_total_munis;

$voter_list->get_muni_score_breakdown;
my $likely = $voter_list->collect_likely_voters;
logd scalar @{$likely->{'Ultra Super Voters'}};
logd scalar @{$likely->{'Very Super Voters'}};
logd scalar @{$likely->{'Super Voters'}};
logd scalar @{$likely->{'Strong Likely Voters'}};
logd scalar @{$likely->{'Likely Voters'}};
logd scalar @{$likely->{'Less Likely Voters'}};
logd scalar @{$likely->{'Strong Emerging Voters'}};
logd scalar @{$likely->{'Weak Emerging Voters'}};
logd scalar @{$likely->{'Weak Perfect Voters'}};
logd scalar @{$likely->{'Very Strong Perfect Voters'}};
logd scalar @{$likely->{'Strong Perfect Voters'}};
logd scalar @{$likely->{'Very Unlikely Voters'}};
logd scalar @{$likely->{'Unlikely Voters'}};
logd scalar @{$likely->{'Blah Voters'}};

logd scalar @{$likely->{'Perfect Mayoral Voters'}};
#
#
#
#logd scalar @{$likely->{'Unlikely Voters'}};
logd scalar @{$likely->{'New Voters'}};
logd scalar @{$likely->{'Non-Muni Election Voters'}};
#logd $likely->{'Unknown Voters'};
logd scalar @{$likely->{'Unknown Voters'}};
logd $likely->{total};

$voter_list->generate_csv;


exit;
logd $voter_list->num_newly_registered_since_last_muni;


logd $voter_list->num_registered_same_year_as_last_muni;
logd $voter_list->num_registered_90_days_b4_last_muni_deadline;
logd $voter_list->num_registered_60_days_b4_last_muni_deadline;
logd $voter_list->num_registered_30_days_b4_last_muni_deadline;
logd $voter_list->num_registered_10_days_b4_last_muni_deadline;
logd $voter_list->num_registered_5_days_b4_last_muni_deadline;

logd $voter_list->num_likely_new_muni_voters_total;
logd $voter_list->num_likely_new_muni_voters_90;
logd $voter_list->num_likely_new_muni_voters_60;
logd $voter_list->num_likely_new_muni_voters_30;
logd $voter_list->num_likely_new_muni_voters_10;
logd $voter_list->num_likely_new_muni_voters_5;

logd $voter_list->num_eligible_and_perfect;
logd $voter_list->num_eligible_and_voted_1;
logd $voter_list->num_eligible_and_voted_2;
logd $voter_list->num_eligible_and_voted_3;
logd $voter_list->num_eligible_and_voted_4;
logd $voter_list->num_eligible_and_voted_5;

#logd $voter_list->voters;


#logd \%unique_values;
