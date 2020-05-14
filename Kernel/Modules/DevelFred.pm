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

package Kernel::Modules::DevelFred;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

use Kernel::Language qw(Translatable);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{Subaction} = $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam( Param => 'Subaction' );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');

    # ---------------------------------------------------------- #
    # show the overview
    # ---------------------------------------------------------- #

    if ( !$Self->{Subaction} ) {
        my $Version = $ConfigObject->Get('Version');

        $LayoutObject->FatalError(
            Message => 'Sorry, this page is currently under development!',
        );
    }

    # ---------------------------------------------------------- #
    # fast handle for fred settings
    # ---------------------------------------------------------- #
    elsif ( $Self->{Subaction} eq 'Setting' ) {

        # get hashref with all Fred-plugins
        my $ModuleForRef = $ConfigObject->Get('Fred::Module');

        # The Console can't be deactivated
        delete $ModuleForRef->{Console};

        # loop over Modules which can be activated and deactivated
        for my $Module ( sort keys %{$ModuleForRef} ) {
            my $Checked = $ModuleForRef->{$Module}->{Active} ? 'checked="checked"' : '';
            $LayoutObject->Block(
                Name => 'FredModule',
                Data => {
                    FredModule  => $Module,
                    Checked     => $Checked,
                    Description => $ModuleForRef->{$Module}->{Description} || '',
                },
            );

            # Provide a link to the SysConfig only for plugins that have config options
            if ( $ConfigObject->Get("Fred::$Module") ) {
                $LayoutObject->Block(
                    Name => 'Config',
                    Data => {
                        ModuleName => $Module,
                    }
                );
            }
        }

        # build output
        my $Output = $LayoutObject->Header(
            Title => 'Fred-Setting',
            Type  => 'Small',
        );
        $Output .= $LayoutObject->Output(
            Data         => {%Param},
            TemplateFile => 'DevelFredSetting',
        );
        $Output .= $LayoutObject->Footer(
            Type => 'Small',
        );

        return $Output;
    }

    # ---------------------------------------------------------- #
    # fast handle for fred settings
    # ---------------------------------------------------------- #
    elsif ( $Self->{Subaction} eq 'SettingAction' ) {
        my $ModuleForRef        = $ConfigObject->Get('Fred::Module');
        my @SelectedFredModules = $ParamObject->GetArray( Param => 'FredModule' );
        my %SelectedModules     = map { $_ => 1; } @SelectedFredModules;
        my $UpdateFlag;
        delete $ModuleForRef->{Console};

        for my $Module ( sort keys %{$ModuleForRef} ) {

            # update the sysconfig settings
            if (
                $ModuleForRef->{$Module}->{Active} && !$SelectedModules{$Module}
                ||
                !$ModuleForRef->{$Module}->{Active} && $SelectedModules{$Module}
                )
            {
                # update certain values
                $ModuleForRef->{$Module}->{Active} = $SelectedModules{$Module} || 0;

                $Self->_SettingUpdate(
                    Valid => 1,
                    Key   => "Fred::Module###$Module",
                    Value => $ModuleForRef->{$Module},
                );
                $UpdateFlag = 1;
            }
        }

        return $LayoutObject->PopupClose(
            Reload => 1,
        );
    }

    # ---------------------------------------------------------- #
    # handle for config switch
    # ---------------------------------------------------------- #
    elsif ( $Self->{Subaction} eq 'ConfigSwitchAJAX' ) {

        my $ItemKey   = $ParamObject->GetParam( Param => 'Key' );
        my $ItemValue = $ParamObject->GetParam( Param => 'Value' );

        my $Success = 0;

        if ($ItemKey) {

            # the value which is passed is the current value, so we
            # need to switch it.
            if ( $ItemValue == 1 ) {
                $ItemValue = 0;
            }
            else {
                $ItemValue = 1;
            }

            $Self->_SettingUpdate(
                Valid => 1,
                Key   => $ItemKey,
                Value => $ItemValue,
            );
            $Success = 1;
        }

        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $Success,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    return 1;
}

sub _SettingUpdate {
    my ( $Self, %Param ) = @_;

    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

    # OTOBO 5 SysConfig API
    if ( $SysConfigObject->can('ConfigItemUpdate') ) {
        ## nofilter(TidyAll::Plugin::OTOBO::Migrations::OTOBO6::SysConfig)
        $SysConfigObject->ConfigItemUpdate(%Param);
    }

    # OTOBO 10+ SysConfig API
    else {
        my $SettingName = 'SecureMode';

        my $ExclusiveLockGUID = $SysConfigObject->SettingLock(
            Name   => $Param{Key},
            Force  => 1,
            UserID => 1,
        );

        # Update config item via SysConfig object.
        my $Result = $SysConfigObject->SettingUpdate(
            Name              => $Param{Key},
            IsValid           => $Param{Valid},
            EffectiveValue    => $Param{Value},
            ExclusiveLockGUID => $ExclusiveLockGUID,
            UserID            => 1,
        );

        if ( !$Result ) {
            $Kernel::OM->Get('Kernel::Output::HTML::Layout')->FatalError(
                Message => Translatable('Can\'t write Config file!'),
            );
        }

        # There is no need to unlock the setting as it was already unlocked in the update.

        # 'Rebuild' the configuration.
        my $Success = $SysConfigObject->ConfigurationDeploy(
            Comments    => "Installer deployment",
            AllSettings => 1,
            Force       => 1,
            UserID      => 1,
        );
    }

    return 1;
}

1;
