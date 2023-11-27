page 69055 "ITI Miniform Functions"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Miniform Functions';
    PageType = List;
    SourceTable = "ITI Miniform Function";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Miniform Code"; Rec."Miniform Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Miniform Code field.';
                    Visible = false;
                }
                field("Function Code"; Rec."Function Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Function Code field.';
                }
                field("Next Miniform"; Rec."Next Miniform")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Function Code field.';

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
                field("Function Caption"; Rec."Function Caption")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the fuction caption wich will be presented in ADCS.';
                }
                field("Keyboard Key"; Rec."Keyboard Key")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the keyboard key wich will trigger function in ADCS.';
                }
                field(Promoted; Rec.Promoted)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the function is visible in navigation in ADCS.';
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the value of the Function Code field.';
                }

                field("Report Caption"; Rec."Report Caption")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the value of the Function Code field.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = All;
                Visible = false;
            }
            systempart(Control1900383208; Notes)
            {
                ApplicationArea = All;
                Visible = false;
            }

        }
    }

    actions
    {
        area(Navigation)
        {
            action("KeyboardKey")
            {
                Caption = 'Assign function''s keyboard key';
                ToolTip = 'Assign function''s keyboard key';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    ITIADCSKeysFunctionSetup: Page "ITI ADCS Fun. Mapping";
                    ITIKeyDef: Enum "ITI KeyDef";
                begin
                    if Rec."Function Code" = Format(ITIKeyDef::Input).ToUpper() then
                        Error(InputErrLbl);
                    ITIADCSKeysFunctionSetup.SetPageAttr(Rec."Miniform Code", Rec."Function Code");
                    ITIADCSKeysFunctionSetup.Run();
                    CurrPage.Update();
                end;
            }
        }
    }
    var
        InputErrLbl: Label 'To input action can not be assigned any keyboard key.';
}

