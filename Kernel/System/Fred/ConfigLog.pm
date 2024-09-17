# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2024 Rother OSS GmbH, https://otobo.io/
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

package Kernel::System::Fred::ConfigLog;
## no critic(Perl::Critic::Policy::OTOBO::ProhibitOpen)

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
);

=head1 NAME

Kernel::System::Fred::ConfigLog

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

    my @LogMessages;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # open the TranslationDebug.log file to get the untranslated words
    my $File = $ConfigObject->Get('Home') . '/var/fred/Config.log';
    my $Filehandle;
    if ( !open $Filehandle, '<', $File ) {
        print STDERR "Can't read /var/fred/Config.log\n";
        return;
    }
    LINE:
    for my $Line ( reverse <$Filehandle> ) {
        last LINE if $Line =~ /FRED/;
        push @LogMessages, $Line;
    }
    close $Filehandle;
    pop @LogMessages;
    $Self->InsertWord( What => "FRED\n" );

    my %IndividualConfig = ();

    for my $Line (@LogMessages) {
        $Line =~ s/\n//;
        $IndividualConfig{$Line}++;
    }

    @LogMessages = ();
    for my $Line ( sort keys %IndividualConfig ) {
        my @SplitedLine = split /;/, $Line;
        push @SplitedLine, $IndividualConfig{$Line};
        push @LogMessages, \@SplitedLine;
    }

    # sort the data
    my $Config  = $ConfigObject->Get('Fred::ConfigLog');
    my $OrderBy = defined( $Config->{OrderBy} ) ? $Config->{OrderBy} : 3;
    if ( $OrderBy == 3 ) {
        @LogMessages = sort { $b->[$OrderBy] <=> $a->[$OrderBy] } @LogMessages;
    }
    else {
        @LogMessages = sort { $a->[$OrderBy] cmp $b->[$OrderBy] } @LogMessages;
    }

    $Param{ModuleRef}->{Data} = \@LogMessages;
    return 1;
}

=item InsertWord()

Save a word in the translation debug log

    $BackendObject->InsertWord(
        What => 'a word',
    );

=cut

sub InsertWord {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $FredSettings = $ConfigObject->GetOriginal('Fred::Module');

    if ( !$FredSettings || !$FredSettings->{ConfigLog} || !$FredSettings->{ConfigLog}->{Active} ) {
        return;
    }

    if ( !$Param{Home} ) {
        $Param{Home} = $ConfigObject->GetOriginal('Home');
    }

    # save the word in log file
    my $File = $Param{Home} . '/var/fred/Config.log';
    open my $Filehandle, '>>', $File || die "Can't write $File !\n";
    print $Filehandle $Param{What} . "\n";
    close $Filehandle;

    return 1;
}

1;

=back
