page 69056 "ITI Miniforms"
{
    AdditionalSearchTerms = 'scanner,handheld,automated data capture,barcode,paper-free';
    ApplicationArea = ADCS;
    Caption = 'ADCS Miniforms';
    CardPageID = "ITI Miniform";
    Editable = false;
    PageType = List;
    SourceTable = "ITI Miniform Header";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec."Code")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the value of the Code field.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the value of the Description field.';
                }
                field("No. of Records in List"; Rec."No. of Records in List")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the value of the No. of Records in List field.';
                }
                field("No. of Used Miniform"; Rec."No. of Used Miniform")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the value of the No. of Records in List field.';
                }
                field("No. of Used Next Miniform"; Rec."No. of Used Next Miniform")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the value of the No. of Records in List field.';
                }
                field("No. of Used Function"; Rec."No. of Used Function")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the value of the No. of Records in List field.';
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

