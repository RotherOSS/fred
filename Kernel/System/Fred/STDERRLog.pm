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

package Kernel::System::Fred::STDERRLog;

use v5.24;
use strict;
use warnings;

# core modules
use IO::Handle;

# CPAN modules

# OTOBO modules

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
);

=head1 NAME

Kernel::System::Fred::STDERRLog

=head1 SYNOPSIS

handle the STDERR log data

=over 4

=cut

=item new()

create an object

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    return bless {}, $Type;
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

    # check needed stuff
    for my $Needed (qw(ModuleRef)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return;
        }
    }

    # Make sure that we get everything to disk before trying to read it (otherwise content could be lost).
    STDERR->flush();

    ## no critic(Perl::Critic::Policy::OTOBO::ProhibitOpen)
    # open the STDERR.log file to get the STDERR messages
    my $File = $Kernel::OM->Get('Kernel::Config')->Get('Home') . '/var/fred/STDERR.log';
    my $Filehandle;
    if ( !open $Filehandle, '<:encoding(UTF-8)', $File ) {
        $Param{ModuleRef}->{Data} = [
            "Perhaps you don't have permission at /var/fred/ or /Kernel/Config/Files/AAAFred.pm.",
            "Can't read /var/fred/STDERR.log",
        ];

        return;
    }

    # Read log in reverse until last "FRED" marker.
    my @LogMessages;
    LINE:
    for my $Line ( reverse <$Filehandle> ) {
        last LINE if $Line =~ m{ \A \s* FRED \s* \z}xms;

        push @LogMessages, $Line;
    }
    close $Filehandle;

    print STDERR "\nFRED\n";

    # left trim the log message array
    while ( @LogMessages && $LogMessages[0] =~ m{ \A \s* \z }xms ) {
        shift @LogMessages;
    }

    # right trim the log message array
    while ( @LogMessages && $LogMessages[-1] =~ m{ \A \s* \z }xms ) {
        pop @LogMessages;
    }

    # still in reverse
    $Param{ModuleRef}->{Data} = \@LogMessages;

    return 1;
}

1;

=back
