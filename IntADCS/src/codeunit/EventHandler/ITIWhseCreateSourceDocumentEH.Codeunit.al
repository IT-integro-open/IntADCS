codeunit 69084 ITIWhseCreateSourceDocumentEH
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Create Source Document", 'OnPurchLine2ReceiptLineOnAfterUpdateReceiptLine', '', false, false)]
    local procedure OnPurchLine2ReceiptLineOnAfterUpdateReceiptLine(var WhseReceiptLine: Record "Warehouse Receipt Line";var WhseReceiptHeader: Record "Warehouse Receipt Header";PurchaseLine: Record "Purchase Line")
    begin
        WhseReceiptLine."ITI Labels Quantity" := PurchaseLine."ITI Labels Quantity";
    end;
    
}
