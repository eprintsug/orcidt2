=head1 NAME

EPrints::Plugin::Orcid::AddWorks

=cut

package EPrints::Plugin::Orcid::AddWorks;

use strict;

use HTTP::Request::Common;

our @ISA = qw/ EPrints::Plugin::Orcid /;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "AddWorks";
	$self->{visible} = "all";
	$self->{screen} = $self->repository->config( 'userhome' );
	$self->{scope} = "/orcid-works/create";
	$self->{description} = "ORCID plugin to get and store a token to add activities to a user's ORCID profile";
	$self->{action} = "add_works";

	return $self;
}

sub perform_action
{
	my( $self, $scope, $orcid, $token, $action, $user_id, $item_id ) = @_;

	my $repo = $self->{repository};
print STDERR "Orcid:AddWorks::perform_action called scope,[$scope,] orcid,[$orcid,] token,[$token,] action[$action] user[$user_id] item[$item_id]\n";
	$self->store_token_for_action( $self->{action}, $scope, $orcid, $token, $action, $user_id, $item_id );

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


