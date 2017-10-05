=begin InternalDoc

=over

=item Settings for the ORCiD interface

=back

 This specifies the version of the API and the nature of the API (Live or Sandbox)

=end InternalDoc

=cut

$c->{orcid_version} =  '2.0';
$c->{orcid_member_server} =  'https://sandbox.orcid.org/';
$c->{orcid_member_api} =  'https://api.sandbox.orcid.org/';
$c->{orcid_public_api} =  'https://pub.sandbox.orcid.org/';

$c->{orcid_exchange_url} = $c->{orcid_member_api} . 'oauth/token' ; 


