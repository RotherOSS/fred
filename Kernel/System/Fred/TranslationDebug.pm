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

package Kernel::System::Fred::TranslationDebug;
## no critic(Perl::Critic::Policy::OTOBO::ProhibitOpen)

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
);

=head1 NAME

Kernel::System::Fred::TranslationDebug

=head1 SYNOPSIS

handle the translation debug data

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

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    if (
        ref $ConfigObject->Get('Fred::Module')
        && $ConfigObject->Get('Fred::Module')->{TranslationDebug}
        )
    {
        $Self->{Active} = $ConfigObject->Get('Fred::Module')->{TranslationDebug}->{Active};
    }

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

    # open the TranslationDebug.log file to get the untranslated words
    my $File = $Kernel::OM->Get('Kernel::Config')->Get('Home') . '/var/fred/TranslationDebug.log';
    my $Filehandle;
    if ( !open $Filehandle, '<:encoding(UTF-8)', $File ) {
        $Param{ModuleRef}->{Data} = ["Can't read /var/fred/TranslationDebug.log"];
        return;
    }

    # get distinct entries from TranslationDebug.log
    # till the last 'FRED' entry
    my %LogLines;
    LINE:
    for my $Line ( reverse <$Filehandle> ) {
        last LINE if $Line =~ /FRED/;

        chomp $Line;
        next LINE if $Line eq '';

        # skip duplicate entries
        next LINE if $LogLines{$Line};

        $LogLines{$Line} = 1;
    }
    close $Filehandle;

    $Self->InsertWord( What => "FRED\n" );

    my @LogLines = sort { $a cmp $b } keys %LogLines;
    $Param{ModuleRef}->{Data} = \@LogLines;

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

    return if ( !$Self->{Active} );

    # check needed stuff
    if ( !defined( $Param{What} ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need What!',
        );
        return;
    }

    # save the word in log file
    my $File = $Kernel::OM->Get('Kernel::Config')->Get('Home') . '/var/fred/TranslationDebug.log';
    open my $Filehandle, '>>:encoding(UTF-8)', $File || die "Can't write $File !\n";
    print $Filehandle $Param{What} . "\n";
    close $Filehandle;

    return 1;
}

1;

=back
