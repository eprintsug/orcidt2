=head1 NAME

EPrints::Plugin::Screen::Import::Orcid

=cut

package EPrints::Plugin::Screen::Import::Orcid;

@ISA = ( 'EPrints::Plugin::Screen::Import' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{actions} = [qw/ test_data import_data /];

	return $self;
}

sub render
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;
	my $xhtml = $repo->xhtml;

	my $frag = $xml->create_document_fragment;


	my $user_ds = $repo->dataset( "user" );
	my $orcid_id_field = $repo->config( "user_orcid_id_field" ); 
	unless( $orcid_id_field && $user_ds->has_field( $orcid_id_field ) )
	{
		$self->{processor}->add_message( "error", $self->html_phrase('no_user_orcid_field' ) );
		return $frag;
	}

	my $current_user = $repo->current_user;
	my $orcid_id = $current_user->value( $orcid_id_field ) if $current_user;

print STDERR "got orcid:[$orcid_id]\n";
	unless( $orcid_id && $orcid_id =~ /\d{4}-\d{4}-\d{4}-\d{3}./ )
	{
		$self->{processor}->add_message( "error", $self->html_phrase('no_user_orcid' ) );
		return $frag;
	}

	$frag->appendChild( $self->html_phrase( "help" ) );
       	my $orcid_prefix = $self->{prefix}."_orcid";

	my $items_div = $frag->appendChild( $repo->make_element( "div", class => "orcid_details" ) );
	$items_div->appendChild( $self->render_orcid_data( $orcid_prefix, $orcid_id ) ) if defined $orcid_id;		
	my $div = $frag->appendChild( $repo->make_element( "div", class => "orcid_actions" ) );
	$div->appendChild( $self->render_action_list( "orcid_actions", {'userid' => $current_user->get_id} ) );
	$div->appendChild( $self->render_action_list( "orcid_management_actions", {'userid' => $current_user->get_id} ) );
	

#	$frag->appendChild( $self->render_import_form );

	return $frag;
}


	
sub render_orcid_data
{
	my( $self, $orcid_prefix, $orcid ) = @_;

	my $repo = $self->{session};
	my $xml = $repo->xml;
	my $frag = $repo->xml->create_document_fragment;
	return $frag unless $orcid;

	my $form = $self->render_form;
	$frag->appendChild( $form );

	my $div = $frag->appendChild( $xml->create_element( "div", class => "orcid_items" ) );

	#my $url = $repo->get_conf( "orcid_public_sandbox_api" );
	my $url = $repo->get_conf( "orcid_public_api" );
	$url .= $orcid;
	$url .= $repo->get_conf( "orcid_works" ); 

	my $req = HTTP::Request->new("GET",$url);
	$req->header( "accept" => "application/json" );

	my $ua = LWP::UserAgent->new;
	my $response = $ua->request($req);
print STDERR "sending [".Data::Dumper::Dumper($req)."] got [".Data::Dumper::Dumper($response)."]\n";

	if (200 != $response->code)
	{
		return $frag->appendChild( $xml->create_text_node( "Received Error code: ".$response->code )  );
	}
	else
	{
		my $content = $response->content;
		my $json_vars = JSON::decode_json($content);
		$div->appendChild( $self->render_orcid_works( $json_vars ) );
	}

	return $frag;
}

