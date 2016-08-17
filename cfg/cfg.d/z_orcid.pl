#
# Settings for the ORCiD interface
#


$c->{orcid_public_api} =  'http://pub.orcid.org/';
$c->{orcid_member_api} =  'https://api.orcid.org/';
$c->{orcid_sandbox_api} =  'http://api.sandbox-1.orcid.org/';
$c->{orcid_public_sandbox_api} =  'http://pub.sandbox-1.orcid.org/v1.0.23/';

$c->{orcid_id} = "/orcid-id";
$c->{orcid_bio} = "/orcid-bio";
$c->{orcid_works} = "/orcid-works";
$c->{orcid_record} = "/orcid-record";

$c->{orcid_search} =  'search/';

# new user fields for ORCiD

push @{$c->{fields}->{user}},
{ name => 'orcid', type => 'id', },
;


#new permissions for ORCiD 
$c->{roles}->{"orcid"} =
[
        "orcid/destroy",
        "orcid/write",
        "orcid/view",
];

push @{$c->{user_roles}->{admin}}, 'orcid';


       


