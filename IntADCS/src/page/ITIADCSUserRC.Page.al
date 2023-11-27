page 69065 "ITI ADCS User RC"
{
    ApplicationArea = All;
    Caption = 'ADCS User RC';
    PageType = RoleCenter;

    actions
    {
        area(Creation)
        {
            action(ADCS)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'ADCS';
                RunObject = Page ITIADCS;
                ToolTip = ' ';
            }
        }
    }

}