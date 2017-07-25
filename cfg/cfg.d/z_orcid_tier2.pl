#
# Settings for the Orcid Member api
#

#new permissions for ORCiD 
$c->{roles}->{"orcid"} =
[
        "orcid/destroy",
        "orcid/write",
        "orcid/view",
];

push @{$c->{user_roles}->{admin}}, 'orcid';

#
# new user fields for the id and persistent authorisation tokens obtained via OAuth.
# see: http://members.orcid.org/api/orcid-scopes
#
push @{$c->{fields}->{user}},
{ name => 'orcid', type => 'id', },
{ name => 'orcid_rl_token', type => 'text', },
{ name => 'orcid_act_u_token', type => 'text', },
{ name => 'orcid_bio_u_token', type => 'text', },
{	name => 'put_codes',
  	type => 'compound', 
  	multiple => 1,
	volatile => 1,
	sql_index => 0,
	text_index => 0,
	can_clone => 0,
	show_in_fieldlist => 0,
	export_as_xml => 0,
	import => 0,
    	fields => [ 
		{
			sub_name => 'code_type',
			type => 'set',
			options => [qw(
				group_id
				address
				education
				employment
				ext_id
				funding
				keyword
				other_name
				peer_review
				researcher_url
				work
			)],
		},
		{
			sub_name => 'code', type => 'int',
		},
		{
			sub_name => 'item', type => 'int',
		},
	],
};

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

$c->{orcid_version} =  '2.0';
$c->{orcid_member_server} =  'https://sandbox.orcid.org/';
$c->{orcid_member_api} =  'https://api.sandbox.orcid.org/';
$c->{orcid_public_api} =  'https://pub.sandbox.orcid.org/';

$c->{orcid_exchange_url} = $c->{orcid_member_api} . 'oauth/token' ; 

$c->{orcid_scope_map} = {
	"/read-limited" 	=> "orcid_rl_token", 
	"/activities/update" 	=> "orcid_act_u_token",
	"/person/update" 	=> "orcid_bio_u_token",
};
	
$c->{orcid_read_scope} = "/read-limited";

$c->{orcid_endpoint_map} = {
	"address"	=>	"/person/update",
	"education"	=>	"/activities/update",
	"employment"	=>	"/activities/update",
	"external-identifiers"	=>	"/person/update",
	"funding"	=>	"/activities/update",
	"keywords"	=>	"/person/update",
	"other-names"	=>	"/person/update",
	"peer-review"	=>	"/activities/update",
	"researcher-urls"	=>	"/person/update",
	"work"		=>	"/activities/update",
	"works"		=>	"/activities/update",
};

