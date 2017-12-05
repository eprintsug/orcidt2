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
        $self->{actions} = [qw/ search read_record update_activities update_profile revoke_read revoke_update_activities 
				revoke_update_profile remove_id export_data /];


	return $self;
}


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

=item allow_search, action_search 

=back

Screen plugin action to search for items to export

=end InternalDoc

=cut

sub allow_search
{
        return 1;
}


sub action_search
{
        my( $self ) = @_;
        my $repo = $self->{repository};

	$self->{processor}->{reqd_orcid_tab} = 1;
	my $orcid_to_search = $repo->param("_orcid_um_search_orcid");
	return unless $orcid_to_search;

	$self->{processor}->{orcid_to_search} = $orcid_to_search;
	unless ( $orcid_to_search )	
	{
		$self->{processor}->add_message( "warning",
				$self->html_phrase( "export_error:no_id" ) );
		return;
	}
	unless ( $repo->call( 'valid_orcid_id', $orcid_to_search ) ) 
	{
		$self->{processor}->add_message( "warning",  
				$self->html_phrase( "incorrect_orcid_format", id=>$repo->make_text( $orcid_to_search ) ) );
		return;
	}

}

=begin InternalDoc

=over

=item allow_export_data, action_export_data 

=back

Screen plugin action to export items to the ORCID profile
If a put_code is returned this is saved on the users profile
so that the next export is an update rather than a create

=end InternalDoc

=cut

sub allow_export_data
{
        return 1;
}


