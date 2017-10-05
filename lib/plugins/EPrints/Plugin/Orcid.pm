=head1 NAME

EPrints::Plugin::Orcid

This is the base class for the ORCID plugins. The sub classes define the action/scope
that they are responsible for and implement the appropriate perform_action routine.

=cut

package EPrints::Plugin::Orcid;

use strict;


our @ISA = qw/ EPrints::Plugin /;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "Orcid";
	$self->{visible} = "all";
	$self->{screen} = $self->repository->config( 'userhome' );
	$self->{scope} = "";
	$self->{description} = "Default ORCID plugin: returns a user's authenticated ORCID iD";
	$self->{action} = "";

	return $self;
}

=begin InternalDoc

=over

=item matches ( $self, $test, $param )

=back

This is part of the Plugin framework and allows specific ORCID plugins to be found
based upon the scope.

=end InternalDoc

=cut

sub matches 
{
	my( $self, $test, $param ) = @_;

	if( $test eq "scope" )
	{
		return( $self->{scope} eq $param );
	}

	# didn't understand this match 
	return $self->SUPER::matches( $test, $param );
}


=begin InternalDoc

=over

=item perform_action ( $self, $scope, $orcid, $token, $action )

=back

This routine should be overridden in the subclass

=end InternalDoc

=cut

sub perform_action
{
	my( $self, $scope, $orcid, $token, $action ) = @_;

	return $orcid ;
}

=begin InternalDoc

=over

=item store_token_for_scope ( $self, $scope, $orcid, $token, $user_id )

=back

This is a utility routine to store the users token for a specifed scope

=end InternalDoc

=cut

sub store_token_for_scope
{
	my( $self, $scope, $orcid, $token, $user_id ) = @_;

	my $repo = $self->{repository};

	#we now have the token for the user so we can update the user 
	my $scope_map = $repo->config( "orcid_scope_map" );
	return unless $scope_map->{$scope};
	my $field = $scope_map->{$scope}; 

	my $ds = $repo->dataset( "user" );
	my $user = $ds->dataobj( $user_id );
	if ( $user && $token && $field )
	{
		$user->set_value( $field, $token );
		$user->commit();
	}
	else
	{
		$repo->render_message( 'error', $repo->html_phrase( "cgi/orcid/ReadProfile:error:user_update_failed" ) );
	}
	return;
}

=begin InternalDoc

=over

=item user_permission_granted ( $self, $user, )

=back

This utility routine will return undef or a token for the action that the plugin is
designed to handle. There is no default action defined for this class but sub classes
that implement specific ORCID Plugins will define an action/scope that they are 
responsible for 

=end InternalDoc

=cut

sub user_permission_granted
{
	my( $self, $user, ) = @_;

	my $repo = $self->{repository};
	return undef unless $self->{scope} && $user;
	my $scope_map = $repo->config( "orcid_scope_map" );
	my $field = $scope_map->{$self->{scope}};
	return undef unless $field;
	return $user->get_value( $field );
}

=begin InternalDoc

=over

=item read_data ( $self, $user, $orcid, $scope, )

=back

This is a generic routine to read data from the ORCID Registry
The action for which data is to be read is defined in the sub class

=end InternalDoc

=cut

sub read_data
{
	#my( $self, $user, $orcid, $scope, $put_code, $end_point,  ) = @_;
	my( $self, $user, $orcid, $scope, ) = @_;

	return undef unless $user;
	my $repo = $self->{repository};
	my $activity_map = $repo->config( "orcid_activity_map" );
	my $scope_map = $repo->config( "orcid_scope_map" );
	my $field = $scope_map->{$self->{scope}}; 
	my $token = $user->get_value( $field );

	my $url =  $repo->config( "orcid_member_api" ) . 
		'v'. $repo->config( "orcid_version" ) .
		'/'. $orcid. 
		'/'. $activity_map->{$self->{action}}->{request} ; 

	my $ua = LWP::UserAgent->new;
	my $request = new HTTP::Request( GET => $url,
			HTTP::Headers->new(
				'Content-Type' => 'application/vdn.orcid+xml', 
				'Authorization' => 'Bearer '.$token )
		);

	my $response = $ua->request($request);

	my $result = {
		code => $response->code,
		data => $response->content,
	};

	if ( 200 != $response->code )
	{
		my $json_vars = JSON::decode_json($response->content);
		$result->{error} = $json_vars->{error};
		$result->{error_description} = $json_vars->{error_description};
	}

	return $result ;
}

=begin InternalDoc

=over

=item get_valid_put_code ( $self, $user, $orcid, $code_type, $end_point )

=back

This routine checks the user data for an appropriate put code.
if one is found then the orcid record is queried to request the 
summary data for the supplied endpoint and 
returns true if the user's put code for the endpoint matches a put code 
for one of the possible elements in the orcid summary data

=end InternalDoc

=cut

sub get_valid_put_code
{
	my( $self, $user, $orcid, $code_type, $end_point ) = @_;

	return unless $user && $orcid && $end_point && $code_type;
	my $repo = $self->{repository};

	# check for an existing put code so we can prevent duplicate entries
	my $codes = EPrints::Utils::clone( $user->get_value( "put_codes" ) );
	my $put_code;
	foreach my $code ( @$codes )
	{
		if ( $code->{code} && $code->{code_type} eq $code_type )
		{
			$put_code = $code->{code};
			last;
		}
	}
	
	return unless $put_code;

	my $scope = $repo->config( "orcid_read_scope" );
	my $scope_map = $repo->config( "orcid_scope_map" );
	my $field = $scope_map->{$scope}; 
	my $token = $user->get_value( $field );

	my $tag_map = $repo->config( "put_code_tag_for_endpoint" );
	my $tag = $tag_map->{$end_point};

	my $url =  $repo->config( "orcid_member_api" ) . 
		'v'. $repo->config( "orcid_version" ) .
		'/'. $orcid.$end_point  ; 

	my $ua = LWP::UserAgent->new;
	my $request = new HTTP::Request( GET => $url,
			HTTP::Headers->new(
				'Content-Type' => 'application/vdn.orcid+xml', 
				'Authorization' => 'Bearer '.$token )
		);

	my $response = $ua->request($request);

	if ( 200 == $response->code )
	{
		my $result_xml = EPrints::XML::parse_xml_string( $response->content );
		#foreach my $employment ( $result_xml->getElementsByTagName( "employment-summary" ) )
		foreach my $element ( $result_xml->getElementsByTagName( $tag ) )
		{
			my $this_put_code = $element->getAttribute("put-code");
			return $put_code if $this_put_code && $this_put_code eq $put_code;
		}
	}

	return;
}


=begin InternalDoc

=over

=item save_put_code ( $self, $user, $code_type, $new_code )

=back

This routine replaces any existing put code for a particular 
put_code_type with the supplied new code
There should be only one put code for a put code type and this routine
will remove any duplicates for the put code type being processed 

=end InternalDoc

=cut

sub save_put_code
{
	my ( $self, $user, $code_type, $new_code ) = @_;
	return unless $new_code && $code_type;
	my $repo = $self->{repository};
	my $new_codes = [];
	my $old_codes = $user->get_value( "put_codes" );
	foreach my $code ( @$old_codes )
	{
		push @$new_codes, $code unless $code->{"code_type"} eq $code_type;
	}
	my $put_code = { code => $new_code, code_type => $code_type };
	push @$new_codes, $put_code;
	$user->set_value( "put_codes", $new_codes );
	$user->commit();
}


1;


