=head1 NAME

EPrints::Plugin::Screen::Admin::orcid::OrcidManager

demonstrate using the public api to retrieve works data

=cut

package EPrints::Plugin::Screen::Admin::Orcid::OrcidManager;

our @ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{appears} = [
		{
			place => "admin_actions_system",
			position => 1050,
		}
	];
        #$self->{actions} = [qw/ update import /];


	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return $self->allow( "orcid/view" );
}

sub allow_update
{
        return 1;
}

sub action_update
{
        my( $self ) = @_;
        my $repo = $self->{session};

	print STDERR "ACTION update\n";
}

sub render
{
	my( $self ) = @_;

	my $repo = $self->{session};

	my $selected_user_id = $repo->param( "user_select" );
	my $entered_orcid = $repo->param( "orcid_input" );
	my $xml = $repo->xml;
	my $f = $xml->create_document_fragment;

	my $ds = $repo->dataset("user"); 
	my $user_list = $ds->search();

	my $current_user = undef;
	if ( $selected_user_id > 0 )
	{
		$current_user = $ds->dataobj( $selected_user_id );
		$entered_orcid = $current_user->get_value( "orcid" );
	}

       	my $orcid_prefix = $self->{prefix}."_orcid";
	$f->appendChild( $self->render_results_selection( $orcid_prefix, $selected_user_id, $entered_orcid, $user_list ) );
	
       	my $table = $repo->make_element( "table", class=>"ep_upload_fields ep_multi" );
	$f->appendChild( $table );

	if ( $entered_orcid )
	{
		my $details_div = $f->appendChild( $repo->make_element( "div", class => "orcid_details" ) );
		$details_div->appendChild( $self->render_selected_details( $orcid_prefix, $current_user ) ) if defined $current_user;		
		my $items_div = $f->appendChild( $repo->make_element( "div", class => "orcid_details" ) );
		$items_div->appendChild( $self->render_orcid_data( $orcid_prefix, $entered_orcid ) ) if defined $entered_orcid;		
		my $div = $f->appendChild( $repo->make_element( "div", class => "orcid_actions" ) );
		$div->appendChild( $self->render_action_list( "orcid_actions", {'userid' => $selected_user_id} ) );
		$div->appendChild( $self->render_action_list( "orcid_management_actions", {'userid' => $selected_user_id} ) );
	}
	else
	{
		$f->appendChild( $self->render_no_results );
		my $div = $f->appendChild( $repo->make_element( "div", class => "orcid_actions" ) );
		$div->appendChild( $self->render_action_list( "orcid_management_actions", {'userid' => $selected_user_id} ) );
	}


	return $f;
}	
	
sub render_no_results
{
	my( $self, ) = @_;

	my $repo = $self->{session};

	return $repo->xml->create_text_node( "No Data" );
}
	
