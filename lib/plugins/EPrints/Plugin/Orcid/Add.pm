=head1 NAME

EPrints::Plugin::Orcid::Add

=cut

package EPrints::Plugin::Orcid::Add;

use strict;


our @ISA = qw/ EPrints::Plugin::Orcid /;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "Add";
	$self->{visible} = "all";
	$self->{screen} = $self->repository->config( 'userhome' );
	$self->{scope} = "/create";
	$self->{description} = "ORCID plugin to get and store a token to add activities to a user's ORCID profile";
	$self->{action} = "create";

	return $self;
}

sub perform_action
{
	my( $self, $scope, $orcid, $token, $action, $user_id, $item_id ) = @_;

	my $repo = $self->{repository};

print STDERR "Orcid::Add::perform_action called scope,[$scope,] orcid,[$orcid,] token,[$token,] action[$action] user[$user_id] item[$item_id]\n";
	#we now have the orcid id for the user so we can update the user and return to the profile screen
	my $orcid_field = $repo->config( "user_orcid_read_token" );
	my $ds = $repo->dataset( "user" );
	my $user = $ds->dataobj( $user_id );
	if ( $user )
	{
#		$user->set_value( $orcid_field, $orcid );
#		$user->commit();
print STDERR "####### updated user redirect to [".$repo->config( 'userhome' )."]\n";
	}
	else
	{
		$repo->render_message( 'error', $repo->html_phrase( "cgi/orcid/auth:error:user_update_failed" ) );
print STDERR "####### updated user ERROR redirect to [".$repo->config( 'userhome' )."]\n";
	}

	my $return_url = $repo->config( 'userhome' );
	if ( $action eq "01" )
	{
		$return_url .= "?screen=User::Orcid::OrcidManager";
	}
#	elsif ( $action eq "02" )
#	{
#		$return_url .= "?screen=User::Orcid::OrcidManager";
#	}
	$repo->redirect( $return_url );
	return 1;
}


1;