$c->{put_code_tag_for_endpoint} = {
	"/activities"   => "activities-summary",
        "/employments"  => "employment-summary",
        "/educations"   => "education-summary",
        "/works"        => "work-summary",
};


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
	user_login => {
		scope 		=> "/authenticate",
		activity_id	=> '03',
		desc		=> "Retrieve a user's authenticated ORCID iD to allow login",
		token_type	=> "single",
		},

	read_record => {
		scope 		=> "/read-limited",
		request		=> "orcid-profile",
		activity_id	=> '01',
		desc		=> "Retrieve information from a user's ORCID record",
		token_type	=> "until_revoked",
		token		=> "orcid_rl_token",
		},
	read_bio => {
		scope 		=> "/read-limited",
		request		=> "orcid-bio",
		activity_id	=> '01',
		desc		=> "Retrieve information from a user's ORCID record",
		token_type	=> "until_revoked",
		token		=> "orcid_rl_token",
		},
	read_research => {
		scope 		=> "/read-limited",
		request		=> "orcid-works",
		activity_id	=> '01',
		desc		=> "Retrieve information from a user's ORCID record",
		token_type	=> "until_revoked",
		token		=> "orcid_rl_token",
		},
	add_works => {
		scope 		=> "/activities/update",
		request		=> "/orcid-works",
		activity_id	=> '01',
		desc		=> "Add research activities",
		token_type	=> "until_revoked",
		token		=> "orcid_act_u_token",
		},
	add_identifier => {
		scope 		=> "/person/update",
		request		=> "/orcid-bio/external-identifiers",
		activity_id	=> '01',
		desc		=> "Create a link between the user's account on your system and their ORCID iD",
		token_type	=> "until_revoked",
		token		=> "orcid_bio_u_token",
		},
	add_affiliation => {
		scope 		=> "/affiliations/update",
		request		=> "/affiliations",
		activity_id	=> '01',
		desc		=> "Add an Affiliation",
		token_type	=> "until_revoked",
		token		=> "orcid_act_u_token",
		},
	add_funding => {
		scope 		=> "/activities/update",
		request		=> "/funding",
		activity_id	=> '01',
		desc		=> "Add a Funding Source",
		token_type	=> "until_revoked",
		token		=> "orcid_act_u_token",
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
		scope 		=> "/activities/update",
		request		=> "orcid-works",
		activity_id	=> '01',
		desc		=> "Update works",
		token_type	=> "until_revoked",
		token		=> "orcid_act_u_token",
		},
	update_affiliation => {
		scope 		=> "/activities/update",
		request		=> "/affiliations",
		activity_id	=> '01',
		desc		=> "Update affiliations",
		token_type	=> "until_revoked",
		token		=> "orcid_act_u_token",
		},
	update_funding => {
		scope 		=> "/activities/update",
		request		=> "/funding",
		activity_id	=> '01',
		desc		=> "Update funders",
		token_type	=> "until_revoked",
		token		=> "orcid_act_u_token",
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

$c->{get_orcid_query_url} = sub
{
        my( $repo, $user_id, $item_id, $activity, $orcid_id ) = @_;
	my $url =  $repo->config( "orcid_member_server" ) . 'v' .$repo->config( "orcid_version" ).'/'; 


};

$c->{get_orcid_authorise_url} = sub
{
        my( $repo, $user_id, $item_id, $scope, $activity, $orcid_id ) = @_;

	$activity = '01' unless $activity;
	my $machine = 1;
	my $state = $machine.$user_id."-".$activity.$item_id;
	my $login_screen = "";
	$login_screen = "&show_login=true&orcid=$orcid_id" if $orcid_id;

	my $orcid_authorise_url =  $repo->config( "orcid_member_server" ) . 'oauth/authorize?' . 
				'client_id=' . $repo->config( "orcid_client_id" ) .
				'&scope=' . $scope .
				'&response_type=code' . 
				'&redirect_uri=' . $repo->config( "orcid_redirect_uri" ). 
				$login_screen.
				'&state=' . $state ;
	
	return $orcid_authorise_url;
};



$c->{form_orcid_work_xml} = sub
{
        my( $repo, $item_id, ) = @_;

print STDERR "form_orcid_work_xml called\n";
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
print STDERR "form_orcid_work_xml [". ref($titles)."] [".$titles."]\n";
		my $w_title = $work->appendChild( $xml->create_element( "work-title" ) );
		my $title = $w_title->appendChild( $xml->create_element( "title" ) );
		if ( ref($titles) eq 'ARRAY' )
		{
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
		else
		{
			$title->appendChild( $xml->create_text_node( $titles ) );
		}
	}
	my $abstracts =  $item->get_value( "abstract" );
	if ( $abstracts )
	{
		my $w_abs = $work->appendChild( $xml->create_element( "short-description" ) );
		if ( ref($abstracts) eq 'ARRAY' )
		{	
			$w_abs->appendChild( $xml->create_text_node( $abstracts->[0]->{text} ) );
		}
		else
		{
			$w_abs->appendChild( $xml->create_text_node( $abstracts ) );
		}
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

$c->{form_orcid_affiliation_xml} = sub
{
        my( $repo, $user, $put_code ) = @_;

        my $xml = $repo->xml;
	my $act_xml;
        $act_xml = $xml->create_element( "employment:employment",
		'xmlns:employment' => "http://www.orcid.org/ns/employment",
		'xmlns:common' => "http://www.orcid.org/ns/common",
		'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
		'xsi:schemaLocation' => "http://www.orcid.org/ns/employment ../employment-2.0.xsd", 
        );

        return $act_xml unless $user;

	if ( $put_code )
	{
	        $act_xml = $xml->create_element( "employment:employment" ); 
		$act_xml->setAttribute( "xmlns:employment", "http://www.orcid.org/ns/employment" );
		$act_xml->setAttribute( "xmlns:common", "http://www.orcid.org/ns/common" );
		$act_xml->setAttribute( "xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance" );
		$act_xml->setAttribute( "xsi:schemaLocation", "http://www.orcid.org/ns/employment ../employment-2.0.xsd" );
		$act_xml->setAttribute( "put-code", $put_code );
	}
        my $dept = $act_xml->appendChild( $xml->create_element( "employment:department-name" ) );
if ( $put_code ) {
        $dept->appendChild( $xml->create_text_node( "MODIFIED Department" ) );
}else{
        $dept->appendChild( $xml->create_text_node( "Department" ) );
}
        my $role = $act_xml->appendChild( $xml->create_element( "employment:role-title" ) );
        $role->appendChild( $xml->create_text_node( "Role title" ) );
        #my $start = $act_xml->appendChild( $xml->create_element( "common:start-date" ) );
        #my $end = $act_xml->appendChild( $xml->create_element( "common:end-date" ) );
        my $organisation = $act_xml->appendChild( $xml->create_element( "employment:organization" ) );
        my $org_name = $organisation->appendChild( $xml->create_element( "common:name" ) );
        $org_name->appendChild( $xml->create_text_node( $repo->config( "org_ringgold_name" ) ) );
        my $org_addr = $organisation->appendChild( $xml->create_element( "common:address" ) );
        my $city = $org_addr->appendChild( $xml->create_element( "common:city" ) );
        $city->appendChild( $xml->create_text_node( $repo->config( "org_ringgold_city" ) ) );
        my $region = $org_addr->appendChild( $xml->create_element( "common:region" ) );
        $region->appendChild( $xml->create_text_node( $repo->config( "org_ringgold_region" ) ) );
        my $country = $org_addr->appendChild( $xml->create_element( "common:country" ) );
        $country->appendChild( $xml->create_text_node( $repo->config( "org_ringgold_country" ) ) );
        my $dissamb_org = $organisation->appendChild( $xml->create_element( "common:disambiguated-organization" ) );
        my $dissamb_org_id = $dissamb_org->appendChild( $xml->create_element( "common:disambiguated-organization-identifier" ) );
        $dissamb_org_id->appendChild( $xml->create_text_node( $repo->config( "org_ringgold_id" ) ) );
        my $dissamb_org_src = $dissamb_org->appendChild( $xml->create_element( "common:disambiguation-source" ) );
        $dissamb_org_src->appendChild( $xml->create_text_node( "RINGGOLD" ) );

        my $prolog = '<?xml version="1.0" encoding="UTF-8"?>';
        my $xml_str = $prolog.$act_xml->toString();
print STDERR "form_orcid_affiliation_xml [".$xml_str."]\n";
        return $xml_str;
};

$c->{valid_orcid_id} = sub
{
        my( $orcid_id, ) = @_;

	return $orcid_id && $orcid_id =~ /\d{4}-\d{4}-\d{4}-\d{3}[Xx\d]/
};
	
$c->{render_orcid_id} = sub
{
        my( $repo, $orcid_id ) = @_;

	my $frag = $repo->make_doc_fragment;
	return $frag unless $repo->call( "valid_orcid_id", $orcid_id );

	my $xml = $repo->xml;
	my $orcid_link = $frag->appendChild( $xml->create_element( "a", href=>"http://orcid.org" ) );
	$orcid_link->appendChild( $xml->create_element( "img", alt => "ORCID logo", 
					src => "/style/images/orcid_16x16.png", 
					id => "orcid-id-logo-16" ) );
	my $orcid_id_link = $frag->appendChild( $xml->create_element( "a", href=>"http://orcid.org/".$orcid_id ) );
	$orcid_id_link->appendChild( $xml->create_text_node( "http://orcid.org/".$orcid_id ) );

	return $frag;
};

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



