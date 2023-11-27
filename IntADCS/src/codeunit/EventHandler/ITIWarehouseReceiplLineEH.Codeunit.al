codeunit 69080 "ITI Warehouse Receipl Line EH"
{
    [EventSubscriber(ObjectType::Table, Database::"Warehouse Receipt Line", OnAfterInitQtyToReceive, '', false, false)]
    local procedure OnAfterInitQtyToReceive(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    var
        Location: record Location;
    begin

        IF Location.GET(WarehouseReceiptLine."Location Code") THEN BEGIN
            IF Location."Use ADCS" THEN BEGIN
                WarehouseReceiptLine."ITI Qty. to Scan" := WarehouseReceiptLine."Qty. Outstanding";
                WarehouseReceiptLine.VALIDATE("Qty. to Receive", 0);
            END ELSE
                WarehouseReceiptLine.VALIDATE("Qty. to Receive", WarehouseReceiptLine."Qty. Outstanding")
        END ELSE
            WarehouseReceiptLine.VALIDATE("Qty. to Receive", WarehouseReceiptLine."Qty. Outstanding")
    end;
}
