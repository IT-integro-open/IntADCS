codeunit 69085 "ITIADE Create Pick EH"
{
    SingleInstance = true;
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", OnAfterSetParameters, '', false, false)]
    local procedure OnAfterSetParameters(var CreatePickParameters: Record "Create Pick Parameters" temporary)
    begin
        // CreatePickParametersGlobal := CreatePickParameters;
        // CreatePickParametersGlobal.insert;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", OnAfterSetWhseShipment, '', false, false)]
    local procedure OnAfterSetWhseShipment(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
        SourceType := WarehouseShipmentLine."Source Type";
        SourceSubType := WarehouseShipmentLine."Source Subtype";
        SourceNo := WarehouseShipmentLine."Source No.";
        SourceLineNo := WarehouseShipmentLine."Source Line No.";
        SourceSubLineNo := 0;
        AssembletoOrder := WarehouseShipmentLine."Assemble to Order";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", OnBeforeCalcPickBin, '', false, false)]
    local procedure OnBeforeCalcPickBin(CrossDock: Boolean; ItemNo: Code[20]; LocationCode: Code[10]; QtyPerUnitofMeasure: Decimal; sender: Codeunit "Create Pick"; ToBinCode: Code[20]; UnitofMeasureCode: Code[10]; var IsHandled: Boolean; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; var TotalQtytoPick: Decimal; var TotalQtytoPickBase: Decimal; VariantCode: Code[10]; WhseSource: Option; WhseTrackingExists: Boolean)
    begin
        IF FindPickBinWithHandyOption(LocationCode, ItemNo, VariantCode, UnitofMeasureCode, ToBinCode, TempWarehouseActivityLine, TotalQtytoPick, TempWhseItemTrackingLine, CrossDock, TotalQtytoPickBase, True, sender) then
            IsHandled := true
        else
            IF FindPickBinWithHandyOption(LocationCode, ItemNo, VariantCode, UnitofMeasureCode, ToBinCode, TempWarehouseActivityLine, TotalQtytoPick, TempWhseItemTrackingLine, CrossDock, TotalQtytoPickBase, false, sender) then
                IsHandled := true;



    end;

    local procedure FindPickBinWithHandyOption(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; ToBinCode: Code[20]; var TempWhseActivLine2: Record "Warehouse Activity Line" temporary; var TotalQtytoPick: Decimal; var TempWhseItemTrkgLine: Record "Whse. Item Tracking Line"; CrossDock: Boolean; var TotalQtytoPickBase: Decimal; HandyBin: Boolean; sender: Codeunit "Create Pick"): Boolean
    var
        FromBinContent: Record "Bin Content";
        WhseItemTrackingSetup: record "Item Tracking Setup" temporary;
        CreatePick: Codeunit "Create Pick";
        FromQtyToPick: Decimal;
        FromQtyToPickBase: Decimal;
        ToQtyToPick: Decimal;
        ToQtyToPickBase: Decimal;
        TotalAvailQtyToPickBase: Decimal;
        AvailableQtyBase: Decimal;
        WhseSource: Option "Pick Worksheet",Shipment,"Movement Worksheet","Internal Pick",Production,Assembly,Job;
    begin
        GetBin(LocationCode, ToBinCode);
        GetLocation(LocationCode);
        BinHandyFilter := TRUE;
        BinHandyValueFilter := HandyBin;
        if (CreatePickParametersGlobal."Whse. Document" = CreatePickParametersGlobal."Whse. Document"::Shipment) and AssembletoOrder then
            WhseSource := CreatePickParametersGlobal."Whse. Document"::Assembly
        else
            WhseSource := CreatePickParametersGlobal."Whse. Document";

        IF BinContentExists(FromBinContent, ItemNo, LocationCode, UnitofMeasureCode, VariantCode, CrossDock, TRUE, TRUE, TempWhseItemTrkgLine) THEN BEGIN
            TotalAvailQtyToPickBase := sender.CalcTotalAvailQtyToPick(LocationCode, ItemNo, VariantCode, TempWhseItemTrkgLine, SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, TotalQtytoPickBase, FALSE);
            IF TotalAvailQtyToPickBase < 0 THEN
                TotalAvailQtyToPickBase := 0;
            WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(TempWhseItemTrkgLine);
            REPEAT
                IF (FromBinContent."Bin Code" <> ToBinCode) AND
                   ((UseForPick(FromBinContent) AND (WhseSource <> WhseSource::"Movement Worksheet")) OR
                    (UseForReplenishment(FromBinContent) AND (WhseSource = WhseSource::"Movement Worksheet")))
                THEN BEGIN
                    sender.CalcBinAvailQtyToPick(AvailableQtyBase, FromBinContent, TempWhseActivLine2, WhseItemTrackingSetup);
                    IF TotalAvailQtyToPickBase < AvailableQtyBase THEN
                        AvailableQtyBase := TotalAvailQtyToPickBase;

                    IF TotalQtytoPickBase < AvailableQtyBase THEN
                        AvailableQtyBase := TotalQtytoPickBase;

                    IF TotalQtytoPickBase <= AvailableQtyBase THEN BEGIN
                        ToQtyToPickBase := sender.CalcQtyToPickBaseExt(FromBinContent, TempWhseActivLine2);
                        IF AvailableQtyBase > ToQtyToPickBase THEN
                            AvailableQtyBase := ToQtyToPickBase;

                        CreatePick.UpdateQuantitiesToPick(
                          AvailableQtyBase,
                          FromBinContent."Qty. per Unit of Measure", FromQtyToPick, FromQtyToPickBase,
                          FromBinContent."Qty. per Unit of Measure", ToQtyToPick, ToQtyToPickBase,
                          TotalQtytoPick, TotalQtytoPickBase);

                        CreatePick.CreateTempActivityLine(
                          LocationCode, FromBinContent."Bin Code", UnitofMeasureCode, FromBinContent."Qty. per Unit of Measure", FromQtyToPick, FromQtyToPickBase, 1, 0);
                        CreatePick.CreateTempActivityLine(
                          LocationCode, ToBinCode, UnitofMeasureCode, FromBinContent."Qty. per Unit of Measure", ToQtyToPick, ToQtyToPickBase, 2, 0);

                        TotalAvailQtyToPickBase := TotalAvailQtyToPickBase - ToQtyToPickBase;
                    END;
                END;
            UNTIL (FromBinContent.NEXT = 0) OR (TotalQtytoPickBase = 0);
        END;

        IF TotalQtytoPickBase = 0 THEN
            EXIT(TRUE);

        EXIT(FALSE);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    var
        WhseSetupLocation: record Location;
    begin
        WhseSetupLocation.GetLocationSetup('', WhseSetupLocation);
        IF LocationCode = '' THEN
            Location := WhseSetupLocation
        ELSE
            IF Location.Code <> LocationCode THEN
                Location.GET(LocationCode);
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        IF (Bin."Location Code" <> LocationCode) OR
           (Bin.Code <> BinCode)
        THEN
            IF NOT Bin.GET(LocationCode, BinCode) THEN
                CLEAR(Bin);
    end;

    procedure BinContentExists(var BinContent: Record "Bin Content"; ItemNo: Code[20]; LocationCode: Code[10]; UOMCode: Code[10]; VariantCode: Code[10]; CrossDock: Boolean; LNRequired: Boolean; SNRequired: Boolean; var TempWhseItemTrkgLine: Record "Whse. Item Tracking Line"): Boolean
    begin
        BinContent.SETCURRENTKEY("Location Code", "Item No.", "Variant Code", "Cross-Dock Bin", "Qty. per Unit of Measure", "Bin Ranking");
        BinContent.SETRANGE("Location Code", LocationCode);
        BinContent.SETRANGE("Item No.", ItemNo);
        BinContent.SETRANGE("Variant Code", VariantCode);
        BinContent.SETRANGE("Cross-Dock Bin", CrossDock);
        BinContent.SETRANGE("Unit of Measure Code", UOMCode);
        IF WhseSource = WhseSource::"Movement Worksheet" THEN
            BinContent.SETFILTER("Bin Ranking", '<%1', Bin."Bin Ranking");
        IF NOT TempWhseItemTrkgLine.IsEmpty THEN BEGIN
            IF LNRequired THEN
                BinContent.SETRANGE("Lot No. Filter", TempWhseItemTrkgLine."Lot No.")
            ELSE
                BinContent.SETFILTER("Lot No. Filter", '%1|%2', TempWhseItemTrkgLine."Lot No.", '');
            IF SNRequired THEN
                BinContent.SETRANGE("Serial No. Filter", TempWhseItemTrkgLine."Serial No.")
            ELSE
                BinContent.SETFILTER("Serial No. Filter", '%1|%2', TempWhseItemTrkgLine."Serial No.", '');
        END;

        BinContent.ASCENDING(FALSE);
        EXIT(NOT BinContent.IsEmpty);
    end;

    local procedure UseForPick(FromBinContent: Record "Bin Content") IsForPick: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;

        if IsHandled then
            exit(IsForPick);

        if FromBinContent."Block Movement" in [FromBinContent."Block Movement"::Outbound, FromBinContent."Block Movement"::All] then
            exit(false);

        GetBinType(FromBinContent."Bin Type Code");
        exit(BinType.Pick);
    end;

    local procedure GetBinType(BinTypeCode: Code[10])
    begin
        if BinTypeCode = '' then
            BinType.Init()
        else
            if BinType.Code <> BinTypeCode then
                BinType.Get(BinTypeCode);
    end;

    local procedure UseForReplenishment(FromBinContent: Record "Bin Content"): Boolean
    begin
        if FromBinContent."Block Movement" in [FromBinContent."Block Movement"::Outbound, FromBinContent."Block Movement"::All] then
            exit(false);

        GetBinType(FromBinContent."Bin Type Code");
        exit(not (BinType.Receive or BinType.Ship));
    end;

    var
        WhseSource: Option "Pick Worksheet",Shipment,"Movement Worksheet","Internal Pick",Production,Assembly,Job;
        AssembletoOrder: Boolean;
        SourceType: Integer;
        SourceSubType: Option;
        SourceNo: Code[20];
        SourceLineNo: Integer;
        SourceSubLineNo: Integer;
        CreatePickParametersGlobal: Record "Create Pick Parameters" temporary;
        BinHandyFilter: Boolean;
        BinHandyValueFilter: Boolean;
        BinType: record "Bin Type";
        Bin: Record Bin;
        Location: Record Location;
}

