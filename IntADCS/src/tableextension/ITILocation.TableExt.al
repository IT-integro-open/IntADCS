tableextension 69060 "ITI ADCS Location" extends Location
{
    fields
    {
        modify("Require Put-away")
        {
            trigger OnAfterValidate()
            begin
                if not "Require Put-away" then
                    CheckAndUpdateAutomaticPutAway();
            end;
        }
        modify("Require Receive")
        {
            trigger OnAfterValidate()
            begin
                if not "Require Receive" then
                    CheckAndUpdateAutomaticPutAway();
            end;
        }
        modify("Use Put-away Worksheet")
        {
            trigger OnAfterValidate()
            begin
                if "Use Put-away Worksheet" then
                    CheckAndUpdateAutomaticPutAway();
            end;
        }
        modify("Require Pick")
        {
            trigger OnAfterValidate()
            begin
                if not "Require Pick" then
                    CheckAndUpdateAutomaticPick();
            end;
        }
        modify("Require Shipment")
        {
            trigger OnAfterValidate()
            begin
                if not "Require Shipment" then
                    CheckAndUpdateAutomaticPick();
            end;
        }

        field(69050; "ITI Automatic Create Pick"; Boolean)
        {
            Caption = 'Automatic Create Pick';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if not (Rec."Require Pick" and Rec."Require Shipment") then
                    Rec."ITI Automatic Create Pick" := false;
            end;
        }
        field(69051; "ITI Automatic Create Put-Away"; Boolean)
        {
            Caption = 'Automatic Create Put-Away';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if not (Rec."Require Put-away" and Rec."Require Receive" and not Rec."Use Put-away Worksheet") then
                    Rec."ITI Automatic Create Put-Away" := false;
            end;
        }
    }

    local procedure CheckAndUpdateAutomaticPutAway()
    begin
        if "ITI Automatic Create Put-Away" then
            "ITI Automatic Create Put-Away" := false;
    end;

    local procedure CheckAndUpdateAutomaticPick()
    begin
        if "ITI Automatic Create Pick" then
            "ITI Automatic Create Pick" := false;
    end;
}