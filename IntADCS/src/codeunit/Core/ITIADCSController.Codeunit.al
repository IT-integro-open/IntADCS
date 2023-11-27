codeunit 69117 "ITI ADCS Controller"
{
    var
        ITIXMLDOMManagement: Codeunit "ITI XML DOM Management";
        PageType: Enum "ITI ADCS Form Type";
        GlobalContent: Text;

    procedure StartADCS(): Text
    var
        ITIADCSWS: Codeunit "ITI ADCS WS";
        Content: Text;
    begin
        Content := Content + '<ADCS>';
        Content := Content + '<Header ID="38583594" Sequence="0" UseCaseCode="hello" />';
        Content := Content + '</ADCS>';
        ITIADCSWS.ProcessDocument(Content);
        GlobalContent := Content;
        exit(Content);
    end;

    procedure NextADCSPage(InputFieldContent: Text): Text
    var
        ITIADCSWS: Codeunit "ITI ADCS WS";
        ITIXMLParser: Codeunit "ITI ADCS XML Parser";
        No, TableNo, RecordID, InerText, InputFieldId : Text;
        Content: Text;
    begin
        GetPageType();

        case PageType of
            PageType::"Data List", PageType::"Selection List":
                ITIXMLParser.FindSelectedValue(GlobalContent, InputFieldContent, No, TableNo, RecordID, InerText);
            PageType::Card, PageType::"Data List Input", PageType::Document:
                ITIXMLParser.GetInputAttributes(GlobalContent, InputFieldId, No, TableNo, RecordID, InerText, InputFieldContent);
        end;

        Content := ITIXMLParser.ParseXMLInput(GlobalContent, No, TableNo, RecordID, InputFieldId, InerText);
        ITIADCSWS.ProcessDocument(Content);
        GlobalContent := Content;
        exit(Content);
    end;


    local procedure GetPageType()
    var
        ContentXmlDocument: XmlDocument;
        RootNode: XmlNode;
    begin
        XmlDocument.ReadFrom(GlobalContent, ContentXmlDocument);
        ITIXMLDOMManagement.GetRootNode(ContentXmlDocument, RootNode);
        ITIXMLDOMManagement.FindNode(RootNode, 'Header', RootNode);
        Evaluate(PageType, ITIXMLDOMManagement.GetAttributeValue(RootNode, 'FormTypeOpt'));
    end;

    procedure CheckCurrPage(ExpectedPageName: Text)
    var
        Xml: XmlDocument;
        RootNode: XmlNode;
        CurrPageName: Text;
    begin
        XmlDocument.ReadFrom(GlobalContent, Xml);
        ITIXMLDOMManagement.GetRootNode(Xml, RootNode);
        ITIXMLDOMManagement.FindNode(RootNode, 'Header', RootNode);
        CurrPageName := ITIXMLDOMManagement.GetAttributeValue(RootNode, 'UseCaseCode');
        if ExpectedPageName <> CurrPageName then
            Error('Expected page was not opened!');
    end;

}