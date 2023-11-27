tableextension 69052 "ITI Warehouse Activity Line" extends "Warehouse Activity Line"
{
    fields
    {
        field(69050; "ITI Take/Place Line No."; Integer)
        {
            Caption = 'Take/Place Line No.';
            DataClassification = CustomerContent;
        }
        field(69051; "ITI Rem. No. of Lines"; Integer)
        {
            Caption = 'Rem. No. of Lines';

            Editable = false;
            FieldClass = FlowField;
            CalcFormula = Count("Warehouse Activity Line" WHERE("Activity Type" = FIELD("Activity Type"), "No." = FIELD("No."), "Action Type" = FIELD("Action Type")));
        }
        field(69052; "ITI Total Location Qty."; Decimal)
        {
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = Sum("Warehouse Entry".Quantity WHERE("Item No." = FIELD("Item No."), "Location Code" = FIELD("Location Code")));
            Caption = 'Total Location Qty.';

        }
        field(69053; "ITI Additional Bin Code"; Code[20])
        {
            Caption = 'Additional Bin Code';
            DataClassification = CustomerContent;
        }
        field(69054; "ITI Pick No. to Whse. Shipment"; Integer)
        {
            Caption = 'Pick No. to Whse. Shipment';
            DataClassification = CustomerContent;
        }
        field(69055; "ITI User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = CustomerContent;
            trigger OnLookup()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("ITI User ID");
            end;
        }
        field(69056; "ITI Default Bin Code"; Code[20])
        {
            Caption = 'Default Bin Code';
            DataClassification = CustomerContent;
        }
        field(69057; "ITI QtyAvailtoPutinDefBin"; Decimal)
        {
            Caption = 'Qty. Avail. to Put in Def. Bin';
            DataClassification = CustomerContent;
        }
        field(69058; "ITI EAN"; Code[20])
        {
            CalcFormula = Lookup(Item."ITI EAN" WHERE ("No."=FIELD("Item No.")));
            Caption = 'EAN Code';
            Editable = false;
            FieldClass = FlowField;
        }
           field(69059;"ITI To Bin Code";Code[20])
        {
            AccessByPermission = TableData 5771=R;
                        FieldClass = FlowField;
            CalcFormula = Lookup("Warehouse Activity Line"."Bin Code" WHERE ("Activity Type"=FIELD("Activity Type"),
                                                                             "No."=FIELD("No."),
                                                                            "Action Type"=CONST(Place),
                                                                             "Source Type"=FIELD("Source Type"),
                                                                             "Source Subtype"=FIELD("Source Subtype"),
                                                                             "Source No."=FIELD("Source No."),
                                                                             "Source Line No."=FIELD("Source Line No."),
                                                                             "ITI Take/Place Line No."=FIELD("ITI Take/Place Line No.")));
            Caption = 'To Bin Code';
            Editable = false;

        }
    }
}
