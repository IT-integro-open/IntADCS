page 69054 "ITI Miniform"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Miniform';
    DataCaptionFields = "Code";
    PageType = ListPlus;
    SourceTable = "ITI Miniform Header";


    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Code; rec.Code)
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the value of the Code field.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the value of the Description field.';
                }
                field("Form Type"; Rec."Form Type")
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the value of the Form Type field.';
                }
                field("No. of Records in List"; Rec."No. of Records in List")
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the value of the No. of Records in List field.';
                }
                field("Handling Codeunit"; Rec."Handling Codeunit")
                {
                    ApplicationArea = ADCS;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the value of the Handling Codeunit field.';
                }
                field("Next Miniform"; Rec."Next Miniform")
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the value of the Next Miniform field.';

                    trigger OnDrillDown()
                    var
                        MiniformHeader: Record "ITI Miniform Header";
                        Miniform: Page "ITI Miniform";
                    begin
                        if Rec."Next Miniform" <> '' then begin
                            MiniformHeader.SetRange(Code, Rec."Next Miniform");
                            Miniform.SetTableView(MiniformHeader);
                            Miniform.Run();
                        end;
                    end;
                }
                field("Start Miniform"; Rec."Start Miniform")
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the value of the Start Miniform field.';
                }
                field("Hide Blank Lines"; rec."Hide Blank Lines")
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the value of the Hide Blank Lines field.';
                }
                field("Main Menu"; rec."Main Menu")
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the value of the Main Menu field.';
                }

            }
            part("Miniform Subform"; "ITI Miniform Subform")
            {
                ApplicationArea = ADCS;
                SubPageLink = "Miniform Code" = FIELD(Code);
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
        area(navigation)
        {
            group("&Mini Form")
            {
                Caption = '&Mini Form';
                Image = MiniForm;
                action("&Functions")
                {
                    ApplicationArea = ADCS;
                    Caption = '&Functions';
                    Image = "Action";
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Page "ITI Miniform Functions";
                    RunPageLink = "Miniform Code" = FIELD(Code);
                    ToolTip = 'Access functions to set up the ADCS interface.';

                    trigger OnAction()
                    var
                        MiniformManagement: Codeunit "ITI Miniform Management";
                    begin
                        MiniformManagement.FillMiniformFunction(Rec);
                    end;
                }
            }
        }
    }
}

