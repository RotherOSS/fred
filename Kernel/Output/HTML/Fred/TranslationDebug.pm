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

package Kernel::Output::HTML::Fred::TranslationDebug;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Log',
);

=head1 NAME

Kernel::Output::HTML::Fred::TranslationDebug - layout backend module

=head1 SYNOPSIS

All layout functions of translation debug module

=over 4

=cut

=item new()

create an object

    $BackendObject = Kernel::Output::HTML::FredTranslationDebug->new(
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

create the output of the translation debugging log

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

    my $HTMLLines = '';
    for my $Line ( @{ $Param{ModuleRef}->{Data} } ) {
        $HTMLLines .= "<span>$Line</span>";
    }

    return 1 if !$HTMLLines;

    $Param{ModuleRef}->{Output} = $Kernel::OM->Get('Kernel::Output::HTML::Layout')->Output(
        TemplateFile => 'DevelFredTranslationDebug',
        Data         => {
            HTMLLines => $HTMLLines,
        },
    );

    return 1;
}

1;

=back
