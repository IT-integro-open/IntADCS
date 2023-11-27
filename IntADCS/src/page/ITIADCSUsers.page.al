/// <summary>
/// Page ITI ADCS Users (ID 50060).
/// </summary>
page 69052 "ITI ADCS Users"
{
    AdditionalSearchTerms = 'scanner,handheld,automated data capture,barcode';
    ApplicationArea = ADCS;
    Caption = 'ADCS Users';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "ITI ADCS User";
    UsageCategory = Lists;
    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'Group';
                field(Name; Rec.Name)
                {
                    ApplicationArea = ADCS;
                    Caption = 'Name';
                    ToolTip = 'Specifies the value of the Name field.';
                }
                field(Password; Rec.Password)
                {
                    ApplicationArea = ADCS;
                    Caption = 'Password';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the value of the Password field.';
                }
                field(Printer; Rec.Printer)
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the value of the Printer field.';
                }
                                field(ProfileId; Rec."Profile Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Profile Id field.';
                }

                field(LastLoginDate; Rec."Last Login Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Profile Id field.';
                    Editable = false;
                }

                field(LastLoginTime; Rec."Last Login Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Profile Id field.';
                    Editable = false;
                }


            }
        }
    }
    actions
    {
        area(Reporting)
        {
            action("ITI Print ADCS User")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Print ADCS User';
                Image = Print;
                Promoted = true;
                PromotedCategory = "Report";
                PromotedIsBig = true;
                ToolTip = 'Executes the Print ADCS User action.';
                trigger OnAction()
                var
                    ADCSUserReport: Report "ITI ADCS User";
                begin
                    Clear(ADCSUserReport);
                    CurrPage.SetSelectionFilter(Rec);
                    ADCSUserReport.SetTableView(Rec);
                    ADCSUserReport.RunModal();
                end;
            }
        }
    }
}

