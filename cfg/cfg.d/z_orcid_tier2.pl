=begin InternalDoc

=over

=item ORCiD member api integration

=back

Fields, configuration and utility functions for the ORCiD member api

=end InternalDoc

=cut


=begin InternalDoc

=over

=item permissions

=back

new permissions for ORCiD

=end InternalDoc

=cut

$c->{roles}->{"orcid_manager"} =
[
        "orcid/admin",
];

$c->{roles}->{"orcid"} =
[
        "orcid/destroy",
        "orcid/write",
        "orcid/view",
];

push @{$c->{user_roles}->{user}}, 'orcid';
push @{$c->{user_roles}->{submitter}}, 'orcid';
push @{$c->{user_roles}->{editor}}, 'orcid';
push @{$c->{user_roles}->{admin}}, 'orcid';
push @{$c->{user_roles}->{admin}}, 'orcid_manager';

=begin InternalDoc

=over

=item New User fields

=back

new user fields for the id and persistent authorisation tokens obtained via OAuth.
see: http://members.orcid.org/api/orcid-scopes

=end InternalDoc

=cut

push @{$c->{fields}->{user}},
{ name => 'orcid', type => 'id', input_cols => '25' },
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

=begin InternalDoc

=over

=item repository field mapping

=back

mapping between ORCID Works fields and repository fields

=end InternalDoc

=cut

$c->{item_doi_field} = "doi";
$c->{item_pmid_field} = "pubmed_id";
$c->{user_orcid_id_field} = "orcid";

$c->{orcid_import_plugin_map} = {
		"DOI" => "DOI",
		"PMID" => "PubMedID",
};

$c->{orcid_import_plugin_rank} = {
		"DOI" => 100,
		"PMID" => 99,
};

=begin InternalDoc

=over

=item Mappings

=back

Mappings for scopes and eprint fields for storing the tokens and put codes

=end InternalDoc

=cut

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


=begin InternalDoc

=over

=item orcid_work_type_map

=back

Mapping between ORCID Work types and EPrint types

=end InternalDoc

=cut

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

=begin InternalDoc

=over

=item get_orcid_query_url ( $repo, $user_id, $item_id, $activity, $orcid_id )

=back

Utility routine to form the query url

=end InternalDoc

=cut

$c->{get_orcid_query_url} = sub
{
        my( $repo, $user_id, $item_id, $activity, $orcid_id ) = @_;
	my $url =  $repo->config( "orcid_member_server" ) . 'v' .$repo->config( "orcid_version" ).'/'; 


};

=begin InternalDoc

=over

=item get_orcid_authorise_url ( $repo, $user_id, $item_id, $scope, $activity, $orcid_id )

=back

Utility routine to form the authorise url

=end InternalDoc

=cut

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

=begin InternalDoc

=over
 
=item form_orcid_work_xml ( $repo, $item_id, )

=back

Utility routine to form the xml for works data 

=end InternalDoc

=cut

