package EPrints::Plugin::Screen::EPMC::Orcidt2;

@ISA = ( 'EPrints::Plugin::Screen::EPMC' );

use strict;
# Make the plug-in
sub new
{
      my( $class, %params ) = @_;

      my $self = $class->SUPER::new( %params );

      $self->{actions} = [qw( enable disable )];
      $self->{disable} = 0; # always enabled, even in lib/plugins

      $self->{package_name} = 'orcidt2';

      return $self;
}

=item $screen->action_enable( [ SKIP_RELOAD ] )

Enable the L<EPrints::DataObj::EPM> for the current repository.

If SKIP_RELOAD is true will not reload the repository configuration.

=cut

sub action_enable
{
        my( $self, $skip_reload ) = @_;

        $self->SUPER::action_enable( $skip_reload );
        my $repo = $self->{repository};

	#my $filename = $repo->config( "config_path" )."/workflows/user/default.xml";
        #my $insert = EPrints::XML::parse_xml( $repo->config( "lib_path" )."/workflows/user/orcid_claim.xml" );
        #EPrints::XML::add_to_xml( $filename, $insert->documentElement(), $self->{package_name} );

        $self->reload_config if !$skip_reload;
}

=item $screen->action_disable( [ SKIP_RELOAD ] )

Disable the L<EPrints::DataObj::EPM> for the current repository.

If SKIP_RELOAD is true will not reload the repository configuration.

=cut

sub action_disable
{
        my( $self, $skip_reload ) = @_;

        $self->SUPER::action_disable( $skip_reload );
        my $repo = $self->{repository};

	#my $filename = $repo->config( "config_path" )."/workflows/user/default.xml";
        #EPrints::XML::remove_package_from_xml( $filename, $self->{package_name} );

        $self->reload_config if !$skip_reload;
}

#sub render_messages
#{
#	my( $self ) = @_;
#
#	my $repo = $self->{repository};
#	my $xml = $repo->xml;
#
#	my $frag = $xml->create_document_fragment;
#	$frag->appendChild( $repo->render_message( 'message', $self->html_phrase( 'ready' ) ) );
#
#	return $frag;
#}


