/// <summary>
/// Report ITI Item Label (ID 69055).
/// </summary>
report 69055 "ITI Item Label"
{
    ApplicationArea = All;
    Caption = 'Item Label';
    DefaultLayout = RDLC;
    RDLCLayout = './src/report/RDLC/ItemLabel.rdl';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            column(ItemNo; "No.")
            {
            }
            column(ItemNoBarcode; TempTenantMedia.Content)
            {
            }
            column(Description; Description)
            {
            }
            column(Description2; "Description 2")
            {
            }
            column(OrderNo; OrderNo)
            {
            }
            column(VendorName; VendorName)
            {
            }
            column(DeliveryDate; DeliveryDate)
            {
            }

            trigger OnAfterGetRecord()
            var
                ITIItemLabelMgt: Codeunit "ITI Item Label Mgt.";
                Result: Boolean;
            begin
                ITIBarcodeMgt2.EncodeCode128(FORMAT("No."), 1, FALSE, TempTenantMedia);
                if PrintOrderDetails then begin
                    Result := ITIItemLabelMgt.HandleWarehouseReceipt(WarehouseReceiptHeader, Item."No.", OrderNoSource, VendorSourceName, DeliverysourceDate);
                    OrderNo := OrderNoLbl + OrderNoSource;
                    if Result then begin
                        VendorName := VendorNameLbl + VendorSourceName;
                        DeliveryDate := ReceiptDateLbl + Format(DeliverysourceDate, 0, '<Day,2>.<Month,2>.<Year4>');
                    end;
                    exit;
                end;
                if PrintOrderDetailsForPostedReceipt then begin
                    Result := ITIItemLabelMgt.HandlePostedWarehouseReceipt(PostedWhseReceiptHeader, Item."No.", OrderNoSource, VendorSourceName, DeliverysourceDate);
                    OrderNo := OrderNoLbl + OrderNoSource;
                    if Result then begin
                        VendorName := VendorNameLbl + VendorSourceName;
                        DeliveryDate := ReceiptDateLbl + Format(DeliverysourceDate, 0, '<Day,2>.<Month,2>.<Year4>');
                    end;
                    exit;
                end;
            end;
        }
    }

    var
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        TempTenantMedia: Record "Tenant Media" temporary;
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WhseReceiptLines: Record "Warehouse Receipt Line";
        PostedWhseReceiptLines: Record "Posted Whse. Receipt Line";
        ITIBarcodeMgt2: codeunit "ITI Barcode Mgt";
        OrderNoLbl: Label 'PO no: ';
        ReceiptDateLbl: Label 'Receipt date: ';
        VendorNameLbl: Label 'Vendor: ';
        DeliveryDate: Text[50];
        OrderNoSource: Text[20];
        OrderNo: Text[50];
        VendorName: Text[120];
        VendorSourceName: Text[50];
        DeliverysourceDate: Date;
        PrintOrderDetails: Boolean;
        PrintOrderDetailsForPostedReceipt: Boolean;


    /// <summary>
    /// SetWarehouseReceiptHeader.
    /// </summary>
    /// <param name="WhseReceptLine">VAR Record "Warehouse Receipt Line".</param>
    // procedure SetWarehouseReceiptHeader(var WhseReceptLine: Record "Warehouse Receipt Line")
    // begin
    //     WhseReceiptLines.Copy(WhseReceptLine);
    //     WarehouseReceiptHeader.Get(WhseReceiptLines."No.");
    //     PrintOrderDetails := true;
    // end;

    /// <summary>
    /// SetPostedWarehouseReceiptHeader.
    /// </summary>
    /// <param name="PstdWhseReceiptLine">VAR Record "Posted Whse. Receipt Line".</param>
    procedure SetPostedWarehouseReceiptHeader(var PstdWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
        PostedWhseReceiptLines.Copy(PstdWhseReceiptLine);
        PostedWhseReceiptHeader.Get(PostedWhseReceiptLines."No.");
        PrintOrderDetailsForPostedReceipt := true;
    end;

    procedure SetWarehouseReceiptHeader(WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        PrintOrderDetails := true;
    end;
}
