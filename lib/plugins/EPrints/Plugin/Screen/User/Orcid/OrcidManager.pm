=head1 NAME
	EPrints::Plugin::Screen::User::Orcid::OrcidManager
=cut

package EPrints::Plugin::Screen::User::Orcid::OrcidManager;

our @ISA = ( 'EPrints::Plugin::Screen' );

use strict;
use EPrints::Const qw( :xml ); # XML node type constants

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{appears} = [
		{
			place => "key_tools",
			position => 1050,
		}
	];
        $self->{actions} = [qw/ read_profile read_bio read_works revoke_read_profile revoke_read_bio revoke_read_works 
				create_works revoke_create_works /];


	return $self;
}

#override parent sub from so that we can allow actions
sub from
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $action_id = $self->{processor}->{action};

	return if( !defined $action_id || $action_id eq "" );

	return if( $action_id eq "null" );

	#check for an import action
	if ( $action_id =~ /^import_work_(\d+)$/ )
	{
		my $format = $repo->param( $action_id."_format" );
		my $data = $repo->param( $action_id."_data" );
		my $imported = $self->import_work( $format, $data );
		if ( ref $imported eq "EPrints::List" && $imported->count > 0 )
		{
			$self->{processor}->add_message( "message",
				$self->html_phrase( "orcid_import_ok",
					format=>$repo->make_text( $format ),
					data=>$repo->make_text( $data ) ) );
		}
		else
		{	
			$self->{processor}->add_message( "error",
				$self->html_phrase( "orcid_import_fail",
					format=>$repo->make_text( $format ),
					data=>$repo->make_text( $data ) ) );
		}
		return;
	}
	elsif ( $action_id =~ /^export_work_(\d+)$/ )
	{
		my $exported = $self->export_work( $1 );
		if ( $exported )
		{
			$self->{processor}->add_message( "message",
				$self->html_phrase( "orcid_export_ok", ) );
		}
		else
		{	
			$self->{processor}->add_message( "error",
				$self->html_phrase( "orcid_export_fail", ) );
		}
		return;
	}
	return $self->SUPER::from( );
}



sub can_be_viewed
{
	my( $self ) = @_;

	return $self->allow( "orcid/view" );
}


sub allow_read_profile
{
        return 1;
}


sub action_read_profile
{
        my( $self ) = @_;
	my $action = "read_record";
	$self->get_permission( $action );
}

sub allow_read_bio
{
        return 1;
}

sub action_read_bio
{
        my( $self ) = @_;
	my $action = "read_bio";
	$self->get_permission( $action );
}

sub allow_read_works
{
        return 1;
}

sub action_read_works
{
        my( $self ) = @_;
	my $action = "read_research";
	$self->get_permission( $action );
}

sub allow_create_works
{
        return 1;
}


sub action_create_works
{
        my( $self ) = @_;
	my $action = "add_works";
	$self->get_permission( $action );
}

sub get_permission
{
        my( $self, $action ) = @_;

        my $repo = $self->{repository};
	my $user = $repo->current_user;
	return unless $user;

	print STDERR "ACTION $action\n";	
	my $auth_url = $repo->call( "get_orcid_authorise_url", $repo, $user->get_id(), 0, $action, $user->get_value( "orcid" ) ); 

	print STDERR "ACTION $action [$auth_url]\n";	
	$repo->redirect( $auth_url );
}


sub allow_revoke_read_profile
{
        return 1;
}

sub action_revoke_read_profile
{
        my( $self ) = @_;

	my $action = "read_record";
	$self->revoke_permission( $action );
}


sub allow_revoke_read_bio
{
        return 1;
}

sub action_revoke_read_bio
{
        my( $self ) = @_;

	my $action = "read_bio";
	$self->revoke_permission( $action );
}

sub allow_revoke_read_works
{
        return 1;
}

sub action_revoke_read_works
{
        my( $self ) = @_;

	my $action = "read_research";
	$self->revoke_permission( $action );
}

sub allow_revoke_create_works
{
        return 1;
}

sub action_revoke_create_works
{
        my( $self ) = @_;

	my $action = "add_works";
	$self->revoke_permission( $action );
}


sub revoke_permission
{
        my( $self, $action ) = @_;
        my $repo = $self->{session};

	my $activity_map = $repo->config( "orcid_activity_map" );
	my $field = $activity_map->{$action}->{token}; 
	my $user = $repo->current_user;
	$user->set_value( $field, undef );
	$user->commit;

	my $revoke_url = $repo->call( "get_orcid_revoke_url", $repo ); 
#	$repo->redirect( $revoke_url );
}