sub render_results_selection
{
	my( $self, $orcid_prefix, $selected_id, $entered_orcid, $user_list ) = @_;
	my $repo = $self->{session};
	my $xml = $repo->xml;

	my $form = $repo->render_form( "GET" );
	$form->appendChild( $repo->render_hidden_field ( "screen", $self->{processor}->{screenid} ) );		
	$form->setAttribute("id", "orcid_select_form");
	
        my $table = $form->appendChild( $xml->create_element( "table", class=>"ep_multi" ) );

        my $selection = $xml->create_element( "select", class => "user_select", name=>"user_select" );
       	$selection->setAttribute( "onchange", "document.forms[\"orcid_select_form\"].submit();" );

       	my $initial_option = $repo->xml->create_element( "option", class => "user_select", value=>"0" );
       	$initial_option->appendChild( $repo->xml->create_text_node( "Select a user or enter an ORCiD" ) );
	$initial_option->setAttribute( "selected", "selected" );
       	$selection->appendChild( $initial_option );

	$user_list->map( sub {
		my( $session, $dataset, $user ) = @_;
        	my $id = $user->get_value("userid");
        	my $name= $user->get_value("name");
        	my $orcid = $user->get_value("orcid");
		if ( $orcid )
		{
        		my $option = $repo->xml->create_element( "option", class => "user_select", value=>"$id" );
        		$option->appendChild( $repo->xml->create_text_node( "id: ".$id." ".$name->{family}.", ".$name->{given} ) );
			$option->setAttribute( "selected", "selected" ) if $id == $selected_id;
        		$selection->appendChild( $option );
		}
	}); 

        my $orcid_input = $xml->create_element( "input", class => "user_select", name=>"orcid_input", type=>"text", value=>$entered_orcid );
        my $button = $xml->create_element( "button",
                        form=>"orcid_select_form",
                        type=>"submit", 
                        name=>"get_from_orcid",
                        value=>"get_from_orcid" );
        $button->appendChild( $xml->create_text_node( "Search" ) );


	my $tr1 = $table->appendChild( $xml->create_element( "tr", style=>"width: 100%" ) );
	my $td11 = $tr1->appendChild( $xml->create_element( "td", class=>"" ) );
	my $td12 = $tr1->appendChild( $xml->create_element( "td", class=>"" ) );

	$td11->appendChild( $xml->create_text_node( "User:" ) ); 
	$td12->appendChild( $selection ); 
 
	my $tr2 = $table->appendChild( $xml->create_element( "tr", style=>"width: 100%" ) );
	my $td21 = $tr2->appendChild( $xml->create_element( "td", class=>"" ) );
	my $td22 = $tr2->appendChild( $xml->create_element( "td", class=>"" ) );

	$td21->appendChild( $xml->create_text_node( "ORCiD:" ) ); 
	$td22->appendChild( $orcid_input ); 
	$td22->appendChild( $button ); 
 

	return $form;

}
	
sub render_selected_details
{
	my( $self, $orcid_prefix, $user ) = @_;

	my $repo = $self->{session};
	my $ds = $repo->dataset("user"); 

        my $table = $repo->make_element( "table", class=>"ep_multi" );
        my $first = 1;
	foreach my $field_name ( qw\ name orcid \ )
	{
		my $field = $ds->field( $field_name );
		next unless $user->is_set( $field->get_name );

                my $label = $field->render_name($repo);
                if( $field->{required} ) 
                {
                        $label = $self->{session}->html_phrase(
                                "sys:ep_form_required",
                                label=>$label );
                }

                $table->appendChild( $repo->render_row_with_help(
                        label=>$label,
                        field=>$field->render_value( $repo, $user->get_value( $field->get_name ) ),
                        help=>$field->render_help($repo),
                        help_prefix=>$orcid_prefix."_".$field->get_name."_help",
                ));
                $first = 0;
	}	
	return $table;
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

	my $url = $repo->get_conf( "orcid_public_api" );
	my $url_v = $repo->get_conf( "orcid_version" );
	$url .= "v".$url_v."/".$orcid;
	$url .= "/orcid-works"; 

print STDERR "req[".$url."]\n";
	my $req = HTTP::Request->new("GET",$url);
	$req->header( "accept" => "application/json" );

	my $ua = LWP::UserAgent->new;
	my $response = $ua->request($req);

	if (200 != $response->code)
	{
		return $frag->appendChild( $xml->create_text_node( "Received Error code: ".$response->code )  );
	}
	else
	{
print STDERR "got[".Data::Dumper::Dumper($response)."]\n";
		my $content = $response->content;
		my $json_vars = JSON::decode_json($content);
		$div->appendChild( $self->render_orcid_works( $json_vars ) );
	}

        my %buttons = ( update => $self->phrase( "action:update:title" ,
                _order=>[ "update" ],
                _class=>"ep_form_button_bar"
        ) );

	return $frag;
}