$c->{form_orcid_work_xml} = sub
{
        my( $repo, $item_id, $put_code ) = @_;

print STDERR "form_orcid_work_xml called for item[".$item_id."]\n";
	my $ds = $repo->dataset( "eprint" );
	my $item = $ds->dataobj( $item_id );

	return undef unless $item;

	my $xml = $repo->xml;
	my $work_xml = $xml->create_element( "work:work", 
    		'xmlns:common' => "http://www.orcid.org/ns/common",
		'xmlns:work' => "http://www.orcid.org/ns/work",
    		'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
		'xsi:schemaLocation' => "http://www.orcid.org/ns/work /work-2.0.xsd ",
	);

	if ( $put_code )
	{
		$work_xml->setAttribute( "put-code", $put_code );
	}

	#work:title
	my $titles = $item->get_value( "title" );
	if ( $titles )
	{
		my $title = $work_xml->appendChild( $xml->create_element( "work:title" ) );
		my $common_title = $title->appendChild( $xml->create_element( "common:title" ) );
#print STDERR "form_orcid_work_xml [". ref($titles)."] [".$titles."]\n";
		if ( ref($titles) eq 'ARRAY' )
		{
			$common_title->appendChild( $xml->create_text_node( $titles->[0]->{text} ) );
			if ( scalar @$titles > 1 )
			{
				foreach my $trans_title ( @$titles )
				{
					my $t_title = $common_title->appendChild( 
						$xml->create_element( "common:translated-title", 
								'language-code'=>$trans_title->{lang} ) );
					$t_title->appendChild( $xml->create_text_node( $trans_title->{text} ) );
				}
			}
		}
		else
		{
			$common_title->appendChild( $xml->create_text_node( $titles ) );
		}
	}

	#work:journal-title
	if ( $item->get_value( "publication" ) )
	{
		my $journal_title = $work_xml->appendChild( $xml->create_element( "work:journal-title" ) );
		$journal_title->appendChild( $xml->create_text_node( $item->get_value( "publication" ) ) );
	}

	#work:short-description
	my $abstracts =  $item->get_value( "abstract" );
	if ( $abstracts )
	{
		my $short_desc = $work_xml->appendChild( $xml->create_element( "work:short-description" ) );
		if ( ref($abstracts) eq 'ARRAY' )
		{	
			$short_desc->appendChild( $xml->create_text_node( $abstracts->[0]->{text} ) );
		}
		else
		{
			$short_desc->appendChild( $xml->create_text_node( $abstracts ) );
		}
	}

	#work:citation
	my $citation = $work_xml->appendChild( $xml->create_element( "work:citation" ) );
	my $citation_type = $citation->appendChild( $xml->create_element( "work:citation-type" ) );
	$citation_type->appendChild( $xml->create_text_node( "formatted-unspecified" ) );
	my $citation_text = $citation->appendChild( $xml->create_element( "work:citation-value" ) );
	$citation_text->appendChild( $item->render_citation( "orcid" ) );
	
	#work:type
	my $work_map = $repo->config( "orcid_work_type_map" );
	my $orcid_work_type = $work_map->{ $item->get_value( "type" ) };
	$orcid_work_type = "other" unless $orcid_work_type;
	my $w_type = $work_xml->appendChild( $xml->create_element( "work:type" ) );
	$w_type->appendChild( $xml->create_text_node( $orcid_work_type ) );

	#common:publication-date
	my $date = $item->get_value( "date" );
	my $date_type = $item->get_value( "date_type" );
	if ( $date && $date_type && $date_type eq 'published' )
	{
		my @parts  = split "-", $date; 
		my $pub_date = $work_xml->appendChild( $xml->create_element( "common:publication-date" ) );
		my $pub_date_yr = $pub_date->appendChild( $xml->create_element( "common:year" ) );
		$pub_date_yr->appendChild( $xml->create_text_node( $parts[0] ) );
		if ( $parts[1] )
		{
			my $pub_date_mn = $pub_date->appendChild( $xml->create_element( "common:month" ) );
			$pub_date_mn->appendChild( $xml->create_text_node( $parts[1] ) );
			if ( $parts[2] )
			{
				my $pub_date_day = $pub_date->appendChild( $xml->create_element( "common:day" ) );
				$pub_date_day->appendChild( $xml->create_text_node( $parts[2] ) );
			}
		}
	}
	
	#common:external-ids
	my $ext_ids = $work_xml->appendChild( $xml->create_element( "common:external-ids" ) );
	
	foreach my $id_type ( qw\ eprintid doi pubmed_id \)
	{
		my $id_val = $item->get_value( $id_type );
		next unless $id_val;
		my $id_source;
		my $id_url;
		if ( $id_type eq 'eprintid' )
		{
			$id_source = "source-work-id";
			$id_url = $item->get_url();
		}
		elsif ( $id_type eq 'doi'  )
                {
			$id_source = "doi";
			my $id_url = "https://doi.org/".$item->get_value( $id_type );
                }
		elsif ( $id_type eq 'pubmed_id'  )
                {
			$id_source = "pmid";
			my $id_url = "https://www.ncbi.nlm.nih.gov/pubmed/".$item->get_value( $id_type );
                }
		my $ext_id = $ext_ids->appendChild( $xml->create_element( "common:external-id" ) );
		my $ext_id_type = $ext_id->appendChild( $xml->create_element( "common:external-id-type" ) );
                $ext_id_type->appendChild( $xml->create_text_node( $id_source ) );
		my $ext_id_val = $ext_id->appendChild( $xml->create_element( "common:external-id-value" ) );
		$ext_id_val->appendChild( $xml->create_text_node( $id_val ) );
		my $ext_id_url = $ext_id->appendChild( $xml->create_element( "common:external-id-url" ) );
		$ext_id_url->appendChild( $xml->create_text_node( $id_url ) );
                my $ext_id_rel = $ext_id->appendChild( $xml->create_element( "common:external-id-relationship" ) );
                $ext_id_rel->appendChild( $xml->create_text_node( "self" ) );
	}

	#work:url
	my $item_url = $work_xml->appendChild( $xml->create_element( "work:url" ) );
	$item_url->appendChild( $xml->create_text_node( $item->get_url() ) );

	#work:contributors
	my $contributors = $item->get_value( "contributors" );
	if ( $contributors )
	{
print STDERR "form_orcid_work_xml called for contribs[".Data::Dumper::Dumper($contributors)."]\n";
		my $sequence = "first";
		my $contribs = $work_xml->appendChild( $xml->create_element( "work:contributors" ) );
		foreach my $contributor ( @$contributors )
		{
			next unless $contributor;
			my $contrib = $contribs->appendChild( $xml->create_element( "work:contributor" ) );
			my $c_orcid = $contributor->{ "orcid" };
			my $c_name = $contributor->{ "name" };
			my $c_role = $contributor->{ "type" };
			if ( $c_orcid )
			{
print STDERR "form_orcid_work_xml adding orcid[".$c_orcid."]\n";
				my $contrib_o = $contrib->appendChild( $xml->create_element( "common:contributor-orcid" ) );
				my $contrib_o_u = $contrib_o->appendChild( $xml->create_element( "common:uri" ) );
				$contrib_o_u->appendChild( $xml->create_text_node( "https://orcid.org/".$c_orcid ) );
				my $contrib_o_p = $contrib_o->appendChild( $xml->create_element( "common:path" ) );
				$contrib_o_p->appendChild( $xml->create_text_node( $c_orcid ) );
				my $contrib_o_h = $contrib_o->appendChild( $xml->create_element( "common:host" ) );
				$contrib_o_h->appendChild( $xml->create_text_node( "orcid.org" ) );
			}
			if ( $c_name )
			{
				my $contrib_n = $contrib->appendChild( $xml->create_element( "work:credit-name" ) );
				my $credit_name = $c_name->{family}.", ".$c_name->{given};
				$contrib_n->appendChild( $xml->create_text_node( $credit_name ) );
			}
			my $contrib_a = $contrib->appendChild( $xml->create_element( "work:contributor-attributes" ) );
			my $contrib_s = $contrib_a->appendChild( $xml->create_element( "work:contributor-sequence" ) );
			$contrib_s->appendChild( $xml->create_text_node( $sequence ) );
			$sequence = "additional";
			my $the_role = "author";
			$the_role = "editor" if $c_role eq "EDITOR";
			$the_role = "chair-or-translator" if $c_role eq "TRANSLATOR";
			my $contrib_r = $contrib_a->appendChild( $xml->create_element( "work:contributor-role" ) );
			$contrib_r->appendChild( $xml->create_text_node( $the_role ) );
		}

	}

	#common:language-code
	my $language = $item->get_value( "language" );
	if ( $language )
	{
		my $item_lang = $work_xml->appendChild( $xml->create_element( "common:language-code" ) );
		$item_lang->appendChild( $xml->create_text_node( $language ) );
	}
	
	#common:country
	my $item_country = $work_xml->appendChild( $xml->create_element( "common:country" ) );
	$item_country->appendChild( $xml->create_text_node( "CH" ) );

	my $prolog = '<?xml version="1.0" encoding="UTF-8"?>'; 
	my $xml_str = $prolog.$work_xml->toString();
print STDERR "\nform_orcid_work_xml #####################################################################\n";
print STDERR Encode::encode("utf8", $xml_str);
print STDERR "\nform_orcid_work_xml #####################################################################\n";
	return $xml_str;

};

