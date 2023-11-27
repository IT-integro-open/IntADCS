codeunit 69089 "ITI WhsePostReceipt EH"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt", 'OnCodeOnAfterGetWhseRcptHeader', '', false, false)]
    local procedure OnCodeOnAfterGetWhseRcptHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    var
WarehouseSetup:record "Warehouse Setup";
    begin
                    WarehouseSetup.GET();
            IF (WarehouseSetup."ITI Posting Date as Today") AND (WarehouseReceiptHeader."Posting Date" <> TODAY) THEN
                WarehouseReceiptHeader.VALIDATE("Posting Date", TODAY);
    end;
    
}
