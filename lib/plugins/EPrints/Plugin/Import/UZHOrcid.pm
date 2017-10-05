=head1 NAME

EPrints::Plugin::Import::UZHOrcid

This is an ORCID Import plugin. 
The result is a JSON formatted list of works for the supplied ORCID iD(s)

=cut

package EPrints::Plugin::Import::UZHOrcid;

use strict;
use EPrints::Plugin::Import;
use EPrints::Plugin::Import::TextFile;
our @ISA = qw/ EPrints::Plugin::Import /;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "UZH Orcid Import";
	$self->{advertise} = 1;
	$self->{visible} = "all";
	$self->{produce} = [ 'list/eprint' ];
	$self->{screen} = "Import::UZHOrcid";
	$self->{arguments}{fields} = [];

	return $self;
}

sub input_fh
{
	my ($self, %opts) = @_;

	return $self->EPrints::Plugin::Import::TextFile::input_fh( %opts );
}

=begin InternalDoc

=over

=item $epdata = input_text_fh( %opts )

=back

This method will valiate the ORCID iDs supplied and then attempt to get the summary of the works
The JSON format works data is returned for any works found and any warnings are added to the processor list.

The supplied data is processed to produce a list of ORCID iDs which are then validated to check the format.
Next, a utility function is called to return the works for each ORCID iD or an error message if the iD is 
not valid or a problem occured.

If the call is successful the JSON data is parsed to extract the works data including title, source and 
External Identifiers (DOI or PMID) 
The works data is returned to the caller.

=end InternalDoc

=cut

sub input_text_fh
{
	my( $self, %opts ) = @_;

	if ($opts{fields})
	{
		$opts{fields} = [split /\s*,\s*/, $opts{fields}]
			if ref($opts{fields}) ne 'ARRAY';
	}

	my $repo = $self->{session};

	my $fh = $opts{fh};
	my $query = join '', <$fh>;
	my @ids = split " ", $query;
	my $works_list = [];
	foreach my $oid ( @ids )
	{
		unless ( $repo->call( 'valid_orcid_id', $oid ) ) 
		{
			$self->{processor}->add_message( "warning",  
				$self->html_phrase( "incorrect_orcid_format", id=>$repo->make_text( $oid ) ) );
			$self->{total} = 0;
			$self->{processor}->{count} = 0 if $self->{processor};

			return $works_list;
		}
	}
	foreach my $oid ( @ids )
	{
		my $result = $repo->call( 'get_works_for_orcid', $repo, $oid );
		unless ( $result->{code} )
		{
			$self->{processor}->add_message( "warning", 
				 $self->html_phrase( "orcid_api_error_undef",
					id =>$repo->make_text($oid) ) ) if $self->{processor};
			next;	
		}
		if ( 200 != $result->{code} )
		{
			my $code = $result->{code};
			my $json_vars = JSON::decode_json($result->{data});
			my $error_name = $json_vars->{'user-message'};
			my $error_desc = $json_vars->{'more-info'};
			$self->{processor}->add_message( "warning", 
				 $self->html_phrase( "orcid_api_error", 
					id =>$repo->make_text($oid),
					code =>$repo->make_text($code),
					err =>$repo->make_text($error_name),
					desc =>$repo->make_text($error_desc),
 				) ) if $self->{processor};
			 
			print STDERR $self->phrase( "orcid_api_error", 
					id =>$repo->make_text($oid),
					code =>$repo->make_text($code),
					err =>$repo->make_text($error_name),
					desc =>$repo->make_text($error_desc),
 				)."\n" unless $self->{processor};
	
			next;	
		}
		else
		{
			my $json_vars = JSON::decode_json($result->{data});
			my $groups = $json_vars->{group};
			foreach my $group ( @$groups )
			{
				my $summary = $group->{'work-summary'};
				foreach my $ws ( @$summary )
				{
					my $work = {};
					$work->{title} = $ws->{title}->{title}->{value} 
						if $ws->{title} && $ws->{title}->{title} && $ws->{title}->{title}->{value};
					$work->{type} = $ws->{type};
					$work->{'put-code'} = $ws->{'put-code'};
					$work->{'source'} = $ws->{'source'}->{'source-name'}->{value}
						if $ws->{'source'} && $ws->{'source'}->{'source-name'} && $ws->{'source'}->{'source-name'}->{value}; 
					if ( $ws->{'external-ids'} && $ws->{'external-ids'}->{'external-id'} )
					{
						foreach my $ext_id ( @{$ws->{'external-ids'}->{'external-id'}} )
						{
							my $id_type = $ext_id->{'external-id-type'};
							my $id_val = $ext_id->{'external-id-value'};
							$work->{$id_type} = $id_val if $id_type eq 'doi' ||  $id_type eq 'pmid'; 
						}
					}
					push @$works_list, $work;
				}
	
			}
		}
	}
	
	$self->{total} = scalar @$works_list;
	$self->{processor}->{count} = scalar @$works_list if $self->{processor};

	return $works_list;
}


1;


