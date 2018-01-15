=head1 NAME

EPrints::Plugin::Screen::EPrint::ExportToOrcid

=cut

package EPrints::Plugin::Screen::EPrint::ExportToOrcid;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{icon} = "action_orcid_export.png";

	$self->{appears} = [
		{ place => "eprint_actions", position => 110, },
		{ place => "eprint_editor_actions", position => 510, },
#		{ place => "eprint_actions_bar_archive", position => 1010, },
#		{ place => "eprint_item_actions", position => 310, },
#               { place => "user_view_actions", position => 1610, },
	];

	$self->{actions} = [qw/ orcid_export /];

	return $self;
}

sub properties_from
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	if ( $repo->param( "eprintid" ) )
	{
		$self->{processor}->{eprintid} = $repo->param( "eprintid" );
		my $ep_ds = $repo->dataset( "eprint" );
		$self->{processor}->{eprint} = $ep_ds->dataobj( $self->{processor}->{eprintid} );
		$self->{processor}->{dataset} = $self->{processor}->{eprint}->get_dataset;
	}

	$self->SUPER::properties_from;
}

sub allow_orcid_export
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $current_user = $repo->current_user;
	return 0 unless $current_user;
	my $current_item = $self->{processor}->{eprint};
	return 0 unless $current_item;
	return 1;
}

sub action_orcid_export
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;
	my $user_id = $repo->param( "_export_user_id" );
	my $orcid_id = $repo->param( "_export_orcid_id" );
	my $token = $repo->param( "_export_token" );
	my $put_code = $repo->param( "_export_put_code" );
	my $item_id = $repo->param( "eprintid" );
	my $orcid_manager_plugin = $repo->plugin( "Screen::User::Orcid::OrcidManager" );
	if ( $item_id && $orcid_id && $user_id && $orcid_manager_plugin )
	{
		my ( $success, $new_put_code ) = $repo->call( "export_work", $repo, $self->{processor}, $item_id, $orcid_id, $token, $put_code );
		unless ( $success )
		{
			$self->{processor}->add_message( "warning",
                                $repo->html_phrase( "Plugin/Screen/User/Orcid/OrcidManager:export_failed", 
					id=>$repo->make_text( $orcid_id ), item=>$repo->make_text( $item_id ) ) );
			next;
		}
		if ( $new_put_code )
		{
			my $plugin = $repo->plugin( "Orcid" );
			my $ds = $repo->dataset( "user" );
			my $user = $ds->dataobj( $user_id );
			$plugin->save_put_code( $user, "work", $new_put_code, $item_id ) if $plugin && $user;
		}
		$self->{processor}->add_message( "message",
                                $repo->html_phrase( "Plugin/Screen/User/Orcid/OrcidManager:exported", 
					id=>$repo->make_text( $orcid_id ), item=>$repo->make_text( $item_id ) ) );
	}
	else
	{
		$self->{processor}->add_message( "warning", $self->html_phrase( "not_able_to_export" ) );
	}

        my $post_import_screen = "EPrint::View";
        my $processor = $self->{processor};
        $processor->{dataobj} = $processor->{eprint};
        $processor->{dataobj_id} = $processor->{eprintid};
        $processor->{screenid} = $post_import_screen;

	return 1;
}


sub can_be_viewed
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $current_user = $repo->current_user;
	my $current_item = $self->{processor}->{eprint};
	return 0 unless $current_user;
	if ( $current_item )
	{
		return 0 unless $current_item->get_value( "eprint_status" ) eq "archive";
		my $item_owner = $current_item->get_value( "userid" ); 
		if ( $current_user->get_id != $item_owner )
		{
			return 0 unless $current_user->allow( 'orcid/admin' );
		}
	}

	return 1;
}

