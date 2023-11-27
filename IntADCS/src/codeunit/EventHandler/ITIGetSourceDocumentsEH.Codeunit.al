codeunit 69112 "ITI Get Source Documents EH"
{
    [EventSubscriber(ObjectType::Report, report::"Get Source Documents", 'OnSalesLineOnAfterGetRecordOnBeforeCreateShptHeader', '', false, false)]
    local procedure OnSalesLineOnAfterGetRecordOnBeforeCreateShptHeader(var WarehouseRequest: Record "Warehouse Request"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        WarehouseShipmentHeader."ITI Destination Type" := WarehouseRequest."Destination Type";
        WarehouseShipmentHeader."ITI Destination No." := WarehouseRequest."Destination No.";
        WarehouseShipmentHeader."ITI Ship-to Code" := WarehouseRequest."ITI Ship-to Code";
        WarehouseShipmentHeader."Shipment Method Code" := WarehouseRequest."Shipment Method Code";
    end;
            [EventSubscriber(ObjectType::Report, Report::"Get Source Documents", 'OnBeforeWhseShptHeaderInsert', '', false, false)]
    local procedure RunOnAfterCreateShptHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseRequest: Record "Warehouse Request");
    begin
        Case WarehouseRequest."Destination Type" of
            WarehouseRequest."Destination Type"::Customer:
                begin
                    WarehouseShipmentHeader.VALIDATE("ITI Destination Type", WarehouseShipmentHeader."ITI Destination Type"::Customer);
                    WarehouseShipmentHeader.VALIDATE("ITI Destination No.", WarehouseRequest."Destination No.");
                end;
            WarehouseRequest."Destination Type"::Vendor:
                begin
                    WarehouseShipmentHeader.VALIDATE("ITI Destination Type", WarehouseShipmentHeader."ITI Destination Type"::Vendor);
                    WarehouseShipmentHeader.VALIDATE("ITI Destination No.", WarehouseRequest."Destination No.");
                end;
            WarehouseRequest."Destination Type"::Location:
                begin
                    WarehouseShipmentHeader.VALIDATE("ITI Destination Type", WarehouseShipmentHeader."ITI Destination Type"::Location);
                    WarehouseShipmentHeader.VALIDATE("ITI Destination No.", WarehouseRequest."Destination No.");
                end;
        end;
    end;
}
