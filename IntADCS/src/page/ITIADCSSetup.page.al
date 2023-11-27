page 69051 "ITI ADCS Setup"
{
    ApplicationArea = all;
    Caption = 'ADCS Setup';
    PageType = Card;
    SourceTable = "ITI ADCS Setup";
    
    layout
    {
        area(content)
        {
            group(General)
            {

                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Location Code field.';
                }
                field("Filter Action Type"; Rec."Filter Action Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Filter Action Type field.';
                }
                field("Sorting Method"; Rec."Sorting Method")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Sorting Method field.';
                }
            }
            group(Receipt)
            {
                field("Post Receipt Line"; Rec."Post Receipt Line")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Post Receipt Line field.';
                }
                field("Automatic Put-away Reg."; Rec."Automatic Put-away Reg.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Automatic Put-away Registration field.';
                }
                field("Assign Whse. Empl. to Put-Away"; Rec."Assign Whse. Empl. to Put-Away")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Assign Whse. Empl. to Put-Away field.';
                }
                field("Allow Change Put-Away Bin"; Rec."Allow Change Put-Away Bin")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Allow Change Put-Away Bin field.';
                }
            }
            group(Shipment)
            {
                field("Allow Change Pick Bin"; Rec."Allow Change Pick Bin")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Allow Change Pick Bin field.';
                }
                field("Automatic Pick Registration"; Rec."Automatic Pick Registration")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Automatic Pick Registration field.';
                }

            }
            group(Warehouse)
            {
                field("Automatic Movment Reg."; Rec."Automatic Movment Reg.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Automatic Movment Registration field.';
                }
                field("Automatic Close Package"; Rec."Automatic Close Package")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Automatic Close Package field.';
                }
                field("Item Lookup"; Rec."Item Lookup")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Item Lookup field.';
                }
            }
        }
    }
    trigger OnOpenPage()
    begin
        Rec.RESET();
        IF NOT Rec.GET() THEN BEGIN
            Rec.INIT();
            Rec.INSERT();
        END;
    end;
}
