/// <summary>
/// Report ITI ADCS User (ID 69050).
/// </summary>
report 69050 "ITI ADCS User"
{
    ApplicationArea = All;
    Caption = 'ADCS User';
    DefaultLayout = RDLC;
    RDLCLayout = './src/report/RDLC/ADCS User.rdlc';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("ITI ADCS User"; "ITI ADCS User")
        {
            column(Name; Name)
            {
            }
            column(ADCS_User_Barcode; TempTenantMedia.Content)
            {
            }
            column(FullName; FullName)
            {
            }
            column(Picture; CompanyInfo.Picture)
            {
            }

            trigger OnAfterGetRecord()
            var
                User: Record User;
            begin
                ITIBarcodeMgt2.EncodeCode128(FORMAT(Name), 1, false, TempTenantMedia);
                User.SetRange("User Name", Name);
                User.SetLoadFields("Full Name");
                if User.FindFirst() then
                    FullName := User."Full Name";
            end;

        }
    }

    trigger OnInitReport()
    begin
        CompanyInfo.Get();
        CompanyInfo.CalcFields(Picture);
    end;

    var
        TempTenantMedia: Record "Tenant Media" temporary;
        CompanyInfo: Record "Company Information";
        ITIBarcodeMgt2: Codeunit "ITI Barcode Mgt";
        FullName: Text[80];
}
