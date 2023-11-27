tableextension 69067 "ITI Purchase Line" extends "Purchase Line"
{
    fields
    {

        field(69050; "ITI Labels Quantity"; Integer)
        {
            Caption = 'Labels Quantity';
            DataClassification = CustomerContent;


            trigger OnValidate()
            begin

                CheckLNRequired;

            end;
        }
    }
    local procedure CheckLNRequired()
    var
        ItemTrackingMgt: Codeunit 6500;
        SNRequired: Boolean;
        LNRequired: Boolean;
    begin

        //ItemTrackingMgt.CheckWhseItemTrkgSetup("No.",SNRequired,LNRequired,TRUE);

    end;
}
