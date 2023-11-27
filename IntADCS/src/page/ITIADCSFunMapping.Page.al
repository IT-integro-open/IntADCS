page 69064 "ITI ADCS Fun. Mapping"
{
    ApplicationArea = ADCS;
    PageType = Card;
    UsageCategory = None;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            usercontrol(ControlName; "ITI ADCS Keys Function SetUp")
            {
                ApplicationArea = All;
                trigger OpenPage()
                var
                    ITIADCSFunMapping: Codeunit "ITI ADCS Fun. Mapping";
                    HtmlContent: Text;
                begin
                    HtmlContent := ITIADCSFunMapping.CreateHtmlPage(GlobalMiniformName, GlobalFunctionCode);
                    CurrPage.ControlName.loadContent(HtmlContent);
                end;

                trigger SaveFunctionMapping(KeyValue: Text)
                var
                    ITIADCSFunMapping: Codeunit "ITI ADCS Fun. Mapping";
                begin
                    ITIADCSFunMapping.SaveKeyMapping(GlobalMiniformName, GlobalFunctionCode, KeyValue);
                    CurrPage.Close();
                end;
            }
        }
    }


    procedure SetPageAttr(MiniformName: Text; FunctionCode: Text)
    begin
        GlobalMiniformName := MiniformName;
        GlobalFunctionCode := FunctionCode;
    end;

    var
        GlobalMiniformName: Text;
        GlobalFunctionCode: Text;
}