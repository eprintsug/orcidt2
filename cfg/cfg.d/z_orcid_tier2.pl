#
# Settings for the Orcid Tier 2 api
#

# 
# Enable/disable the Orcid plugins
#

$c->{plugins}->{"Import::Orcid"}->{params}->{disable} = 0;
$c->{plugins}->{"InputForm::Component::Field::OrcidId"}->{params}->{disable} = 0;
$c->{plugins}->{"Orcid::Add"}->{params}->{disable} = 0;
$c->{plugins}->{"Orcid::AddWorks"}->{params}->{disable} = 0;
$c->{plugins}->{"Orcid::Auth"}->{params}->{disable} = 0;
$c->{plugins}->{"Orcid::ReadBio"}->{params}->{disable} = 0;
$c->{plugins}->{"Orcid::Read"}->{params}->{disable} = 0;
$c->{plugins}->{"Orcid::ReadProfile"}->{params}->{disable} = 0;
$c->{plugins}->{"Orcid::ReadResearch"}->{params}->{disable} = 0;
$c->{plugins}->{"Orcid"}->{params}->{disable} = 0;
$c->{plugins}->{"Screen::Admin::Orcid::OrcidManager"}->{params}->{disable} = 0;
$c->{plugins}->{"Screen::Import::Orcid"}->{params}->{disable} = 0;
$c->{plugins}->{"Screen::User::Orcid::OrcidManager"}->{params}->{disable} = 0;


#
# new user fields for persistent authorisation tokens obtained via OAuth.
# see: http://support.orcid.org/knowledgebase/articles/120162-orcid-scopes
#
push @{$c->{fields}->{user}},
{ name => 'orcid_profile_rl_token', type => 'text', },
{ name => 'orcid_bio_rl_token', type => 'text', },
{ name => 'orcid_works_rl_token', type => 'text', },
{ name => 'orcid_works_c_token', type => 'text', },
{ name => 'orcid_bio_extern_ids_c_token', type => 'text', },
{ name => 'orcid_affiliations_c_token', type => 'text', },
{ name => 'orcid_funding_c_token', type => 'text', },
{ name => 'orcid_bio_u_token', type => 'text', },
{ name => 'orcid_works_u_token', type => 'text', },
{ name => 'orcid_affiliations_u_token', type => 'text', },
{ name => 'orcid_funding_u_token', type => 'text', },
;

#
# fields for persistent authorisation tokens obtained via Client Credentials.
# see: http://support.orcid.org/knowledgebase/articles/117230
#
#
# curl -i -L -H 'Accept: application/json' -d 'client_id=0000-0002-9353-5519' -d 'client_secret=1470a572-1e0d-4e7d-899a-c9eafca4e05d' -d 'scope=/read-public' -d 'grant_type=client_credentials' 'https://api.sandbox.orcid.org/oauth/token'
#
#
#curl -i -L -H 'Accept: application/json' -d 'client_id=0000-0002-1572-7910' -d 'client_secret=4bfb0aca-d757-4d2f-bded-4d14bfa30f00' -d 'scope=/read-public' -d 'grant_type=client_credentials' 'https://api.sandbox.orcid.org/oauth/token'
#
$c->{orcid_read_public_token} = "23296131-86b4-4943-adba-6e9f8d6ea7c4";
$c->{orcid_profile_c_token} = "22";
$c->{orcid_webhook_token} = "22";

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

$c->{orcid_import_plugin_rank} = {
		"DOI" => 100,
		"PMID" => 99,
};

#
# ORCID Config and utilities
#

$c->{orcid_version} =  '1.2';
$c->{orcid_tier_2_server} =  'https://sandbox.orcid.org/';
$c->{orcid_tier_2_api} =  'https://api.sandbox.orcid.org/';

$c->{orcid_exchange_url} = $c->{orcid_tier_2_api} . 'oauth/token' ; 

