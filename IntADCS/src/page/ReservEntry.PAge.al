page 69057 ResEntries
{
    Caption = 'ResEntries';
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "Reservation Entry";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }

            }
        }
        area(Factboxes)
        {

        }
    }

}