sub render
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;
	my $page = $xml->create_document_fragment;
	my $form = $page->appendChild( $self->render_form );

	my $current_user = $repo->current_user;
	my $current_item = $self->{processor}->{eprint};
	return $page unless $current_item;
	my $item_owner = $current_item->get_value( "userid" ); 
	my $user_for_export = $current_user;

	if ( $current_user != $item_owner && $current_user->allow( 'orcid/admin' ) )
        {
		my $user_ds = $repo->dataset( "user" );
		$user_for_export = $user_ds->dataobj( $item_owner );
        }
	else
	{
		$form->appendChild( $self->html_phrase( "user_not_staff") );
		return $page;
	}

        my $rl_granted = (defined $user_for_export->get_value( 'orcid_rl_token' ));
        my $au_granted = (defined $user_for_export->get_value( 'orcid_act_u_token' ));
	unless ( $rl_granted && $au_granted )
	{
		$form->appendChild( $self->html_phrase( "user_has_not_given_permission") );
                return $page;
	}
        my $au_token = $user_for_export->get_value( 'orcid_act_u_token' );

	my $orcid = $user_for_export->get_value( "orcid" );
	my $current_works = $repo->call( "get_works_for_orcid", $repo, $orcid );

	unless ( $current_works )
	{
		$form->appendChild( $repo->html_phrase( "Plugin/Screen/User/Orcid/OrcidManager:orcid_api_error_undef", 
			id =>$repo->make_text($orcid) ) );
		return $page;
	}
	unless ( $current_works->{code} )
	{
		$form->appendChild( $repo->html_phrase( "Plugin/Screen/User/Orcid/OrcidManager:orcid_api_error_undef", 
			id =>$repo->make_text($orcid) ) );
		return $page;
	}
	if ( 200 != $current_works->{code} )
	{
		eval {
			my $code = $current_works->{code};
			my $json_vars = JSON::decode_json($current_works->{data});
			my $error_name = $json_vars->{'user-message'};
			my $error_desc = $json_vars->{'more-info'};
			$form->appendChild( $repo->html_phrase( "Plugin/Screen/User/Orcid/OrcidManager:orcid_api_error", 
					id =>$repo->make_text($orcid),
					code =>$repo->make_text($code),
					err =>$repo->make_text($error_name),
					desc =>$repo->make_text($error_desc),
 			) );
		};
		$form->appendChild( $repo->html_phrase( "Plugin/Screen/User/Orcid/OrcidManager:unknown_orcid_api_error" ) ) if $@;
		return $page;
	}

	my $works_data;
	eval {
		$works_data = JSON::decode_json( $current_works->{data} );
	};
	$form->appendChild( $repo->html_phrase( "Plugin/Screen/User/Orcid/OrcidManager:unknown_orcid_api_error" ) ) if $@;
	return $page unless $works_data;
	
	# get the user put codes
	my $put_codes = $user_for_export->get_value( 'put_codes' ); 
	my $relevant_codes = [];
	foreach my $code ( @$put_codes )
	{
		if ( $code->{'code_type'} eq 'work' )
		{
			push @$relevant_codes, $code;
		}
	}

	my $export = $repo->call( 'find_orcid_exports', $current_item, $works_data, $relevant_codes  );

#print STDERR "###### ExportToOrcid: [".Data::Dumper::Dumper($works_data)."]\n";

	my $div = $form->appendChild( $xml->create_element("div", id=>"ep_orcid_export_list") );
	my $table = $div->appendChild( $xml->create_element("table") );

	my $tr = $table->appendChild( $xml->create_element("tr", ) );

	my $cb_td = $tr->appendChild( $xml->create_element( "td" ) );
	my $cb_value = $current_item->get_id();
	my $cb = $cb_td->appendChild( $xml->create_element(
		"input",
		name => $self->{prefix}.'_export_code',
		value => $cb_value,
		type => "checkbox",
		checked => 'checked',
		disabled => 'disabled',
	) );
	if ( $export && $export->{put_code} )
	{
		$cb_td->appendChild( $self->html_phrase( "export_update" ) );
	}

	my $item_td = $tr->appendChild( $xml->create_element("td" ) );
	$item_td->appendChild( $current_item->render_citation("default") );

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
	
	my $tr2 = $table->appendChild( $xml->create_element("tr", ) );
	my $td2 = $tr2->appendChild( $xml->create_element("td") );
	$td2->appendChild( $repo->render_action_buttons(
			orcid_export => $self->phrase( "export_btn" ),
			_order => [qw( orcid_export )],
	) );

	$form->appendChild($div);
	if ( $export && $export->{put_code} )
	{
		$form->appendChild( $repo->render_hidden_field( "_export_put_code", $export->{put_code} ) );
	}
	$form->appendChild( $repo->render_hidden_field( "_export_user_id", $user_for_export->get_id() ) );
	$form->appendChild( $repo->render_hidden_field( "_export_orcid_id", $orcid ) );
	$form->appendChild( $repo->render_hidden_field( "_export_token", $au_token ) );
	$form->appendChild( $repo->render_hidden_field( "eprintid", $current_item->get_id() ) );

	return $page;
}

sub redirect_to_me_url
{
        my( $self ) = @_;

        return defined $self->{processor}->{eprintid} ?
                $self->SUPER::redirect_to_me_url."&eprintid=".$self->{processor}->{eprintid} :
                $self->SUPER::redirect_to_me_url;
}



1;

