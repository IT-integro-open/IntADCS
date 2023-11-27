tableextension 69058 "ITI Warehouse Receipt Line" extends "Warehouse Receipt Line"
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
        field(69051; "ITI Scanned"; Boolean)
        {
            Caption = 'Scanned';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(69052; "ITI Qty. to Assign"; Decimal)
        {
            Caption = 'Qty. to Assign';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }
        field(69053; "ITI Rem. No. of Lines"; Integer)
        {
            CalcFormula = Count("Warehouse Receipt Line" WHERE("No." = FIELD("No."),
                                                                "ITI Scanned" = CONST(false)));
            Caption = 'Rem. No. of Lines';
            FieldClass = FlowField;
            editable = false;
        }
        field(69054; "ITI Lot No."; Code[20])
        {
            Caption = 'Lot No.';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(69055; "ITI Serial No."; Code[20])
        {
            Caption = 'Serial No.';
            DataClassification = CustomerContent;

        }
        field(69056; "ITI Qty. to Scan"; Decimal)
        {
            Caption = 'Qty. to Scan';

            Editable = false;
            DataClassification = CustomerContent;
        }
        field(69057; "ITI EAN"; Code[20])
        {
            CalcFormula = Lookup(Item."ITI EAN" WHERE("No." = FIELD("Item No.")));
            Caption = 'EAN Code';
            Editable = false;
            FieldClass = FlowField;
        }
        field(69058; "ITI User ID"; Code[50])
        {
            Caption = 'User ID';
            TableRelation = User."User Name";
            DataClassification = CustomerContent;
            trigger OnLookup()
            var
                UserMgt: Codeunit 418;
            begin
                //UserMgt.LookupUserID("User ID");
            end;
        }
        field(69060; "ITI Package No."; Code[50])
        {
            Caption = 'Package No.';
        }
        field(69070; "ITI Expiry Date"; Date)
        {
            Caption = 'Expiry Date';
        }

    }
    local procedure CheckLNRequired()
    var
        ItemTrackingMgt: Codeunit 6500;
        SNRequired: Boolean;
        LNRequired: Boolean;
    begin
        // START/ASM/ADCS/009
        //ItemTrackingMgt.CheckWhseItemTrkgSetup("Item No.",SNRequired,LNRequired,TRUE);
        // STOP /ASM/ADCS/009
    end;
}
