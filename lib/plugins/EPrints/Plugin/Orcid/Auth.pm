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


########################################################################################
########################################################################################
sub perform_action
{
	my( $self, $scope, $orcid, $token, $action, $user_id, $item_id ) = @_;

	my $repo = $self->{repository};

        # store the token for the scopes requested
        my @scopes = split " ", $scope;
        foreach my $s ( @scopes )
        {
                $self->store_token_for_scope( $s, $orcid, $token, $user_id );
	}

#print STDERR "Orcid::Auth::perform_action called scope,[$scope,] orcid,[$orcid,] token,[$token,] action[$action] user[$user_id] item[$item_id]\n";
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
		$self->set_affiliation( $user, $orcid );
	}
	elsif ( $action eq "03" )
	{
		my $user_orcid = $user->get_value( $orcid_field );
		my $login_allowed = $user->get_value( "allow_orcid_login" );
	
		if ( $user_orcid && $orcid && $user_orcid eq $orcid && $login_allowed eq "TRUE" )
		{
			EPrints::DataObj::LoginTicket->expire_all( $repo );
			$repo->dataset( "loginticket" )->create_dataobj({
        			userid => $user_id,
			})->set_cookies();

			$return_url = $repo->config( 'userhome' );
		}
		else
		{
			$repo->render_message( 'message', $repo->html_phrase( "Plugin/Screen/Login/OrcidLogin:not_allowed", 
								orcid=>$repo->xml->create_text_node($orcid) ) );
		}
	}
	elsif ( $action eq "04" )
	{
		#$user->set_value( $orcid_field, $orcid );
		#$user->commit();
		$return_url .= "?screen=User::Orcid::OrcidManager";
	}

	$repo->redirect( $return_url );
	return 1;
}


########################################################################################
## This routine attempts to set the affiliation for the user on their ORCID record
## If an existing employment put code is found then the existing record will be updated
## if no put code is found then a new record will be created.
## If successful the new put code will be stored on the users details.
########################################################################################
sub set_affiliation
{
	my ( $self, $user, $orcid ) = @_;
	my $repo = $self->{repository};
	my $scope_map = $repo->config( "orcid_scope_map" );
	my $add_token_field = $scope_map->{"/activities/update"} if $scope_map;
        my $add_token =  $user->get_value( $add_token_field ) if $add_token_field;
	my $read_token_field = $scope_map->{"/read-limited"} if $scope_map;
        my $read_token =  $user->get_value( $read_token_field ) if $read_token_field;

	return unless $add_token && $read_token;

	# check for an existing put code so we can prevent duplicate entries
	my $put_code_type = "employment";
	my $put_code = $self->get_valid_put_code( $user, $orcid, $put_code_type, "/employments" ); 
#print STDERR "set_affiliation GOT put code [".$put_code."]####################\n";

        my $act_xml = $repo->call( "form_orcid_affiliation_xml", $repo, $user, $put_code );
        my $add_act_url = $repo->config( "orcid_member_api" );
        $add_act_url .= "v".$repo->config( "orcid_version" )."/";
        $add_act_url .= $orcid;
        $add_act_url .= "/employment";

	my $req;
	if ( $put_code )
	{
               	$add_act_url .= "/".$put_code;
#print STDERR "send put request to  [".$add_act_url."]####################\n";
               	$req = HTTP::Request->new(PUT => $add_act_url, );
	}
	else
	{
               	$req = HTTP::Request->new(POST => $add_act_url, );
	}
        $req->header('content-type' => 'application/orcid+xml');
        $req->header('Authorization' => 'Bearer '.$add_token);

        # add POST data to HTTP request body
        $req->content(Encode::encode("utf8", $act_xml));

        my $ua = LWP::UserAgent->new;
        my $response = $ua->request($req);
#print STDERR "Response \n\n\n[".Data::Dumper::Dumper($response)."]\n";

	if ( $response->code == 201 )
	{
		# Success: get the msg and the put code
#print STDERR "Response \n\n\n code[".$response->code."] msg[".$response->message()."] put code[".$response->header("location")."]\n";
		if ( $response->message() eq 'Created' && $response->header("location") =~ /\/$orcid\/$put_code_type\/(\d+)$/ )
		{
#print STDERR "got put code [".$1."]for type[".$put_code_type."] \n";
			my $this_code = $1;
			$self->save_put_code( $user, $put_code_type, $this_code );
		}
		$repo->render_message( 'message', $repo->html_phrase( "cgi/orcid/auth:added affiliation" ) );
	}
        else
        {
        	$repo->render_message( "message", $self->html_phrase( "orcid_export_error", 
								code=> $repo->xml->create_text_node($response->code) ) );
        }
	return;
}




1;