$c->{orcid_activity_map} = {
	authenticate => {
		scope 		=> "/authenticate",
		activity_id	=> '01',
		desc		=> "Retrieve a user's authenticated ORCID iD to store in your system. Redirect to profile",
		token_type	=> "single",
		},
	user_authenticate => {
		scope 		=> "/authenticate",
		activity_id	=> '02',
		desc		=> "Retrieve a user's authenticated ORCID iD to store in your system. Redirect to User orcid management screen",
		token_type	=> "single",
		},
	read_record => {
		scope 		=> "/orcid-profile/read-limited",
		request		=> "orcid-profile",
		activity_id	=> '01',
		desc		=> "Retrieve information from a user's ORCID record",
		token_type	=> "until_revoked",
		token		=> "orcid_profile_rl_token",
		},
	read_bio => {
		scope 		=> "/orcid-bio/read-limited",
		request		=> "orcid-bio",
		activity_id	=> '01',
		desc		=> "Retrieve information from a user's ORCID record",
		token_type	=> "until_revoked",
		token		=> "orcid_bio_rl_token",
		},
	read_research => {
		scope 		=> "/orcid-works/read-limited",
		request		=> "orcid-works",
		activity_id	=> '01',
		desc		=> "Retrieve information from a user's ORCID record",
		token_type	=> "until_revoked",
		token		=> "orcid_works_rl_token",
		},
	add_works => {
		scope 		=> "/orcid-works/create",
		request		=> "/orcid-works",
		activity_id	=> '01',
		desc		=> "Add research activities",
		token_type	=> "until_revoked",
		token		=> "orcid_works_c_token",
		},
	add_identifier => {
		scope 		=> "/orcid-bio/external-identifiers/create",
		request		=> "/orcid-bio/external-identifiers",
		activity_id	=> '01',
		desc		=> "Create a link between the user's account on your system and their ORCID iD",
		token_type	=> "until_revoked",
		token		=> "orcid_bio_extern_ids_c_token",
		},
	add_affiliation => {
		scope 		=> "/affiliations/create",
		request		=> "/affiliations",
		activity_id	=> '01',
		desc		=> "Add an Affiliation",
		token_type	=> "until_revoked",
		token		=> "orcid_affiliations_c_token",
		},
	add_funding => {
		scope 		=> "/funding/create",
		request		=> "/funding",
		activity_id	=> '01',
		desc		=> "Add a Funding Source",
		token_type	=> "until_revoked",
		token		=> "orcid_funding_c_token",
		},
	update_bio => {
		scope 		=> "/orcid-bio/update",
		request		=> "/orcid-bio",
		activity_id	=> '01',
		desc		=> "Update Bio",
		token_type	=> "until_revoked",
		token		=> "orcid_bio_u_token",
		},
	update_works => {
		scope 		=> "/orcid-works/update",
		request		=> "orcid-works",
		activity_id	=> '01',
		desc		=> "Update works",
		token_type	=> "until_revoked",
		token		=> "orcid_works_u_token",
		},
	update_affiliation => {
		scope 		=> "/affiliations/update",
		request		=> "/affiliations",
		activity_id	=> '01',
		desc		=> "Update affiliations",
		token_type	=> "until_revoked",
		token		=> "orcid_affiliations_u_token",
		},
	update_funding => {
		scope 		=> "/funding/update",
		request		=> "/funding",
		activity_id	=> '01',
		desc		=> "Update funders",
		token_type	=> "until_revoked",
		token		=> "orcid_funding_u_token",
		},
	add_record => {
		scope 		=> "/orcid-profile/create",
		request		=> "/orcid-profile",
		activity_id	=> '01',
		desc		=> "Create a new ORCID record for a user / Have the user claim their ORCID record",
		token_type	=> "client",
		token		=> "orcid_profile_c_token",
		},
	read_public => {
		scope 		=> "/read-public",
		request		=> "/*",
		activity_id	=> '01',
		desc		=> "Read Public Info via the member api",
		token_type	=> "client",
		token		=> "orcid_read_public_token",
		},
	webhook => {
		scope 		=> "/webhook",
		request		=> "/webhook",
		activity_id	=> '01',
		desc		=> "register a webhook to recieve updates",
		token_type	=> "client",
		token		=> "orcid_webhook_token",
		},

};


$c->{orcid_work_type_map} = {
	article => "journal-article",
	magazine_article => "magazine article",
	book_section => "book-chapter",
	book => "book",
	report => "report",
	conference_item => "conference-paper",
	working_paper => "working-paper",
	thesis => "supervised-student-publication",
	journal_series => "journal-issue",
	audio_visual => "other",
	dataset => "data set",
	patent => "patent",
	other => "other",
};