=begin InternalDoc

=over

=item form_orcid_affiliation_xml ( $repo, $user, $put_code )

=back

Utility routine to form the xml for affiliation (employment) data

=end InternalDoc

=cut

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
        #my $dept = $act_xml->appendChild( $xml->create_element( "employment:department-name" ) );
        #$dept->appendChild( $xml->create_text_node( "Department" ) );
        #my $role = $act_xml->appendChild( $xml->create_element( "employment:role-title" ) );
        #$role->appendChild( $xml->create_text_node( "Role title" ) );
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
#print STDERR "form_orcid_affiliation_xml [".$xml_str."]\n";
        return $xml_str;
};

=begin InternalDoc

=over

=item valid_orcid_id ( $orcid_id, )

=back

utility routine to test the validity of the format of an ORCID iD

=end InternalDoc

=cut

$c->{valid_orcid_id} = sub
{
        my( $orcid_id, ) = @_;

	return $orcid_id && $orcid_id =~ /\d{4}-\d{4}-\d{4}-\d{3}[Xx\d]/
};

=begin InternalDoc

=over

=item render_orcid_id ( $repo, $orcid_id )

=back

utility routine to render an ORCID iD using current guidelines

=end InternalDoc

=cut

$c->{render_orcid_id} = sub
{
        my( $repo, $orcid_id ) = @_;

	my $frag = $repo->make_doc_fragment;
	return $frag unless $repo->call( "valid_orcid_id", $orcid_id );

	my $xml = $repo->xml;
	my $orcid_link = $frag->appendChild( $xml->create_element( "a", href=>"https://orcid.org" ) );
	$orcid_link->appendChild( $xml->create_element( "img", alt => "ORCID logo", 
					src => "/style/images/orcid_16x16.png", 
					id => "orcid-id-logo-16" ) );
	my $orcid_id_link = $frag->appendChild( $xml->create_element( "a", href=>"https://orcid.org/".$orcid_id ) );
	$orcid_id_link->appendChild( $xml->create_text_node( "https://orcid.org/".$orcid_id ) );

	return $frag;
};

