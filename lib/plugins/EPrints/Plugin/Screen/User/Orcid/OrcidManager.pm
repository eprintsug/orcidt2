=head1 NAME

EPrints::Plugin::Screen::User::Orcid::OrcidManager

This screen plugin provides a landing screen for the
create/connect actions plus a facility to manage
permissions, perform actions and view data

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
			position => 290,
		}
	];
        $self->{actions} = [qw/ read_record update_activities update_profile revoke_read revoke_update_activities 
				revoke_update_profile remove_id /];


	return $self;
}

=begin InternalDoc

=over

=item from

=back

override parent routine so that we can allow custom internal actions

=end InternalDoc

=cut

########################################################################################
#
# This is currently commented out as no internal actions are enabled yet
########################################################################################
#sub from
#{
#	my( $self ) = @_;
#
#	my $repo = $self->{repository};
#	my $action_id = $self->{processor}->{action};
#
#	return if( !defined $action_id || $action_id eq "" );
#
#	return if( $action_id eq "null" );
#
#	#check for an import action
#	if ( $action_id =~ /^import_work_(\d+)$/ )
#	{
#		my $format = $repo->param( $action_id."_format" );
#		my $data = $repo->param( $action_id."_data" );
#		my $imported = $self->import_work( $format, $data );
#		if ( ref $imported eq "EPrints::List" && $imported->count > 0 )
#		{
#			$self->{processor}->add_message( "message",
#				$self->html_phrase( "orcid_import_ok",
#					format=>$repo->make_text( $format ),
#					data=>$repo->make_text( $data ) ) );
#		}
#		else
#		{	
#			$self->{processor}->add_message( "error",
#				$self->html_phrase( "orcid_import_fail",
#					format=>$repo->make_text( $format ),
#					data=>$repo->make_text( $data ) ) );
#		}
#		return;
#	}
#	elsif ( $action_id =~ /^export_work_(\d+)$/ )
#	{
#		my $exported = $self->export_work( $1 );
#		if ( $exported )
#		{
#			$self->{processor}->add_message( "message",
#				$self->html_phrase( "orcid_export_ok", ) );
#		}
#		else
#		{	
#			$self->{processor}->add_message( "error",
#				$self->html_phrase( "orcid_export_fail", ) );
#		}
#		return;
#	}
#	return $self->SUPER::from( );
#}


=begin InternalDoc

=over

=item can_be_viewed

=back

control visibility of the screen plugin via a user/role permission

=end InternalDoc

=cut

sub can_be_viewed
{
	my( $self ) = @_;

	return $self->allow( "orcid/view" );
}

=begin InternalDoc

=over

=item allow_read_record, action_read_record 

=back

Screen plugin action to get the user's permission for the read-limited scope

=end InternalDoc

=cut

sub allow_read_record
{
        return 1;
}


sub action_read_record
{
        my( $self ) = @_;
	my $scope = "/read-limited";
	$self->get_permission( $scope );
}

=begin InternalDoc

=over

=item allow_update_activities, action_update_activities

=back

Screen plugin action to get the user's permission for the activities/update scope

=end InternalDoc

=cut

sub allow_update_activities
{
        return 1;
}

sub action_update_activities
{
        my( $self ) = @_;
	my $scope = "/activities/update";
	$self->get_permission( $scope );
}

=begin InternalDoc

=over

=item allow_update_profile, action_update_profile

=back

Screen plugin action to get the user's permission for the person/update scope

=end InternalDoc

=cut

sub allow_update_profile
{
        return 1;
}

sub action_update_profile
{
        my( $self ) = @_;
	my $scope = "/person/update";
	$self->get_permission( $scope );
}

=begin InternalDoc

=over

=item allow_revoke_read, action_revoke_read

=back

Screen plugin action to revoke the user's permission for the /read-limited scope
N.B. this simply deletes the token stored for the scope the user's ORCID profile
is not modified.

=end InternalDoc

=cut

sub allow_revoke_read
{
        return 1;
}

sub action_revoke_read
{
        my( $self ) = @_;

	my $scope = "/read-limited";
	$self->revoke_permission( $scope );
}

=begin InternalDoc

=over

=item allow_revoke_update_activities,action_revoke_update_activities

=back

Screen plugin action to revoke the user's permission for the /activities/update scope
N.B. this simply deletes the token stored for the scope the user's ORCID profile
is not modified.

=end InternalDoc

=cut

sub allow_revoke_update_activities
{
        return 1;
}

sub action_revoke_update_activities
{
        my( $self ) = @_;

	my $scope = "/activities/update";
	$self->revoke_permission( $scope );
}

=begin InternalDoc

=over

=item allow_revoke_update_profile, action_revoke_update_profile

=back

Screen plugin action to revoke the user's permission for the /person/update scope
N.B. this simply deletes the token stored for the scope the user's ORCID profile
is not modified.

=end InternalDoc

=cut

sub allow_revoke_update_profile
{
        return 1;
}

sub action_revoke_update_profile
{
        my( $self ) = @_;

	my $scope = "/person/update";
	$self->revoke_permission( $scope );
}

=begin InternalDoc

=over

=item allow_remove_id, action_remove_id

=back

Screen plugin action to revoke the user's permission for the /person/update scope
N.B. this simply deletes the token stored for the scope the user's ORCID profile
is not modified.

=end InternalDoc

=cut

sub allow_remove_id
{
        return 1;
}

sub action_remove_id
{
        my( $self ) = @_;

        my $repo = $self->{repository};
	my $user = $repo->current_user;
	return unless $user;
	$user->set_value( 'orcid', undef );
	$user->commit;
}

=begin InternalDoc

=over

=item get_permission ( $self, $scope )

=back

