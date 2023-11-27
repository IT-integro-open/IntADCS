codeunit 69068 "ITI Get Src Doc Outb Evnt Hndl"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Get Source Doc. Outbound", 'OnAfterGetSingleOutboundDoc', '', false, false)]
    local procedure RunOnAfterGetSingleOutboundoc(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        Location: Record Location;
        WhseShptLine: Record "Warehouse Shipment Line";
        CreateAutomaticPick: codeunit "ITI Create Automatic Pick";
    begin
        if Location.Get(WarehouseShipmentHeader."Location Code") and Location."ITI Automatic Create Pick" then
            if WarehouseShipmentHeader.Get(WarehouseShipmentHeader."No.") then begin
                WhseShptLine.SetRange("No.", WarehouseShipmentHeader."No.");
                WhseShptLine.SetRange("Location Code", WarehouseShipmentHeader."Location Code");
                if WhseShptLine.FindLast() then
                    CreateAutomaticPick.CreatePick(WhseShptLine, WarehouseShipmentHeader, true);
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Get Source Doc. Outbound", 'OnGetSingleOutboundDocOnSetFilterGroupFilters', '', false, false)]
    local procedure OnGetSingleOutboundDocOnSetFilterGroupFilters(var WhseRqst: Record "Warehouse Request"; WhseShptHeader: Record "Warehouse Shipment Header")

    begin
        WhseRqst.SETRANGE("Destination Type", WhseShptHeader."ITI Destination Type");
        WhseRqst.SETRANGE("Destination No.", WhseShptHeader."ITI Destination No.");
        WhseRqst.SETRANGE("ITI Ship-to Code", WhseShptHeader."ITI Ship-to Code");
        WhseRqst.SETRANGE("Shipment Method Code", WhseShptHeader."Shipment Method Code");
    end;
 

   

}