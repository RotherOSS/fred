# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2022 Rother OSS GmbH, https://otobo.de/
# --
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# --

package Kernel::Output::HTML::FilterContent::Fred;

use v5.24;
use strict;
use warnings;

# core modules
use URI::Escape;

# CPAN modules

# OTOBO modules

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Fred',
    'Kernel::System::Web::Response',
);

=head1 NAME

Kernel::Output::HTML::FilterContent::Fred

=head1 SYNOPSIS

a output filter module specially for developer

=head1 PUBLIC INTERFACE

=over 4

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # perhaps no output is generated
    die 'Fred: At the moment, your code generates no output!' unless $Param{Data};

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # do not show the debug bar in Fred's setting window
    return 1 if ( $LayoutObject->{Action} && $LayoutObject->{Action} eq 'DevelFred' );

    # Do nothing if output is an attachment download or AJAX request.
    # Note that in OTOBO 10.1. the headers are no longer part of the data. Therefore inspect
    # the global response object for checking headers.
    {
        my $ResponseObject = $Kernel::OM->Get('Kernel::System::Web::Response');

        return 1 if $ResponseObject->Header('Content-Disposition') =~ m/^(?:inline|attachment)/i;
    }

    # No check for redirects are needed as redirects circumvent the output filters.

    # do nothing if it is fred itself
    if ( $Param{Data}->$* =~ m{Fred-Setting<\/title>}msx ) {
        print STDERR "CHANGE FRED SETTING\n";

        return 1;
    }

    # do nothing if it does not contain the <html> element, might be
    # an embedded layout rendering
    return 1 unless $Param{Data}->$* =~ m{<html[^>]*>}msx;

    # get data of the activated modules
    my $ConfigObject   = $Kernel::OM->Get('Kernel::Config');
    my $ModuleForRef   = $ConfigObject->Get('Fred::Module');
    my $ModulesDataRef = {};
    for my $Module ( sort keys %{$ModuleForRef} ) {
        if ( $ModuleForRef->{$Module}->{Active} ) {
            $ModulesDataRef->{$Module} = {};
        }
    }

    for my $ModuleName ( sort keys %{$ModulesDataRef} ) {

        $Kernel::OM->Get( 'Kernel::System::Fred::' . $ModuleName )->DataGet(
            ModuleRef      => $ModulesDataRef->{$ModuleName},
            HTMLDataRef    => $Param{Data},
            FredModulesRef => $ModulesDataRef,
        );

        $Kernel::OM->Get( 'Kernel::Output::HTML::Fred::' . $ModuleName )->CreateFredOutput(
            ModuleRef => $ModulesDataRef->{$ModuleName},
        );
    }

    # build the content string
    my $Output = '';
    if ( $ModulesDataRef->{Console}->{Output} ) {
        $Output .= $ModulesDataRef->{Console}->{Output};
        delete $ModulesDataRef->{Console};
    }
    for my $Module ( sort keys %{$ModulesDataRef} ) {
        $Output .= $ModulesDataRef->{$Module}->{Output} || '';
    }

    my $JSOutput = '';
    $Output =~ s{(<script.+?/script>)}{
        $JSOutput .= $1;
        "";
    }smxeg;

    # Put output in the Fred Container
    $Output = $LayoutObject->Output(
        TemplateFile => 'DevelFredContainer',
        Data         => {
            Data => $Output
        },
    );

    # include the fred output in the original output
    if ( $Param{Data}->$* !~ s/(\<body(|.+?)\>)/$1\n$Output\n\n\n\n/mx ) {
        $Param{Data}->$* =~ s/^(.)/\n$Output\n\n\n\n$1/mx;
    }

    return unless $LayoutObject->{UserID};

    # add fred icon to header
    my $Active = $ConfigObject->Get('Fred::Active') || 0;
    my $Class  = $Active ? 'FredActive' : '';
    $Param{Data}->$* =~ s{ <div [^>]* id="header" [^>]*> }{
        $&

        <div class="DevelFredToggleContainer">
            <a id="DevelFredToggleContainerLink" class="$Class" href="#">F</a>
        </div>
    }xmsig;
    $Param{Data}->$* =~ s{ (<body [^>]* class=" [^"]*) ( " [^>]*> ) }{ $1 $Class $2 }xmsig;

    # Inject JS at the end of the body
    $Param{Data}->$* =~ s{</body>}{$JSOutput\n\t</body>}smx;

    return 1;
}

1;

=back
