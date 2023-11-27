codeunit 69082 "ITI Create Pick SI"
{
    SingleInstance = true;
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", OnCreateTempActivityLineOnAfterTransferFrom, '', false, false)]
    local procedure OnCreateTempActivityLineOnAfterTransferFrom(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary)
    begin
        IF TempWarehouseActivityLine."Action Type" = TempWarehouseActivityLine."Action Type"::Take THEN
            LineNo2 := TempWarehouseActivityLine."Line No.";
        TempWarehouseActivityLine."ITI Take/Place Line No." := LineNo2;
        TempWarehouseActivityLine."ITI Pick No. to Whse. Shipment" := WhseShptPickNo;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", OnBeforeCreateNewWhseDoc, '', false, false)]
    local procedure OnBeforeCreateNewWhseDoc(OldLocationCode: Code[10]; OldNo: Code[20]; OldSourceNo: Code[20]; sender: Codeunit "Create Pick"; var FirstWhseDocNo: Code[20]; var LastWhseDocNo: Code[20]; var NoOfLines: Integer; var NoOfSourceDoc: Integer; var TempWhseActivLine: Record "Warehouse Activity Line" temporary; var WhseDocCreated: Boolean)
    begin
        /* IF OldPickNo <> TempWhseActivLine."ITI Pick No. to Whse. Shipment" THEN
             sender.CreateWhseActivHeader(
               TempWhseActivLine."Location Code", FirstWhseDocNo, LastWhseDocNo,
               NoOfSourceDoc, NoOfLines, WhseDocCreated);
               */
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", OnBeforeWhseActivHeaderInsert, '', false, false)]
    local procedure OnBeforeWhseActivHeaderInsert(CreatePickParameters: Record "Create Pick Parameters" temporary; var TempWhseActivityLine: Record "Warehouse Activity Line" temporary; var WarehouseActivityHeader: Record "Warehouse Activity Header"; WhseShptLine: Record "Warehouse Shipment Line")
    var
    test: text;
    begin
        WarehouseActivityHeader."ITI Whse. Document Type" := TempWhseActivityLine."Whse. Document Type";
        WarehouseActivityHeader."ITI Whse. Document No." := TempWhseActivityLine."Whse. Document No.";
        WarehouseActivityHeader."ITI Pick No. to Whse. Shipment" := TempWhseActivityLine."ITI Pick No. to Whse. Shipment";
        OldPickNo := TempWhseActivityLine."ITI Pick No. to Whse. Shipment";


    end;

    procedure SetWhseShptPickNo(_WhseShptPickNo: Integer)
    begin
        WhseShptPickNo := _WhseShptPickNo;
    end;

    var
        WhseShptPickNo: Integer;
        LineNo2: integer;
        OldPickNo: Integer;
}
