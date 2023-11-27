page 69058 "ITI Fields"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Fields';
    Editable = false;
    PageType = List;
    SourceTable = Field;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(TableNo; Rec.TableNo)
                {
                    Caption = 'TableNo';
                    ToolTip = 'Specifies the table number.';
                    ApplicationArea = All;
                }
                field("No."; Rec."No.")
                {
                    Caption = 'No.';
                    ToolTip = 'Specifies the ID number of the field in the table.';
                    ApplicationArea = All;
                }
                field(TableName; Rec.TableName)
                {
                    Caption = 'TableName';
                    ToolTip = 'Specifies the name of the table.';
                    ApplicationArea = All;
                }
                field(FieldName; Rec.FieldName)
                {
                    Caption = 'FieldName';
                    ToolTip = 'Specifies the name of the field in the table.';
                    ApplicationArea = All;
                }
                field(Type; Rec.Type)
                {
                    Caption = 'Type';
                    ToolTip = 'Specifies the type of the field in the table, which indicates the type of data it contains.';
                    ApplicationArea = All;
                }
                field(Class; Rec.Class)
                {
                    Caption = 'Class';
                    ToolTip = 'Specifies the type of class. Normal is data entry, FlowFields calculate and display results immediately, and FlowFilters display results based on user-defined filter values that affect the calculation of a FlowField.';
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