Request permission from the user for a particular scope. This uses the auth plugin to
handle the user's response

=end InternalDoc

=cut

sub get_permission
{
        my( $self, $scope ) = @_;

        my $repo = $self->{repository};
	my $user = $repo->current_user;
	return unless $user;

	my $activity = "04"; # do nothing and return to orcid screen
	my $auth_url = $repo->call( "get_orcid_authorise_url", $repo, $user->get_id(), 0, $scope, $activity, $user->get_value( "orcid" ) ); 

	$repo->redirect( $auth_url );
}

=begin InternalDoc

=over

=item revoke_permission ( $self, $scope )

=back

Delete the token stored for the user for the specified scope 

=end InternalDoc

=cut

sub revoke_permission
{
        my( $self, $scope ) = @_;
        my $repo = $self->{session};

	my $scope_map = $repo->config( "orcid_scope_map" );
	my $field = $scope_map->{$scope}; 
	my $user = $repo->current_user;
	$user->set_value( $field, undef );
	$user->commit;
}

=begin InternalDoc

=over

=item render ( $self )

=back

This is the main render routine for the screen plugin
If there is an ORCID iD stored for the user then it will be displayed
and the create/connect button will be disabled.

The state of the tokens stored for a user will also be displayed along with a button 
toggle the state of the permissions. 

N.B. the presence of a token for a scope does not necessarily mean that the token
is still valid.

If there is no ORCID iD then an input field and an active create/connectbutton is 
displayed.

=end InternalDoc

=cut

