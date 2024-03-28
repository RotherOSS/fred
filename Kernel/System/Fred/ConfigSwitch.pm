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

package Kernel::System::Fred::ConfigSwitch;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
);

=head1 NAME

Kernel::System::Fred::ConfigSwitch

=head1 SYNOPSIS

handle the config log data

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
And add the data to the module ref.

    $BackendObject->DataGet(
        ModuleRef => $ModuleRef,
    );

=cut

sub DataGet {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $Config = $ConfigObject->Get('Fred::ConfigSwitch');

    return if !$Config->{Settings};

    my @ConfigItems;
    for my $Item ( sort @{ $Config->{Settings} } ) {
        push @ConfigItems, {
            Key   => $Item,
            Value => $ConfigObject->Get($Item),
        };
    }

    $Param{ModuleRef}->{Data} = \@ConfigItems;

    return 1;
}

1;

=back
