codeunit 69079 "ITI Warehouse Document-Print"
{
    procedure PrintBinLabel(PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header")
    var
        ReportSelectionWhse: Record "Report Selection Warehouse";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintBinLabel(PostedWhseShipmentHeader, IsHandled);
        if IsHandled then
            exit;

        PostedWhseShipmentHeader.SetRange("No.", PostedWhseShipmentHeader."No.");
        ReportSelectionWhse.PrintPostedWhseShipmentHeader(PostedWhseShipmentHeader, false);
    end;
    /*
        procedure PrintBinLabel(Bin: Record "7354")
        begin

            Bin.SETRANGE("Location Code", Bin."Location Code");
            Bin.SETRANGE(Code, Bin.Code);
            REPORT.RUN(REPORT::"Bin - Labels", TRUE, FALSE, Bin);

        end;
            procedure PrintRcptLabelFromHdr(RcptHeader: Record "7316")
        var
            RcptLine: Record "7317";
        begin
            // START/ASM/ADCS/009
            RcptLine.SETRANGE("No.", RcptHeader."No.");
            RcptLine.SETFILTER("Labels Quantity", '<>%1', 0);
            REPORT.RUN(REPORT::"Whse. - Receipt Labels", TRUE, FALSE, RcptLine);
            // STOP /ASM/ADCS/009
        end;

        [Scope('Internal')]
        procedure PrintRcptLabelFromLine(RcptLine: Record "7317")
        begin
            // START/ASM/ADCS/009
            RcptLine.SETRANGE("No.", RcptLine."No.");
            RcptLine.SETRANGE(RcptLine."Line No.", RcptLine."Line No.");
            REPORT.RUN(REPORT::"Whse. - Receipt Labels", TRUE, FALSE, RcptLine);
            // STOP /ASM/ADCS/009
        end;

        [Scope('Internal')]
        procedure PrintPackage(PackageHeader: Record "50015")
        begin
            // START/ASM/ADCS/009
            PackageHeader.SETRANGE("No.", PackageHeader."No.");
            REPORT.RUN(REPORT::"Whse. - Package Labels", TRUE, FALSE, PackageHeader);
            // STOP /ASM/ADCS/009
        end;
        */
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintBinLabel(var PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header"; var IsHandled: Boolean)
    begin
    end;

}