sub render
{
	my( $self ) = @_;

	my $repo = $self->{session};
	my $user = $repo->current_user;

	my $entered_orcid = $repo->param( "orcid_input" );
	my $xml = $repo->xml;
	#my $f = $xml->create_document_fragment;
        my $f = $repo->render_form( "GET" );
        $f->appendChild( $repo->render_hidden_field ( "screen", "User::Orcid::OrcidManager" ) );

	my $ds = $repo->dataset("user"); 

	$entered_orcid = $user->get_value( "orcid" );

       	my $orcid_prefix = $self->{prefix}."_orcid_um";
	$f->appendChild( $self->render_id_selection( $orcid_prefix, $user, $entered_orcid, ) );
	
	#my $table = $repo->make_element( "table", class=>"ep_upload_fields ep_multi" );
	#$f->appendChild( $table );

	if ( $entered_orcid )
	{

		my @labels;
		my @panels;

		my $settings_div = $repo->make_element( "div", class => "orcid_details" );
		my $details_div = $settings_div->appendChild( $repo->make_element( "div", class => "orcid_details" ) );
		$details_div->appendChild( $self->render_selected_details( $orcid_prefix, $user ) ) if defined $user;		
	
		my $revoke_div = $settings_div->appendChild( $repo->make_element( "div", class => "orcid_details" ) );
		$revoke_div->appendChild( $self->html_phrase( "account_settings", acc=>"https://sandbox.orcid.org/signin" ) );
		push @labels,  $self->html_phrase( "user_settings" );
		push @panels, $settings_div;


		my $items_div = $repo->make_element( "div", class => "orcid_details" );
		$items_div->appendChild( $self->render_orcid_data( $orcid_prefix, $user, $entered_orcid ) ) if defined $entered_orcid;		
		push @labels,  $self->html_phrase( "public_profile" );
		push @panels, $items_div;

		my $export_div = $repo->make_element( "div", class => "orcid_actions" );
		$export_div->appendChild( $self->render_export_data( $orcid_prefix, $user, $entered_orcid ) ) if defined $entered_orcid;		
		push @labels,  $self->html_phrase( "export" );
		push @panels, $export_div;

		my $notification_div = $repo->make_element( "div", class => "orcid_actions" );
		$notification_div->appendChild( $self->render_action_list( "orcid_actions", {'userid' => $user->get_id} ) );
		$notification_div->appendChild( $self->render_action_list( "orcid_management_actions", {'userid' => $user->get_id} ) );
		push @labels,  $self->html_phrase( "notification" );
		push @panels, $notification_div;

		$f->appendChild( $repo->xhtml->tabs(
					\@labels,
					\@panels,
					basename => "ep_user_orcid_man",
				) );

	}
	else
	{
		$f->appendChild( $self->render_no_results );
		my $div = $f->appendChild( $repo->make_element( "div", class => "orcid_actions" ) );
		$div->appendChild( $self->render_action_list( "orcid_management_actions", {'userid' => $user->get_id} ) );
	}


	return $f;
}	
	
sub render_no_results
{
	my( $self, ) = @_;

	my $repo = $self->{session};

	return $repo->xml->create_text_node( "No Data" );
}
	