sub action_export_data
{
        my( $self ) = @_;
        my $repo = $self->{repository};
	my $orcid_to_update = $repo->param("_orcid_um_export_to_orcid");
	my $token = $repo->param("_orcid_um_act_update_token");
	my $user_id = $repo->param("_orcid_um_act_update_user_id");
	$self->{processor}->{orcid_to_search} = $orcid_to_update;
	my @ids_to_export = $repo->param("_orcid_um_export_code");

	$self->{processor}->{reqd_orcid_tab} = 1;
	unless ( $orcid_to_update )	
	{
		$self->{processor}->add_message( "warning",
				$self->html_phrase( "export_error:no_id" ) );
		return;
	}
	unless ( $repo->call( 'valid_orcid_id', $orcid_to_update ) ) 
	{
		$self->{processor}->add_message( "warning",  
				$self->html_phrase( "incorrect_orcid_format", id=>$repo->make_text( $orcid_to_update ) ) );
		return;
	}
	foreach my $id_to_export ( @ids_to_export )
	{
		# extract the id and put_code from the id_to_export
		my $id;
		my $put_code;
		if ( $id_to_export =~ /(\d+)_(\d+)/ )
		{
			$id = $1;
			$put_code = $2;
		}
		else
		{
			$id = $id_to_export;
		}
		my ( $success, $new_put_code ) = $self->export_work( $id, $orcid_to_update, $token, $put_code );
		unless ( $success )
		{
			$self->{processor}->add_message( "warning",
                                $self->html_phrase( "export_failed", id=>$repo->make_text( $orcid_to_update ), item=>$repo->make_text( $id ) ) );
			next;
		}
		if ( $new_put_code )
		{
			my $plugin = $repo->plugin( "Orcid" );
			my $ds = $repo->dataset( "user" );
			my $user = $ds->dataobj( $user_id );
			$plugin->save_put_code( $user, "work", $new_put_code, $id ) if $plugin && $user;
		}
		$self->{processor}->add_message( "message",
                                $self->html_phrase( "exported", id=>$repo->make_text( $orcid_to_update ), item=>$repo->make_text( $id ) ) );
	}

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

	my $xml = $repo->xml;
        my $f = $repo->render_form( "GET" );
        $f->appendChild( $repo->render_hidden_field ( "screen", "User::Orcid::OrcidManager" ) );

	my $ds = $repo->dataset("user"); 

	my $entered_orcid = $user->get_value( "orcid" );

       	my $orcid_prefix = $self->{prefix}."_orcid_um";
	$f->appendChild( $self->render_id_selection( $orcid_prefix, $user, $entered_orcid, ) );
	
	if ( $entered_orcid )
	{
		my @labels;
		my @panels;

		my $settings_div = $repo->make_element( "div", class => "orcid_details" );
		my $details_div = $settings_div->appendChild( $repo->make_element( "div", class => "orcid_details" ) );
		$details_div->appendChild( $self->render_selected_details( $orcid_prefix, $user ) ) if defined $user;		

                my $acc_link_div = $settings_div->appendChild( $repo->make_element( "div", class => "orcid_details" ) );
                $acc_link_div->appendChild( $self->html_phrase( "account_settings" ) );

		push @labels,  $self->html_phrase( "user_settings" );
		push @panels, $settings_div;

		my $export_div = $repo->make_element( "div", class => "orcid_actions" );
		$export_div->appendChild( $self->render_export_data( $orcid_prefix, $user ) );		
		push @labels,  $self->html_phrase( "export" );
		push @panels, $export_div;

		my $current = 0;
		$current = $self->{processor}->{reqd_orcid_tab} if $self->{processor}->{reqd_orcid_tab};
		$f->appendChild( $repo->xhtml->tabs(
					\@labels,
					\@panels,
					basename => "ep_user_orcid_man",
					current => $current,
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

                $input_div->appendChild( $repo->make_element(
                                        "input",
                                        type=>"image",
                                        src=> "/style/images/delete.png",
                                        alt=>"Remove",
                                        title=>"Remove",
					name => "_action_remove_id", 
                                        class => "epjs_ajax",
                                   	id => "delete-orcid-button",
                                        value=>"1" ));

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
	

=begin InternalDoc

=over

=item render_export_data ( $self, $orcid_prefix, $current_user, $orcid )

=back

This routine renders the export tab. The tab displays the results of searching for
items in the repository contributed to by the specified ORCID iD. The items found are
matched to works downloaded from the profile of the specified ORCID iD. If a put_code
for a work matches a putcode for an item for the user with the OCRID iD then the export
will be an update rather than a create.
a checkbox is provided for each item and an export button is provided to initiate the 
export to the ORCID profile.

If the user is an admin user then an input is provided to allow the user to specifiy 
an ORCID iD to use for the search and export process. For non admin users the ORCID iD
used is the one associated with the users account.

=end InternalDoc

=cut

sub render_export_data
{
	my( $self, $orcid_prefix, $current_user ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;

	my $orcid = $current_user->get_value( "orcid" );

       	my $works_div = $repo->make_element( "div" );
	my $div = $works_div->appendChild( $xml->create_element( "div", class=>"orcid_connect" ) );
	my $text_div = $div->appendChild( $xml->create_element( "div", class=>"orcid_connect_text" ) );
	my $input_div = $div->appendChild( $xml->create_element( "div", class=>"orcid_connect_input" ) );
	my $btn_div = $div->appendChild( $xml->create_element( "div", class=>"orcid_connect_btn" ) );

        # check that the user has granted permission to read their profile data before contnuing.
        my $rl_granted = (defined $current_user->get_value( 'orcid_rl_token' ));
        my $au_granted = (defined $current_user->get_value( 'orcid_act_u_token' ));
        unless ( $rl_granted && $au_granted )
        {
                $text_div->appendChild( $self->html_phrase( "export_not_allowed" ) );
                return $works_div;
        }


	# check permissions before allowing override
	if ( $current_user->allow( 'orcid/admin' ) )
	{  
		# override the user ORCID iD and provide a search button
		my $orcid_to_search = $self->{processor}->{orcid_to_search};
		$orcid = $orcid_to_search if $orcid_to_search;

                $text_div->appendChild( $self->html_phrase( "export_help_admin" ) );
		$input_div->appendChild( $xml->create_element( "input",
			value => $orcid,
			type => 'text',
			size => 20,
			id => $orcid_prefix.'_search_orcid',
			name => $orcid_prefix.'_search_orcid',
		) );

		my $btn = { search => $self->html_phrase( "search_btn:title" ),
			    _class=>"ep_form_button_bar"  };
		$btn_div->appendChild( $repo->render_action_buttons( %$btn ) );
	}
	else
	{
                $text_div->appendChild( $self->html_phrase( "export_help" ) );
		my $btn = { search => $self->html_phrase( "search_btn:title" ),
			    _class=>"ep_form_button_bar"  };
		$btn_div->appendChild( $repo->render_action_buttons( %$btn ) );
	}
	my $ds = $repo->dataset("archive"); 
	my $current_items = $ds->search(
		satisfy_all => 0,
		filters =>  [
			{ meta_fields => [ 
				'contributors_orcid', 
				'creators_orcid' , 
				'editors_orcid'  
				], 
			  value => $orcid, match=>'EQ', merge => 'ANY' },
		],
	);

	#my $current_items = $current_user->owned_eprints_list();

        my $h3_4 = $works_div->appendChild( $repo->make_element( "h3" ) );
	$h3_4->appendChild( $self->html_phrase( "works" ) );

	unless ( $current_items && $current_items->count )
	{
		$works_div->appendChild( $self->html_phrase( "export_error:no_items" ) );
		return $works_div;
	}

	my $current_works = $repo->call( "get_works_for_orcid", $repo, $orcid );
	unless ( $current_works )
	{
		$self->{processor}->add_message( "warning", 
			 $self->html_phrase( "orcid_api_error_undef",
				id =>$repo->make_text($orcid) ) );
		return $works_div;
	}
	unless ( $current_works->{code} )
	{
		$self->{processor}->add_message( "warning", 
			 $self->html_phrase( "orcid_api_error_undef",
				id =>$repo->make_text($orcid) ) );
		return $works_div;
	}
	if ( 200 != $current_works->{code} )
	{
		eval {
			my $code = $current_works->{code};
			my $json_vars = JSON::decode_json($current_works->{data});
			my $error_name = $json_vars->{'user-message'};
			my $error_desc = $json_vars->{'more-info'};
			$self->{processor}->add_message( "warning", 
				 $self->html_phrase( "orcid_api_error", 
					id =>$repo->make_text($orcid),
					code =>$repo->make_text($code),
					err =>$repo->make_text($error_name),
					desc =>$repo->make_text($error_desc),
 			) );
		};
		$self->{processor}->add_message( "warning", $self->html_phrase( "unknown_orcid_api_error",) ) if $@;
		return $works_div;
	}
	
	my $user_ds = $repo->dataset( "user" );
	my $user = $user_ds->dataobj( $current_works->{user} );
	unless ( $user && $orcid eq $user->get_value( "orcid" ) )
	{
		$works_div->appendChild( $self->html_phrase( "export_error:no_user" ) );
		return $works_div;
	}
	unless( $current_user->allow( 'orcid/admin' ) )
	{
		if ( $current_works->{user} != $current_user->get_id )
		{
			$works_div->appendChild( $self->html_phrase( "export_error:wrong_user" ) );
			return $works_div;
		}
	}

	# check This user has given permission
	my $act_u_token = $user->get_value( 'orcid_act_u_token' );
	unless ( $act_u_token )
	{
		$works_div->appendChild( $self->html_phrase( "export_error:no_user_permission" ) );
		return $works_div;
	}

	my $put_codes = $user->get_value( 'put_codes' ); 
	my $relevant_codes = [];
	foreach my $code ( @$put_codes )
	{
		if ( $code->{'code_type'} eq 'work' )
		{
			push @$relevant_codes, $code;
		}
	}

	if( defined $current_items && $current_works )
	{
		eval {
			my $works_data = JSON::decode_json( $current_works->{data} );
			$works_div->appendChild( $self->render_results( 
					$orcid_prefix, 
					$orcid, 
					$user->get_id(),
					$act_u_token, 
					$current_items, 
					$works_data, 
					$relevant_codes ) );
		};
		$self->{processor}->add_message( "warning", $self->html_phrase( "unknown_orcid_api_error",) ) if $@;
	}

	return $works_div;
}

=begin InternalDoc

=over

=item render_results

=back

This method displays the list of items that could potentially be exported to the ORCID profile for the supplied ORCID iD. 
A checkbox and export button are provided to allow the user to export selected works

=end InternalDoc

=cut

sub render_results
{
	my( $self, $orcid_prefix, $orcid, $user_id, $token, $items, $works, $put_codes ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;
	my $xhtml = $repo->xhtml;

	my $offset = $self->{processor}->{offset};

	my $form = $self->render_form;
	$form->setAttribute( class => "import_single" );
	$form->appendChild( $xhtml->hidden_field( data => $self->{processor}->{data} ) );
	$form->appendChild( $xhtml->hidden_field( results_offset => $offset ) );
	
	my $total = $items->count;
	$total = 1000 if $total > 1000;

	my $ds = $repo->dataset( "archive" );
	my $i = 0;
	my $list = EPrints::Plugin::Screen::Import::OrcidWork::List->new(
		session => $repo,
		dataset => $ds,
		ids => [0 .. ($total - 1)],
		items => {
				map { ($offset + $i++) => $_ } @{$items->ids}
			}
		);

	$form->appendChild( EPrints::Paginate->paginate_list(
		$repo, "results", $list,
		container => $xml->create_element( "table", class => "table" ),
		params => {
			$self->hidden_bits,
			data => $self->{processor}->{data},
			_action_test_data => 1,
		},
		render_result => sub {
			my( undef, $item_id, undef, $n ) = @_;
			my $item = $ds->dataobj( $item_id );
			return unless $item;

			my $export = $self->find_exports( $item, $works, $put_codes  );

			my $tr = $xml->create_element( "tr" );
			my $num_td = $tr->appendChild( $xml->create_element( "td" ) );
			my $item_td = $tr->appendChild( $xml->create_element( "td" ) );
			$num_td->appendChild( $xml->create_text_node( $n ) );
			$item_td->appendChild( $self->html_phrase( "results_title" ) );
			$item_td->appendChild( $xml->create_text_node( $item->get_value('title') ) );
			$item_td->appendChild( $xml->create_element( "br" ) );
			$item_td->appendChild( $self->html_phrase( "results_type" ) );
			my $item_type = $item->get_value( 'type' ); 
			$item_td->appendChild( $repo->html_phrase("eprint_typename_".$item_type ) );
			$item_td->appendChild( $xml->create_element( "br" ) );
			$item_td->appendChild( $self->html_phrase( "results_ids" ) );
			my $doi = $item->get_value( "doi" );
			my $pmid = $item->get_value( "pubmed_id" );
			if ( $doi )
			{
				$item_td->appendChild( $xml->create_text_node( $doi ) );
			}
			else
			{
				$item_td->appendChild( $self->html_phrase( "results_no_id" ) );
			}
			$item_td->appendChild( $xml->create_text_node( " / " ) );
			if ( $pmid )
			{
				$item_td->appendChild( $xml->create_text_node( $pmid ) );
			}
			else
			{
				$item_td->appendChild( $self->html_phrase( "results_no_id" ) );
			}

			if ( $export )
			{
				$item_td->appendChild( $xml->create_element( "br" ) );
				$item_td->appendChild( $self->html_phrase( "exists_on_profile" ) );
				$item_td->appendChild( $xml->create_element( "br" ) );
				$item_td->appendChild( $self->html_phrase( "export_source" ) );
				if ( $export->{source} )
				{
					$item_td->appendChild( $xml->create_text_node( $export->{source} ) );
				}
				else
				{
					$item_td->appendChild( $self->html_phrase( "export_no_source" ) );
				}
				if ( $export->{title} )
				{
					$item_td->appendChild( $xml->create_element( "br" ) );
					$item_td->appendChild( $self->html_phrase( "export_title" ) );
					$item_td->appendChild( $xml->create_text_node( $export->{title} ) );
				}
				if ( $export->{doi} )
				{
					$item_td->appendChild( $xml->create_element( "br" ) );
					$item_td->appendChild( $self->html_phrase( "export_doi" ) );
					$item_td->appendChild( $xml->create_text_node( $export->{doi} ) );
				}
	
				if ( $export->{pmid} )
				{
					$item_td->appendChild( $xml->create_element( "br" ) );
					$item_td->appendChild( $self->html_phrase( "export_pmid" ) );
					$item_td->appendChild( $xml->create_text_node( $export->{pmid} ) );
				}
	
			}
	
			my $cb_td = $tr->appendChild( $xml->create_element( "td" ) );
			my $cb_value = $item->get_id();
			if ( $export && $export->{put_code} )
			{
				$cb_value .= "_".$export->{put_code};
			}
			my $cb = $cb_td->appendChild( $xml->create_element(
				"input",
				name => $orcid_prefix.'_export_code',
				value => $cb_value,
				type => "checkbox",
			) );
			if ( $export && $export->{put_code} )
			{
				$cb_td->appendChild( $self->html_phrase( "export_update" ) );
			}

			return $tr;
		},
	) );

        $form->appendChild( $repo->render_hidden_field ( $orcid_prefix."_export_to_orcid", $orcid ) );
        $form->appendChild( $repo->render_hidden_field ( $orcid_prefix."_act_update_token", $token ) );
        $form->appendChild( $repo->render_hidden_field ( $orcid_prefix."_act_update_user_id", $user_id ) );
	$form->appendChild( $repo->render_action_buttons( export_data => $self->phrase( "action_export_data" ), ) );
	
	return $form;
}

=begin InternalDoc

=over

=item find_exports

=back

This method looks up the put_code, doi, pmid or title of the item in the works data obtained from 
the ORCID Registry to identify if this user has already exported it.

=end InternalDoc

=cut

sub find_exports
{
	my( $self, $item, $works, $put_codes ) = @_;

	my $export = {};
	my $match_found = 0;
	my $put_code;
	foreach my $code ( @$put_codes )
	{
		if ( $code->{item} && $code->{item} eq $item->get_id() )
		{
			$put_code = $code->{code};
		}
	}
	my $item_doi = $item->get_value( "doi" );
	my $item_pmid = $item->get_value( "pubmed_id" );
	my $item_title = $item->get_value( "title" );

	my $groups = $works->{group};
	foreach my $group ( @$groups )
	{
		my $summary = $group->{'work-summary'};
                foreach my $ws ( @$summary )
                {
			my $doi;
			my $pmid;
			if ( $ws->{'external-ids'} && $ws->{'external-ids'}->{'external-id'} )
			{
				foreach my $ext_id ( @{$ws->{'external-ids'}->{'external-id'}} )
				{
					my $id_type = $ext_id->{'external-id-type'};
					my $id_val = $ext_id->{'external-id-value'};
					$doi = $id_val if $id_type eq 'doi';
					$pmid = $id_val if $id_type eq 'pmid';
				}
			}
				
			my $code = $ws->{'put-code'};;
			my $source = $ws->{'source'}->{'source-name'}->{value}
                                             if $ws->{'source'} && 
						$ws->{'source'}->{'source-name'} && 
						$ws->{'source'}->{'source-name'}->{value};
			my $title = $ws->{title}->{title}->{value}
                                             if $ws->{title} && 
						$ws->{title}->{title} && 
						$ws->{title}->{title}->{value};
			if ( $code && $put_code && $code eq $put_code )
			{
				$export->{put_code} = $code;
				$export->{source} = $source if $source;
				$export->{title} = $title if $title;
				$export->{doi} = $doi if $doi;
				$export->{pmid} = $pmid if $pmid;
				$match_found++;
			}  
			elsif ( $doi && $item_doi && $doi eq $item_doi )
			{
				$export->{source} = $source if $source;
				$export->{title} = $title if $title;
				$export->{doi} = $doi if $doi;
				$export->{pmid} = $pmid if $pmid;
				$match_found++;
			}
			elsif ( $pmid && $item_pmid && $pmid eq $item_pmid )
			{
				$export->{source} = $source if $source;
				$export->{title} = $title if $title;
				$export->{doi} = $doi if $doi;
				$export->{pmid} = $pmid if $pmid;
				$match_found++;
			}
			elsif ( $title && $item_title && $title eq $item_title )
			{
				$export->{source} = $source if $source;
				$export->{title} = $title if $title;
				$export->{doi} = $doi if $doi;
				$export->{pmid} = $pmid if $pmid;
				$match_found++;
			}
		}
	}

	return $export if $match_found;
	return undef;
}


=begin InternalDoc

=over

=item export_work

=back

This method forms and sends the xml for exporting an item to the ORCID 
Registry. The export may be a create or update depending upon the 
existence of a put code. The item is exported to the profile for the 
supplied ORCID iD  

=end InternalDoc

=cut

sub export_work
{
	my( $self, $item_id, $orcid_id, $token, $put_code ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;
	return unless $orcid_id;

	my $work_xml = $repo->call( "form_orcid_work_xml", $repo, $item_id, $put_code ); 
	unless ( $work_xml )
	{
		$self->{processor}->add_message( "warning", 
			$self->html_phrase( "export_no_work_xml", item=>$repo->make_text( $item_id )  ) );
		return;
	}

	my $url =  $repo->config( "orcid_member_api" ) . 'v' .$repo->config( "orcid_version" ).'/'.$orcid_id.'/work'; 

	my $req;
        if ( $put_code )
        {
                $url .= "/".$put_code;
                $req = HTTP::Request->new(PUT => $url, );
        }
        else
        {
                $req = HTTP::Request->new(POST => $url, );
        }

	$req->header('content-type' => 'application/orcid+xml');
	$req->header('Authorization' => 'Bearer '.$token);
		 
	# add POST data to HTTP request body
	$req->content(Encode::encode("utf8", $work_xml));

	my $ua = LWP::UserAgent->new;
	my $response = $ua->request($req);

print STDERR "\n\n\n\n####### got response [".Data::Dumper::Dumper($response)."]\n\n";

	if ( $response->code > 299 )
	{
		$self->{processor}->add_message( "warning",
			$self->html_phrase( "orcid_export_error", code=> $xml->create_text_node($response->code) ) );
		return 0;
	}
	# a new work was created so get the put_code and return it to the caller.
	my $put_code_type = "work";
	if ( $response->code == 201 && 
	     $response->message() eq 'Created' && 
	     $response->header("location") =~ /\/$orcid_id\/$put_code_type\/(\d+)$/ )
	{
		my $this_code = $1;
		return ( 1, $this_code ) if $this_code > 1;
	}
	
	return 1;
}



1;


