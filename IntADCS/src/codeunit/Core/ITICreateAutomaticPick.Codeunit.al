/// <summary>
/// Codeunit ITI Create Automatic Pick (ID 69065).
/// </summary>
codeunit 69065 "ITI Create Automatic Pick"
{
    TableNo = "Warehouse Request";
    trigger OnRun()
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        WhseShptLine.SetRange("Source No.", Rec."Source No.");
        WhseShptLine.SetRange("Location Code", Rec."Location Code");
        if WhseShptLine.FindLast() and WarehouseShipmentHeader.Get(WhseShptLine."No.") then
            CreatePick(WhseShptLine, WarehouseShipmentHeader, false);
    end;

    /// <summary>
    /// CreatePick.
    /// </summary>
    /// <param name="WhseShptLine">VAR Record "Warehouse Shipment Line".</param>
    /// <param name="WarehouseShipmentHeader">VAR Record "Warehouse Shipment Header".</param>
    /// <param name="ShowPickResultMsg">Boolean.</param>
    procedure CreatePick(var WhseShptLine: Record "Warehouse Shipment Line"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ShowPickResultMsg: Boolean)
    var
        WhseShipmentCreatePick: Report "Whse.-Shipment - Create Pick";
        ReleaseWhseShipment: Codeunit "Whse.-Shipment Release";
    begin
        if WarehouseShipmentHeader.Status = WarehouseShipmentHeader.Status::Open then
            ReleaseWhseShipment.Release(WarehouseShipmentHeader);

        WhseShptLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WhseShptLine.SetRange("Completely Picked", false);
        WhseShptLine.SetFilter(Quantity, '>0');
        if WhseShptLine.FindFirst() then begin
            WhseShipmentCreatePick.SetWhseShipmentLine(WhseShptLine, WarehouseShipmentHeader);
            WhseShipmentCreatePick.UseRequestPage(false);
            WhseShipmentCreatePick.RunModal();
            if ShowPickResultMsg then
                WhseShipmentCreatePick.GetResultMessage();
            Clear(WhseShipmentCreatePick);
        end;
    end;
}