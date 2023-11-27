page 69050 "ITI ADCS Profile"
{
    ApplicationArea = ADCS;
    Caption = 'ADCS Profile';
    PageType = List;
    SourceTable = "ITI ADCS Profile";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Miniform; Rec.Miniform)
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the value of the Miniform field.';
                }
                field("Profile ID"; Rec."Profile ID")
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the value of the Profile ID field.';
                }
            }
        }
    }
}
