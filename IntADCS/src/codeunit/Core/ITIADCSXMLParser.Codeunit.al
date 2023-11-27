codeunit 69114 "ITI ADCS XML Parser"
{
    procedure ParseXMLInput(XMLContent: Text; No: Text; TableNo: Text; RecordID: Text; InputFieldId: Text; InputContent: Text): Text
    var
        NewXmlElement: XmlElement;
        InputXmlDocument: XmlDocument;
        Output: Text;
        NewNode: XmlNode;
        ReturnedNode: XmlNode;
        RootNode: XmlNode;
    begin
        XmlDocument.ReadFrom(XMLContent, InputXmlDocument);
        ITIXMLDOMManagement.GetRootNode(InputXmlDocument, RootNode);
        ITIXMLDOMManagement.FindNode(RootNode, 'Header', ReturnedNode);
        MiniformCode := ITIXMLDOMManagement.GetAttributeValue(ReturnedNode, 'UseCaseCode');
        NewNode := XmlElement.Create('Input').AsXmlNode();
        ITIXMLDOMManagement.AddAttribute(NewNode, 'FieldID', InputFieldId);
        ITIXMLDOMManagement.AddAttribute(NewNode, 'No', No);
        ITIXMLDOMManagement.AddAttribute(NewNode, 'TableNo', TableNo);
        ITIXMLDOMManagement.AddAttribute(NewNode, 'RecordID', RecordID);
        NewXmlElement := NewNode.AsXmlElement();
        NewXmlElement.Add(InputContent);
        NewNode := NewXmlElement.AsXmlNode();
        ReturnedNode.AsXmlElement().Add(NewNode);
        if ITIXMLDOMManagement.FindNode(RootNode, 'Header//Comment', ReturnedNode) then
            ReturnedNode.Remove();
        InputXmlDocument.WriteTo(Output);
        Output := DelChr(Output, '<', '<?xml version="1.0" encoding="utf-16"?>');
        exit(Output);
    end;

    procedure FindSelectedValue(XMLContent: Text; SelectedLine: Text; var No: Text; var TableNo: Text; var RecordID: Text; var Content: Text)
    var
        InputXmlDocument: XmlDocument;
        RootNode: XmlNode;
        ReturnedNode: XmlNode;
        SelectedLineNo: Integer;
        LinesNode: XmlNodeList;
        IterNode: XmlNode;
        ChildNode: XmlNode;
    begin
        XmlDocument.ReadFrom(XMLContent, InputXmlDocument);
        ITIXMLDOMManagement.GetRootNode(InputXmlDocument, RootNode);

        ITIXMLDOMManagement.FindNode(RootNode, 'Header', ReturnedNode);
        MiniformCode := ITIXMLDOMManagement.GetAttributeValue(ReturnedNode, 'UseCaseCode');

        GetFunctionsNames();
        if not ((FunctionsName.Contains(SelectedLine.ToUpper())) or (FunctionKeys.Contains(SelectedLine.ToUpper()))) then begin
            Evaluate(SelectedLineNo, SelectedLine);
            SelectedLineNo -= 1;
        end else
            SelectedLineNo := 0;

        ITIXMLDOMManagement.FindNode(RootNode, 'Lines//Body', ReturnedNode);
        LinesNode := ReturnedNode.AsXmlElement().GetChildElements();
        foreach IterNode in LinesNode do
            if ITIXMLDOMManagement.GetAttributeValue(IterNode, 'No') = Format(SelectedLineNo) then begin
                No := Format(SelectedLineNo);
                TableNo := ITIXMLDOMManagement.GetAttributeValue(IterNode, 'TableNo');
                RecordID := ITIXMLDOMManagement.GetAttributeValue(IterNode, 'RecordID');

                if FunctionsName.Contains(SelectedLine.ToUpper()) then
                    Content := SelectedLine
                else
                    if FunctionKeys.Contains(SelectedLine.ToUpper()) then
                        Content := GetKeyFuction(SelectedLine)
                    else
                        if IterNode.AsXmlElement().GetChildElements().Count > 0 then begin
                            ITIXMLDOMManagement.FindNode(IterNode, 'Field', ChildNode);
                            Content := ChildNode.AsXmlElement().InnerText;
                        end;
            end;
    end;

    procedure GetInputAttributes(XMLContent: Text; var FieldNo: Text; var No: Text; var TableNo: Text; var RecordID: Text; var InerText: Text; FieldInputContent: Text)
    var
        InputXmlDocument: XmlDocument;
        RootNode: XmlNode;
        ReturnedNode: XmlNode;
        LinesNode: XmlNodeList;
        InputNode: XmlNode;
        ParentInputNode: XmlNode;
        ParentInputElement: XmlElement;
    begin
        XmlDocument.ReadFrom(XMLContent, InputXmlDocument);
        ITIXMLDOMManagement.GetRootNode(InputXmlDocument, RootNode);

        ITIXMLDOMManagement.FindNode(RootNode, 'Header', ReturnedNode);
        MiniformCode := ITIXMLDOMManagement.GetAttributeValue(ReturnedNode, 'UseCaseCode');
        GetFunctionsNames();

        ITIXMLDOMManagement.FindNode(RootNode, 'Lines//Body', ReturnedNode);
        LinesNode := ReturnedNode.AsXmlElement().GetChildElements();
        if FindInputField(RootNode, InputNode) then begin
            InputNode.GetParent(ParentInputElement);
            ParentInputNode := ParentInputElement.AsXmlNode();
            FieldNo := ITIXMLDOMManagement.GetAttributeValue(InputNode, 'FieldID');
            TableNo := ITIXMLDOMManagement.GetAttributeValue(InputNode, 'TableNo');
            RecordID := ITIXMLDOMManagement.GetAttributeValue(InputNode, 'RecordID');
        end
        else
            LinesNode.Get(1, ParentInputNode);

        No := ITIXMLDOMManagement.GetAttributeValue(ParentInputNode, 'No');
        if TableNo = '' then
            TableNo := ITIXMLDOMManagement.GetAttributeValue(ParentInputNode, 'TableNo');
        if RecordID = '' then
            RecordID := ITIXMLDOMManagement.GetAttributeValue(ParentInputNode, 'RecordID');

        if FunctionKeys.Contains(FieldInputContent.ToUpper()) then
            InerText := GetKeyFuction(FieldInputContent)
        else
            InerText := FieldInputContent;
    end;

    local procedure FindInputField(RootNode: XmlNode; var InputNode: XmlNode): Boolean
    var
        RootChildrensList: XmlNodeList;
        IterNode: XmlNode;
    begin
        RootChildrensList := RootNode.AsXmlElement().GetDescendantElements();
        foreach IterNode in RootChildrensList do
            if IterNode.AsXmlElement().Name = 'Field' then
                if ITIXMLDOMManagement.GetAttributeValue(IterNode, 'Type') = 'Input' then begin
                    InputNode := IterNode;
                    exit(true);
                end;
        exit(false);
    end;

    local procedure GetFunctionsNames()
    var
        ITIMiniformFunction: Record "ITI Miniform Function";
        ITIKeyDef: Enum "ITI KeyDef";
        IterFunction: Text;
    begin
        foreach IterFunction in ITIKeyDef.Names do
            FunctionsName.Add(IterFunction.ToUpper());

        ITIMiniformFunction.SetRange("Miniform Code", MiniformCode);
        if ITIMiniformFunction.FindSet() then
            repeat
                FunctionKeys.Add(ITIMiniformFunction."Keyboard Key".ToUpper());
            until ITIMiniformFunction.Next() = 0;
    end;

    local procedure GetKeyFuction(KeyFunc: Text): Text
    var
        ITIMiniformFunction: Record "ITI Miniform Function";
    begin
        ITIMiniformFunction.SetRange("Miniform Code", MiniformCode);
        ITIMiniformFunction.SetRange("Keyboard Key", KeyFunc);
        if ITIMiniformFunction.FindFirst() then
            exit(ITIMiniformFunction."Function Code")
        else
            exit('');
    end;

    var
        ITIXMLDOMManagement: Codeunit "ITI XML DOM Management";
        FunctionKeys: List of [Text];
        FunctionsName: List of [Text];
        MiniformCode: Text;
}