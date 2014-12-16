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
	$self->{action} = "authenticate";

	return $self;
}

sub matches 
{
	my( $self, $test, $param ) = @_;

print STDERR "matches testing  [".$test."]\n";
	if( $test eq "scope" )
	{
print STDERR "testing scope returning [".$self->{scope} eq $param."]\n";
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



1;


