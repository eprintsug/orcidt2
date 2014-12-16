=head1 NAME

EPrints::Plugin::Import::Orcid

=cut

package EPrints::Plugin::Import::Orcid;

use strict;

use EPrints::Plugin::Import::TextFile;
use URI;

our @ISA = qw/ EPrints::Plugin::Import::TextFile /;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "Orcid";
	$self->{visible} = "all";
	$self->{produce} = [ 'dataobj/eprint', 'list/eprint' ];
	$self->{screen} = "Import::Orcid";

	return $self;
}

sub screen
{
	my( $self, %params ) = @_;

	return $self->{repository}->plugin( "Screen::Import::Orcid", %params );
}

sub input_text_fh
{
	my( $plugin, %opts ) = @_;

	my $repo = $plugin->{session};
	my @ids;

	my $user_ds = $repo->dataset( "user" );
	my $orcid_id_field = $repo->config( "user_orcid_id_field" ); 
	unless( $orcid_id_field && $user_ds->has_field( $orcid_id_field ) )
	{
		$plugin->error( 'You need to configure your user ORCID iD field' );
		return undef;
	}

	my $current_user = $repo->current_user;
	my $orcid_id = $current_user->value( $orcid_id_field ) if $current_user;

print STDERR "got orcid:[$orcid_id]\n";
	unless( $orcid_id && $orcid_id =~ /\d{4}-\d{4}-\d{4}-\d{3}./ )
	{
		$plugin->error( 'It has not been possible to find the ORCID iD associated with this account' );
		return undef;
	}

	my $fh = $opts{fh};
	while( my $doi = <$fh> )
	{
		$doi =~ s/^\s+//;
		$doi =~ s/\s+$//;

		next unless length($doi);

		$doi =~ s/^(doi:)?/doi:/i;

		my %params = (
			#pid => $api,
			noredirect => "true",
			id => $doi,
		);

		my $url = URI->new( "http://www.crossref.org/openurl" );
		$url->query_form( %params );

		my $dom_doc;
		eval {
			$dom_doc = EPrints::XML::parse_url( $url );
		};

		my $dom_top = $dom_doc->getDocumentElement;

		my $dom_query_result = ($dom_top->getElementsByTagName( "query_result" ))[0];

		if( $@ || !defined $dom_query_result)
		{
			$plugin->handler->message( "warning", $plugin->html_phrase( "invalid_doi",
				doi => $plugin->{session}->make_text( $doi ),
				msg => $plugin->{session}->make_text( "No or unrecognised response" )
			));
			next;
		}

		my $dom_body = ($dom_query_result->getElementsByTagName( "body" ))[0];
		my $dom_query = ($dom_body->getElementsByTagName( "query" ))[0];
		my $status = $dom_query->getAttribute( "status" );

		if( defined($status) && ($status eq "unresolved" || $status eq "malformed") )
		{
			my $msg = ($dom_query->getElementsByTagName( "msg" ))[0];
			$msg = EPrints::Utils::tree_to_utf8( $msg );
			$plugin->handler->message( "warning", $plugin->html_phrase( "invalid_doi",
				doi => $plugin->{session}->make_text( $doi ),
				msg => $plugin->{session}->make_text( $msg )
			));
			next;
		}

		my $data = { doi => $doi };
		foreach my $node ( $dom_query->getChildNodes )
		{
			next if( !EPrints::XML::is_dom( $node, "Element" ) );
			my $name = $node->tagName;
			if( $node->hasAttribute( "type" ) )
			{
				$name .= ".".$node->getAttribute( "type" );
			}
			if( $name eq "contributors" )
			{
				$plugin->contributors( $data, $node );
			}
			else
			{
				$data->{$name} = EPrints::Utils::tree_to_utf8( $node );
			}
		}

		EPrints::XML::dispose( $dom_doc );

		my $epdata = $plugin->convert_input( $data );
		next unless( defined $epdata );

		my $dataobj = $plugin->epdata_to_dataobj( $opts{dataset}, $epdata );
		if( defined $dataobj )
		{
			push @ids, $dataobj->get_id;
		}
	}

	return EPrints::List->new( 
		dataset => $opts{dataset}, 
		session => $plugin->{session},
		ids=>\@ids );
}

sub contributors
{
	my( $plugin, $data, $node ) = @_;

	my @creators;

	foreach my $contributor ($node->childNodes)
	{
		next unless EPrints::XML::is_dom( $contributor, "Element" );

		my $creator_name = {};
		foreach my $part ($contributor->childNodes)
		{
			if( $part->nodeName eq "given_name" )
			{
				$creator_name->{given} = EPrints::Utils::tree_to_utf8($part);
			}
			elsif( $part->nodeName eq "surname" )
			{
				$creator_name->{family} = EPrints::Utils::tree_to_utf8($part);
			}
		}
		push @creators, { name => $creator_name }
			if exists $creator_name->{family};
	}

	$data->{creators} = \@creators if @creators;
}

sub convert_input
{
	my( $plugin, $data ) = @_;

	my $epdata = {};

	if( defined $data->{creators} )
	{
		$epdata->{creators} = $data->{creators};
	}
	elsif( defined $data->{author} )
	{
		$epdata->{creators} = [ 
			{ 
				name=>{ family=>$data->{author} }, 
			} 
		];
	}

	if( defined $data->{year} && $data->{year} =~ /^[0-9]{4}$/ )
	{
		$epdata->{date} = $data->{year};
	}

	if( defined $data->{"issn.electronic"} )
	{
		$epdata->{issn} = $data->{"issn.electronic"};
	}
	if( defined $data->{"issn.print"} )
	{
		$epdata->{issn} = $data->{"issn.print"};
	}
	if( defined $data->{"doi"} )
	{
		$epdata->{id_number} = $data->{"doi"};
		my $doi = $data->{"doi"};
		$doi =~ s/^\s*doi:\s*//gi;
		$epdata->{official_url} = "http://dx.doi.org/$doi";
	}
	if( defined $data->{"volume_title"} )
	{
		$epdata->{book_title} = $data->{"volume_title"};
	}


	if( defined $data->{"journal_title"} )
	{
		$epdata->{publication} = $data->{"journal_title"};
	}
	if( defined $data->{"article_title"} )
	{
		$epdata->{title} = $data->{"article_title"};
	}


	if( defined $data->{"series_title"} )
	{
		# not sure how to map this!
		# $epdata->{???} = $data->{"series_title"};
	}


	if( defined $data->{"isbn"} )
	{
		$epdata->{isbn} = $data->{"isbn"};
	}
	if( defined $data->{"volume"} )
	{
		$epdata->{volume} = $data->{"volume"};
	}
	if( defined $data->{"issue"} )
	{
		$epdata->{number} = $data->{"issue"};
	}

	if( defined $data->{"first_page"} )
	{
		$epdata->{pagerange} = $data->{"first_page"};
	}
	if( defined $data->{"last_page"} )
        {
                $epdata->{pagerange} = "" unless defined $epdata->{pagerange};
                $epdata->{pagerange} .= "-" . $data->{"last_page"};
        }

	if( defined $data->{"doi.conference_paper"} )
	{
		$epdata->{type} = "conference_item";
	}
	if( defined $data->{"doi.journal_article"} )
	{
		$epdata->{type} = "article";
	}

	return $epdata;
}

sub url_encode
{
        my ($str) = @_;
        $str =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
        return $str;
}

1;


