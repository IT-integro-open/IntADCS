codeunit 69061 "ITI WMS Management"
{
    procedure GetDefaultBinAndQuantity(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; var BinCode: Code[20]; var QtyToPut: Decimal): Boolean
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SETCURRENTKEY(Default);
        BinContent.SETRANGE(Default, TRUE);
        BinContent.SETRANGE("Location Code", LocationCode);
        BinContent.SETRANGE("Item No.", ItemNo);
        BinContent.SETRANGE("Variant Code", VariantCode);
        BinContent.SETAUTOCALCFIELDS(Quantity);
        IF BinContent.FindFirst() THEN BEGIN
            BinCode := BinContent."Bin Code";
            QtyToPut := BinContent."Max. Qty." - BinContent.Quantity;
            EXIT(TRUE);
        END;

    end;

    procedure GetAdditionaltBin(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]) FoundBin: Code[20]
    var
        BinContent: Record "Bin Content";
        MaxQty: Decimal;
    begin

        FoundBin := '';
        MaxQty := 0;
        BinContent.SETCURRENTKEY(Default);
        BinContent.SETRANGE(Default, FALSE);
        BinContent.SETRANGE("ITI Additional", TRUE);
        BinContent.SETRANGE("Location Code", LocationCode);
        BinContent.SETRANGE("Item No.", ItemNo);
        BinContent.SETRANGE("Variant Code", VariantCode);
        BinContent.SETFILTER("Bin Code", '<>%1', BinCode);
        BinContent.SETAUTOCALCFIELDS(Quantity);
        IF BinContent.FindSet() THEN
            REPEAT
                IF MaxQty < BinContent."Max. Qty." - BinContent.Quantity THEN
                    FoundBin := BinContent."Bin Code";
            UNTIL BinContent.Next() = 0;
    end;

}
