=head1 NAME

EPrints::Plugin::Screen::Import::UZHOrcid

This provides the user interface for the ORCID Import Plugin

=cut

package EPrints::Plugin::Screen::Import::UZHOrcid;

@ISA = ( 'EPrints::Plugin::Screen::Import' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{actions} = [qw/ test_data import_data import_single /];

	return $self;
}

sub wishes_to_export { shift->{repository}->param( "ajax" ); }
sub export_mimetype { "text/html;charset=utf-8" };
sub export
{
	my( $self ) = @_;

	my $item = $self->{processor}->{items}->[0];
	$self->{repository}->not_found, return if !defined $item;

	my $link = $self->{repository}->xml->create_data_element( "a",
		$item->id,
		href => $item->uri,
	);

	binmode(STDOUT, ":utf8");
	print $self->{repository}->xml->to_string( $link );
}

sub properties_from
{
	my( $self ) = @_;

	$self->SUPER::properties_from;

	$self->{processor}->{offset} = $self->{repository}->param( "results_offset" );
	$self->{processor}->{offset} ||= 0;

	$self->{processor}->{data} = $self->{repository}->param( "data" );

	my @workcodes = $self->{repository}->param( "workcode" );
	$self->{processor}->{workcodes} = \@workcodes;

	$self->{processor}->{items} = [];
}

sub allow_import_single { shift->can_be_viewed }

sub arguments
{
	my( $self ) = @_;

	return(
		offset => $self->{processor}->{offset},
	);
}

=begin InternalDoc

=over

=item action_test_data (  )

=back

This method runs the import as a dry run to retrieve the works data from the ORCID Registry

=end InternalDoc

=cut

sub action_test_data
{
	my( $self ) = @_;

	my $tmpfile = File::Temp->new;
	syswrite($tmpfile, scalar($self->{repository}->param( "data" )));
	sysseek($tmpfile, 0, 0);

	my $list = $self->run_import( 1, 1, $tmpfile ); # dry run without messages
	$self->{processor}->{results} = $list;
}

=begin InternalDoc

=over

=item action_import_data (  )

=back

This method obtains the PMID or DOI for the selected works and passes them to the
appropriate Import plugin to actualy import the data for the work.
A list of the imported items is created so that the post_import process can 
redirect to the appropriate workflow page.

=end InternalDoc

=cut

sub action_import_data
{
	my( $self ) = @_;
	my $repo = $self->{repository};

	#local $self->{i} = 0;

	my $import_count = 0;
	my $workcodes = $self->{processor}->{workcodes};
	my @ids;
	if ( $workcodes )
	{
		foreach my $code ( @$workcodes )
		{
			my $eprint;
			if ( $code =~ /^doi:/ )
			{
				$eprint = $self->import_using_plugin( $code, "Import::DOI" );
			}
			elsif ( $code =~ /^pmid:/ )
			{
				$code =~ s/pmid://;
				$eprint = $self->import_using_plugin( $code, "Import::PubMedID"  );
			}
			if ( $eprint )
			{
				push @ids, $eprint->get_id;
				$import_count++;
			}
		}
	}

	$self->{processor}->add_message( "message", $repo->html_phrase( "Plugin/Screen/Import:import_completed",
		count => $repo->xml->create_text_node( $import_count )
		) );
	#create a list of imported items and display single item or all
	my $ds = $repo->dataset( "eprint" );
	my $list = $ds->list( \@ids );

	if( !$self->wishes_to_export )
	{
		if ( $list && $list->count )
		{
			$self->{processor}->{results} = $list;
			$self->post_import( $list );
		}
		else
		{
			$self->{processor}->{items} = [];
			# re-run the search query
			$self->action_test_data;
		}
	}
}

=begin InternalDoc

=over

=item import_using_plugin ( $id, $plugin_id )

=back

This method takes an id and a plugin id and uses the plugin to import the data for the id
Any error messages are displayed to the user.
The created item is returned on success

=end InternalDoc

=cut

sub import_using_plugin
{
	my( $self, $id, $plugin_id ) = @_;
	my $repo = $self->{repository};

	my $eprint;

	my $plugin = $repo->plugin( $plugin_id );
	$plugin->set_handler(EPrints::CLIProcessor->new(
		message => sub { $self->{processor}->add_message( @_ ) },
		epdata_to_dataobj => sub {
			$eprint = $self->SUPER::epdata_to_dataobj( @_ );
		},
	) );

	{
		open(my $fh, "<", \$id);
		$plugin->input_fh(
				dataset => $repo->dataset( "inbox" ),
				fh => $fh,
			);
	}
	return $eprint;

}


=begin InternalDoc

=over

=item render

=back

This method displays the input form and potentialy the list of works along with a checkbox to select the ones to import.
An Import button is provided.

=end InternalDoc

=cut

sub render
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;
	my $xhtml = $repo->xhtml;

	my $items = $self->{processor}->{results};

	my $frag = $xml->create_document_fragment;

	$frag->appendChild( $self->html_phrase( "help" ) )
		if !defined $items;

	my $form = $frag->appendChild( $self->render_form );
	$form->appendChild( EPrints::MetaField->new(
			name => "data",
			type => "longtext",
			repository => $repo,
		)->render_input_field(
			$repo,
			$self->{processor}->{data},
		) );
	$form->appendChild( $xhtml->input_field(
		_action_test_data => $repo->phrase( "lib/searchexpression:action_search" ),
		type => "submit",
		class => "ep_form_action_button",
	) );

	if( defined $items )
	{
		$frag->appendChild( $self->render_results( $items ) );
	}

	return $frag;
}

=begin InternalDoc

=over

=item render_results

=back

This method displays the list of works 

