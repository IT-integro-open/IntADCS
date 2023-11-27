tableextension 69051 "ITI Bin Content" extends "Bin Content"
{
    fields
    {
        field(69050; "ITI Additional"; Boolean)
        {
            Caption = 'Additional';
            DataClassification = CustomerContent;
            trigger OnValidate()
            var
                WMSManagement: Codeunit "WMS Management";
            begin
                TESTFIELD(Default, FALSE);

                IF (xRec."ITI Additional" <> "ITI Additional") AND "ITI Additional" THEN
                    IF NOT WMSManagement.CheckDefaultBin(
                         "Item No.", "Variant Code", "Location Code", "Bin Code")
                    THEN
                        ERROR(DefineDefaultErr, "Location Code", "Item No.", "Variant Code");

            end;
        }
        field(69052; "ITI Lot No."; Code[50])
        {
            caption = 'Lot No.';
            FieldClass = FlowField;
            CalcFormula = Lookup("Warehouse Entry"."Lot No." WHERE("Location Code" = FIELD("Location Code"),
                                                                    "Bin Code" = FIELD("Bin Code"),
                                                                    "Item No." = FIELD("Item No."),
                                                                    "Variant Code" = FIELD("Variant Code"),
                                                                    "Unit of Measure Code" = FIELD("Unit of Measure Code"),
                                                                    "Lot No." = FIELD("Lot No. Filter"),
                                                                    "Serial No." = FIELD("Serial No. Filter")));

        }
        field(69053; "ITI Serial No."; Code[50])
        {
            caption = 'Serial No.';
            CalcFormula = Lookup("Warehouse Entry"."Serial No." WHERE("Location Code" = FIELD("Location Code"),
                                                                       "Bin Code" = FIELD("Bin Code"),
                                                                      "Item No." = FIELD("Item No."),
                                                                       "Variant Code" = FIELD("Variant Code"),
                                                                       "Unit of Measure Code" = FIELD("Unit of Measure Code"),
                                                                       "Lot No." = FIELD("Lot No. Filter"),
                                                                       "Serial No." = FIELD("Serial No. Filter")));
            FieldClass = FlowField;
        }
        field(50001; "ITI EAN"; Code[20])
        {
            CalcFormula = Lookup(Item."ITI EAN" WHERE("No." = FIELD("Item No.")));
            Caption = 'EAN Code';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50002; "ITI Item Description"; Text[100])
        {
            CalcFormula = Lookup(Item.Description WHERE("No." = FIELD("Item No.")));
            Caption = 'Item Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50003; "ITI Item Description 2"; Text[100])
        {
            CalcFormula = Lookup(Item."Description 2" WHERE("No." = FIELD("Item No.")));
            Caption = 'Item Description 2';
            Editable = false;
            FieldClass = FlowField;
        }
    }
    var
        DefineDefaultErr: Label 'First you need define a default bin content for location code %1, item no. %2 and variant code %3.';
}
