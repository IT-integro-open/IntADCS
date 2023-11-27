page 69090 ITIADCS
{
    PageType = Card;
    ApplicationArea = all;
    UsageCategory = Administration;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    layout
    {
        area(Content)
        {
            usercontrol(ControlName; ITIADCSControl)
            {

                ApplicationArea = All;
                trigger OpenPage()
                begin
                    CreatePageContent(ITIADCSCommunicationInter.StartADCS());
                end;

                trigger SendInputValue(InputContent: Text)
                begin
                    CreatePageContent(ITIADCSCommunicationInter.NextADCSPage(InputContent));
                end;

            }
        }
    }

    local procedure CreatePageContent(PageXMLContent: Text)
    var
        ITIHtmlParser: Codeunit "ITI ADCS Html Parser";
        MakeSound: Boolean;
        PageHTMLContent: Text;
    begin
        PageHTMLContent := ITIHtmlParser.CreteHtmlFromXML(PageXMLContent, MakeSound);
        CurrPage.ControlName.loadContent(PageHTMLContent, MakeSound);
    end;


    var
        ITIADCSCommunicationInter: Codeunit "ITI ADCS Controller";
}