#
# ORCID Utilities
#

$c->{get_orcid_authorise_url} = sub
{
        my( $repo, $user_id, $item_id, $activity, $orcid_id ) = @_;

	my $target_map = $repo->config( "orcid_target_machines" );
	my $host = $repo->config( "host" );
	my $machine = $target_map->{$host};
	$machine = 3 unless $machine;

	$machine = 3;

	my $activity_map = $repo->config( "orcid_activity_map" );
	my $activity_id = $activity_map->{$activity}->{activity_id};
	my $state = $machine.$user_id."-".$activity_id.$item_id;
	my $login_screen = "";
	$login_screen = "&show_login=true&orcid=$orcid_id" if $orcid_id;

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
				$login_screen.
				'&state=' . $state ;
	
	return $orcid_authorise_url;
};

$c->{get_orcid_revoke_url} = sub
{
        my( $repo ) = @_;

	my $orcid_revoke_url =  $repo->config( "orcid_tier_2_server" ) . 'account?activeTab=application-tab';
	return $orcid_revoke_url;
};



$c->{form_orcid_work_xml} = sub
{
        my( $repo, $item_id, ) = @_;

	my $xml = $repo->xml;
	my $work_xml = $xml->create_element( "orcid-message", 
    		'xmlns' => "http://www.orcid.org/ns/orcid",
    		'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
    		'xsi:schemaLocation' => "https://raw.github.com/ORCID/ORCID-Source/master/orcid-model/src/main/resources/orcid-message-1.2.xsd",
	);
	my $ds = $repo->dataset( "eprint" );
	my $item = $ds->dataobj( $item_id );

	return $work_xml unless $item;

	my $version = $work_xml->appendChild( $xml->create_element( "message-version" ) );
	$version->appendChild( $xml->create_text_node( $repo->config( "orcid_version" ) ) );
	my $profile = $work_xml->appendChild( $xml->create_element( "orcid-profile" ) );
	my $activities = $profile->appendChild( $xml->create_element( "orcid-activities" ) );
	my $works = $activities->appendChild( $xml->create_element( "orcid-works" ) );
	my $work = $works->appendChild( $xml->create_element( "orcid-work", visibility => "public" ) );
	my $titles = $item->get_value( "title" );
	if ( $titles )
	{
		my $w_title = $work->appendChild( $xml->create_element( "work-title" ) );
		my $title = $w_title->appendChild( $xml->create_element( "title" ) );
		$title->appendChild( $xml->create_text_node( $titles->[0]->{text} ) );
		if ( scalar @$titles > 1 )
		{
			foreach my $trans_title ( @$titles )
			{
				my $t_title = $w_title->appendChild( $xml->create_element( "translated-title", 'language-code'=>$trans_title->{lang} ) );
				$t_title->appendChild( $xml->create_text_node( $trans_title->{text} ) );
			}
		}
	}
	if ( $item->get_value( "abstract" ) )
	{
		my $w_abs = $work->appendChild( $xml->create_element( "short-description" ) );
		$w_abs->appendChild( $xml->create_text_node( @{$item->get_value( "abstract" )}[0]->{text} ) );
	}

	my $work_map = $repo->config( "orcid_work_type_map" );
	my $orcid_work_type = $work_map->{ $item->get_value( "type" ) };
	$orcid_work_type = "other" unless $orcid_work_type;
	my $w_type = $work->appendChild( $xml->create_element( "work-type" ) );
	$w_type->appendChild( $xml->create_text_node( $orcid_work_type ) );

	if ( $item->get_value( "publication" ) )
	{
		my $journal_title = $work->appendChild( $xml->create_element( "journal-title" ) );
		$journal_title->appendChild( $xml->create_text_node( $item->get_value( "publication" ) ) );
	}
	my $e_ids = $work->appendChild( $xml->create_element( "work-external-identifiers" ) );
	
	foreach my $id_type ( qw\ eprintid doi pubmed_id \)
	{
		next unless $item->get_value( $id_type );
		my $e_id = $e_ids->appendChild( $xml->create_element( "work-external-identifier" ) );
		my $e_id_type = $e_id->appendChild( $xml->create_element( "work-external-identifier-type" ) );
		$e_id_type->appendChild( $xml->create_text_node( "source-work-id" ) ) if $id_type eq "eprintid";
		$e_id_type->appendChild( $xml->create_text_node( "doi" ) ) if $id_type eq "doi";
		$e_id_type->appendChild( $xml->create_text_node( "pmid" ) ) if $id_type eq "pubmed_id";
		my $e_id_id = $e_id->appendChild( $xml->create_element( "work-external-identifier-id" ) );
		$e_id_id->appendChild( $xml->create_text_node( $item->get_value( $id_type ) ) );
	}

	my $date = $item->get_value( "date" );
	if ( $date )
	{
		my @parts  = split "-", $date; 
		my $pub_date = $work->appendChild( $xml->create_element( "publication-date" ) );
		my $pub_date_yr = $pub_date->appendChild( $xml->create_element( "year" ) );
		$pub_date_yr->appendChild( $xml->create_text_node( $parts[0] ) );
		if ( $parts[1] )
		{
			my $pub_date_mn = $pub_date->appendChild( $xml->create_element( "month" ) );
			$pub_date_mn->appendChild( $xml->create_text_node( $parts[1] ) );
		}
	}
	my $item_url = $work->appendChild( $xml->create_element( "url" ) );
	$item_url->appendChild( $xml->create_text_node( $item->get_url() ) );
	my $language = $item->get_value( "language" );
	if ( $language )
	{
		my $item_lang = $work->appendChild( $xml->create_element( "language-code" ) );
		$item_lang->appendChild( $xml->create_text_node( $language ) );
	}
	#my $item_country = $work->appendChild( $xml->create_element( "country" ) );
	#$item_country->appendChild( $xml->create_text_node( "US" ) );

	my $citation = $work->appendChild( $xml->create_element( "work-citation" ) );
	my $citation_type = $citation->appendChild( $xml->create_element( "work-citation-type" ) );
	$citation_type->appendChild( $xml->create_text_node( "formatted-unspecified" ) );
	my $citation_text = $citation->appendChild( $xml->create_element( "citation" ) );
	$citation_text->appendChild( $item->render_citation( "default" ) );
	
	my $contributors = $item->get_value( "contributors" );
	if ( $contributors )
	{
		my $sequence = "first";
		my $contribs = $work->appendChild( $xml->create_element( "work-contributors" ) );
		foreach my $contributor ( @$contributors )
		{
			next unless $contributor;
			my $contrib = $contribs->appendChild( $xml->create_element( "contributor" ) );
			my $c_orcid = $contributor->{ "orcid" };
			my $c_name = $contributor->{ "name" };
			my $c_role = $contributor->{ "type" };
			if ( $c_orcid )
			{
				my $contrib_o = $contrib->appendChild( $xml->create_element( "contributor-orcid" ) );
				my $contrib_o_u = $contrib_o->appendChild( $xml->create_element( "uri" ) );
				$contrib_o_u->appendChild( $xml->create_text_node( $c_orcid ) );
			}
			if ( $c_name )
			{
				my $contrib_n = $contrib->appendChild( $xml->create_element( "credit-name" ) );
				my $credit_name = $c_name->{family}.", ".$c_name->{given};
				$contrib_n->appendChild( $xml->create_text_node( $credit_name ) );
			}
			my $contrib_a = $contrib->appendChild( $xml->create_element( "contributor-attributes" ) );
			my $contrib_s = $contrib_a->appendChild( $xml->create_element( "contributor-sequence" ) );
			$contrib_s->appendChild( $xml->create_text_node( $sequence ) );
			$sequence = "additional";
			my $the_role = "author";
			$the_role = "editor" if $c_role eq "EDITOR";
			$the_role = "chair-or-translator" if $c_role eq "TRANSLATOR";
			my $contrib_r = $contrib_a->appendChild( $xml->create_element( "contributor-role" ) );
			$contrib_r->appendChild( $xml->create_text_node( $the_role ) );
		}

	}

	my $prolog = '<?xml version="1.0" encoding="UTF-8"?>'; 
	my $xml_str = $prolog.$work_xml->toString();
print STDERR "form_orcid_work_xml [".$xml_str."]\n";
	return $xml_str;

};