=end InternalDoc

=cut

sub render_results
{
	my( $self, $items ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;
	my $xhtml = $repo->xhtml;

	my $offset = $self->{processor}->{offset};

	my $form = $self->render_form;
	$form->setAttribute( class => "import_single" );
	$form->appendChild( $xhtml->hidden_field( data => $self->{processor}->{data} ) );
	$form->appendChild( $xhtml->hidden_field( results_offset => $offset ) );
	
	$form->appendChild( $xml->create_data_element( "h2",
		$self->html_phrase( "results" )
	) );


	my $total = $self->{processor}->{plugin}->{total};
	$total = 1000 if $total > 1000;

	my $i = 0;
	my $list = EPrints::Plugin::Screen::Import::OrcidWork::List->new(
		session => $repo,
		dataset => $repo->dataset( "inbox" ),
		ids => [0 .. ($total - 1)],
		items => {
				map { ($offset + $i++) => $_ } @$items
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
			my( undef, $work, undef, $n ) = @_;
			my @dupes = $self->find_duplicate( $work );
			my $tr = $xml->create_element( "tr" );
			my $num_td = $tr->appendChild( $xml->create_element( "td" ) );
			my $item_td = $tr->appendChild( $xml->create_element( "td" ) );
			$num_td->appendChild( $xml->create_text_node( $n ) );
			$item_td->appendChild( $self->html_phrase( "results_title" ) );
			$item_td->appendChild( $xml->create_text_node( $work->{title} ) );
			$item_td->appendChild( $xml->create_element( "br" ) );
			$item_td->appendChild( $self->html_phrase( "results_type" ) );
			my $work_type = $repo->call( "convert_orcid_work_type", $repo, $work->{type} ); 
			$item_td->appendChild( $repo->html_phrase("eprint_typename_".$work_type ) );
			$item_td->appendChild( $xml->create_element( "br" ) );
			$item_td->appendChild( $self->html_phrase( "results_source" ) );
			$item_td->appendChild( $xml->create_text_node( $work->{source} ) );
			
			my $td = $tr->appendChild( $xml->create_element( "td" ) );
			my $work_val = "putcode:".$work->{"put-code"};
			if ( $work->{doi} )
			{
				$work_val = "doi:".$work->{"doi"};
				$item_td->appendChild( $xml->create_element( "br" ) );
				$item_td->appendChild( $self->html_phrase( "results_ext_id_doi" ) );
				$item_td->appendChild( $xml->create_text_node( $work->{doi} ) );
			}
			elsif ( $work->{pmid} )
			{
				$work_val = "pmid:".$work->{"pmid"};
				$item_td->appendChild( $xml->create_element( "br" ) );
				$item_td->appendChild( $self->html_phrase( "results_ext_id_pmid" ) );
				$item_td->appendChild( $xml->create_text_node( $work->{pmid} ) );
			}
			else
			{
				$item_td->appendChild( $xml->create_element( "br" ) );
				$item_td->appendChild( $self->html_phrase( "results_no_ext_id" ) );
			}
			if( @dupes )
			{
				$item_td->appendChild( $xml->create_element( "br" ) );
				$item_td->appendChild( $self->html_phrase( "duplicates" ) );
			}
			foreach my $dupe (@dupes)
			{
				$item_td->appendChild( $xml->create_data_element( "a",
					$dupe->id,
					href => $dupe->uri,
				) );
				$item_td->appendChild( $xml->create_text_node( ", " ) )
					if $dupe ne $dupes[$#dupes];
			}
	
			my $cb = $td->appendChild( $xml->create_element(
				"input",
				name => 'workcode',
				value => $work_val,
				type => "checkbox",
			) );
			if ( $work_val !~ /^(doi|pmid):/ )
			{
				$cb->setAttribute( disabled => "disabled" );
			} 
		return $tr;
		},
	) );

	$form->appendChild( $repo->render_action_buttons(
			import_data => $self->phrase( "action_import_data" ),
		) );
	
	return $form;
}

=begin InternalDoc

=over

=item find_duplicate

=back

This method looks up the doi, pmid or title of  work to identify duplicates

=end InternalDoc

=cut

sub find_duplicate
{
	my( $self, $work ) = @_;

	my $repo = $self->{repository};
	my $field;
	my $val;
	if ( $work->{doi} )
        {
		$field = $repo->config( "item_doi_field" );
		$val = $work->{"doi"};
	}
        elsif ( $work->{pmid} )
        {
		$field = $repo->config( "item_pmid_field" );
        	$val = $work->{"pmid"};
        }
	else
	{
		$field = "title";
        	$val = $work->{"title"};
	}
  
	my @dupes;

	$self->{repository}->dataset( "eprint" )->search(
		filters => [
			{ meta_fields => [ $field ], value => $val, match => "EX", },
		],
		limit => 5,
	)->map(sub {
		(undef, undef, my $dupe) = @_;

		push @dupes, $dupe;
	});

	return @dupes;
}

=begin InternalDoc

=over

=item OrcidWork::List

=back

This package provides a wrapper for the works data as an EPrints List 

=end InternalDoc

=cut


package EPrints::Plugin::Screen::Import::OrcidWork::List;

our @ISA = qw( EPrints::List );

sub _get_records
{
	my( $self, $offset, $count, $justids ) = @_;

	$offset = 0 if !defined $offset;
	$count = $self->count - $offset if !defined $count;
	$count = @{$self->{ids}} if $offset + $count > @{$self->{ids}};

	my $ids = [ @{$self->{ids}}[$offset .. ($offset + $count - 1)] ];

	return $justids ?
		$ids :
		(grep { defined $_ } map { $self->{items}->{$_} } @$ids);
}

1;


