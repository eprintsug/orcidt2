#
# This file contains the ORCID credentials for the registered application
#

$c->{orcid_client_id} =  '0000-0000-0000-0000';
$c->{orcid_client_secret} =  'replace-me';
$c->{orcid_redirect_uri} =  'http://<myorg.org>/cgi/orcid/auth';

$c->{orcid_target_machines} = {
        'replace-me-dev' => 3,		# this will be the default machine 
        'replace-me-test' => 2,
        'replace-me-live' => 1,
};

