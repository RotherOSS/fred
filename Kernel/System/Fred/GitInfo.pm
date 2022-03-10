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

package Kernel::System::Fred::GitInfo;

use v5.24;
use strict;
use warnings;

# core modules

# CPAN modules
use Path::Class qw(file);
use Text::Trim qw(trim);

# OTOBO modules

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
);

=head1 NAME

Kernel::System::Fred::GitInfo

=head1 SYNOPSIS

collect info about the Git sandbox

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

Collect Git info.

    my $DataGetOk = $BackendObject->DataGet(
        ModuleRef => $ModuleRef,
    );

=cut

sub DataGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw( ModuleRef )) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $Home         = $ConfigObject->Get('Home');

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

    my ($GithubIssue) = $GitBranch =~ m{^issue-#(\d+)-};

    $Param{ModuleRef}->{Data} = {
        GitBranch   => $GitBranch,
        GitRepo     => $GitRepo,
        GitCommit   => $GitCommit,
        GithubIssue => $GithubIssue,
    };

    return 1;
}

1;

=back
