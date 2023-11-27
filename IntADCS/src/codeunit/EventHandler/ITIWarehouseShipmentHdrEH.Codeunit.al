codeunit 69078 "ITI Warehouse Shipment Hdr EH"
{
    [EventSubscriber(ObjectType::Table, database::"Warehouse Shipment Header", OnBeforeWhseShptLineDelete, '', false, false)]
    local procedure OnBeforeWhseShptLineDeleteWarehouseShipmentHeader(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    var
        SalesLine: Record "Sales Line";
    begin
        IF WarehouseShipmentLine."Source Document" = WarehouseShipmentLine."Source Document"::"Sales Order" THEN
            IF SalesLine.GET(SalesLine."Document Type"::Order, WarehouseShipmentLine."Source No.", WarehouseShipmentLine."Source Line No.") THEN BEGIN
                SalesLine.VALIDATE("ITI Qty. to Ship from Whse.", SalesLine."ITI Qty. to Ship from Whse." + WarehouseShipmentLine."Qty. Outstanding");
                SalesLine.MODIFY;
            END;
    end;

}