sub render_orcid_works
{
	my( $self, $data ) = @_;

	my $repo = $self->{session};
	my $xml = $repo->xml;

        my $table = $xml->create_element( "table", class=>"ep_upload_fields ep_multi" );
	
	#nodes: orcid orcid-id orcid-preferences group-type client-type orcid-activities type orcid-history

	my $label = "ORCiD";
	my $value = $data->{'orcid-profile'}->{'orcid'}->{'value'}; 

	$table->appendChild( $self->render_table_row_with_text( $xml, $label, $value ) );

	my $import_count = 0;
	my $works = $data->{'orcid-profile'}->{'orcid-activities'}->{'orcid-works'}->{'orcid-work'};
	foreach my $work ( @$works )
	{
		my $date = "";
		$date .= $work->{'publication-date'}->{'day'}->{'value'} if $work->{'publication-date'}->{'day'}->{'value'};
		$date .= "/".$work->{'publication-date'}->{'month'}->{'value'} if $work->{'publication-date'}->{'month'}->{'value'};
		$date .= "/".$work->{'publication-date'}->{'year'}->{'value'} if $work->{'publication-date'}->{'year'}->{'value'};

		my $title = $work->{'work-title'}->{'title'}->{'value'};
		my $citation  = $work->{'work-citation'}->{'citation'};
		my $citation_format  = $work->{'work-citation'}->{'work-citation-type'};

		$table->appendChild( $self->render_table_row_with_text( $xml, "Title", $title, 1 ) );
		$table->appendChild( $self->render_table_row_with_text( $xml, "Date", $date ) );
		$table->appendChild( $self->render_table_row_with_import( $xml, "Citation", $citation, $citation_format, $citation, $import_count++ ) );
		$table->appendChild( $self->render_table_row_with_text( $xml, "Citation Format", $citation_format ) );

		my $ext_ids = $work->{'work-external-identifiers'}->{'work-external-identifier'};
		foreach my $ext_id ( @$ext_ids )
		{
			my $id_type = $ext_id->{'work-external-identifier-type'};
			my $id = $ext_id->{'work-external-identifier-id'}->{'value'};
			$table->appendChild( $self->render_table_row_with_import( $xml, $id_type, $id, $id_type, $id, $import_count++ ) );
		}
		my $url  = $work->{'url'}->{'value'};
		$table->appendChild( $self->render_table_row_with_link( $xml, "URL", $url, $url ) );
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


sub render_table_row_with_link
{
	my( $self, $xml, $label_val, $value_val, $link_val ) = @_;

	my $label = $xml->create_text_node( $label_val );
	my $value = $xml->create_element( "a", href=>$link_val, target=>"_blank" );
	$value->appendChild( $xml->create_text_node( $value_val ) );
	my $link = $xml->create_text_node( "" );
	return $self->render_table_row( $xml, $label, $value, $link );
}

sub render_table_row_with_import
{
	my( $self, $xml, $label_val, $disp_val, $import_type, $import_value, $import_count ) = @_;

	my $plugin_map = {
		"DOI" => "DOI",
		"BIBTEX" => "BibTeX",
                "PMID" => "PubMedID",
	};

	my $repo = $self->{session};
	my $label = $xml->create_text_node( $label_val );
	my $value = $xml->create_text_node( $disp_val );
	
	my $import_plugin = $plugin_map->{$import_type};

	my $form = $repo->render_form( "POST" );
	$form->appendChild( $repo->render_hidden_field ( "screen", "Import" ) );		
	$form->appendChild( $repo->render_hidden_field ( "_action_import_from", "Import" ) );		
	$form->appendChild( $repo->render_hidden_field ( "format", $import_plugin ) );		
	$form->appendChild( $repo->render_hidden_field ( "data", $import_value ) );		
	$form->setAttribute("id", "orcid_import_form_".$import_count);
	my $button = $form->appendChild( $xml->create_element( "button", 
			form=>"orcid_import_form_".$import_count, 
			type=>"submit", 
			name=>"Import_from_orcid", 
			value=>"Import_from_orcid" ) );
	$button->setAttribute( "disabled", "disabled" ) unless $import_plugin;
	$button->appendChild( $xml->create_text_node( "Import" ) );
	return $self->render_table_row( $xml, $label, $value, $form );
}




1;


