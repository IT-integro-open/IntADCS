codeunit 69077 "ITI Warehouse Shipment Line EH"
{
    [EventSubscriber(ObjectType::Table, database::"Warehouse Shipment Line", OnAfterDeleteEvent, '', false, false)]
    local procedure OnAfterDeleteEventWarehouseActivityLine(var Rec: Record "Warehouse Shipment Line")
    var
        SalesLine: Record "Sales Line";
    begin
        IF Rec."Source Document" = Rec."Source Document"::"Sales Order" THEN
            IF SalesLine.GET(SalesLine."Document Type"::Order, Rec."Source No.", Rec."Source Line No.") THEN BEGIN
                SalesLine.VALIDATE("ITI Qty. to Ship from Whse.", SalesLine."ITI Qty. to Ship from Whse." + Rec."Qty. Outstanding");
                SalesLine.MODIFY;
            END;
    end;
        [EventSubscriber(ObjectType::Table, database::"Warehouse Shipment Line", OnBeforeValidateEvent, "Qty. Picked", false, false)]
    local procedure OnAfterValidateEventQtyPicked(var Rec: Record "Warehouse Shipment Line")
    begin
        Rec.validate("ITI Qty. Out. to Pack", Rec."Qty. Picked");
    end;

    [EventSubscriber(ObjectType::Table, database::"Warehouse Shipment Line", OnBeforeInsertEvent, '', false, false)]
    local procedure OnBeforeInsertEvent(var Rec: Record "Warehouse Shipment Line")
    begin
        Rec.validate("ITI Qty. Out. to Pack", Rec.Quantity);
    end;
    
}
