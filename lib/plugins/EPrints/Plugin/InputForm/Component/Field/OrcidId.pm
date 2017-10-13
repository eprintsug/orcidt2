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

	return $self;
}

=begin InternalDoc

=over

=item update_from_form ( $self, $processor )

=back

override this method so that we can process the remove button. Calling the super function
allows the value to be specified in the input field. This may not be a very good idea.
it is probably true to say that there should not actually be an input field for this
component

=end InternalDoc

=cut

sub update_from_form
{
        my( $self, $processor ) = @_;
        my $field = $self->{config}->{field};
        my $session = $self->{session};
        my $prefix = $self->{prefix};

        my $ibutton = $self->get_internal_button;
        my $ibutton_pressed = $session->internal_button_pressed;
	if ( $ibutton =~ m/^orcid_remove$/ )
	{
		$self->{dataobj}->set_value( $field->get_name, "" );
		return;
	}
	return $self->SUPER::update_from_form();
}

=begin InternalDoc

=over

=item render_content ( $self, $surround )

=back

Render the details of this workflow component
this renders the title, the input field and the conect button
if the orcid id is already set for this user then the input field is not editable
and the button is disabled

=end InternalDoc

=cut

sub render_content
{
	my( $self, $surround ) = @_;
	my $repo = $self->{session};
	my $xml = $repo->xml;
	
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


	if ( $value )
	{
		my $fieldname = $self->{prefix}."_".$self->{config}->{field}->name;

		$td_input->appendChild( $repo->render_hidden_field( $fieldname, $value ) );
		$td_input->appendChild( $repo->call( "render_orcid_id", $repo, $value ) );
                $td_input->appendChild( $repo->make_element(
                                        "input",
                                        type=>"image",
                                       # src=> "/style/images/action_remove.png",
                                        src=> "/style/images/delete.png",
                                        alt=>"Remove",
                                        title=>"Remove",
                                        name=>"_internal_".$self->{prefix}."_orcid_remove",
                                        class => "epjs_ajax",
					id => "delete-orcid-button",
                                       value=>"1" ));

		my $button = $td3->appendChild( $xml->create_element( "button", 
					id => "disabled-connect-orcid-button",
					type => "button",
					disabled => "true"
					) );
		$button->appendChild( $xml->create_element( "img", 
			id =>"orcid-id-logo-24", 
			src =>"/style/images/orcid_24x24.png", 
			alt =>"ORCID logo" ) );
					
		$button->appendChild( $repo->html_phrase( "orcid_connect_btn:title" ) );
	}
	else
	{
		$td_input->appendChild( $self->{config}->{field}->render_input_field( 
			$repo, 
			$value, 
			$self->{dataobj}->get_dataset,
			0, # staff mode should be detected from workflow
			undef,
			$self->{dataobj},
			$self->{prefix},
 		) );

		my $activity = "02"; # user_authenticate
		my $scope = "/authenticate /activities/update /person/update /read-limited";
		my $auth_url = $repo->call( "get_orcid_authorise_url", $repo, $self->{dataobj}->get_id(), 0, $scope, $activity ); 
		my $user_name = $self->{dataobj}->get_value( "name" );
		my $user_email = $self->{dataobj}->get_value( "email" );
		$auth_url .= "&family_names=". $user_name->{family} if $user_name->{family};
		$auth_url .= "&given_names=". $user_name->{given} if $user_name->{given};

		# the javascript function appends the current orcid from the input text box or the email address
		# and then loads the url
		my $button = $td3->appendChild( $xml->create_element( "button", 
					id => "connect-orcid-button",
					type => "button",
					onclick => "EPJS_appendOrcidIfSet( \'$self->{prefix}\', 
								\'$self->{config}->{field}->{name}\', 
								\'$auth_url\', 
								\'$user_email\' );" ,
	
					) );
		$button->appendChild( $xml->create_element( "img", 
			id =>"orcid-id-logo", 
			src =>"/style/images/orcid_24x24.png", 
			alt =>"ORCID logo" ) );
		$button->appendChild( $repo->html_phrase( "orcid_connect_btn:title" ) );
	}

	return $frag;
}

=begin InternalDoc

=over

=item render_title ( $self, $surround )

=back

Render the field title

=end InternalDoc

=cut

sub render_title
{
	my( $self, $surround ) = @_;

	my $xml = $self->{repository}->xml;
	return $self->html_phrase( "title" );
}


1;


