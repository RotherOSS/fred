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
use Cwd qw(getcwd);

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

    # Add git info to the output.
    my ( $GitBranch, $GitRepo, $GitCommit );
    {
        if ( -d "$Home/.git" ) {
            my $OldWorkingDir = getcwd();
            chdir $Home;
            $GitBranch = `git branch --show-current`;
            $GitRepo   = `git config --get remote.origin.url`;
            $GitCommit = `git log --pretty=format:'%H' -n 1`;
            chdir $OldWorkingDir;
        }

        # Look in the git-* files as fallback. These are usually available in the Docker images.
        if ( !$GitBranch && -r "$Home/git-branch.txt" ) {
            $GitBranch = file("$Home/git-branch.txt")->slurp;
            trim $GitBranch;
        }
        if ( !$GitRepo && -r "$Home/git-repo.txt" ) {
            $GitRepo = file("$Home/git-repo.txt")->slurp;
            trim $GitRepo;
        }
        if ( !$GitCommit && -r "$Home/git-commit.txt" ) {
            $GitCommit = file("$Home/git-commit.txt")->slurp;
            trim $GitCommit;
        }

        $GitBranch ||= 'Git branch could not be detected';
        $GitRepo   ||= 'Git repo could not be detected';
        $GitCommit ||= 'Git commit could not be detected';
    }

    # Warn when not in an issue branch
    my ($IssueNumber) = $GitBranch =~ m{^issue-#(\d+)-};
    my $BranchClass = defined $IssueNumber ? '' : 'Warning';

    $Param{ModuleRef}->{Output} = $Kernel::OM->Get('Kernel::Output::HTML::Layout')->Output(
        TemplateFile => 'DevelFredConsole',
        Data         => {
            Text            => $Console,
            ModPerl         => _ModPerl(),
            Perl            => sprintf( '%vd', $^V ),
            SystemName      => $SystemName,
            OTOBOVersion    => $OTOBOVersion,
            GitBranch       => $GitBranch,
            GitRepo         => $GitRepo,
            GitCommit       => $GitCommit,
            IssueNumber     => $IssueNumber,
            BranchClass     => $BranchClass,
            BackgroundColor => $BackgroundColor,
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
