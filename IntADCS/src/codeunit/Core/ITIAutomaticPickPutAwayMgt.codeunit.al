/// <summary>
/// Codeunit ITI Automatic Pick PutAway Mgt (ID 69069).
/// </summary>
codeunit 69069 "ITI Automatic Pick PutAway Mgt"
{
    /// <summary>
    /// PostReceiptCreatePutAway.
    /// </summary>
    /// <param name="WarehouseRequest">VAR record "Warehouse Request".</param>
    procedure PostReceiptCreatePutAway(var WarehouseRequest: record "Warehouse Request")
    var
        WhseReceiptLines: Record "Warehouse Receipt Line";
    begin
        WhseReceiptLines.SetRange("Source No.", WarehouseRequest."Source No.");
        WhseReceiptLines.SetRange("Location Code", WarehouseRequest."Location Code");
        if WhseReceiptLines.FindLast() then
            CODEUNIT.Run(CODEUNIT::"Whse.-Post Receipt", WhseReceiptLines);
    end;

    /// <summary>
    /// PostReceiptCreatePutAway.
    /// </summary>
    /// <param name="WarehouseReceiptHeader">VAR Record "Warehouse Receipt Header".</param>
    procedure PostReceiptCreatePutAway(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    var
        WhseReceiptLines: Record "Warehouse Receipt Line";
    begin
        WhseReceiptLines.SetRange("No.", WarehouseReceiptHeader."No.");
        WhseReceiptLines.SetRange("Location Code", WarehouseReceiptHeader."Location Code");
        if WhseReceiptLines.FindLast() then
            CODEUNIT.Run(CODEUNIT::"Whse.-Post Receipt", WhseReceiptLines);
    end;


    /// <summary>
    /// AutomaticPick.
    /// </summary>
    /// <param name="WarehouseRequest">VAR Record "Warehouse Request".</param>
    /// <param name="WhseShipmentHeader">VAR Record "Warehouse Shipment Header".</param>
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure AutomaticPick(var WarehouseRequest: Record "Warehouse Request"; var WhseShipmentHeader: Record "Warehouse Shipment Header")
    var
        Location: Record Location;
        TempErrorMessage: Record "Error Message" temporary;
        ErrorInf: ErrorInfo;
        ErrorDescriptionLbl: label 'Problem with pick creation on Location %1: %2', Comment = '%1 location %2 error description';
    begin
        if WarehouseRequest.FindSet() then
            if (WarehouseRequest.Count > 1) and (CheckLocationFilterNotSingular(WarehouseRequest.GetFilter("Location Code"))) then
                repeat
                    if Location.Get(WarehouseRequest."Location Code") and Location."ITI Automatic Create Pick" then begin
                        Commit();
                        if not Codeunit.Run(Codeunit::"ITI Create Automatic Pick", WarehouseRequest) then begin
                            TempErrorMessage.ID := TempErrorMessage.ID + 1;
                            TempErrorMessage.Message := StrSubstNo(ErrorDescriptionLbl, WarehouseRequest."Location Code", CopyStr(GetLastErrorText(), 1, MaxStrLen(TempErrorMessage.Message)));
                            TempErrorMessage.Insert();
                        end;
                    end;
                until WarehouseRequest.Next() = 0
            else
                if WarehouseRequest.Count = 1 then
                    if Location.Get(WhseShipmentHeader."Location Code") and Location."ITI Automatic Create Pick" then begin
                        Commit();
                        if not Codeunit.Run(Codeunit::"ITI Create Automatic Pick", WarehouseRequest) then begin
                            TempErrorMessage.ID := TempErrorMessage.ID + 1;
                            TempErrorMessage.Message := StrSubstNo(ErrorDescriptionLbl, WarehouseRequest."Location Code", CopyStr(GetLastErrorText(), 1, MaxStrLen(TempErrorMessage.Message)));
                            TempErrorMessage.Insert();
                        end;
                    end;

        if HasCollectedErrors then
            foreach ErrorInf in system.GetCollectedErrors() do begin
                TempErrorMessage.ID := TempErrorMessage.ID + 1;
                TempErrorMessage.Message := CopyStr(ErrorInf.Message, 1, MaxStrLen(TempErrorMessage.Message));
                TempErrorMessage.Validate("Record ID", ErrorInf.RecordId);
                TempErrorMessage.Insert();
            end;
        ClearCollectedErrors();
        if not TempErrorMessage.IsEmpty then
            page.RunModal(page::"Error Messages", TempErrorMessage);
    end;

    local procedure CheckLocationFilterNotSingular(LocationFilter: Text): Boolean
    var
        Location: Record Location;
    begin
        Location.SetRange(Code, LocationFilter);
        if Location.IsEmpty and (LocationFilter <> '') then
            exit(true)
        else
            exit(false)
    end;
}