sub render_id_selection
{
	my( $self, $orcid_prefix, $user, $value, ) = @_;
	my $repo = $self->{session};
	my $xml = $repo->xml;
	my $ds = $repo->dataset("user"); 
	my $field = $ds->field( "orcid" );

	my $frag = $repo->make_doc_fragment;
	my $table = $frag->appendChild( $xml->create_element( "table", class=>"ep_multi" ) );
	my $tr = $table->appendChild( $xml->create_element( "tr", class=>"ep_first" ) );
	my $th = $tr->appendChild( $xml->create_element( "th", class=>"ep_multi_heading" ) );
	my $td2 = $tr->appendChild( $xml->create_element( "td" ) );
	my $td3 = $tr->appendChild( $xml->create_element( "td" ) );

	$th->appendChild( $self->html_phrase( "title" ) );

	my $input_table = $td2->appendChild( $xml->create_element( "table", border=>"0", cellpadding=>"0", cellspacing=>"0", class=>"ep_form_input_grid" ) );
	my $tr_input = $input_table->appendChild( $xml->create_element( "tr" ) );
	my $td_input = $tr_input->appendChild( $xml->create_element( "td", valign=>"top" ) );

	$td_input->appendChild( $field->render_input_field( 
			$repo, 
			$value, 
			$ds,
			0, # staff mode should be detected from workflow
			undef,
			$user,
			$orcid_prefix,
 	) );

	my $link = $xml->create_element( "img", width=>138, height=>50, 
				src=>"/style/images/getorcid_2.png", 
				style=>"float:right; opacity: 0.4; filter: alpha(opacity=40);",
			 	);
	
	unless ( $value )
	{
		my $auth_url = $repo->call( "get_orcid_authorise_url", $repo, $user->get_id(), 0, "user_authenticate" ); 
	
		my $user_name = $user->get_value( "name" );
		my $user_email = $user->get_value( "email" );
		$auth_url .= "&family_names=". $user_name->{family} if $user_name->{family};
		$auth_url .= "&given_names=". $user_name->{given} if $user_name->{given};

		# the javascript function appends the current orcid from the input text box or the email address
		# and then loads the url
		$link = $xml->create_element( "img", width=>138, height=>50, 
				src=>"/style/images/getorcid_2.png", 
				style=>"float:right;",
				onclick=>"EPJS_appendOrcidIfSet( \'$orcid_prefix\', 
								\'$field->{name}\', 
								\'$auth_url\', 
								\'$user_email\' );" ,
			 	);
	}
	$td3->appendChild( $link );

	return $frag;

#	my $form = $repo->render_form( "GET" );
#	$form->appendChild( $repo->render_hidden_field ( "screen", $self->{processor}->{screenid} ) );		
#	$form->setAttribute("id", "user_orcid_select_form");
	
#        my $table = $form->appendChild( $xml->create_element( "table", class=>"ep_multi" ) );

#        my $selection = $xml->create_element( "select", class => "user_select", name=>"user_select" );
#       	$selection->setAttribute( "onchange", "document.forms[\"orcid_select_form\"].submit();" );

#       	my $initial_option = $repo->xml->create_element( "option", class => "user_select", value=>"0" );
	#      	$initial_option->appendChild( $repo->xml->create_text_node( "Select a user or enter an ORCiD" ) );
#	$initial_option->setAttribute( "selected", "selected" );
#       	$selection->appendChild( $initial_option );

#	$user_list->map( sub {
#		my( $session, $dataset, $user ) = @_;
#        	my $id = $user->get_value("userid");
#        	my $name= $user->get_value("name");
#        	my $orcid = $user->get_value("orcid");
#		if ( $orcid )
#		{
#        		my $option = $repo->xml->create_element( "option", class => "user_select", value=>"$id" );
#        		$option->appendChild( $repo->xml->create_text_node( "id: ".$id." ".$name->{family}.", ".$name->{given} ) );
#			$option->setAttribute( "selected", "selected" ) if $id == $selected_id;
#        		$selection->appendChild( $option );
#		}
#	}); 

#        my $orcid_input = $xml->create_element( "input", class => "user_select", name=>"orcid_input", type=>"text", value=>$entered_orcid );
#        my $button = $xml->create_element( "button",
#                        form=>"user_orcid_select_form",
#                        type=>"submit", 
#                        name=>"get_from_orcid",
#                        value=>"get_from_orcid" );
#        $button->appendChild( $xml->create_text_node( "Search" ) );


#	my $tr1 = $table->appendChild( $xml->create_element( "tr", style=>"width: 100%" ) );
#	my $td11 = $tr1->appendChild( $xml->create_element( "td", class=>"" ) );
#	my $td12 = $tr1->appendChild( $xml->create_element( "td", class=>"" ) );

#	$td11->appendChild( $xml->create_text_node( "User:" ) ); 
#	$td12->appendChild( $selection ); 
 
#	my $tr2 = $table->appendChild( $xml->create_element( "tr", style=>"width: 100%" ) );
#	my $td21 = $tr2->appendChild( $xml->create_element( "td", class=>"" ) );
#	my $td22 = $tr2->appendChild( $xml->create_element( "td", class=>"" ) );

#	$td21->appendChild( $xml->create_text_node( "ORCiD:" ) ); 
#	$td22->appendChild( $orcid_input ); 
#	$td22->appendChild( $button ); 
# 

#	return $form;

}
	
sub render_selected_details
{
	my( $self, $orcid_prefix, $user ) = @_;

	my $repo = $self->{session};
	my $ds = $repo->dataset("user"); 

        my $div = $repo->make_element( "div" );
        my $h3 = $div->appendChild( $repo->make_element( "h3" ) );
	$h3->appendChild( $self->html_phrase( "user_settings" ) );
        my $table = $div->appendChild( $repo->make_element( "table", class=>"ep_multi" ) );
        my $first = 1;
	foreach my $field_name ( qw\ orcid_rl_token orcid_act_u_token orcid_bio_u_token \ ) 
	{
		next unless $ds->has_field( $field_name );
		my $field = $ds->field( $field_name );
		#next unless $user->is_set( $field->get_name );

                my $label = $field->render_name($repo);
		my $value = (defined $user->get_value( $field->get_name )) ? 
			$self->html_phrase( "granted" ) : 
			$self->html_phrase( "revoked" );
		
                $table->appendChild( $repo->render_row_with_help(
                        label=>$label,
                        field=>$value,
                        help=>$field->render_help($repo),
                        help_prefix=>$orcid_prefix."_".$field->get_name."_help",
                ));
                $first = 0;
	}	
	return $div;
}
	
