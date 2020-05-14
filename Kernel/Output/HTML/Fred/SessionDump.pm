# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2020 Rother OSS GmbH, https://otobo.de/
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

package Kernel::Output::HTML::Fred::SessionDump;
## nofilter(TidyAll::Plugin::OTOBO::Perl::Dumper)

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Output::HTML::Layout',
    'Kernel::System::AuthSession',
    'Kernel::System::Log',
);

use Data::Dumper;

=head1 NAME

Kernel::Output::HTML::Fred::SessionDump - layout backend module

=head1 SYNOPSIS

All layout functions of the session dump object

=over 4

=cut

=item new()

create an object

    $BackendObject = Kernel::Output::HTML::FredSessionDump->new(
        %Param,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item CreateFredOutput()

Get the session data and create the output of the session dump

    $LayoutObject->CreateFredOutput(
        ModulesRef => $ModulesRef,
    );

=cut

sub CreateFredOutput {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ModuleRef} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ModuleRef!',
        );
        return;
    }

    my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $SessionObject = $Kernel::OM->Get('Kernel::System::AuthSession');

    # Data is generated here, as it is not available in Kernel::System::Fred::SessionDump
    my $SessionID = $LayoutObject->{EnvRef}->{SessionID};
    my %SessionData;
    if ($SessionID) {
        %SessionData = $SessionObject->GetSessionIDData( SessionID => $SessionID );
    }

    for my $Key ( sort keys %SessionData ) {

        $LayoutObject->Block(
            Name => 'SessionDataRow',
            Data => {
                Key   => $Key,
                Value => $SessionData{$Key},
            },
        );
    }

    # output the html
    $Param{ModuleRef}->{Output} = $LayoutObject->Output(
        TemplateFile => 'DevelFredSessionDump',
    );

    return 1;
}

1;

=back
