page 69059 "ITI Functions"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Functions';
    Editable = false;
    PageType = List;
    SourceTable = "ITI Miniform Function Group";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Code; Rec.Code)
                {
                    ToolTip = 'Specifies the value of the Code field.';
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the value of the Description field.';
                    ApplicationArea = All;
                }
                field(KeyDef; Rec.KeyDef)
                {
                    ToolTip = 'Specifies the value of the KeyDef field.';
                    ApplicationArea = All;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