sub render_orcid_data
{
	my( $self, $orcid_prefix, $user, $orcid ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;

	my @labels;
	my @panels;


        my $profile_div = $repo->make_element( "div" );
        my $h3_2 = $profile_div->appendChild( $repo->make_element( "h3" ) );
	$h3_2->appendChild( $self->html_phrase( "profile" ) );

	my $read_profile_plugin = $repo->plugin( "Orcid::ReadProfile" ); 
	$self->read_and_render_orcid_data( $profile_div, $read_profile_plugin, $user, $orcid, "orcid-profile", "render_orcid_profile" );

	my %read_button = ( 
		read_profile => $self->phrase( "action:read_profile:title" ),
		revoke_read_profile => $self->phrase( "action:revoke:title" ),
                _order=>[ "read_profile", "revoke_read_profile" ],
                _class=>"ep_form_button_bar"
        );

	$profile_div->appendChild( $repo->render_action_buttons( %read_button ) );
	push @labels,  $self->html_phrase( "profile" );
	push @panels, $profile_div;

        my $bio_div = $repo->make_element( "div" );
        my $h3_3 = $bio_div->appendChild( $repo->make_element( "h3" ) );
	$h3_3->appendChild( $self->html_phrase( "bio" ) );

	my $read_bio_plugin = $repo->plugin( "Orcid::ReadBio" ); 
	$self->read_and_render_orcid_data( $bio_div, $read_bio_plugin, $user, $orcid, "orcid-bio", "render_orcid_bio" );

	my %bio_button = ( read_bio => $self->phrase( "action:read_bio:title" ),
		revoke_read_bio => $self->phrase( "action:revoke:title" ),
                _order=>[ "read_bio", "revoke_read_bio" ],
                _class=>"ep_form_button_bar"
         );

	$bio_div->appendChild( $repo->render_action_buttons( %bio_button ) );
	push @labels,  $self->html_phrase( "bio" );
	push @panels, $bio_div;


        my $works_div = $repo->make_element( "div" );
        my $h3_4 = $works_div->appendChild( $repo->make_element( "h3" ) );
	$h3_4->appendChild( $self->html_phrase( "works" ) );

	my $read_works_plugin = $repo->plugin( "Orcid::ReadResearch" ); 
	$self->read_and_render_orcid_data( $works_div, $read_works_plugin, $user, $orcid, "orcid-works", "render_orcid_works" );

	my %works_button = ( read_works => $self->phrase( "action:read_works:title" ),
		revoke_read_works => $self->phrase( "action:revoke:title" ),
                _order=>[ "read_works", "revoke_read_works" ],
                _class=>"ep_form_button_bar"
        );

	$works_div->appendChild( $repo->render_action_buttons( %works_button ) );
	push @labels,  $self->html_phrase( "works" );
	push @panels, $works_div;


        my $extern_div = $repo->make_element( "div" );
        my $h3_5 = $extern_div->appendChild( $repo->make_element( "h3" ) );
	$h3_5->appendChild( $self->html_phrase( "extern_id" ) );
	push @labels,  $self->html_phrase( "extern_id" );
	push @panels, $extern_div;

        my $aff_div = $repo->make_element( "div" );
        my $h3_6 = $aff_div->appendChild( $repo->make_element( "h3" ) );
	$h3_6->appendChild( $self->html_phrase( "affiliations" ) );
	push @labels,  $self->html_phrase( "affiliations" );
	push @panels, $aff_div;

        my $funding_div = $repo->make_element( "div" );
        my $h3_7 = $funding_div->appendChild( $repo->make_element( "h3" ) );
	$h3_7->appendChild( $self->html_phrase( "funding" ) );
	push @labels,  $self->html_phrase( "funding" );
	push @panels, $funding_div;

        my $public_div = $repo->make_element( "div" );
        my $h3 = $public_div->appendChild( $repo->make_element( "h3" ) );
	$h3->appendChild( $self->html_phrase( "public_profile" ) );
        $public_div->appendChild( $repo->make_element( "br" ) );

	$public_div->appendChild( $repo->xhtml->tabs(
					\@labels,
					\@panels,
					basename => "ep_user_orcid_public_man",
				) );


	return $public_div;
}

sub read_and_render_orcid_data
{
	my( $self, $form, $plugin, $user, $orcid, $tag, $subroutine ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;

	my $read_granted = $plugin->user_permission_granted( $user );
	if ( $read_granted )
	{
		my $data = $plugin->read_data( $user, $orcid );
		if ( $data ) 
		{
			if (200 == $data->{code} )
			{
				my $result_xml = EPrints::XML::parse_xml_string( $data->{data} );
				my $tag_data = ($result_xml->getElementsByTagName( $tag ))[0];


#print STDERR "$tag data [". $tag_data->toString()."]\n" if $tag_data;
				my $rendered_data = $self->$subroutine( $tag_data );
				$form->appendChild( $rendered_data );
			}
			else
			{
				$form->appendChild( $xml->create_text_node( "Error code: ".$data->{code} ) );
        			$form->appendChild( $repo->make_element( "br" ) );
				$form->appendChild( $xml->create_text_node( "Error: ".$data->{error} ) );
        			$form->appendChild( $repo->make_element( "br" ) );
				$form->appendChild( $xml->create_text_node( "Description: ".$data->{error_description} ) );
        			$form->appendChild( $repo->make_element( "br" ) );
			}
		}
	}
	else
	{
		$form->appendChild( $self->html_phrase( "permission_not_granted" ) );
	}
}



sub render_orcid_profile
{
	my( $self, $data ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;

        my $div = $xml->create_element( "div" );
	my $tag_data =  [ 
		{
			tag => 'orcid-preferences',
			phrase => 'orcid-preferences',
			call => 'render_tag_details',
		},		
		{
			tag => 'orcid-identifier',
			phrase => 'orcid-identifier',
			call => 'render_tag_details',
		},
		{
			tag => 'orcid-history',
			phrase => 'orcid-history',
			call => 'render_tag_details',
		},
		{
			tag => 'orcid-bio',
			phrase => 'orcid-bio',
			call => 'render_tag_details',
		},
		{
			tag => 'orcid-activities',
			phrase => 'orcid-activities',
			call => 'render_tag_details',
		},
	];

	foreach my $tag ( @$tag_data )
	{
		my $tag_contents = ($data->getElementsByTagName( $tag->{tag} ))[0];
		$div->appendChild( $self->html_phrase( $tag->{phrase} ) );
		my $subroutine = $tag->{call};
		$div->appendChild( $self->$subroutine( $tag_contents ) );
	}

	return $div;
}

sub render_orcid_bio
{
	my( $self, $data ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;

        my $div = $xml->create_element( "div" );

	$div->appendChild( $self->html_phrase( 'orcid-bio' ) );
	$div->appendChild( $self->render_tag_details( $data ) );

	return $div;
}

sub render_tag_details
{
	my( $self, $data ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;

        my $table = $xml->create_element( "table", class=>"ep_upload_fields ep_multi" );
	
	if ( $data && $data->hasChildNodes )
	{
		my @nodes = $data->getChildNodes();
		foreach my $node ( @nodes )
		{
			next unless $node->nodeType() eq XML_ELEMENT_NODE;
			my $label = $node->nodeName;
			my $value = EPrints::Utils::tree_to_utf8( $node );

			$table->appendChild( $self->render_table_row_with_text( $xml, $label, $value ) );
		}
	}
	return $table;
}




sub render_orcid_works
{
	my( $self, $data, $form ) = @_;

#print STDERR "render_orcid_works [".$data->toString()."]\n";
	my $repo = $self->{session};
	my $xml = $repo->xml;

        my $div = $xml->create_element( "div" );

       	my $table = $div->appendChild( $xml->create_element( "table", class=>"ep_upload_fields ep_multi" ) );
	my $import_count = 0;
	my @works = $data->getElementsByTagName( "orcid-work" );
	foreach my $work ( @works )
	{
	
#		my $label = "put-code";
#		my $value = "-";
#		my $attributes = $work->attributes();
#		my $put_code_attr = $attributes->{"NodeMap"}->{'put-code'};
#		$value = $put_code_attr->value if $put_code_attr; 
#		$table->appendChild( $self->render_table_row_with_text( $xml, $label, $value, 1 ) );

		my $pub_date = ($work->getElementsByTagName('publication-date'))[0];
		my $date;
		if ( $pub_date )
		{
			my $pub_year = ($pub_date->getElementsByTagName('year'))[0];
			my $pub_month = ($pub_date->getElementsByTagName('month'))[0];
			my $pub_day = ($pub_date->getElementsByTagName('day'))[0];
			$date = $pub_day ? $pub_day->textContent()."/".$pub_month->textContent()."/".$pub_year->textContent() : "";
		}

		my $work_title = ($work->getElementsByTagName('work-title'))[0];
		my $title = ($work_title->getElementsByTagName('title'))[0]->textContent();
		my $sub_title = ($work_title->getElementsByTagName('subtitle'))[0]->textContent() if $work_title->getElementsByTagName('subtitle');
#		my $work_citation  = ($work->getElementsByTagName('work-citation'))[0];
#		my $citation  = ($work_citation->getElementsByTagName('citation'))[0]->textContent();
#		my $citation_format  = ($work_citation->getElementsByTagName('work-citation-type'))[0]->textContent();

		my $ext_id_tag  = ($work->getElementsByTagName('work-external-identifiers'))[0];

		my @ext_ids  = $ext_id_tag->getElementsByTagName('work-external-identifier');

		my $plugin_rank = $repo->config( "orcid_import_plugin_rank" );
		my $duplicate = 0;
		my $id_type;
		my $id;
		foreach my $ext_id ( @ext_ids )
		{
			my $this_id_type  = ($ext_id->getElementsByTagName('work-external-identifier-type'))[0]->textContent();
			my $this_id = ($ext_id->getElementsByTagName('work-external-identifier-id'))[0]->textContent();;
			if ( $id_type )
			{
				my $current_rank = $plugin_rank->{uc($id_type)} ? $plugin_rank->{uc($id_type)} : 0;
				my $new_rank = $plugin_rank->{uc($this_id_type)} ? $plugin_rank->{uc($this_id_type)} : 0;
				if ( $new_rank > $current_rank )
				{	
					$id_type = $this_id_type;
					$id = $this_id;
				}
			}
			else
			{
				$id_type = $this_id_type;
				$id = $this_id;
			}
print STDERR "id_type is [$id_type] this[$this_id_type]\n";
			$duplicate++ if $self->is_duplicate ( $this_id_type, $this_id );
			last if $duplicate;

		}
		if ( $duplicate )
		{
			$table->appendChild( $self->render_works_table_row_with_tick( $xml, "Title", $title ) );
		}
		else 
		{		
                       	$table->appendChild( $self->render_works_table_row_with_import( $xml, "Title", $title, $id_type, $id, $import_count++ ) );
		}
		$table->appendChild( $self->render_works_table_row( $xml, "Subtitle", $sub_title ) );
		$table->appendChild( $self->render_works_table_row( $xml, "Date", $date ) );
		$table->appendChild( $self->render_works_table_row( $xml, "IDs", EPrints::Utils::tree_to_utf8( $ext_id_tag ) ) );
#		$table->appendChild( $self->render_table_row_with_text( $xml, "Citation Format", $citation_format ) );
#		$table->appendChild( $self->render_table_row_with_import( $xml, "Citation", $citation, $citation_format, $citation, $import_count++ ) );
	}

#	$div->appendChild( $self->render_tag_details( $data ) );
	return $div;
}

sub render_works_table_row
{
	my( $self, $xml, $label, $value, $first ) = @_;
	my $tr = $xml->create_element( "tr", style=>"width: 100%" );
	my $first_class = "";
	$first_class = "_first" if $first;
	my $td1 = $tr->appendChild( $xml->create_element( "td", class=>"ep_orcid_works_label".$first_class ) );
	my $td2 = $tr->appendChild( $xml->create_element( "td", class=>"ep_orcid_works_value".$first_class ) );
	$td1->appendChild( $xml->create_text_node( $label ) );
	$td2->appendChild( $xml->create_text_node( $value ) );

	return $tr;
}
sub render_works_table_row_with_tick
{
	my( $self, $xml, $label, $value, $first ) = @_;
	my $tr = $xml->create_element( "tr", style=>"width: 100%" );
	my $first_class = "";
	$first_class = "_first" if $first;
	my $td1 = $tr->appendChild( $xml->create_element( "td", class=>"ep_orcid_works_label".$first_class ) );
	my $td2 = $tr->appendChild( $xml->create_element( "td", class=>"ep_orcid_works_value".$first_class ) );
	my $td3 = $tr->appendChild( $xml->create_element( "td", class=>"ep_orcid_works_link".$first_class, rowspan=>"4" ) );
	$td1->appendChild( $xml->create_text_node( $label ) );
	$td2->appendChild( $xml->create_text_node( $value ) );
	my $tick_div = $xml->create_element( "div", class=>"ep_form_button_bar" ); 
	my $tick = $tick_div->appendChild( $xml->create_element( "img", width=>32, height=>32, src=>"/style/images/tick.png" ) );
	$td3->appendChild( $tick_div );

	return $tr;
}

sub render_works_table_row_with_import
{
	my( $self, $xml, $label, $value, $import_type, $import_value, $import_count, $first ) = @_;

	my $repo = $self->{repository};

	my $tr = $xml->create_element( "tr", style=>"width: 100%" );
	my $first_class = "";
	$first_class = "_first" if $first;
	my $td1 = $tr->appendChild( $xml->create_element( "td", class=>"ep_orcid_works_label".$first_class ) );
	my $td2 = $tr->appendChild( $xml->create_element( "td", class=>"ep_orcid_works_value".$first_class ) );
	my $td3 = $tr->appendChild( $xml->create_element( "td", class=>"ep_orcid_works_link".$first_class, rowspan=>"4" ) );
	$td1->appendChild( $xml->create_text_node( $label ) );
	$td2->appendChild( $xml->create_text_node( $value ) );
	
	my $plugin_map = $repo->config( "orcid_import_plugin_map" );
	my $import_plugin = $plugin_map->{ uc($import_type) };

print STDERR "using import plugin [$import_type] [$import_plugin]\n";
	my $action_name = "import_work_".$import_count;
	my $div = $xml->create_element( "div", class=>"ep_form_button_bar" ); 

	my $button = $div->appendChild( $xml->create_element( "input", 
		type=>"submit", 
		name=> "_action_".$action_name, 
		value=>$self->phrase( "action:import_work:title" ) ) );
	if ( $import_plugin )
	{
		$div->appendChild( $repo->render_hidden_field ( $action_name."_format", $import_plugin ) );
		$div->appendChild( $repo->render_hidden_field ( $action_name."_data", $import_value ) );
	}
	else
	{
		$button->setAttribute( "disabled", "disabled" ) unless $import_plugin;
	}
	$td3->appendChild( $div );
	return $tr;
}


sub render_table_row
{
	my( $self, $xml, $label, $value, $link, $first ) = @_;
	my $tr = $xml->create_element( "tr", style=>"width: 100%" );
	my $first_class = "";
	$first_class = "_first" if $first;
	my $td1 = $tr->appendChild( $xml->create_element( "td", class=>"ep_orcid_works_label".$first_class ) );
	my $td2 = $tr->appendChild( $xml->create_element( "td", class=>"ep_orcid_works_value".$first_class ) );
	my $td3 = $tr->appendChild( $xml->create_element( "td", class=>"ep_orcid_works_link".$first_class ) );
	$td1->appendChild( $label );
	$td2->appendChild( $value );
	$td3->appendChild( $link );

	return $tr;
}

sub render_table_row_with_text
{
	my( $self, $xml, $label_val, $value_val, $first ) = @_;

	my $label = $xml->create_text_node( $label_val );
	my $value = $xml->create_text_node( $value_val );
	my $link = $xml->create_text_node( "" );
	return $self->render_table_row( $xml, $label, $value, $link, $first );
}


sub render_table_row_with_link
{
	my( $self, $xml, $label_val, $value_val, $link_val ) = @_;

	my $label = $xml->create_text_node( $label_val );
	my $value = $xml->create_element( "a", href=>$link_val, target=>"_blank" );
	$value->appendChild( $xml->create_text_node( $value_val ) );
	my $link = $xml->create_text_node( "" );
	return $self->render_table_row( $xml, $label, $value, $link );
}



sub is_duplicate
{
	my ( $self, $type, $value ) = @_;
	my $repo = $self->{repository};
	my $ds = $repo->dataset("eprint");
print STDERR "OrcidManager::is_duplicate [$type] [$value] \n";

	my $searchexp = $ds->prepare_search( satisfy_all => 0 );
	foreach my $fn ( qw/ item_doi_field item_pmid_field / )
	{
		my $id_field = $repo->config( $fn );
		$searchexp->add_field(
			fields => [ $ds->field( $id_field ) ],
			value  => $value,
			match  => "EQ",
		);
	}

	my $list = $searchexp->perform_search;
	
print STDERR "OrcidManager::is_duplicate [$type] [$value] returning [".$list->count."]\n";
	return $list->count;
}

sub import_work
{
	my( $self, $plugin_id, $data, ) = @_;

	my $repo = $self->{repository};
	my $plugin = $repo->plugin( "Import::".$plugin_id );

	return unless $plugin;
	my $data_file = $data;

	my $data_fh = new FileHandle("echo \'$data_file\' |") or die;

	$plugin->set_handler( $self );
	my %opts = ( fh=>$data_fh, dataset=>$repo->dataset("inbox") );
	my $list = $plugin->input_text_fh( %opts );
	return $list;
}

sub message
{
	my( $self, $type, $msg ) = @_;

	unless( $self->{quiet} )
	{
		$self->{processor}->add_message( $type, $msg );
	}
}

sub epdata_to_dataobj
{
print STDERR "OrcidManager::epdata_to_dataobj called !!!!!!!!!!!!!!!!!!!\n";
	my( $self, $epdata, %opts ) = @_;
	$self->{parsed}++;

	return if $self->{dryrun};

	my $dataset = $opts{dataset};
	if( $dataset->base_id eq "eprint" )
	{
		my $user = $self->{repository}->current_user;
		$epdata->{userid} = $user->get_id;
		$epdata->{eprint_status} = "inbox";
	}	

	$self->{wrote}++;

	return $dataset->create_dataobj( $epdata );
}

sub render_export_data
{
	my( $self, $orcid_prefix, $user, $orcid ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;

        my $works_div = $repo->make_element( "div" );
        my $h3_4 = $works_div->appendChild( $repo->make_element( "h3" ) );
	$h3_4->appendChild( $self->html_phrase( "works" ) );

	my $users_eprints = $user->owned_eprints_list();
	unless ( $users_eprints && $users_eprints->count )
	{
		$works_div->appendChild( $xml->create_text_node( "No items found" ) );
		return $works_div;
	}

	my $orcid_work_ids = {};
	my $read_works_plugin = $repo->plugin( "Orcid::ReadResearch" ); 
	if ( $read_works_plugin->user_permission_granted( $user ) )
	{
		my $data = $read_works_plugin->read_data( $user, $orcid );
		if ( $data ) 
		{
			if (200 == $data->{code} )
			{
				my $result_xml = EPrints::XML::parse_xml_string( $data->{data} );
				my $tag_data = ($result_xml->getElementsByTagName( "orcid-works" ))[0] if $result_xml;
				my @works = $tag_data->getElementsByTagName( "orcid-work" ) if $tag_data;
				foreach my $work ( @works )
				{
	
					#my $work_title = ($work->getElementsByTagName('work-title'))[0];
					#my $title = ($work_title->getElementsByTagName('title'))[0]->textContent();
					my $ext_id_tag  = ($work->getElementsByTagName('work-external-identifiers'))[0];
					my @ext_ids  = $ext_id_tag->getElementsByTagName('work-external-identifier');
					foreach my $ext_id ( @ext_ids )
					{
						my $this_id = ($ext_id->getElementsByTagName('work-external-identifier-id'))[0]->textContent();;
						$orcid_work_ids->{$this_id}++;
					}
				}
			}
			else
			{
				$works_div->appendChild( $xml->create_text_node( "Error code: ".$data->{code} ) );
        			$works_div->appendChild( $repo->make_element( "br" ) );
				$works_div->appendChild( $xml->create_text_node( "Error: ".$data->{error} ) );
        			$works_div->appendChild( $repo->make_element( "br" ) );
				$works_div->appendChild( $xml->create_text_node( "Description: ".$data->{error_description} ) );
        			$works_div->appendChild( $repo->make_element( "br" ) );
			}

		}
	}
	else
	{
		$works_div->appendChild( $self->html_phrase( "permission_not_granted" ) );
	}

        my $table = $works_div->appendChild( $xml->create_element( "table", class=>"ep_upload_fields ep_multi" ) );
	$users_eprints->map( sub {
		my ( $repo, $dataset, $eprint ) = @_;
		if ( $eprint->value( "eprint_status" ) eq "archive" )
		{
			my $uploaded = 0;
			foreach my $id_field_name ( qw\ item_doi_field item_pmid_field \ )
			{
				my $id_field = $repo->config( $id_field_name );
				if ( $id_field )
				{
					my $id = $eprint->get_value( $id_field );
					$uploaded++ if $id && $orcid_work_ids->{$id};
print STDERR "check id field[$id_field] value[$id] uploaded[$uploaded]\n";
				}
			}	
			my $ep_title = $eprint->value( "title" ); #->[0]->{text};
			$ep_title = $ep_title->[0]->{text} if ( ref $ep_title eq "ARRAY" );
			if ( $uploaded )
			{
				$table->appendChild( $self->render_table_row_with_tick( $xml, "Title", $ep_title, 1, $user->get_id, $eprint->get_id ) );
			}
			else
			{
				$table->appendChild( $self->render_table_row_with_export( $xml, "Title", $ep_title, 1, $user, $eprint->get_id ) );
			}
		}
	});

	my %add_button = ( 
		create_works => $self->phrase( "action:create_works:title" ),
		revoke_create_works => $self->phrase( "action:revoke:title" ),
                _order=>[ "create_works", "revoke_create_works" ],
                _class=>"ep_form_button_bar"
        );

	$works_div->appendChild( $repo->render_action_buttons( %add_button ) );
	
	
print STDERR "Export got ids [".Data::Dumper::Dumper($orcid_work_ids)."]\n";
	return $works_div;
}

sub render_table_row_with_export
{
	my( $self, $xml, $label_val, $value_val, $first, $user, $item_id ) = @_;

	my $repo = $self->{repository};

	my $label = $xml->create_text_node( $label_val );
	my $value = $xml->create_text_node( $value_val );

	my $action_name = "export_work_".$item_id;
	my $button = $xml->create_element( "input", 
		type => "image", 
		src => "/style/images/export.png",
		width => 32, 
		height => 32,
		name => "_action_".$action_name, 
		title => $self->phrase( "action:export_work:title" ), 
		alt => $self->phrase( "action:export_work:title" ), 
	);
	my $works_plugin = $repo->plugin( "Orcid::AddWorks" ); 
	my $add_granted = $works_plugin->user_permission_granted( $user );
	if ( !$add_granted )
	{
		$button->setAttribute( "disabled", "disabled" );
		$button->setAttribute( "style", "opacity: 0.4; filter: alpha(opacity=40);" );
	}
	
	#my $auth_url = $repo->config( "orcid_authorise_url" ); 
	#$auth_url .= "u".$user_id."i".$item_id."a0";
#	my $auth_url = $repo->call( "get_orcid_authorise_url", $repo, $user_id, $item_id, "update_works" ); 

#	my $link = $xml->create_element( "a", href=>$auth_url );
#	my $tick = $link->appendChild( $xml->create_element( "img", width=>32, height=>32, src=>"/style/images/export.png" ) );
	return $self->render_table_row( $xml, $label, $value, $button, $first );
}

sub render_table_row_with_tick
{
	my( $self, $xml, $label_val, $value_val, $first, $user_id, $item_id ) = @_;

	my $repo = $self->{session};

	my $label = $xml->create_text_node( $label_val );
	my $value = $xml->create_text_node( $value_val );

	my $tick = $xml->create_element( "img", width=>32, height=>32, src=>"/style/images/tick.png" );
	return $self->render_table_row( $xml, $label, $value, $tick, $first );
}


sub export_work
{
	my( $self, $id ) = @_;
print STDERR "############### export_work called for id [$id] ##################\n";	

	my $repo = $self->{repository};
	my $xml = $repo->xml;
	my $user = $repo->current_user;
	return unless $user;
	my $orcid = $user->get_value( "orcid" );
	return unless $orcid;

	my $plugin = $repo->plugin( "Orcid::AddWorks" ); 
	my $add_granted = $plugin->user_permission_granted( $user );
	if ( $add_granted )
	{
print STDERR "add work token:[$add_granted]\n";
		my $work_xml = $repo->call( "form_orcid_work_xml", $repo, $id ); 

# curl -H 'Content-Type: application/orcid+xml' -H 'Authorization: Bearer aa2c8730-07af-4ac6-bfec-fb22c0987348' -d '@/Documents/new_work.xml' -X POST 'https://api.sandbox.orcid.org/v1.2/0000-0002-2389-8429/orcid-works'

		my $add_work_url = $repo->config( "orcid_tier_2_api" );
		$add_work_url .= "v1.2/";
		$add_work_url .= $orcid;
		$add_work_url .= "/orcid-works";

		my $req = HTTP::Request->new(POST => $add_work_url, );
		$req->header('content-type' => 'application/orcid+xml');
		$req->header('Authorization' => 'Bearer '.$add_granted);
		 
		# add POST data to HTTP request body
		$req->content(Encode::encode("utf8", $work_xml));

		my $ua = LWP::UserAgent->new;
		my $response = $ua->request($req);

print STDERR "\n\n\n\n####### got response [".Data::Dumper::Dumper($response)."]\n\n";

		if ( $response->code > 299 )
		{

			$self->{processor}->add_message( "message",
				$self->html_phrase( "orcid_export_error", code=> $xml->create_text_node($response->code) ) );
			return 0;
		}
		else 
		{
			return 1;
		}
	}
	else
	{
		$self->{processor}->add_message( "message",
				$self->html_phrase( "permission_not_granted", ) );
	}

	return 0;
}



1;


