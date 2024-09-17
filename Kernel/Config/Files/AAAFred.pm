# OTOBO config file (automatically generated)
# VERSION:1.1
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

package Kernel::Config::Files::AAAFred;

use v5.24;
use strict;
no warnings 'redefine';    ## no critic qw(TestingAndDebugging::ProhibitNoWarnings)

# core modules

# CPAN modules

# OTOBO modules
use Kernel::Config::Defaults;
use Kernel::Language;
use Kernel::System::Fred::ConfigLog;
use Kernel::System::Fred::SQLLog;
use Kernel::System::Fred::TranslationDebug;

our $ObjectManagerDisabled = 1;

sub Load {
    my ( $File, $Self ) = @_;

    if ( $ENV{GATEWAY_INTERFACE} ) {

        # check if the needed path is available
        my $Path = $Self->{Home} . '/var/fred';
        if ( !-e $Path ) {
            mkdir $Path;
        }

        my $File = $Self->{Home} . '/var/fred/STDERR.log';

        # check log file size
        if ( -s $File > 20 * 1024 * 1024 ) {
            unlink $File;
        }

        # move STDOUT to tmp file
        ## no critic qw(OTOBO::ProhibitOpen)
        if ( !open STDERR, '>>', $File ) {
            print STDERR "ERROR: Can't write $File!";
        }
    }

    # disable redefine warnings in this scope
    {
        no warnings 'redefine';               ## no critic qw(TestingAndDebugging::ProhibitNoWarnings)

        # Override Kernel::Language::Get() method to intercept missing translations
        if ( Kernel::Language->can('Get') && !Kernel::Language->can('GetOriginal') ) {
            *Kernel::Language::GetOriginal = \&Kernel::Language::Get;
            *Kernel::Language::Get         = sub {
                my ( $Self, $What ) = @_;

                return    if !defined $What;
                return '' if $What eq '';

                my $Result = $Self->GetOriginal($What);

                if ( $What && $What =~ /^(.+?)",\s{0,1}"(.*?)$/ ) {
                    $What = $1;
                }

                if ( !$Self->{Translation}->{$What} ) {
                    $Self->{TranslationDebugObject} ||= Kernel::System::Fred::TranslationDebug->new();
                    $Self->{TranslationDebugObject}->InsertWord( What => $What );
                }

                return $Result;
            };
        }

        # Override Kernel::Language::Translate() method to intercept missing translations
        if ( Kernel::Language->can('Translate') && !Kernel::Language->can('TranslateOriginal') ) {
            *Kernel::Language::TranslateOriginal = \&Kernel::Language::Translate;
            *Kernel::Language::Translate         = sub {
                my ( $Self, $Text, @Parameters ) = @_;

                if ( $Text && !$Self->{Translation}->{$Text} ) {
                    $Self->{TranslationDebugObject} ||= Kernel::System::Fred::TranslationDebug->new();
                    $Self->{TranslationDebugObject}->InsertWord( What => $Text );
                }

                return $Self->TranslateOriginal( $Text, @Parameters );
            };
        }

        # Override Kernel::System::DB::Prepare() method to intercept database calls
        if ( Kernel::System::DB->can('Prepare') && !Kernel::System::DB->can('PrepareOriginal') ) {
            *Kernel::System::DB::PrepareOriginal = \&Kernel::System::DB::Prepare;
            *Kernel::System::DB::Prepare         = sub {
                my ( $Self, %Param ) = @_;

                $Self->{SQLLogObject} ||= Kernel::System::Fred::SQLLog->new();
                $Self->{SQLLogObject}->PreStatement(%Param);
                my $Result = $Self->PrepareOriginal(%Param);
                $Self->{SQLLogObject}->PostStatement(%Param);

                return $Result;
            };
        }

        # Override Kernel::System::DB::Do() method to intercept database calls
        if ( Kernel::System::DB->can('Do') && !Kernel::System::DB->can('DoOriginal') ) {
            *Kernel::System::DB::DoOriginal = \&Kernel::System::DB::Do;
            *Kernel::System::DB::Do         = sub {
                my ( $Self, %Param ) = @_;

                $Self->{SQLLogObject} ||= Kernel::System::Fred::SQLLog->new();
                $Self->{SQLLogObject}->PreStatement(%Param);
                my $Result = $Self->DoOriginal(%Param);
                $Self->{SQLLogObject}->PostStatement(%Param);

                return $Result;
            };
        }

        # Override Kernel::Config::Get() method to intercept config strings
        if ( Kernel::Config::Defaults->can('Get') && !Kernel::Config::Defaults->can('GetOriginal') ) {
            *Kernel::Config::Defaults::GetOriginal = \&Kernel::Config::Defaults::Get;
            *Kernel::Config::Defaults::Get         = sub {
                my ( $Self, $What ) = @_;

                $Self->{ConfigLogObject} ||= Kernel::System::Fred::ConfigLog->new();
                my $Caller = caller();
                if ( $Self->{$What} ) {
                    $Self->{ConfigLogObject}->InsertWord(
                        What => "$What;True;$Caller;",
                        Home => $Self->{Home}
                    );
                }
                else {
                    $Self->{ConfigLogObject}->InsertWord(
                        What => "$What;False;$Caller;",
                        Home => $Self->{Home}
                    );
                }

                return $Self->GetOriginal($What);
            };
        }
    }

    return;
}

1;
