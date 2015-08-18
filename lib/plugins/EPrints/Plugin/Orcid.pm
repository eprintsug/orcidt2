=head1 NAME

EPrints::Plugin::Orcid

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

sub matches 
{
	my( $self, $test, $param ) = @_;

print STDERR "matches testing  test[".$test."] param[$param]\n";
	if( $test eq "scope" )
	{
print STDERR "##################testing scope returning [".$self->{scope} eq $param."]\n";
		return( $self->{scope} eq $param );
	}

	# didn't understand this match 
	return $self->SUPER::matches( $test, $param );
}


sub perform_action
{
	my( $self, $scope, $orcid, $token, $action ) = @_;

	return $orcid ;
}

sub store_token_for_action
{
	my( $self, $orcid_action, $scope, $orcid, $token, $action, $user_id, $item_id ) = @_;

	my $repo = $self->{repository};

print STDERR "Orcid:store_token_for_action called orcid_action,[$orcid_action] scope,[$scope,] orcid,[$orcid,] token,[$token,] action[$action] user[$user_id] item[$item_id]\n";
	#we now have the token for the user so we can update the user and return to the management screen
	my $activity_map = $repo->config( "orcid_activity_map" );
	my $field = $activity_map->{$orcid_action}->{token}; 

	my $ds = $repo->dataset( "user" );
	my $user = $ds->dataobj( $user_id );
	if ( $user && $token && $field )
	{
		$user->set_value( $field, $token );
		$user->commit();
print STDERR "####### Orcid:store_token_for_action updated user field [$field] with token[$token] redirect \n";
	}
	else
	{
		$repo->render_message( 'error', $repo->html_phrase( "cgi/orcid/ReadProfile:error:user_update_failed" ) );
print STDERR "####### updated user ERROR redirect to [".$repo->config( 'userhome' )."]\n";
	}
	return;
}



sub user_permission_granted
{
	my( $self, $user, ) = @_;

	my $repo = $self->{repository};
	return undef unless $self->{action} && $user;
	my $activity_map = $repo->config( "orcid_activity_map" );
	my $token_type = $activity_map->{$self->{action}}->{token_type};
	return undef unless $token_type;
	if ( $token_type eq "until_revoked" )
	{
		my $token_name = $activity_map->{$self->{action}}->{token};
		return $user->get_value( $token_name );
	}

	return undef;
}

sub read_data
{
	my( $self, $user, $orcid ) = @_;

	return undef unless $user;
	my $repo = $self->{repository};
	my $activity_map = $repo->config( "orcid_activity_map" );
	my $field = $activity_map->{$self->{action}}->{token}; 
	my $token = $user->get_value( $field );

# curl -H 'Content-Type: application/vdn.orcid+xml' -H 'Authorization: Bearer d0127437-7a09-4c37-be2e-a437381644ac' -X GET 'https://api.sandbox.orcid.org/v1.1/0000-0002-0244-9026/orcid-profile' -L -i

	my $url =  $repo->config( "orcid_tier_2_api" ) . 
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




1;


