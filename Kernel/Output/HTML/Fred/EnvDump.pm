# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2024 Rother OSS GmbH, https://otobo.de/
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

package Kernel::Output::HTML::Fred::EnvDump;
## nofilter(TidyAll::Plugin::OTOBO::Perl::Dumper)

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Log',
);

=head1 NAME

Kernel::Output::HTML::Fred::EnvDump - show dump of the environment ref, data for $Env in dtl

=head1 SYNOPSIS

All layout functions of the layout environment dump object

=over 4

=cut

=item new()

create an object

    $BackendObject = Kernel::Output::HTML::FredEnvDump->new(
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

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # Kernel::System::Fred::EnvDump::DataGet() is not used,
    # as the data of interest is not easily available there.
    for my $Key ( sort keys %{ $LayoutObject->{EnvRef} } ) {

        $LayoutObject->Block(
            Name => 'EnvDataRow',
            Data => {
                Key   => $Key,
                Value => $LayoutObject->{EnvRef}->{$Key},
            },
        );
    }

    # output the html
    $Param{ModuleRef}->{Output} = $LayoutObject->Output(
        TemplateFile => 'DevelFredEnvDump',
    );

    return 1;
}

1;

=back
