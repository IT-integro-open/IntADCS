tableextension 69061 "ITI ADCS Sales Line" extends "Sales Line"
{
    fields
    {
        field(69050; "ITI Qty. to Ship from Whse."; Decimal)
        {
            AccessByPermission = TableData 110 = R;
            Caption = 'Qty. to Ship from Warehouse';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
            begin

                 IF CurrFieldNo <> 0 THEN BEGIN
                     CALCFIELDS("Whse. Outstanding Qty.");
                     IF (ABS(Quantity) - ABS("Whse. Outstanding Qty.")) < "ITI Qty. to Ship from Whse." THEN
                         ERROR(ShipMoreErr,ABS(Quantity) - ABS("Whse. Outstanding Qty."));

                     IF ((("ITI Qty. to Ship from Whse." < 0) XOR (Quantity < 0)) AND (Quantity <> 0) AND ("ITI Qty. to Ship from Whse." <> 0)) OR
                        (ABS("ITI Qty. to Ship from Whse.") > ABS("Outstanding Quantity")) OR
                        (((Quantity < 0) XOR ("Outstanding Quantity" < 0)) AND (Quantity <> 0) AND ("Outstanding Quantity" <> 0))
                     THEN
                         ERROR(ShipMoreErr,"Outstanding Quantity");

                     "ITI QtytoShipfromWhse(Base)" := CalcBaseQty("ITI Qty. to Ship from Whse.", FieldCaption("ITI Qty. to Ship from Whse."), FieldCaption("ITI QtytoShipfromWhse(Base)"));

                     IF ((("ITI QtytoShipfromWhse(Base)" < 0) XOR ("Quantity (Base)" < 0)) AND ("ITI QtytoShipfromWhse(Base)" <> 0) AND ("Quantity (Base)" <> 0)) OR
                        (ABS("ITI QtytoShipfromWhse(Base)") > ABS("Outstanding Qty. (Base)")) OR
                        ((("Quantity (Base)" < 0) XOR ("Outstanding Qty. (Base)" < 0)) AND ("Quantity (Base)" <> 0) AND ("Outstanding Qty. (Base)" <> 0))
                     THEN
                         ERROR(ShipMoreBaseErr,"Outstanding Qty. (Base)");
                 END ELSE
                 
                "ITI QtytoShipfromWhse(Base)" := CalcBaseQty("ITI Qty. to Ship from Whse.", FieldCaption("ITI Qty. to Ship from Whse."), FieldCaption("ITI QtytoShipfromWhse(Base)"));


            end;
        }
        field(69051; "ITI QtytoShipfromWhse(Base)"; Decimal)
        {
            AccessByPermission = TableData 110 = R;
            Caption = 'Qty. to Ship from Warehouse (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            DataClassification = CustomerContent;

        }
    }
    var
        ShipMoreErr: Label 'You cannot ship more than %1 units.';
        ShipMoreBaseErr: Label 'You cannot ship more than %1 base units.';
}
