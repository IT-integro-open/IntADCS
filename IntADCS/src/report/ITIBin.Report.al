report 69051 "ITI Bin"
{
    ApplicationArea = All;
    Caption = 'Bin';
    DefaultLayout = RDLC;
    RDLCLayout = './src/report/RDLC/Bin.rdl';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("ITI Bin"; Bin)
        {
            column(Code; Code)
            {
            }
            column(Bin_Barcode; TempTenantMedia.Content)
            {
            }

            trigger OnAfterGetRecord()
            begin
                ITIBarcodeMgt2.EncodeCode128(FORMAT(Code), 1, FALSE, TempTenantMedia);
            end;

        }
    }

    var
        TempTenantMedia: Record "Tenant Media" temporary;
        ITIBarcodeMgt2: Codeunit "ITI Barcode Mgt";
}