sub render
{
	my( $self ) = @_;

	my $repo = $self->{session};
	my $user = $repo->current_user;

	my $entered_orcid = $repo->param( "orcid_input" );
	my $xml = $repo->xml;
        my $f = $repo->render_form( "GET" );
        $f->appendChild( $repo->render_hidden_field ( "screen", "User::Orcid::OrcidManager" ) );

	my $ds = $repo->dataset("user"); 

	$entered_orcid = $user->get_value( "orcid" );

       	my $orcid_prefix = $self->{prefix}."_orcid_um";
	$f->appendChild( $self->render_id_selection( $orcid_prefix, $user, $entered_orcid, ) );
	
	if ( $entered_orcid )
	{
		my @labels;
		my @panels;

		my $settings_div = $repo->make_element( "div", class => "orcid_details" );
		my $details_div = $settings_div->appendChild( $repo->make_element( "div", class => "orcid_details" ) );
		$details_div->appendChild( $self->render_selected_details( $orcid_prefix, $user ) ) if defined $user;		
	
		my $revoke_div = $settings_div->appendChild( $repo->make_element( "div", class => "orcid_details" ) );
		$revoke_div->appendChild( $self->html_phrase( "account_settings" ) );
		push @labels,  $self->html_phrase( "user_settings" );
		push @panels, $settings_div;

# The following panels are not currently required

#		my $items_div = $repo->make_element( "div", class => "orcid_details" );
#		$items_div->appendChild( $self->render_orcid_data( $orcid_prefix, $user, $entered_orcid ) ) if defined $entered_orcid;		
#		push @labels,  $self->html_phrase( "public_profile" );
#		push @panels, $items_div;

#		my $export_div = $repo->make_element( "div", class => "orcid_actions" );
#		$export_div->appendChild( $self->render_export_data( $orcid_prefix, $user, $entered_orcid ) ) if defined $entered_orcid;		
#		push @labels,  $self->html_phrase( "export" );
#		push @panels, $export_div;

#		my $notification_div = $repo->make_element( "div", class => "orcid_actions" );
#		$notification_div->appendChild( $self->render_action_list( "orcid_actions", {'userid' => $user->get_id} ) );
#		$notification_div->appendChild( $self->render_action_list( "orcid_management_actions", {'userid' => $user->get_id} ) );
#		push @labels,  $self->html_phrase( "notification" );
#		push @panels, $notification_div;

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

=begin InternalDoc

=over

=item render_no_results ( $self, ) 

=back

Display a message to indicate no data has been obtained from the ORCID Registry

=end InternalDoc

=cut

sub render_no_results
{
	my( $self, ) = @_;

	my $repo = $self->{session};

	return $self->html_phrase( "no_data" );
}

=begin InternalDoc

=over

=item render_id_selection ( $self, $orcid_prefix, $user, $value, )

=back

display the connect/create button based on 
http://members.orcid.org/api/resources/graphics

=end InternalDoc

=cut

sub render_id_selection
{
	my( $self, $orcid_prefix, $user, $value, ) = @_;
	my $repo = $self->{session};
	my $xml = $repo->xml;
	my $ds = $repo->dataset("user"); 
	my $field = $ds->field( "orcid" );

	my $frag = $repo->make_doc_fragment;
	my $div = $frag->appendChild( $xml->create_element( "div", class=>"orcid_connect" ) );
	my $text_div = $div->appendChild( $xml->create_element( "div", class=>"orcid_connect_text" ) );
	my $input_div = $div->appendChild( $xml->create_element( "div", class=>"orcid_connect_input" ) );
	my $btn_div = $div->appendChild( $xml->create_element( "div", class=>"orcid_connect_btn" ) );
	if ( $value )
	{
		$input_div->appendChild( $repo->call( "render_orcid_id", $repo, $value ) );
		my $rm_action= $input_div->appendChild( $xml->create_element( "input", 
			value => $self->phrase( "action:remove_id:title" ),
			type => "submit", 
			name => "_action_remove_id", 
			class => "btn btn-uzh-prime" ) );

		my $button = $btn_div->appendChild( $xml->create_element( "button", 
					id => "disabled-connect-orcid-button",
					type => "button",
					disabled => "true"
					) );
		$button->appendChild( $xml->create_element( "img", 
			id =>"orcid-id-logo-24", 
			src =>"/style/images/orcid_24x24.png", 
			alt =>"ORCID logo" ) );
					
		$button->appendChild( $repo->html_phrase( "orcid_connect_btn:title" ) );
	}
	else
	{
                $text_div->appendChild( $repo->html_phrase( "user_fieldhelp_orcid" ) );
		$input_div->appendChild( $field->render_input_field( 
			$repo, 
			$value, 
			$ds,
			0, # staff mode should be detected from workflow
			undef,
			$user,
			$orcid_prefix,
 		) );

		my $activity = "02"; # user_authenticate
		my $scope = "/authenticate /activities/update /person/update /read-limited";
		my $auth_url = $repo->call( "get_orcid_authorise_url", $repo, $user->get_id(), 0, $scope, $activity ); 
	
		my $user_name = $user->get_value( "name" );
		my $user_email = $user->get_value( "email" );
		$auth_url .= "&family_names=". $user_name->{family} if $user_name->{family};
		$auth_url .= "&given_names=". $user_name->{given} if $user_name->{given};

		# the javascript function appends the current orcid from the input text box or the email address
		# and then loads the url
		my $button = $btn_div->appendChild( $xml->create_element( "button", 
					id => "connect-orcid-button",
					type => "button",
					onclick => "EPJS_appendOrcidIfSet( \'$orcid_prefix\', 
								\'$field->{name}\', 
								\'$auth_url\', 
								\'$user_email\' );" ,
	
					) );
		$button->appendChild( $xml->create_element( "img", 
			id =>"orcid-id-logo", 
			src =>"/style/images/orcid_24x24.png", 
			alt =>"ORCID logo" ) );
		$button->appendChild( $repo->html_phrase( "orcid_connect_btn:title" ) ); 
	}


	return $frag;
}

=begin InternalDoc

=over

=item render_selected_details ( $self, $orcid_prefix, $user )

=back

routine to render the scopes and the current state of the associated tokens plus
actions to toggle the state.

=end InternalDoc

=cut

sub render_selected_details
{
	my( $self, $orcid_prefix, $user ) = @_;

	my $repo = $self->{session};
	my $ds = $repo->dataset("user"); 

        my $div = $repo->make_element( "div" );
        my $h3 = $div->appendChild( $repo->make_element( "h3" ) );
	$h3->appendChild( $self->html_phrase( "user_settings" ) );


	foreach my $field_name ( qw\ orcid_rl_token orcid_act_u_token orcid_bio_u_token \ ) 
	{
		next unless $ds->has_field( $field_name );
		my $field = $ds->field( $field_name );
                my $label = $field->render_name($repo);
		my $help = $field->render_help($repo); 
		my $value = (defined $user->get_value( $field->get_name ));
		my $action = $self->html_phrase( "no_action" );

        	my $div_read = $div->appendChild( $repo->make_element( "div", class=>"orcid_revoke_div" ) );
		my $btn = {};

		if ( $value )
		{
			my $btn_label = $self->phrase( "action:revoke:title" );
			if ( $field_name eq "orcid_rl_token" )
			{
				$btn = { revoke_read => $btn_label, _class=>"ep_form_button_bar" };
			}
			elsif ($field_name eq "orcid_act_u_token" )
			{
				$btn = { revoke_update_activities => $btn_label, _class=>"ep_form_button_bar" };
			}
			elsif ($field_name eq "orcid_bio_u_token" )
			{
				$btn = { revoke_update_profile => $btn_label, _class=>"ep_form_button_bar" };
			}
		}
		else
		{
			if ( $field_name eq "orcid_rl_token" )
			{
				my $btn_label = $self->phrase( "action:read_record:title" );
				$btn = { read_record => $btn_label, _class=>"ep_form_button_bar" };
			}
			elsif ($field_name eq "orcid_act_u_token" )
			{
				my $btn_label = $self->phrase( "action:update_activities:title" );
				$btn = { update_activities => $btn_label, _class=>"ep_form_button_bar" };
			}
			elsif ($field_name eq "orcid_bio_u_token" )
			{
				my $btn_label = $self->phrase( "action:update_profile:title" );
				$btn = { update_profile => $btn_label, _class=>"ep_form_button_bar" };
			}
		}
		if ( $btn )
		{
			$action = $repo->render_action_buttons( %$btn ); 
		}
		my $status = $self->html_phrase( "revoked" );
		if ( $value )
		{
			$status = $self->html_phrase( "granted" ); 
		}
		$div_read->appendChild( $self->html_phrase( "token_status", label=>$label, desc=>$help, status=>$status, action=>$action ) );
	}	

	return $div;
}
	
########################################################################################
# not yet enabled
########################################################################################
#sub render_orcid_data
#{
#	my( $self, $orcid_prefix, $user, $orcid ) = @_;
#
#	my $repo = $self->{repository};
#	my $xml = $repo->xml;
#
#	my @labels;
#	my @panels;
#
#        my $profile_div = $repo->make_element( "div" );
#        my $h3_2 = $profile_div->appendChild( $repo->make_element( "h3" ) );
#	$h3_2->appendChild( $self->html_phrase( "profile" ) );
#
#	my $read_profile_plugin = $repo->plugin( "Orcid::ReadProfile" ); 
#	$self->read_and_render_orcid_data( $profile_div, $read_profile_plugin, $user, $orcid, "orcid-profile", "render_orcid_profile" );
#
#	my %read_button = ( 
#		read_profile => $self->phrase( "action:read_profile:title" ),
#		revoke_read_profile => $self->phrase( "action:revoke:title" ),
#                _order=>[ "read_profile", "revoke_read_profile" ],
#                _class=>"ep_form_button_bar"
#        );
#
#	$profile_div->appendChild( $repo->render_action_buttons( %read_button ) );
#	push @labels,  $self->html_phrase( "profile" );
#	push @panels, $profile_div;
#
#        my $bio_div = $repo->make_element( "div" );
#        my $h3_3 = $bio_div->appendChild( $repo->make_element( "h3" ) );
#	$h3_3->appendChild( $self->html_phrase( "bio" ) );
#
#	my $read_bio_plugin = $repo->plugin( "Orcid::ReadBio" ); 
#	$self->read_and_render_orcid_data( $bio_div, $read_bio_plugin, $user, $orcid, "orcid-bio", "render_orcid_bio" );
#
#	my %bio_button = ( read_bio => $self->phrase( "action:read_bio:title" ),
#		revoke_read_bio => $self->phrase( "action:revoke:title" ),
#                _order=>[ "read_bio", "revoke_read_bio" ],
#                _class=>"ep_form_button_bar"
#         );
#
#	$bio_div->appendChild( $repo->render_action_buttons( %bio_button ) );
#	push @labels,  $self->html_phrase( "bio" );
#	push @panels, $bio_div;
#
#
#        my $works_div = $repo->make_element( "div" );
#        my $h3_4 = $works_div->appendChild( $repo->make_element( "h3" ) );
#	$h3_4->appendChild( $self->html_phrase( "works" ) );
#
##	my $read_works_plugin = $repo->plugin( "Orcid::ReadResearch" ); 
##	$self->read_and_render_orcid_data( $works_div, $read_works_plugin, $user, $orcid, "orcid-works", "render_orcid_works" );
#
#	my %works_button = ( read_works => $self->phrase( "action:read_works:title" ),
#		revoke_read_works => $self->phrase( "action:revoke:title" ),
#                _order=>[ "read_works", "revoke_read_works" ],
#                _class=>"ep_form_button_bar"
#        );
#
#	$works_div->appendChild( $repo->render_action_buttons( %works_button ) );
#	push @labels,  $self->html_phrase( "works" );
#	push @panels, $works_div;
#
#        my $public_div = $repo->make_element( "div" );
#        my $h3 = $public_div->appendChild( $repo->make_element( "h3" ) );
#	$h3->appendChild( $self->html_phrase( "public_profile" ) );
#        $public_div->appendChild( $repo->make_element( "br" ) );
#
#	$public_div->appendChild( $repo->xhtml->tabs(
#					\@labels,
#					\@panels,
#					basename => "ep_user_orcid_public_man",
#				) );
#
#
#	return $public_div;
#}

########################################################################################
# not yet enabled
########################################################################################
#sub read_and_render_orcid_data
#{
#	my( $self, $form, $plugin, $user, $orcid, $tag, $subroutine ) = @_;
#
#	my $repo = $self->{repository};
#	my $xml = $repo->xml;
#
#	my $read_granted = $plugin->user_permission_granted( $user );
#	if ( $read_granted )
#	{
#		my $data = $plugin->read_data( $user, $orcid );
#		if ( $data ) 
#		{
#			if (200 == $data->{code} )
#			{
#				my $result_xml = EPrints::XML::parse_xml_string( $data->{data} );
#				my $tag_data = ($result_xml->getElementsByTagName( $tag ))[0];
#
#
##print STDERR "$tag data [". $tag_data->toString()."]\n" if $tag_data;
#				my $rendered_data = $self->$subroutine( $tag_data );
#				$form->appendChild( $rendered_data );
#			}
#			else
#			{
#				$form->appendChild( $xml->create_text_node( "Error code: ".$data->{code} ) );
#        			$form->appendChild( $repo->make_element( "br" ) );
#				$form->appendChild( $xml->create_text_node( "Error: ".$data->{error} ) );
#        			$form->appendChild( $repo->make_element( "br" ) );
#				$form->appendChild( $xml->create_text_node( "Description: ".$data->{error_description} ) );
#        			$form->appendChild( $repo->make_element( "br" ) );
#			}
#		}
#	}
#	else
#	{
#		$form->appendChild( $self->html_phrase( "permission_not_granted" ) );
#	}
#}


########################################################################################
# not yet enabled
########################################################################################
#sub render_orcid_profile
#{
#	my( $self, $data ) = @_;
#
#	my $repo = $self->{repository};
#	my $xml = $repo->xml;
#
#        my $div = $xml->create_element( "div" );
#	my $tag_data =  [ 
#		{
#			tag => 'orcid-preferences',
#			phrase => 'orcid-preferences',
#			call => 'render_tag_details',
#		},		
#		{
#			tag => 'orcid-identifier',
#			phrase => 'orcid-identifier',
#			call => 'render_tag_details',
#		},
#		{
#			tag => 'orcid-history',
#			phrase => 'orcid-history',
#			call => 'render_tag_details',
#		},
#		{
#			tag => 'orcid-bio',
#			phrase => 'orcid-bio',
#			call => 'render_tag_details',
#		},
#		{
#			tag => 'orcid-activities',
#			phrase => 'orcid-activities',
#			call => 'render_tag_details',
#		},
#	];
#
#	foreach my $tag ( @$tag_data )
#	{
#		my $tag_contents = ($data->getElementsByTagName( $tag->{tag} ))[0];
#		$div->appendChild( $self->html_phrase( $tag->{phrase} ) );
#		my $subroutine = $tag->{call};
#		$div->appendChild( $self->$subroutine( $tag_contents ) );
#	}
#
#	return $div;
#}

########################################################################################
# not yet enabled
########################################################################################
#sub render_orcid_bio
#{
#	my( $self, $data ) = @_;
#
#	my $repo = $self->{repository};
#	my $xml = $repo->xml;
#
#        my $div = $xml->create_element( "div" );
#
#	$div->appendChild( $self->html_phrase( 'orcid-bio' ) );
#	$div->appendChild( $self->render_tag_details( $data ) );
#
#	return $div;
#}

########################################################################################
# not yet enabled
########################################################################################
#sub render_tag_details
#{
#	my( $self, $data ) = @_;
#
#	my $repo = $self->{repository};
#	my $xml = $repo->xml;
#
#        my $table = $xml->create_element( "table", class=>"ep_upload_fields ep_multi" );
#	
#	if ( $data && $data->hasChildNodes )
#	{
#		my @nodes = $data->getChildNodes();
#		foreach my $node ( @nodes )
#		{
#			next unless $node->nodeType() eq XML_ELEMENT_NODE;
#			my $label = $node->nodeName;
#			my $value = EPrints::Utils::tree_to_utf8( $node );
#
#			$table->appendChild( $self->render_table_row_with_text( $xml, $label, $value ) );
#		}
#	}
#	return $table;
#}




########################################################################################
# not yet enabled
########################################################################################
#sub render_orcid_works
#{
#	my( $self, $data, $form ) = @_;
#
##print STDERR "render_orcid_works [".$data->toString()."]\n";
#	my $repo = $self->{session};
#	my $xml = $repo->xml;
#
#        my $div = $xml->create_element( "div" );
#	return $div unless $data;
#
#       	my $table = $div->appendChild( $xml->create_element( "table", class=>"ep_upload_fields ep_multi" ) );
#	my $import_count = 0;
#	my @works = $data->getElementsByTagName( "orcid-work" );
#	foreach my $work ( @works )
#	{
#	
##		my $label = "put-code";
##		my $value = "-";
##		my $attributes = $work->attributes();
##		my $put_code_attr = $attributes->{"NodeMap"}->{'put-code'};
##		$value = $put_code_attr->value if $put_code_attr; 
##		$table->appendChild( $self->render_table_row_with_text( $xml, $label, $value, 1 ) );
#
#		my $pub_date = ($work->getElementsByTagName('publication-date'))[0];
#		my $date;
#		if ( $pub_date )
#		{
#			my $pub_year = ($pub_date->getElementsByTagName('year'))[0];
#			my $pub_month = ($pub_date->getElementsByTagName('month'))[0];
#			my $pub_day = ($pub_date->getElementsByTagName('day'))[0];
#			$date = $pub_day ? $pub_day->textContent()."/".$pub_month->textContent()."/".$pub_year->textContent() : "";
#		}
#
#		my $work_title = ($work->getElementsByTagName('work-title'))[0];
#		my $title = ($work_title->getElementsByTagName('title'))[0]->textContent();
#		my $sub_title = ($work_title->getElementsByTagName('subtitle'))[0]->textContent() if $work_title->getElementsByTagName('subtitle');
##		my $work_citation  = ($work->getElementsByTagName('work-citation'))[0];
##		my $citation  = ($work_citation->getElementsByTagName('citation'))[0]->textContent();
##		my $citation_format  = ($work_citation->getElementsByTagName('work-citation-type'))[0]->textContent();
#
#		my $ext_id_tag  = ($work->getElementsByTagName('work-external-identifiers'))[0];
#
#		my @ext_ids  = $ext_id_tag->getElementsByTagName('work-external-identifier');
#
#		my $plugin_rank = $repo->config( "orcid_import_plugin_rank" );
#		my $duplicate = 0;
#		my $id_type;
#		my $id;
#		foreach my $ext_id ( @ext_ids )
#		{
#			my $this_id_type  = ($ext_id->getElementsByTagName('work-external-identifier-type'))[0]->textContent();
#			my $this_id = ($ext_id->getElementsByTagName('work-external-identifier-id'))[0]->textContent();;
#			if ( $id_type )
#			{
#				my $current_rank = $plugin_rank->{uc($id_type)} ? $plugin_rank->{uc($id_type)} : 0;
#				my $new_rank = $plugin_rank->{uc($this_id_type)} ? $plugin_rank->{uc($this_id_type)} : 0;
#				if ( $new_rank > $current_rank )
#				{	
#					$id_type = $this_id_type;
#					$id = $this_id;
#				}
#			}
#			else
#			{
#				$id_type = $this_id_type;
#				$id = $this_id;
#			}
#print STDERR "id_type is [$id_type] this[$this_id_type]\n";
#			$duplicate++ if $self->is_duplicate ( $this_id_type, $this_id );
#			last if $duplicate;
#
#		}
#		if ( $duplicate )
#		{
#			$table->appendChild( $self->render_works_table_row_with_tick( $xml, "Title", $title ) );
#		}
#		else 
#		{		
#                       	$table->appendChild( $self->render_works_table_row_with_import( $xml, "Title", $title, $id_type, $id, $import_count++ ) );
#		}
#		$table->appendChild( $self->render_works_table_row( $xml, "Subtitle", $sub_title ) );
#		$table->appendChild( $self->render_works_table_row( $xml, "Date", $date ) );
#		$table->appendChild( $self->render_works_table_row( $xml, "IDs", EPrints::Utils::tree_to_utf8( $ext_id_tag ) ) );
##		$table->appendChild( $self->render_table_row_with_text( $xml, "Citation Format", $citation_format ) );
##		$table->appendChild( $self->render_table_row_with_import( $xml, "Citation", $citation, $citation_format, $citation, $import_count++ ) );
#	}
#
##	$div->appendChild( $self->render_tag_details( $data ) );
#	return $div;
#}

########################################################################################
# not yet enabled
########################################################################################
#sub render_works_table_row
#{
#	my( $self, $xml, $label, $value, $first ) = @_;
#	my $tr = $xml->create_element( "tr", style=>"width: 100%" );
#	my $first_class = "";
#	$first_class = "_first" if $first;
#	my $td1 = $tr->appendChild( $xml->create_element( "td", class=>"ep_orcid_works_label".$first_class ) );
#	my $td2 = $tr->appendChild( $xml->create_element( "td", class=>"ep_orcid_works_value".$first_class ) );
#	$td1->appendChild( $xml->create_text_node( $label ) );
#	$td2->appendChild( $xml->create_text_node( $value ) );
#
#	return $tr;
#}
########################################################################################
# not yet enabled
########################################################################################
#sub render_works_table_row_with_tick
#{
#	my( $self, $xml, $label, $value, $first ) = @_;
#	my $tr = $xml->create_element( "tr", style=>"width: 100%" );
#	my $first_class = "";
#	$first_class = "_first" if $first;
#	my $td1 = $tr->appendChild( $xml->create_element( "td", class=>"ep_orcid_works_label".$first_class ) );
#	my $td2 = $tr->appendChild( $xml->create_element( "td", class=>"ep_orcid_works_value".$first_class ) );
#	my $td3 = $tr->appendChild( $xml->create_element( "td", class=>"ep_orcid_works_link".$first_class, rowspan=>"4" ) );
#	$td1->appendChild( $xml->create_text_node( $label ) );
#	$td2->appendChild( $xml->create_text_node( $value ) );
#	my $tick_div = $xml->create_element( "div", class=>"ep_form_button_bar" ); 
#	my $tick = $tick_div->appendChild( $xml->create_element( "img", width=>32, height=>32, src=>"/style/images/tick.png" ) );
#	$td3->appendChild( $tick_div );
#
#	return $tr;
#}

########################################################################################
# not yet enabled
########################################################################################
#sub render_works_table_row_with_import
#{
#	my( $self, $xml, $label, $value, $import_type, $import_value, $import_count, $first ) = @_;
#
#	my $repo = $self->{repository};
#
#	my $tr = $xml->create_element( "tr", style=>"width: 100%" );
#	my $first_class = "";
#	$first_class = "_first" if $first;
#	my $td1 = $tr->appendChild( $xml->create_element( "td", class=>"ep_orcid_works_label".$first_class ) );
#	my $td2 = $tr->appendChild( $xml->create_element( "td", class=>"ep_orcid_works_value".$first_class ) );
#	my $td3 = $tr->appendChild( $xml->create_element( "td", class=>"ep_orcid_works_link".$first_class, rowspan=>"4" ) );
#	$td1->appendChild( $xml->create_text_node( $label ) );
#	$td2->appendChild( $xml->create_text_node( $value ) );
#	
#	my $plugin_map = $repo->config( "orcid_import_plugin_map" );
#	my $import_plugin = $plugin_map->{ uc($import_type) };
#
#print STDERR "using import plugin [$import_type] [$import_plugin]\n";
#	my $action_name = "import_work_".$import_count;
#	my $div = $xml->create_element( "div", class=>"ep_form_button_bar" ); 
#
#	my $button = $div->appendChild( $xml->create_element( "input", 
#		type=>"submit", 
#		name=> "_action_".$action_name, 
#		value=>$self->phrase( "action:import_work:title" ) ) );
#	if ( $import_plugin )
#	{
#		$div->appendChild( $repo->render_hidden_field ( $action_name."_format", $import_plugin ) );
#		$div->appendChild( $repo->render_hidden_field ( $action_name."_data", $import_value ) );
#	}
#	else
#	{
#		$button->setAttribute( "disabled", "disabled" ) unless $import_plugin;
#	}
#	$td3->appendChild( $div );
#	return $tr;
#}


########################################################################################
# not yet enabled
########################################################################################
#sub render_table_row
#{
#	my( $self, $xml, $label, $value, $link, $first ) = @_;
#	my $tr = $xml->create_element( "tr", style=>"width: 100%" );
#	my $first_class = "";
#	$first_class = "_first" if $first;
#	my $td1 = $tr->appendChild( $xml->create_element( "td", class=>"ep_orcid_works_label".$first_class ) );
#	my $td2 = $tr->appendChild( $xml->create_element( "td", class=>"ep_orcid_works_value".$first_class ) );
#	my $td3 = $tr->appendChild( $xml->create_element( "td", class=>"ep_orcid_works_link".$first_class ) );
#	$td1->appendChild( $label );
#	$td2->appendChild( $value );
#	$td3->appendChild( $link );
#
#	return $tr;
#}

########################################################################################
# not yet enabled
########################################################################################
#sub render_table_row_with_text
#{
#	my( $self, $xml, $label_val, $value_val, $first ) = @_;
#
#	my $label = $xml->create_text_node( $label_val );
#	my $value = $xml->create_text_node( $value_val );
#	my $link = $xml->create_text_node( "" );
#	return $self->render_table_row( $xml, $label, $value, $link, $first );
#}


########################################################################################
# not yet enabled
########################################################################################
#sub render_table_row_with_link
#{
#	my( $self, $xml, $label_val, $value_val, $link_val ) = @_;
#
#	my $label = $xml->create_text_node( $label_val );
#	my $value = $xml->create_element( "a", href=>$link_val, target=>"_blank" );
#	$value->appendChild( $xml->create_text_node( $value_val ) );
#	my $link = $xml->create_text_node( "" );
#	return $self->render_table_row( $xml, $label, $value, $link );
#}



########################################################################################
# not yet enabled
########################################################################################
#sub is_duplicate
#{
#	my ( $self, $type, $value ) = @_;
#	my $repo = $self->{repository};
#	my $ds = $repo->dataset("eprint");
#print STDERR "OrcidManager::is_duplicate [$type] [$value] \n";
#
#	my $searchexp = $ds->prepare_search( satisfy_all => 0 );
#	foreach my $fn ( qw/ item_doi_field item_pmid_field / )
#	{
#		my $id_field = $repo->config( $fn );
#		$searchexp->add_field(
#			fields => [ $ds->field( $id_field ) ],
#			value  => $value,
#			match  => "EQ",
#		);
#	}
#
#	my $list = $searchexp->perform_search;
#	
#print STDERR "OrcidManager::is_duplicate [$type] [$value] returning [".$list->count."]\n";
#	return $list->count;
#}

########################################################################################
# not yet enabled
########################################################################################
#sub import_work
#{
#	my( $self, $plugin_id, $data, ) = @_;
#
#	my $repo = $self->{repository};
#	my $plugin = $repo->plugin( "Import::".$plugin_id );
#
#	return unless $plugin;
#	my $data_file = $data;
#
#	my $data_fh = new FileHandle("echo \'$data_file\' |") or die;
#
#	$plugin->set_handler( $self );
#	my %opts = ( fh=>$data_fh, dataset=>$repo->dataset("inbox") );
#	my $list = $plugin->input_text_fh( %opts );
#	return $list;
#}

########################################################################################
# not yet enabled
########################################################################################
#sub message
#{
#	my( $self, $type, $msg ) = @_;
#
#	unless( $self->{quiet} )
#	{
#		$self->{processor}->add_message( $type, $msg );
#	}
#}

########################################################################################
# not yet enabled
########################################################################################
#sub epdata_to_dataobj
#{
#print STDERR "OrcidManager::epdata_to_dataobj called !!!!!!!!!!!!!!!!!!!\n";
#	my( $self, $epdata, %opts ) = @_;
#	$self->{parsed}++;
#
#	return if $self->{dryrun};
#
#	my $dataset = $opts{dataset};
#	if( $dataset->base_id eq "eprint" )
#	{
#		my $user = $self->{repository}->current_user;
#		$epdata->{userid} = $user->get_id;
#		$epdata->{eprint_status} = "inbox";
#	}	
#
#	$self->{wrote}++;
#
#	return $dataset->create_dataobj( $epdata );
#}

########################################################################################
# not yet enabled
########################################################################################
#sub render_export_data
#{
#	my( $self, $orcid_prefix, $user, $orcid ) = @_;
#
#	my $repo = $self->{repository};
#	my $xml = $repo->xml;
#
#       my $works_div = $repo->make_element( "div" );
#        my $h3_4 = $works_div->appendChild( $repo->make_element( "h3" ) );
#	$h3_4->appendChild( $self->html_phrase( "works" ) );
#
#	my $users_eprints = $user->owned_eprints_list();
#	unless ( $users_eprints && $users_eprints->count )
#	{
#		$works_div->appendChild( $xml->create_text_node( "No items found" ) );
#		return $works_div;
#	}
#
#	my $orcid_work_ids = {};
#	my $read_works_plugin = $repo->plugin( "Orcid::ReadResearch" ); 
#	if ( $read_works_plugin->user_permission_granted( $user ) )
#	{
#		my $data = $read_works_plugin->read_data( $user, $orcid );
#		if ( $data ) 
#		{
#			if (200 == $data->{code} )
#			{
#				my $result_xml = EPrints::XML::parse_xml_string( $data->{data} );
#				my $tag_data = ($result_xml->getElementsByTagName( "orcid-works" ))[0] if $result_xml;
#				my @works = $tag_data->getElementsByTagName( "orcid-work" ) if $tag_data;
#				foreach my $work ( @works )
#				{
#	
#					#my $work_title = ($work->getElementsByTagName('work-title'))[0];
#					#my $title = ($work_title->getElementsByTagName('title'))[0]->textContent();
#					my $ext_id_tag  = ($work->getElementsByTagName('work-external-identifiers'))[0];
#					my @ext_ids  = $ext_id_tag->getElementsByTagName('work-external-identifier');
#					foreach my $ext_id ( @ext_ids )
#					{
#						my $this_id = ($ext_id->getElementsByTagName('work-external-identifier-id'))[0]->textContent();;
#						$orcid_work_ids->{$this_id}++;
#					}
#				}
#			}
#			else
#			{
#				$works_div->appendChild( $xml->create_text_node( "Error code: ".$data->{code} ) );
#        			$works_div->appendChild( $repo->make_element( "br" ) );
#				$works_div->appendChild( $xml->create_text_node( "Error: ".$data->{error} ) );
#        			$works_div->appendChild( $repo->make_element( "br" ) );
#				$works_div->appendChild( $xml->create_text_node( "Description: ".$data->{error_description} ) );
#        			$works_div->appendChild( $repo->make_element( "br" ) );
#			}
#
#		}
#	}
#	else
#	{
#		$works_div->appendChild( $self->html_phrase( "permission_not_granted" ) );
#	}
#
#        my $table = $works_div->appendChild( $xml->create_element( "table", class=>"ep_upload_fields ep_multi" ) );
#	$users_eprints->map( sub {
#		my ( $repo, $dataset, $eprint ) = @_;
#		if ( $eprint->value( "eprint_status" ) eq "archive" )
#		{
#			my $uploaded = 0;
#			foreach my $id_field_name ( qw\ item_doi_field item_pmid_field \ )
#			{
#				my $id_field = $repo->config( $id_field_name );
#				if ( $id_field )
#				{
#					my $id = $eprint->get_value( $id_field );
#					$uploaded++ if $id && $orcid_work_ids->{$id};
#print STDERR "check id field[$id_field] value[$id] uploaded[$uploaded]\n";
#				}
#			}	
#			my $ep_title = $eprint->value( "title" ); #->[0]->{text};
#			$ep_title = $ep_title->[0]->{text} if ( ref $ep_title eq "ARRAY" );
#			if ( $uploaded )
#			{
#				$table->appendChild( $self->render_table_row_with_tick( $xml, "Title", $ep_title, 1, $user->get_id, $eprint->get_id ) );
#			}
#			else
#			{
#				$table->appendChild( $self->render_table_row_with_export( $xml, "Title", $ep_title, 1, $user, $eprint->get_id ) );
#			}
#		}
#	});
#
#	my %add_button = ( 
#		create_works => $self->phrase( "action:create_works:title" ),
#		revoke_create_works => $self->phrase( "action:revoke:title" ),
#                _order=>[ "create_works", "revoke_create_works" ],
#                _class=>"ep_form_button_bar"
#        );
#
#	$works_div->appendChild( $repo->render_action_buttons( %add_button ) );
#	
#	
#print STDERR "Export got ids [".Data::Dumper::Dumper($orcid_work_ids)."]\n";
#	return $works_div;
#}

########################################################################################
# not yet enabled
########################################################################################
#sub render_table_row_with_export
#{
#	my( $self, $xml, $label_val, $value_val, $first, $user, $item_id ) = @_;
#
#	my $repo = $self->{repository};
#
#	my $label = $xml->create_text_node( $label_val );
#	my $value = $xml->create_text_node( $value_val );
#
#	my $action_name = "export_work_".$item_id;
#	my $button = $xml->create_element( "input", 
#		type => "image", 
#		src => "/style/images/export.png",
#		width => 32, 
#		height => 32,
#		name => "_action_".$action_name, 
#		title => $self->phrase( "action:export_work:title" ), 
#		alt => $self->phrase( "action:export_work:title" ), 
#	);
#	my $works_plugin = $repo->plugin( "Orcid::AddWorks" ); 
#	my $add_granted = $works_plugin->user_permission_granted( $user );
#	if ( !$add_granted )
#	{
#		$button->setAttribute( "disabled", "disabled" );
#		$button->setAttribute( "style", "opacity: 0.4; filter: alpha(opacity=40);" );
#	}
#	
#	#my $auth_url = $repo->config( "orcid_authorise_url" ); 
#	#$auth_url .= "u".$user_id."i".$item_id."a0";
##	my $auth_url = $repo->call( "get_orcid_authorise_url", $repo, $user_id, $item_id, "update_works" ); 
#
##	my $link = $xml->create_element( "a", href=>$auth_url );
##	my $tick = $link->appendChild( $xml->create_element( "img", width=>32, height=>32, src=>"/style/images/export.png" ) );
#	return $self->render_table_row( $xml, $label, $value, $button, $first );
#}

########################################################################################
# not yet enabled
########################################################################################
#sub render_table_row_with_tick
#{
#	my( $self, $xml, $label_val, $value_val, $first, $user_id, $item_id ) = @_;
#
#	my $repo = $self->{session};
#
#	my $label = $xml->create_text_node( $label_val );
#	my $value = $xml->create_text_node( $value_val );
#
#	my $tick = $xml->create_element( "img", width=>32, height=>32, src=>"/style/images/tick.png" );
#	return $self->render_table_row( $xml, $label, $value, $tick, $first );
#}


########################################################################################
# not yet enabled
########################################################################################
#sub export_work
#{
#	my( $self, $id ) = @_;
#print STDERR "############### export_work called for id [$id] ##################\n";	
#
#	my $repo = $self->{repository};
#	my $xml = $repo->xml;
#	my $user = $repo->current_user;
#	return unless $user;
#	my $orcid = $user->get_value( "orcid" );
#	return unless $orcid;
#
#	my $plugin = $repo->plugin( "Orcid::AddWorks" ); 
#	my $add_granted = $plugin->user_permission_granted( $user );
#	if ( $add_granted )
#	{
#print STDERR "add work token:[$add_granted]\n";
#		my $work_xml = $repo->call( "form_orcid_work_xml", $repo, $id ); 
#
## curl -H 'Content-Type: application/orcid+xml' -H 'Authorization: Bearer aa2c8730-07af-4ac6-bfec-fb22c0987348' -d '@/Documents/new_work.xml' -X POST 'https://api.sandbox.orcid.org/v1.2/0000-0002-2389-8429/orcid-works'
#
#		my $add_work_url = $repo->config( "orcid_member_api" );
#		$add_work_url .= "v1.2/";
#		$add_work_url .= $orcid;
#		$add_work_url .= "/orcid-works";
#
#		my $req = HTTP::Request->new(POST => $add_work_url, );
#		$req->header('content-type' => 'application/orcid+xml');
#		$req->header('Authorization' => 'Bearer '.$add_granted);
#		 
#		# add POST data to HTTP request body
#		$req->content(Encode::encode("utf8", $work_xml));
#
#		my $ua = LWP::UserAgent->new;
#		my $response = $ua->request($req);
#
#print STDERR "\n\n\n\n####### got response [".Data::Dumper::Dumper($response)."]\n\n";
#
#		if ( $response->code > 299 )
#		{
#
#			$self->{processor}->add_message( "message",
#				$self->html_phrase( "orcid_export_error", code=> $xml->create_text_node($response->code) ) );
#			return 0;
#		}
#		else 
#		{
#			return 1;
#		}
#	}
#	else
#	{
#		$self->{processor}->add_message( "message",
#				$self->html_phrase( "permission_not_granted", ) );
#	}
#
#	return 0;
#}



1;


