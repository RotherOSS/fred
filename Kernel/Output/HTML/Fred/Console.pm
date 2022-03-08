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

package Kernel::Output::HTML::Fred::Console;

use v5.24;
use strict;
use warnings;

# core modules
use Cwd;

# CPAN modules
use Path::Class qw(file);
use Text::Trim qw(trim);

# OTOBO moduels

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Log',
);

=head1 NAME

Kernel::Output::HTML::Fred::Console - layout backend module

=head1 SYNOPSIS

All layout functions of console object

=over 4

=cut

=item new()

create an object

    $BackendObject = Kernel::Output::HTML::FredConsole->new(
        %Param,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    return bless {}, $Type;
}

=item CreateFredOutput()

create the output of the STDERR log

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

    # create the console table
    my $Console = 'Activated modules: <strong>'
        . ( join ' - ', @{ $Param{ModuleRef}->{Data} } )
        . '</strong>';

    return 1 unless $Param{ModuleRef}->{Status};

    if ( $Param{ModuleRef}->{Setting} ) {
        $Kernel::OM->Get('Kernel::Output::HTML::Layout')->Block(
            Name => 'Setting',
        );
    }

    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
    my $Home            = $ConfigObject->Get('Home');
    my $SystemName      = $ConfigObject->Get('Fred::SystemName')      || $Home;
    my $OTOBOVersion    = $ConfigObject->Get('Version')               || 'Version unknown';
    my $BackgroundColor = $ConfigObject->Get('Fred::BackgroundColor') || 'red';

    # Add git info to output
    my $BranchName;
    {
        if ( -d "$Home/.git" ) {
            my $OldWorkingDir = getcwd();
            chdir($Home);
            my $GitResult = `git branch`;
            chdir($OldWorkingDir);

            if ($GitResult) {
                ($BranchName) = $GitResult =~ m/^[*] \s+ (\S+)/xms;
            }
        }

        # Look in the git-* files as fallback. These are usually available in the Docker images.
        if ( !$BranchName && -r "$Home/git-branch.txt" ) {
            $BranchName = file("$Home/git-branch.txt")->slurp;
            trim $BranchName;
        }

        $BranchName ||= 'could not be detected';
    }

    # Derive more info from the branch name
    my ( $BranchClass, $BugNumber );

    if ( $BranchName eq 'master' ) {
        $BranchClass = 'Warning';
    }
    elsif ( $BranchName =~ m{bug-((\d){1,6}).*} ) {
        $BugNumber = $1;
    }

    $Param{ModuleRef}->{Output} = $Kernel::OM->Get('Kernel::Output::HTML::Layout')->Output(
        TemplateFile => 'DevelFredConsole',
        Data         => {
            Text            => $Console,
            ModPerl         => _ModPerl(),
            Perl            => sprintf( "%vd", $^V ),
            SystemName      => $SystemName,
            OTOBOVersion    => $OTOBOVersion,
            BranchName      => $BranchName,
            BranchClass     => $BranchClass,
            BackgroundColor => $BackgroundColor,
            BugNumber       => $BugNumber,
        },
    );

    return 1;
}

sub _ModPerl {

    # find out, if modperl is used
    # disregard $ENV{MOD_PERL} as it is not sure whether Plack::Handler::Apache2 sets this variable
    return $mod_perl::VERSION // 'not active';
}

1;

=back
