=head1 NAME

EPrints::Plugin::Orcid::Auth

=cut

package EPrints::Plugin::Orcid::Auth;

use strict;


our @ISA = qw/ EPrints::Plugin::Orcid /;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "Auth";
	$self->{visible} = "all";
	$self->{screen} = $self->repository->config( 'userhome' );
	$self->{scope} = "/authenticate";
	$self->{description} = "Default ORCID plugin: returns a user's authenticated ORCID iD";
	$self->{action} = "authenticate";

	return $self;
}

sub perform_action
{
	my( $self, $scope, $orcid, $token, $action, $user_id, $item_id ) = @_;

	my $repo = $self->{repository};

        # store the token for the scopes requested
        my $activity_map = $repo->config( "orcid_activity_map" );
        my @scopes = split " ", $scope;
        foreach my $s ( @scopes )
        {
                foreach my $activity ( keys %$activity_map )
                {
                        if ( $s eq $activity_map->{$activity}->{scope} &&
                                $activity_map->{$activity}->{token} )
                        {
                                $self->store_token_for_action( $activity, $s, $orcid, $token, $action, $user_id, $item_id );
                        }
                }
	}


print STDERR "Orcid::Auth::perform_action called scope,[$scope,] orcid,[$orcid,] token,[$token,] action[$action] user[$user_id] item[$item_id]\n";
	#we now have the orcid id for the user so we can update the user and return to the profile screen
	my $orcid_field = $repo->config( "user_orcid_id_field" );
	my $ds = $repo->dataset( "user" );
	my $user = $ds->dataobj( $user_id );
	unless ( $user )
	{
		$repo->render_message( 'error', $repo->html_phrase( "cgi/orcid/auth:error:user_update_failed" ) );
	}

	my $return_url = $repo->config( 'userhome' );
	if ( $action eq "01" )
	{
		$user->set_value( $orcid_field, $orcid );
		$user->commit();
		$return_url .= "?screen=Workflow::Edit&dataset=user&dataobj=".$user_id."&stage=default";
	}
	elsif ( $action eq "02" )
	{
		$user->set_value( $orcid_field, $orcid );
		$user->commit();
		$return_url .= "?screen=User::Orcid::OrcidManager";

                # for this action we can set the affiliation

                my $add_token =  $user->get_value( "orcid_act_u_token" );
                $repo->redirect( $return_url ) unless $add_token;

                my $act_xml = $repo->call( "form_orcid_affiliation_xml", $repo, $user );
                my $add_act_url = $repo->config( "orcid_tier_2_api" );
                $add_act_url .= "v1.2/";
                $add_act_url .= $orcid;
                $add_act_url .= "/affiliations";

                my $req = HTTP::Request->new(POST => $add_act_url, );
                $req->header('content-type' => 'application/orcid+xml');
                $req->header('Authorization' => 'Bearer '.$add_token);

                # add POST data to HTTP request body
                $req->content(Encode::encode("utf8", $act_xml));

                my $ua = LWP::UserAgent->new;
                my $response = $ua->request($req);

                if ( $response->code > 299 )
                {

                        $self->{processor}->add_message( "message",
                                $self->html_phrase( "orcid_export_error", code=> $repo->xml->create_text_node($response->code) ) );
                }
                else
                {
                        $repo->render_message( 'message', $repo->html_phrase( "cgi/orcid/auth:added affiliation" ) );
                }

	}
	elsif ( $action eq "03" )
	{
		EPrints::DataObj::LoginTicket->expire_all( $repo );
		$repo->dataset( "loginticket" )->create_dataobj({
        		userid => $user_id,
		})->set_cookies();

		$return_url = $repo->config( 'userhome' );
	}

	$repo->redirect( $return_url );
	return 1;
}

1;


