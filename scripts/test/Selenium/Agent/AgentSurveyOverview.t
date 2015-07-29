# --
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

# get selenium object
my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        # get helper object
        my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # create test survey
        my $SurveyTitle = 'Survey ' . $Helper->GetRandomID();
        my $SurveyID    = $Kernel::OM->Get('Kernel::System::Survey')->SurveyAdd(
            UserID              => 1,
            Title               => $SurveyTitle,
            Introduction        => 'Survey Introduction',
            Description         => 'Survey Description',
            NotificationSender  => 'quality@example.com',
            NotificationSubject => 'Survey Notification Subject',
            NotificationBody    => 'Survey Notifiation Body',
            Queues              => [2],
        );
        $Self->True(
            $SurveyID,
            "Survey ID $SurveyID - created",
        );

        # create test user and login
        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => [ 'admin', 'users' ],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # get script alias
        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');

        # navigate to AgentSurveyOverview of created test survey
        $Selenium->get("${ScriptAlias}index.pl?Action=AgentSurveyOverview");

        # check screen
        $Selenium->find_element( "table",             'css' );
        $Selenium->find_element( "table thead tr th", 'css' );
        $Selenium->find_element( "table tbody tr td", 'css' );

        # check for test created survey
        $Self->True(
            index( $Selenium->get_page_source(), "$SurveyTitle" ) > -1,
            "$SurveyTitle - found",
        );

        # click on test created survey
        $Selenium->find_element("//div[\@title='$SurveyTitle']")->click();

        # verify we are in AgentSurveyZoom screen
        my $URLAction = $Selenium->get_current_url();
        $Self->Is(
            index( $URLAction, "Action=AgentSurveyZoom;SurveyID=$SurveyID" ) > -1,
            1,
            "Link from Overview to Zoom view - success",
        );

        # delete test created survey
        my $Success = $Kernel::OM->Get('Kernel::System::DB')->Do(
            SQL => "DELETE FROM survey WHERE id = $SurveyID",
        );
        $Self->True(
            $Success,
            "$SurveyTitle - deleted",
        );
    }
);

1;