sub render_orcid_works
{
	my( $self, $data ) = @_;

	my $repo = $self->{session};
	my $xml = $repo->xml;

	my $items_per_page = 5;
        my $table = $xml->create_element( "table", class=>"ep_upload_fields ep_multi" );
	
	#nodes: orcid orcid-id orcid-preferences group-type client-type orcid-activities type orcid-history


	my $item_count = 0;
	my $works = $data->{'orcid-profile'}->{'orcid-activities'}->{'orcid-works'}->{'orcid-work'};
	foreach my $work ( @$works )
	{
		last if $item_count > $items_per_page;
		my $can_import = $self->can_import( $work );
		my $need_to_import = $self->need_to_import( $work );

		my $title = $work->{'work-title'}->{'title'}->{'value'};
		my $citation  = $work->{'work-citation'}->{'citation'};
		my $citation_format  = $work->{'work-citation'}->{'work-citation-type'};

		if ( $need_to_import ) 
		{
			$table->appendChild( $self->render_table_row_with_import( $xml, "Title", $title, 1, $citation_format, $citation, $item_count++ ) );
		}
		else
		{
			$table->appendChild( $self->render_table_row_with_tick( $xml, "Title", $title, 1 ) );
		}
	#	if ( $need_to_import ) {
	#		$table->appendChild( $self->render_table_row_with_import( $xml, "Citation", $citation, 1, $citation_format, $citation, $item_count++ ) );
	#	}
	#	else
	#	{
			$table->appendChild( $self->render_table_row_with_text( $xml, "Citation", $citation, 0 ) );
	#	}

		my $ids = "";
		my $first_id = 1;
		my $ext_ids = $work->{'work-external-identifiers'}->{'work-external-identifier'};
		foreach my $ext_id ( @$ext_ids )
		{
			$ids .= ", " unless $first_id;
			$ids .= $ext_id->{'work-external-identifier-type'};
			$ids .= ": ";
			$ids .= $ext_id->{'work-external-identifier-id'}->{'value'};
			$first_id = 0;
		}
		$table->appendChild( $self->render_table_row_with_text( $xml, "IDs", $ids, 0  ) );
		$item_count++;
	}


	my $current_user = $repo->current_user;

	my $user_ep_list = $current_user->owned_eprints_list() if $current_user;
	if ( $user_ep_list && $user_ep_list->count )
	{
		$user_ep_list->map( sub {
			my( $session, $dataset, $eprint ) = @_;
			if ( $eprint->value( "eprint_status" ) eq "archive" )
			{
print STDERR "item [".$eprint->get_id."] is in the archive\n";
				my $ep_title = $eprint->value( "title" ); #->[0]->{text};
				$table->appendChild( $self->render_table_row_with_export( $xml, "Title", $ep_title, 1, $current_user->get_id, $eprint->get_id ) );
			}

		});



	}

	return $table;
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
sub render_table_row_with_tick
{
	my( $self, $xml, $label_val, $value_val, $first ) = @_;

	my $label = $xml->create_text_node( $label_val );
	my $value = $xml->create_text_node( $value_val );
	my $tick = $xml->create_element( "img", width=>32, height=>32, src=>"/style/images/tick.png" );
	return $self->render_table_row( $xml, $label, $value, $tick, $first );
}
sub render_table_row_with_import
{
	my( $self, $xml, $label_val, $value_val, $first ) = @_;

	my $label = $xml->create_text_node( $label_val );
	my $value = $xml->create_text_node( $value_val );
	my $tick = $xml->create_element( "img", width=>32, height=>32, src=>"/style/images/import.png" );
	#export/import icons produced by http://momentumdesignlab.com/
	return $self->render_table_row( $xml, $label, $value, $tick, $first );
}
sub render_table_row_with_export
{
	my( $self, $xml, $label_val, $value_val, $first, $user_id, $item_id ) = @_;

	my $repo = $self->{session};

	my $label = $xml->create_text_node( $label_val );
	my $value = $xml->create_text_node( $value_val );

	#my $auth_url = $repo->config( "orcid_authorise_url" ); 
	#$auth_url .= "u".$user_id."i".$item_id."a0";
	my $auth_url = $repo->call( "get_orcid_authorise_url", $repo, $user_id, $item_id, "update_works" ); 

	my $link = $xml->create_element( "a", href=>$auth_url );
	my $tick = $link->appendChild( $xml->create_element( "img", width=>32, height=>32, src=>"/style/images/export.png" ) );
	return $self->render_table_row( $xml, $label, $value, $link, $first );
}





sub render_table_row_with_link
{
	my( $self, $xml, $label_val, $value_val, $first, $link_val ) = @_;

	my $label = $xml->create_text_node( $label_val );
	my $value = $xml->create_element( "a", href=>$link_val, target=>"_blank" );
	$value->appendChild( $xml->create_text_node( $value_val ) );
	my $link = $xml->create_text_node( "" );
	return $self->render_table_row( $xml, $label, $value, $link, $first );
}

#sub render_table_row_with_import
#{
#	my( $self, $xml, $label_val, $disp_val, $first, $import_type, $import_value, $import_count ) = @_;
#
#
#	my $repo = $self->{session};
#	my $label = $xml->create_text_node( $label_val );
#	my $value = $xml->create_text_node( $disp_val );
#	
#	my $plugin_map = $repo->config( "orcid_import_plugin_map" ); 
#	my $import_plugin = $plugin_map->{$import_type};
#
#	my $form = $repo->render_form( "POST" );
#	$form->appendChild( $repo->render_hidden_field ( "screen", "Import" ) );		
#	$form->appendChild( $repo->render_hidden_field ( "_action_import_from", "Import" ) );		
#	$form->appendChild( $repo->render_hidden_field ( "format", $import_plugin ) );		
#	$form->appendChild( $repo->render_hidden_field ( "data", $import_value ) );		
#	$form->setAttribute("id", "orcid_import_form_".$import_count);
#	my $button = $form->appendChild( $xml->create_element( "button", 
#			form=>"orcid_import_form_".$import_count, 
#			type=>"submit", 
#			name=>"Import_from_orcid", 
#			value=>"Import_from_orcid" ) );
#	$button->setAttribute( "disabled", "disabled" ) unless $import_plugin;
#	$button->appendChild( $xml->create_text_node( "Import" ) );
#	return $self->render_table_row( $xml, $label, $value, $form, $first );
#}


sub can_import
{
	my( $self, $work ) = @_;
	my $repo = $self->{session};
	my $citation_format  = $work->{'work-citation'}->{'work-citation-type'};

	my $plugin_map = $repo->config( "orcid_import_plugin_map" ); 

	return 1 if $plugin_map->{$citation_format};

	my $ext_ids = $work->{'work-external-identifiers'}->{'work-external-identifier'};
	foreach my $ext_id ( @$ext_ids )
	{
		my $id_type = $ext_id->{'work-external-identifier-type'};
print STDERR "can_import id[$id_type] ok[".$plugin_map->{$id_type}."]\n";
		return 1 if $plugin_map->{$id_type};
	}
	return 0;
}

sub need_to_import
{
	my( $self, $work ) = @_;
	my $repo = $self->{session};

	my $title = $work->{'work-title'}->{'title'}->{'value'};
	my $doi;
	my $pmid;

	my $ext_ids = $work->{'work-external-identifiers'}->{'work-external-identifier'};
	foreach my $ext_id ( @$ext_ids )
	{
		my $id_type = $ext_id->{'work-external-identifier-type'};
		$doi = $ext_id->{'work-external-identifier-id'}->{'value'} if "DOI" eq $id_type;
		$pmid = $ext_id->{'work-external-identifier-id'}->{'value'} if "PMID" eq $id_type;
	}

	my @filters = ();
	my $field;
	my $value;
#	my $match = "EX";
	if ( $doi )
	{
		push @filters, { meta_fields => [ $repo->get_conf( "item_doi_field" ) ], value => $doi, match => "EX" };
#print STDERR "need_to_import search doi\n";
		$field = $repo->get_conf( "item_doi_field" );
		$value = $doi;
	}
	if( $pmid )
	{
#print STDERR "need_to_import search pmid\n";
#		push @filters, { meta_fields => [ $repo->get_conf( "item_pmid_field" ) ], value => $pmid, match => "EX" };
#		$field = $repo->get_conf( "item_pmid_field" );
#		$value = $pmid;
	}
	if( $title )
	{
#print STDERR "need_to_import search title\n";
#		push @filters, { meta_fields => [ "title" ], value => $title, match => "IN" };
#		$field = "title";
#		$value = $title;
#		$match = "IN";
	}

	if ( $field && $value )
	{
		#my $list = $repo->dataset( 'eprint' )->search(
        	#	filters => [ { meta_fields => [ $field ], value => $value, match => $match } ] );
		my $list = $repo->dataset( 'eprint' )->search(
        		filters => \@filters,
			satisfy => "ANY",
			satisfy_any => 1,
			satisfy_all => 0 );
print STDERR "need_to_import title[$title] doi[$doi] pmid[$pmid] count[".$list->count."]\n";
		return 0 if $list->count;
	}
print STDERR "need_to_import title[$title] doi[$doi] pmid[$pmid] no search\n";
	return 1;
}



1;


