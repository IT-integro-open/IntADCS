page 69087 "ITI Miniform Subform"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'Lines';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "ITI Miniform Line";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Area"; Rec."Area")
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the value of the Area field.';
                }
                field("Field Type"; Rec."Field Type")
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the value of the Field Type field.';
                }
                field("Table No."; Rec."Table No.")
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the value of the Table No. field.';
                }
                field("Field No."; Rec."Field No.")
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the value of the Field No. field.';
                }
                field("Field Length"; Rec."Field Length")
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the value of the Field Length field.';
                }
                field("Text"; Rec."Text")
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the value of the Text field.';
                }
                field("Call Miniform"; Rec."Call Miniform")
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the value of the CADCS Miniform field.';

                    trigger OnDrillDown()
                    var
                        MiniformHeader: Record "ITI Miniform Header";
                        Miniform: Page "ITI Miniform";
                    begin
                        if Rec."Call Miniform" <> '' then begin
                            MiniformHeader.SetRange(Code, Rec."Call Miniform");
                            Miniform.SetTableView(MiniformHeader);
                            Miniform.Run();
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MoveDown)
            {
                Caption = 'Move Down';
                Image = MoveDown;
                ApplicationArea = All;
                ToolTip = 'Executes the Move Down action.';

                trigger OnAction()
                var
                    MiniformLine: Record "ITI Miniform Line";
                    MiniformManagement: Codeunit "ITI Miniform Management";
                begin
                    CurrPage.SetSelectionFilter(MiniformLine);
                    if MiniformLine.Count = 1 then
                        MiniformManagement.MoveDown(MiniformLine)
                end;
            }
            action(MoveUp)
            {
                Caption = 'Move Up';
                Image = MoveUp;
                ApplicationArea = All;
                ToolTip = 'Executes the Move Up action.';

                trigger OnAction()
                var
                    MiniformLine: Record "ITI Miniform Line";
                    MiniformManagement: Codeunit "ITI Miniform Management";
                begin
                    CurrPage.SetSelectionFilter(MiniformLine);
                    if MiniformLine.Count = 1 then
                        MiniformManagement.MoveUp(MiniformLine)
                end;
            }
        }
    }
}

