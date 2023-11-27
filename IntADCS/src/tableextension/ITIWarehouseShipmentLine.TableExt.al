tableextension 69056 "ITI Warehouse Shipment Line" extends "Warehouse Shipment Line"
{
    fields
    {
        field(69050; "ITI Quantity Packed"; Decimal)
        {
            Caption = 'Quantity Packed';
            DecimalPlaces = 0 : 5;
            Editable = true;
            MinValue = 0;
            DataClassification = CustomerContent;
            trigger OnValidate()
            var
                WarehouseShipmentHeader: Record 7320;
            begin
                Rec."ITI Qty. Packed (Base)" := ITICalcBaseQty(Rec."ITI Quantity Packed");
                Rec.VALIDATE(Rec."Qty. to Ship", Rec."ITI Quantity Packed" - Rec."Qty. Shipped");
                Rec."Qty. to Ship (Base)" := Rec."ITI Qty. Packed (Base)" - Rec."Qty. Shipped (Base)";

                Rec."ITI Qty. Out. to Pack" := Rec."Qty. Picked" - "ITI Quantity Packed";
                Rec."ITI Qty. Out. to Pack (Base)" := Rec."Qty. Picked (Base)" - Rec."ITI Qty. Packed (Base)";

                IF Rec."ITI Qty. Out. to Pack" = 0 THEN
                    Rec."ITI Package Status" := Rec."ITI Package Status"::"Completely Packed"
                ELSE
                    IF "ITI Quantity Packed" = 0 THEN
                        Rec."ITI Package Status" := Rec."ITI Package Status"::" "
                    ELSE
                        Rec."ITI Package Status" := Rec."ITI Package Status"::"Partially Packed";
                WarehouseShipmentHeader.GET(Rec."No.");
                IF "ITI Package Status" = "ITI Package Status"::"Partially Packed" THEN
                    WarehouseShipmentHeader."ITI Package Status" := "ITI Package Status"
                ELSE
                    WarehouseShipmentHeader."ITI Package Status" := WarehouseShipmentHeader.GetPackageStatus("Line No.", "ITI Package Status");
                WarehouseShipmentHeader.MODIFY;
            end;
        }
        field(69060; "ITI Qty. Packed (Base)"; Decimal)
        {
            Caption = 'Qty. Packed (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(69070; "ITI Qty. Out. to Pack"; Decimal)
        {
            Caption = 'Qty. Outstanding to Pack';
            DecimalPlaces = 0 : 5;
            Editable = false;
            DataClassification = CustomerContent;

        }
        field(69080; "ITI Qty. Out. to Pack (Base)"; Decimal)
        {
            Caption = 'Qty. Outstanding to Pack (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(69090; "ITI Package Status"; enum "ITI Package Status")
        {
            Caption = 'Package Status';

            Editable = false;
        
            DataClassification = CustomerContent;
        }
        field(69100; "ITI Qty. to Assign"; Decimal)
        {
            Caption = 'Qty. to Assign';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }
        field(69110; "ITI EAN"; Code[20])
        {
            CalcFormula = Lookup(Item."ITI EAN" WHERE("No."=FIELD("Item No.")));
            Caption = 'EAN Code';
            Editable = false;
            FieldClass = FlowField;
        }
    }
    local procedure ITICalcBaseQty(Qty: Decimal): Decimal
    begin
        TESTFIELD("Qty. per Unit of Measure");
        EXIT(ROUND(Qty * "Qty. per Unit of Measure", 0.00001));
    end;
}
