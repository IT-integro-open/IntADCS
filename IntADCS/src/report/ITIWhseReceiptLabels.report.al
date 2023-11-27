report 69146 "Whse. - Receipt Labels"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Whse. - Receipt Labels';
    DefaultLayout = RDLC;
    PreviewMode = PrintLayout;
    RDLCLayout = './src/report/RDLC/WhseReceiptLabels.rdlc';

    dataset
    {
        dataitem("Warehouse Receipt Line"; "Warehouse Receipt Line")
        {
            CalcFields = "ITI EAN";
            dataitem(DataItem1000000001; Integer)
            {
                column(LotNo; LotNo)
                {
                }
                column(Barcode; recTmpBlob.Content)
                {
                }
                column(EANBarcode; recTmpBlobEAN.Content)
                {
                }
                column(EAN; "Warehouse Receipt Line"."ITI EAN")
                {
                }
                column(Description; "Warehouse Receipt Line".Description)
                {
                }
                column(ItemNo; "Warehouse Receipt Line"."Item No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    recTmpBlob.DELETEALL;
                    LotNo := '';
                    LotNo := NoSeriesMgt.GetNextNo(WarehouseSetup."ITI Lot Nos.", WORKDATE, ModifySeries);
                    cduBarcodeMgt.EncodeCode128(LotNo, 2, FALSE, recTmpBlob);

                    cduBarcodeMgt.EncodeCode128("Warehouse Receipt Line"."ITI EAN", 2, FALSE, recTmpBlobEAN);
                end;

                trigger OnPreDataItem()
                begin
                    SETRANGE(Number, 1, "Warehouse Receipt Line"."ITI Labels Quantity");
                end;
            }

            trigger OnPreDataItem()
            begin
                WarehouseSetup.GET;
                WarehouseSetup.TESTFIELD("ITI Lot Nos.");
                IF NOT CurrReport.PREVIEW THEN
                    ModifySeries := TRUE
                ELSE
                    ModifySeries := FALSE;
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        WarehouseSetup: Record 5769;
        recTmpBlob: Record "Tenant Media" temporary;
        recTmpBlobEAN: Record "Tenant Media" temporary;
        cduBarcodeMgt: Codeunit 69091;
        NoSeriesMgt: Codeunit 396;
        LotNo: Code[20];
        ModifySeries: Boolean;
}