=begin InternalDoc

=over

=item convert_orcid_work_type ( $repo, $orcid_type )

=back

utility routine to convert ORCID work types to EPrint item types

=end InternalDoc

=cut

$c->{convert_orcid_work_type} = sub
{
        my( $repo, $orcid_type ) = @_;

	return unless $orcid_type;
	my $type = lc( $orcid_type );
	$type =~ s/_/\-/g;

	my $type_map = {
		"journal-article" => 'article',
		'magazine-article' => 'article',
		'book-chapter' => 'book_section',
		'book' => 'book',
		'report' => 'article',
		'conference-paper' => 'conference_item',
		'working-paper' => 'article',
		'supervised-student-publication' => 'thesis',
		'journal-issue' => 'article',
		'data set' => 'dataset',
		'patent' => 'patent',
		'other' => 'other',
	};
	return $type_map->{$type} if $type_map->{$type};
	return $type; 
};

=begin InternalDoc

=over

=item get_works_for_orcid ( $repo, $orcid_id )

=back

utility routine to get ORCID works for the supplied ORCID iD

The routine first looks up the ORCID iD in the user dataset to extract
the read_limited scope token.

If no user is found then the client read_public token can be used
N.B. if a user is found but no read_limited token is found then the
code will not revert to the read_public token as in this case it may
be that the user has revoked the permission
 
with a token a call is made to read the works summay data from the ORCID 
Registry

a hash containing the user id, the return code and the returned data is 
returned to the caller.

=end InternalDoc

=cut

$c->{get_works_for_orcid} = sub
{
        my( $repo, $orcid_id ) = @_;

	# default to the read_public token if the user has not given permission?
	my $token = $repo->config( "orcid_read_public_token" );
	# find the user with the specified orcid id
	my $list = $repo->dataset( 'user' )->search(
		filters => [
                 	{ meta_fields => [ 'orcid' ], value => $orcid_id, match => 'EX' }
                 ] );

	# Uncomment the next line to return from this routine if there is no user
	# with the supplied ORCID iD
	# If the routine is allowed to continue it will use the read_public permission
	# to attempt to import works for the supplied iD

#	return undef unless $list->count == 1;

	my $user;
	if ( $list->count == 1 )
	{
		$user = $list->item(0);
		$token = $user->get_value( "orcid_rl_token" );
		# return if we have a user but no token
		return undef unless $token;
	}

	my $url =  $repo->config( "orcid_member_api" ) . 'v' .$repo->config( "orcid_version" ).'/'.$orcid_id.'/works'; 

	my $ua = LWP::UserAgent->new;
	my $request = new HTTP::Request( GET => $url,
			HTTP::Headers->new(
				'Content-Type' => 'application/json', 
				'Authorization' => 'Bearer '.$token )
		);
        $request->header( "accept" => "application/json" );

	my $response = $ua->request($request);
	my $user_id;
	my $code;
	my $data;
	if ( $response )
	{
		$code = $response->code;
		$data = $response->content;
	}
	$user_id = $user->get_id if $user;

	my $result = {
		user => $user_id,
		code => $code,
		data => $data,
	};

	return $result;	
};




# 
# Enable/disable the Orcid plugins
#

$c->{plugins}->{"Import::Orcid"}->{params}->{disable} = 1;
$c->{plugins}->{"Import::UZHOrcid"}->{params}->{disable} = 0;
$c->{plugins}->{"InputForm::Component::Field::OrcidId"}->{params}->{disable} = 0;
$c->{plugins}->{"Orcid::Auth"}->{params}->{disable} = 0;
$c->{plugins}->{"Orcid"}->{params}->{disable} = 0;
$c->{plugins}->{"Screen::Import::UZHOrcid"}->{params}->{disable} = 0;
$c->{plugins}->{"Screen::User::Orcid::OrcidManager"}->{params}->{disable} = 0;



