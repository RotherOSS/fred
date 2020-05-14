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

package Kernel::System::Fred::Console;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Log',
);

=head1 NAME

Kernel::System::Fred::Console

=head1 SYNOPSIS

gives you all functions which are needed for the FRED-console

=over 4

=cut

=item new()

create an object

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item DataGet()

Get the data for this Fred module. Returns true or false.
And adds the data to the module ref.

    $BackendObject->DataGet(
        ModuleRef => $ModuleRef,
    );

=cut

sub DataGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Ref (qw(ModuleRef HTMLDataRef FredModulesRef)) {
        if ( !$Param{$Ref} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Ref!",
            );
            return;
        }
    }

    my @Modules;
    for my $Module ( sort keys %{ $Param{FredModulesRef} } ) {
        if ( $Module ne 'Console' ) {
            push @Modules, $Module;
        }
    }
    $Param{ModuleRef}->{Data} = \@Modules;

    if ( ${ $Param{HTMLDataRef} } !~ m/Fred-Setting/ && ${ $Param{HTMLDataRef} } =~ /\<body.*?\>/ )
    {
        $Param{ModuleRef}->{Status} = 1;
    }

    if ( ${ $Param{HTMLDataRef} } !~ m/name="Action" value="Login"/ ) {
        $Param{ModuleRef}->{Setting} = 1;
    }

    return 1;
}

1;

=back
