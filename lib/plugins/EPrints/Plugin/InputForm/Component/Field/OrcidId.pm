=head1 NAME

EPrints::Plugin::InputForm::Component::Field::OrcidId

=cut

package EPrints::Plugin::InputForm::Component::Field::OrcidId;

use EPrints::Plugin::InputForm::Component::Field;

@ISA = ( "EPrints::Plugin::InputForm::Component::Field" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = "OrcidId";
	$self->{visible} = "all";

#	$self->{actions} = [qw/ create /];

	return $self;
}

	
sub render_content
{
	my( $self, $surround ) = @_;
	my $repo = $self->{session};
	my $xml = $repo->xml;
print STDERR "OrcidId::render_content called for [".$self->{config}->{field}->{name} ."]\n";
	
	my $value;
	if( $self->{dataobj} )
	{
		$value = $self->{dataobj}->get_value( $self->{config}->{field}->{name} );
	}
	else
	{
		$value = $self->{default};
	}

	my $frag = $repo->make_doc_fragment;
	my $table = $frag->appendChild( $xml->create_element( "table", class=>"ep_multi" ) );
	my $tr = $table->appendChild( $xml->create_element( "tr", class=>"ep_first" ) );
	my $th = $tr->appendChild( $xml->create_element( "th", class=>"ep_multi_heading" ) );
	my $td2 = $tr->appendChild( $xml->create_element( "td" ) );
	my $td3 = $tr->appendChild( $xml->create_element( "td" ) );


	$th->appendChild( $self->html_phrase( "title" ) );

	my $input_table = $td2->appendChild( $xml->create_element( "table", border=>"0", cellpadding=>"0", cellspacing=>"0", class=>"ep_form_input_grid" ) );
	my $tr_input = $input_table->appendChild( $xml->create_element( "tr" ) );
	my $td_input = $tr_input->appendChild( $xml->create_element( "td", valign=>"top" ) );



	$td_input->appendChild( $self->{config}->{field}->render_input_field( 
			$repo, 
			$value, 
			$self->{dataobj}->get_dataset,
			0, # staff mode should be detected from workflow
			undef,
			$self->{dataobj},
			$self->{prefix},
 	) );

	my $auth_url = $repo->call( "get_orcid_authorise_url", $repo, $self->{dataobj}->get_id(), 0, "authenticate" ); 

	my $user_name = $self->{dataobj}->get_value( "name" );
	my $user_email = $self->{dataobj}->get_value( "email" );
	$auth_url .= "&family_names=". $user_name->{family} if $user_name->{family};
	$auth_url .= "&given_names=". $user_name->{given} if $user_name->{given};

	# the javascript function appends the current orcid from the input text box or the email address
	# and then loads the url
	#my $link = $xml->create_element( "img", width=>100, height=>50, 
	#			src=>"/style/images/getorcid.png", 
	my $link = $xml->create_element( "img", width=>138, height=>50, 
				src=>"/style/images/getorcid_2.png", 
				style=>"float:right;",
				onclick=>"EPJS_appendOrcidIfSet( \'$self->{prefix}\', 
								\'$self->{config}->{field}->{name}\', 
								\'$auth_url\', 
								\'$user_email\' );" ,
			 	);
	$td3->appendChild( $link );

	return $frag;
}

sub render_title
{
	my( $self, $surround ) = @_;

	my $xml = $self->{repository}->xml;
	return $self->html_phrase( "title" );
}



1;


