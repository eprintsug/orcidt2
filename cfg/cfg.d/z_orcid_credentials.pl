#
# This file contains the ORCID credentials for the registered application
#

$c->{orcid_client_id} =  '0000-0000-0000-0000';
$c->{orcid_client_secret} =  'replace-me';
$c->{orcid_redirect_uri} =  'http://<myorg.org>/cgi/orcid/auth';

# fields for persistent authorisation tokens obtained via Client Credentials.
# see: http://support.orcid.org/knowledgebase/articles/117230
#
#
# curl -i -L -H 'Accept: application/json' -d 'client_id=0000-0002-9353-5519' -d 'client_secret=1470a572-1e0d-4e7d-899a-c9eafca4e05d' -d 'scope=/read-public' -d 'grant_type=client_credentials' 'https://api.sandbox.orcid.org/oauth/token'
#
#
$c->{orcid_read_public_token} = "replace-me";
$c->{orcid_webhook_token} = "replace-me";

$c->{org_ringgold_id} = "replace-me";
$c->{org_ringgold_name} = "replace-me";
$c->{org_ringgold_city} = "replace-me";
$c->{org_ringgold_region} = "replace-me";
$c->{org_ringgold_country} = "replace-me";
$c->{org_isni} = "replace-me";




