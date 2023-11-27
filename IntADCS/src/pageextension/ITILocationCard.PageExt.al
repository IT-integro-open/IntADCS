pageextension 69053 "ITI ADCS Location Card" extends "Location Card"
{
    layout
    {
        addafter("Require Pick")
        {
            field("ITI Automatic Pick"; Rec."ITI Automatic Create Pick")
            {
                ApplicationArea = All;
                Enabled = AutomaticPickEnabled;
                ToolTip = 'Specifies if the Automatic Pick is enabled for current location.';
            }
        }
        addafter("Require Put-away")
        {
            field("ITI Automatic Put-Away"; Rec."ITI Automatic Create Put-Away")
            {
                ApplicationArea = All;
                Enabled = AutomaticPutAwayEnabled;
                ToolTip = 'Specifies if the Automatic Put-Away is enabled for current location.';
            }
        }
    }
    actions
    {
        addlast(navigation)
        {
            action("ADCS Setup")
            {
                ApplicationArea = all;
                Caption = 'ADCS Setup';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Executes the Print ADCS Setup action.';
                RunObject = page "ITI ADCS Setup";
                RunPageLink = "Location Code" = field(Code);

         
            }
        }
    }

    var
        AutomaticPickEnabled: Boolean;
        AutomaticPutAwayEnabled: Boolean;

    trigger OnAfterGetRecord()
    begin
        UpdateAutomaticFieldsEnabled();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        UpdateAutomaticFieldsEnabled();
    end;

    local procedure UpdateAutomaticFieldsEnabled()
    begin
        AutomaticPickEnabled := (Rec."Require Pick" and Rec."Require Shipment");
        AutomaticPutAwayEnabled := (Rec."Require Put-away" and Rec."Require Receive" and not Rec."Use Put-away Worksheet");
    end;
}