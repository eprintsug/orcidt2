#
# Settings for the Orcid Tier 2 api
#

#
# repository field mapping
#
$c->{item_doi_field} = "doi";
$c->{item_pmid_field} = "pubmed_id";
$c->{user_orcid_id_field} = "orcid";

$c->{orcid_import_plugin_map} = {
		"DOI" => "DOI",
		"PMID" => "PubMedID",
		"BIBTEX" => "BibTeX",
};

#
# ORCID Config and utilities
#

$c->{orcid_version} =  '1.1';
$c->{orcid_tier_2_server} =  'https://sandbox.orcid.org/';
$c->{orcid_tier_2_api} =  'https://api.sandbox.orcid.org/';

$c->{orcid_exchange_url} = $c->{orcid_tier_2_api} . 'oauth/token' ; 

$c->{orcid_activity_map} = {
	authenticate => {
		scope 		=> "/authenticate",
		activity_id	=> 1,
		desc		=> "Retrieve a user's authenticated ORCID iD to store in your system"
		},
	read_record => {
		scope 		=> "/orcid-profile/read-limited",
		request		=> "orcid-profile",
		activity_id	=> 2,
		desc		=> "Retrieve information from a user's ORCID record"
		},
	read_bio => {
		scope 		=> "/orcid-bio/read-limited",
		request		=> "orcid-bio",
		activity_id	=> 3,
		desc		=> "Retrieve information from a user's ORCID record"
		},
	read_research => {
		scope 		=> "/orcid-works/read-limited",
		request		=> "orcid-works",
		activity_id	=> 4,
		desc		=> "Retrieve information from a user's ORCID record"
		},
	add_works => {
		scope 		=> "/orcid-works/create",
		request		=> "/orcid-works",
		activity_id	=> 5,
		desc		=> "Add research activities"
		},
	add_identifier => {
		scope 		=> "/orcid-bio/external-identifiers/create",
		request		=> "/orcid-bio/external-identifiers",
		activity_id	=> 6,
		desc		=> "Create a link between the user's account on your system and their ORCID iD"
		},
	add_record => {
		scope 		=> "/orcid-profile/create",
		request		=> "/orcid-profile",
		activity_id	=> 7,
		desc		=> "Create a new ORCID record for a user / Have the user claim their ORCID record"
		},
	add_affiliation => {
		scope 		=> "/affiliations/create",
		request		=> "/affiliations",
		activity_id	=> 8,
		desc		=> "Add an Affiliation"
		},
	add_funding => {
		scope 		=> "/funding/create",
		request		=> "/funding",
		activity_id	=> 9,
		desc		=> "Add a Funding Source"
		},
	update_bio => {
		scope 		=> "/orcid-bio/update",
		request		=> "/orcid-bio",
		activity_id	=> 10,
		desc		=> "Update Bio"
		},
	update_works => {
		scope 		=> "/orcid-works/update",
		request		=> "orcid-works",
		activity_id	=> 11,
		desc		=> "Update works"
		},
	update_affiliation => {
		scope 		=> "/affiliations/update",
		request		=> "/affiliations",
		activity_id	=> 12,
		desc		=> "Update affiliations"
		},
	update_funding => {
		scope 		=> "/funding/update",
		request		=> "/funding",
		activity_id	=> 13,
		desc		=> "Update funders"
		},
};



#
# ORCID Utilities
#

$c->{get_orcid_authorise_url} = sub
{
        my( $repo, $user_id, $item_id, $activity ) = @_;

	my $activity_map = $repo->config( "orcid_activity_map" );
	my $activity_id = $activity_map->{$activity}->{activity_id};
	my $state = "u".$user_id."i".$item_id."a".$activity_id;

	my $orcid_profile_scope = "/orcid-profile/read-limited";
	if ( $activity )
	{
		$orcid_profile_scope = $activity_map->{$activity}->{scope};
	}
	my $orcid_authorise_url =  $repo->config( "orcid_tier_2_server" ) . 'oauth/authorize?' . 
				'client_id=' . $repo->config( "orcid_client_id" ) .
				'&scope=' . $orcid_profile_scope .
				'&response_type=code' . 
				'&redirect_uri=' . $repo->config( "orcid_redirect_uri" ). 
				'&state=' . $state ;
	return $orcid_authorise_url;
};


$c->{form_orcid_work_xml} = sub
{
        my( $repo, $item_id, ) = @_;

	my $xml = $repo->xml;
	my $work_xml = $xml->create_element( "orcid-message", 
					 'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
    					 'xsi:schemaLocation' => "http://www.orcid.org/ns/orcid https://raw.github.com/ORCID/ORCID-Source/master/orcid-model/src/main/resources/orcid-message-1.1.xsd",
					 'xmlns' => "http://www.orcid.org/ns/orcid" );
	my $ds = $repo->dataset( "eprint" );
	my $item = $ds->dataobj( $item_id );

	return $work_xml unless $item;

	my $version = $work_xml->appendChild( $xml->create_element( "message-version" ) );
	$version->appendChild( $xml->create_text_node( $repo->config( "orcid_version" ) ) );
	my $profile = $work_xml->appendChild( $xml->create_element( "orcid-profile" ) );
	my $activities = $profile->appendChild( $xml->create_element( "orcid-activities" ) );
	my $works = $activities->appendChild( $xml->create_element( "orcid-works" ) );
	my $work = $works->appendChild( $xml->create_element( "orcid-work", visibility => "public" ) );
	my $w_title = $work->appendChild( $xml->create_element( "work-title" ) );
	my $title = $w_title->appendChild( $xml->create_element( "title" ) );
	$title->appendChild( $xml->create_text_node( @{$item->get_value( "title" )}[0] ) );
	my $w_type = $work->appendChild( $xml->create_element( "work-type" ) );
	$w_type->appendChild( $xml->create_text_node( "book" ) );
	
print STDERR "form_orcid_work_xml [".$work_xml->toString()."]\n";

	return $work_xml;
};


