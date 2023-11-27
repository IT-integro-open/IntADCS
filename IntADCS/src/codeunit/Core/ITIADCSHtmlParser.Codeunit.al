codeunit 69113 "ITI ADCS Html Parser"
{
    procedure CreteHtmlFromXML(XMLContent: Text; var MakeSound: Boolean): Text
    var
        InputXmlDocument: XmlDocument;
        HTMLContent: TextBuilder;
        RootNode: XmlNode;
    begin
        CreatAttrHtmlMapping();
        XmlDocument.ReadFrom(XMLContent, InputXmlDocument);
        ITIXMLDOMManagement.GetRootNode(InputXmlDocument, RootNode);
        GetGlobalValues(RootNode);

        HTMLContent.AppendLine('<div ID="ADCSMainContainer" class="ADCS-ExternalContainer">');
        HTMLContent.AppendLine('    <div class="ADCS-Container">');
        HTMLContent.AppendLine('        <div class="ADCS-Navbar">');
        HTMLContent.AppendLine('            <div class="ADCS-ActionMenu-icon" onclick="toggleMenu()">');
        HTMLContent.AppendLine('                <span></span>');
        HTMLContent.AppendLine('                <span></span>');
        HTMLContent.AppendLine('                <span></span>');
        HTMLContent.AppendLine('            </div>');
        HTMLContent.AppendLine('            <div class="ADCS-InputContainer">');
        GetImputField(HTMLContent, RootNode);
        HTMLContent.AppendLine('            </div>');
        HTMLContent.AppendLine('        </div>');
        HTMLContent.AppendLine('        <div class="ADCS-Menu">');
        SetFunctions(HTMLContent, RootNode);
        HTMLContent.AppendLine('        </div>');
        SetComment(HTMLContent, RootNode, MakeSound);
        HTMLContent.AppendLine('        <div class="ADCS-Content">');
        CreteHTMLContent(HTMLContent, RootNode);
        HTMLContent.AppendLine('        </div>');
        HTMLContent.AppendLine('    </div>');
        HTMLContent.AppendLine('</div>');
        exit(HTMLContent.ToText());
    end;

    local procedure GetGlobalValues(RootNode: XmlNode)
    var
        TempNode: XmlNode;
    begin
        ITIXMLDOMManagement.FindNode(RootNode, 'Header', TempNode);
        GetXMLAttributes(TempNode, PageAttr);
        SetParserGlobalValues();
    end;

    local procedure SetParserGlobalValues()
    begin
        if PageAttr.ContainsKey('FormTypeOpt') then
            Evaluate(ADCSFormType, PageAttr.Get('FormTypeOpt'))
        else
            Error(PageTypeErr);

        if PageAttr.ContainsKey('InputIsHidden') then
            HideInput := PageAttr.Get('InputIsHidden') = '1';
    end;

    local procedure GetImputField(HTMLContent: TextBuilder; RootNode: XmlNode)
    var
        ParentInputElement: XmlElement;
        InputNodeAttributes: Dictionary of [Text, Text];
        ParentInputNodeAttributes: Dictionary of [Text, Text];
        InputNode: XmlNode;
    begin
        if (ADCSFormType = ADCSFormType::Card) or (ADCSFormType = ADCSFormType::"Data List Input") or (ADCSFormType = ADCSFormType::Document) then begin
            if FindInputField(RootNode, InputNode) then begin
                GetXMLAttributes(InputNode, InputNodeAttributes);
                InputNode.AsXmlElement().GetParent(ParentInputElement);
                GetXMLAttributes(ParentInputElement.AsXmlNode(), ParentInputNodeAttributes);

                ActiveInputFieldID := GetDictionartValue(InputNodeAttributes, 'FieldID');
                ActiveInputRecordID := GetDictionartValue(InputNodeAttributes, 'RecordID');
                ActiveInputFieldDescription := GetDictionartValue(InputNodeAttributes, 'Descrip');

                HTMLContent.AppendLine('<input class="ADCS-Input" ' + SetInputType() + ' id = "ADCSInput" placeholder="' + GetDictionartValue(InputNodeAttributes, 'Descrip') + '" autofocus/>');
                HTMLContent.AppendLine('<button id="ADCSButton" onclick="NextPage()" class="ADCS-NextButton" type="button">' + NextLbl + '</button>');
            end else begin
                HTMLContent.AppendLine('<input class="ADCS-Input" id = "ADCSInput" placeholder="' + SelectionLbl + '" autofocus />');
                HTMLContent.AppendLine('<button id="ADCSButton" onclick="NextPage()" class="ADCS-NextButton" type="button">' + NextLbl + '</button>');
            end;
        end else begin
            HTMLContent.AppendLine('<input class="ADCS-Input" id = "ADCSInput" placeholder="' + SelectionLbl + '" autofocus />');
            HTMLContent.AppendLine('<button id="ADCSButton" onclick="NextPage()" class="ADCS-NextButton" type="button">' + NextLbl + '</button>');
        end;
    end;

    local procedure FindInputField(RootNode: XmlNode; var InputNode: XmlNode): Boolean
    var
        IterNode: XmlNode;
        RootChildrensList: XmlNodeList;
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


    local procedure CreteHTMLContent(HTMLContent: TextBuilder; RootNode: XmlNode)
    var
        FirstElement: Boolean;
        ADCSArea: enum "ITI ADCS Area";
        DummyLineAttributes: Dictionary of [Text, Text];
        IterNode: XmlNode;
        LinesNode: XmlNode;
        XMLNodeList: XmlNodeList;
    begin
        if ITIXMLDOMManagement.FindNode(RootNode, 'Lines', LinesNode) then begin
            XMLNodeList := LinesNode.AsXmlElement().GetChildElements();
            foreach IterNode in XMLNodeList do begin
                Evaluate(ADCSArea, IterNode.AsXmlElement().Name);
                case ADCSArea of
                    ADCSArea::Header:
                        begin
                            FirstElement := true;
                            HTMLContent.AppendLine('<div class="ADCS-FormHeader-Container">');
                            ParseFieldAreaToHtml(HTMLContent, IterNode, ADCSArea, DummyLineAttributes, FirstElement);
                            HTMLContent.AppendLine('</div>')
                        end;
                    ADCSArea::Body:
                        case ADCSFormType of
                            ADCSFormType::Card, ADCSFormType::Document:
                                begin
                                    FirstElement := true;
                                    ParseFieldAreaToHtml(HTMLContent, IterNode, ADCSArea, DummyLineAttributes, FirstElement);
                                end;
                            ADCSFormType::"Data List":
                                ParseDataListBodyToHTML(HTMLContent, IterNode);
                            ADCSFormType::"Data List Input":
                                ParseDataListInputBodyToHtml(HTMLContent, IterNode);
                            ADCSFormType::"Selection List":
                                ParseSelectionLineBodyToHTML(HTMLContent, IterNode);
                            else
                                Error('Unknown Form Type');
                        end;
                    ADCSArea::Footer:
                        begin
                            FirstElement := true;
                            HTMLContent.AppendLine('<div class="ADCS-FormFooter-Container">');
                            ParseFieldAreaToHtml(HTMLContent, IterNode, ADCSArea, DummyLineAttributes, FirstElement);
                            HTMLContent.AppendLine('</div>')
                        end;
                    ADCSArea::Repeater:
                        ParseDocumentRepeaterToHTML(HTMLContent, IterNode);
                    else
                        Error('Unknown form array');
                end;
            end;
        end;
    end;

    local procedure ParseDataListInputBodyToHtml(var HTMLContent: TextBuilder; BodyNode: XmlNode)
    var
        FirstElement: Boolean;
        ADCSArea: enum "ITI ADCS Area";
        LineAttributes: Dictionary of [Text, Text];
        IterNode: XmlNode;
        XMLNodeList: XmlNodeList;
    begin
        XMLNodeList := BodyNode.AsXmlElement().GetChildElements();
        FirstElement := true;

        HTMLContent.AppendLine('<div >');
        foreach IterNode in XMLNodeList do begin
            GetXMLAttributes(IterNode, LineAttributes);
            ParseFieldAreaToHtml(HTMLContent, IterNode, ADCSArea::Body, LineAttributes, FirstElement);
        end;
        HTMLContent.AppendLine('</div >');
    end;

    local procedure ParseSelectionLineBodyToHTML(var HTMLContent: TextBuilder; BodyNode: XmlNode)
    var
        FirstElement: Boolean;
        ADCSArea: enum "ITI ADCS Area";
        LineAttributes: Dictionary of [Text, Text];
        IterNode: XmlNode;
        XMLNodeList: XmlNodeList;
    begin
        XMLNodeList := BodyNode.AsXmlElement().GetChildElements();
        FirstElement := true;
        HTMLContent.AppendLine('<div >');
        foreach IterNode in XMLNodeList do begin
            GetXMLAttributes(IterNode, LineAttributes);
            ParseFieldAreaToHtml(HTMLContent, IterNode, ADCSArea::Body, LineAttributes, FirstElement);
        end;
        HTMLContent.AppendLine('</div >');
    end;

    local procedure ParseDataListBodyToHTML(var HTMLContent: TextBuilder; BodyNode: XmlNode)
    var
        ADCSArea: enum "ITI ADCS Area";
        LineAttributes: Dictionary of [Text, Text];
        IterNode: XmlNode;
        XMLNodeList: XmlNodeList;
    begin
        XMLNodeList := BodyNode.AsXmlElement().GetChildElements();


        HTMLContent.AppendLine('<div >');
        HTMLContent.AppendLine('<table class="ADCS-Table" id="example-table">');

        GenerateTableHeader(HTMLContent, XMLNodeList);

        foreach IterNode in XMLNodeList do begin
            GetXMLAttributes(IterNode, LineAttributes);
            ParseDataListBodyToHtml(HTMLContent, IterNode, ADCSArea::Body, LineAttributes);
        end;

        HTMLContent.AppendLine('</tbody>');
        HTMLContent.AppendLine('</table>');
        HTMLContent.AppendLine('</div >');
    end;


    local procedure ParseDocumentRepeaterToHTML(var HTMLContent: TextBuilder; RepeaterNode: XmlNode)
    var
        ADCSArea: enum "ITI ADCS Area";
        LineAttributes: Dictionary of [Text, Text];
        IterNode: XmlNode;
        XMLNodeList: XmlNodeList;
    begin
        XMLNodeList := RepeaterNode.AsXmlElement().GetChildElements();


        HTMLContent.AppendLine('<div >');
        HTMLContent.AppendLine('<table class="ADCS-Table" id="example-table">');

        GenerateTableHeader(HTMLContent, XMLNodeList);

        foreach IterNode in XMLNodeList do begin
            GetXMLAttributes(IterNode, LineAttributes);
            ParseRepeaterToHtml(HTMLContent, IterNode, ADCSArea::Repeater, LineAttributes);
        end;

        HTMLContent.AppendLine('</tbody>');
        HTMLContent.AppendLine('</table>');
        HTMLContent.AppendLine('</div >');
    end;

    local procedure GenerateTableHeader(var HTMLContent: TextBuilder; XMLNodeList: XmlNodeList)
    var
        FieldsNode: XMLNodeList;
        IterNode: XmlNode;
        OneNode: XmlNode;
    begin
        XMLNodeList.Get(1, OneNode);
        FieldsNode := OneNode.AsXmlElement().GetChildElements();
        HTMLContent.AppendLine('<thead>');
        HTMLContent.AppendLine('<tr class="ADCS-Table-tbody-tr">');
        if ADCSFormType <> ADCSFormType::Document then
            HTMLContent.AppendLine('<th class="ADCS-Table-th">' + NoLbl + '</th>');
        foreach IterNode in FieldsNode do
            HTMLContent.AppendLine(Format('<th class="ADCS-Table-th">' + ITIXMLDOMManagement.GetAttributeValue(IterNode, 'Descrip') + '</th>'));

        HTMLContent.AppendLine('</tr>');
        HTMLContent.AppendLine('</thead>');
        HTMLContent.AppendLine('<tbody>');
    end;

    local procedure ParseDataListBodyToHtml(var HTMLContent: TextBuilder; AreaNode: XmlNode; ADCSArea: enum "ITI ADCS Area"; LineAttributes: Dictionary of [Text, Text])
    var
        FirstElement: Boolean;
        LineNo: Integer;
        IterNode: XmlNode;
        XmlNodeList: XmlNodeList;
        ElementAttributes: Dictionary of [Text, Text];
    begin
        FirstElement := true;
        Evaluate(LineNo, LineAttributes.Get('No'));
        HTMLContent.AppendLine('<tr class="ADCS-Table-tbody-tr" onclick="SelectFromList(''' + Format(LineNo + 1) + ''')">');
        HTMLContent.AppendLine(Format('<td class="ADCS-Table-td">' + Format(LineNo + 1) + '</td>'));
        XMLNodeList := AreaNode.AsXmlElement().GetChildElements();
        foreach IterNode in XMLNodeList do begin
            HTMLContent.AppendLine('<td class="ADCS-Table-td">');
            GetXMLAttributes(IterNode, ElementAttributes);
            GenrateHTMLForField(HTMLContent, IterNode, ADCSArea, LineAttributes, ElementAttributes, FirstElement);
            HTMLContent.AppendLine('</td>');
        end;
        HTMLContent.AppendLine('</tr>');
    end;

    local procedure ParseRepeaterToHtml(var HTMLContent: TextBuilder; AreaNode: XmlNode; ADCSArea: enum "ITI ADCS Area"; LineAttributes: Dictionary of [Text, Text])
    var
        FirstElement: Boolean;
        IterNode: XmlNode;
        XmlNodeList: XmlNodeList;
        ElementAttributes: Dictionary of [Text, Text];
        FieldValueType: Enum "ITI ADCS Field Type";
    begin
        FirstElement := true;
        HTMLContent.AppendLine('<tr class="ADCS-Table-tbody-tr">');
        XMLNodeList := AreaNode.AsXmlElement().GetChildElements();
        foreach IterNode in XMLNodeList do begin
            GetXMLAttributes(IterNode, ElementAttributes);
            if ElementAttributes.ContainsKey('Type') then
                Evaluate(FieldValueType, ElementAttributes.Get('Type'));
            if FieldValueType <> FieldValueType::Input then
                HTMLContent.AppendLine('<td class="ADCS-Table-td">')
            else
                if (GetDictionartValue(ElementAttributes, 'Descrip') = ActiveInputFieldDescription) and
                                   (GetDictionartValue(ElementAttributes, 'FieldID') = ActiveInputFieldID) and (GetDictionartValue(LineAttributes, 'RecordID') = ActiveInputRecordID) then
                    HTMLContent.AppendLine('<td class="ADCS-Table-Activtd">')
                else
                    HTMLContent.AppendLine('<td class="ADCS-Table-td">');
            GenrateHTMLForField(HTMLContent, IterNode, ADCSArea, LineAttributes, ElementAttributes, FirstElement);
            HTMLContent.AppendLine('</td>');
        end;
        HTMLContent.AppendLine('</tr>');
    end;

    local procedure ParseFieldAreaToHtml(var HTMLContent: TextBuilder; AreaNode: XmlNode; ADCSArea: enum "ITI ADCS Area";
                                            LineAttributes: Dictionary of [Text, Text]; var FirstElement: Boolean)
    var
        AreaElements: XmlNodeList;
        IterNode: XmlNode;
        ElementAttributes: Dictionary of [Text, Text];
    begin
        AreaElements := AreaNode.AsXmlElement().GetChildElements();
        foreach IterNode in AreaElements do begin
            GetXMLAttributes(IterNode, ElementAttributes);
            GenrateHTMLForField(HTMLContent, IterNode, ADCSArea, LineAttributes, ElementAttributes, FirstElement);
        end;

    end;

    local procedure GenrateHTMLForField(var HTMLContent: TextBuilder; Node: XmlNode; ADCSArea: enum "ITI ADCS Area"; LineAttributes: Dictionary of [Text, Text]; ElementAttributes: Dictionary of [Text, Text]; var FirstElement: Boolean)
    var
        LineNo: Integer;
        FieldValue: Enum "ITI ADCS Field Type";
    begin
        if ElementAttributes.ContainsKey('Type') then begin
            Evaluate(FieldValue, ElementAttributes.Get('Type'));
            case ADCSArea of
                ADCSArea::Header:
                    case ADCSFormType of
                        ADCSFormType::Card, ADCSFormType::"Data List", ADCSFormType::"Data List Input", ADCSFormType::"Selection List":
                            case FieldValue of
                                FieldValue::Text:
                                    HTMLContent.Append(Format('<div class="ADCS-FormHeader-Container"><span class="ADCS-FormHeader-Text">' + Node.AsXmlElement().InnerText() + '</span></div>'));
                                FieldValue::Output:
                                    HTMLContent.AppendLine('<div class="ADCS-FormHeader-Container"><span class="ADCS-FormHeader-Text"' + ' ' + SetRestAttr(ElementAttributes) + '>'
                                    + Node.AsXmlElement().InnerText() + '</span></div>');
                                else
                                    Error('Unhandled field type');
                            end;
                        else
                            Error('Unknown form type');
                    end;
                ADCSArea::Footer:
                    case ADCSFormType of
                        ADCSFormType::Card, ADCSFormType::"Data List", ADCSFormType::"Data List Input", ADCSFormType::"Selection List":
                            case FieldValue of
                                FieldValue::Text:
                                    HTMLContent.Append(Format('<span Class="ADCS-FormFooter-Text">' + Node.AsXmlElement().InnerText() + '</span>'));
                                else
                                    Error('Unhandled field type');
                            end;
                        else
                            Error('Unknown form type');
                    end;
                ADCSArea::Body:
                    case ADCSFormType of
                        ADCSFormType::Card, ADCSFormType::"Data List Input", ADCSFormType::Document:
                            case FieldValue of
                                FieldValue::Text:
                                    begin
                                        HTMLContent.AppendLine('<div class="ADCS-FormField-Container">');
                                        HTMLContent.AppendLine('<span class="ADCS-FormField-Description">');
                                        HTMLContent.AppendLine(Node.AsXmlElement().InnerText());
                                        HTMLContent.AppendLine('</span>');
                                        HTMLContent.AppendLine('</div>');
                                    end;
                                FieldValue::Output, FieldValue::Input:
                                    if (GetDictionartValue(ElementAttributes, 'Descrip') = ActiveInputFieldDescription) and
                                       (GetDictionartValue(ElementAttributes, 'FieldID') = ActiveInputFieldID) and
                                       FirstElement then begin
                                        FirstElement := false;
                                        HTMLContent.AppendLine('<div class="ADCS-FormField-Container">');
                                        HTMLContent.AppendLine('<span class="ADCS-FormActiveField-Description">');
                                        HTMLContent.AppendLine(GetDictionartValue(ElementAttributes, 'Descrip') + ': ');
                                        HTMLContent.AppendLine('</span>');
                                        HTMLContent.AppendLine('<span class="ADCS-FormActiveField-Value">');
                                        HTMLContent.AppendLine(Format('<output' + ' ' + SetRestAttr(ElementAttributes) + '>' + Node.AsXmlElement().InnerText() + '</output>'));
                                        HTMLContent.AppendLine('</span>');
                                        HTMLContent.AppendLine('</div>');
                                    end
                                    else begin
                                        HTMLContent.AppendLine('<div class="ADCS-FormField-Container">');
                                        HTMLContent.AppendLine('<span class="ADCS-FormField-Description">');
                                        HTMLContent.AppendLine(GetDictionartValue(ElementAttributes, 'Descrip') + ': ');
                                        HTMLContent.AppendLine('</span>');
                                        HTMLContent.AppendLine('<span class="ADCS-FormField-Value">');
                                        HTMLContent.AppendLine(Format('<output' + ' ' + SetRestAttr(ElementAttributes) + '>' + Node.AsXmlElement().InnerText() + '</output>'));
                                        HTMLContent.AppendLine('</span>');
                                        HTMLContent.AppendLine('</div>');
                                    end;
                                else
                                    Error('Unhandled field type');
                            end;
                        ADCSFormType::"Data List":
                            case FieldValue of
                                FieldValue::Text:
                                    HTMLContent.Append(Format('<b>' + Node.AsXmlElement().InnerText() + '</b>'));
                                FieldValue::Output, FieldValue::Input:
                                    HTMLContent.AppendLine(Format('<output' + ' ' + SetRestAttr(ElementAttributes) + '>' + Node.AsXmlElement().InnerText() + '</output>'));
                                else
                                    Error('Unhandled field type');
                            end;
                        ADCSFormType::"Selection List":
                            case FieldValue of
                                FieldValue::Text:
                                    begin
                                        Evaluate(LineNo, GetDictionartValue(LineAttributes, 'No'));
                                        HTMLContent.AppendLine('<div class="button-container">');
                                        HTMLContent.AppendLine(Format('<button ID="ADCSButton" onclick="SelectFromList(''' + Format(LineNo + 1) + ''')"'
                                                    + ' class="custom-ADCSMenuButton"> <span class="number-ADCSMenuButton">' + Format(SetInteger(GetDictionartValue(LineAttributes, 'No')) + 1) + '</span><span class="text-ADCSMenuButton">'
                                                    + Node.AsXmlElement().InnerText + '</span></button>'));
                                        HTMLContent.AppendLine('</div>');
                                    end;


                                else
                                    Error('Unhandled field type');
                            end;
                    end;
                ADCSArea::Repeater:
                    case FieldValue of
                        FieldValue::Text:
                            HTMLContent.Append(Format('<b>' + Node.AsXmlElement().InnerText() + '</b>'));
                        FieldValue::Output, FieldValue::Input:
                            HTMLContent.AppendLine(Format('<output' + ' ' + SetRestAttr(ElementAttributes) + '>' + Node.AsXmlElement().InnerText() + '</output>'));
                        else
                            Error('Unhandled field type');
                    end;
            end;
        end;
    end;

    local procedure GetXMLAttributes(IterNode: XmlNode; var XMLAttributes: Dictionary of [Text, Text])
    var
        NodeAttribute: XmlAttribute;
        ValueTxt: Text;
        NodeAttributes: XmlAttributeCollection;
    begin
        Clear(XMLAttributes);
        NodeAttributes := IterNode.AsXmlElement().Attributes();
        foreach NodeAttribute in NodeAttributes do begin
            ValueTxt := NodeAttribute.Value;
            if ValueTxt.Contains('""') then
                ValueTxt := ValueTxt.Replace('""', '&quot;&quot;');
            XMLAttributes.Add(NodeAttribute.Name(), ValueTxt);
        end;

    end;

    local procedure SetRestAttr(FieldAttributes: Dictionary of [Text, Text]) Result: Text
    var
        attribute: Text;
        attributes: List of [Text];
    begin
        attributes := FieldAttributes.Keys();
        Result := '';
        foreach attribute in attributes do
            if attribute <> 'Type' then
                if AttrHtmlMapping.ContainsKey(attribute) then
                    Result := Result + AttrHtmlMapping.Get(attribute) + '="' + FieldAttributes.Get(attribute) + '" ';

        if FieldAttributes.Get('Type') = 'Input' then begin
            if HideInput then
                Result := Result + 'type="password"';
            InputId := FieldAttributes.Get('FieldID');
        end;

        exit(Result);
    end;

    local procedure CreatAttrHtmlMapping()
    begin
        AttrHtmlMapping.Add('MaxLen', 'maxlength');
        AttrHtmlMapping.Add('FieldID', 'id');
        AttrHtmlMapping.Add('Descrip', 'Descrip');
    end;

    local procedure SetComment(HTMLContent: TextBuilder; RootNode: XmlNode; var MakeSound: Boolean)
    var
        ErrorAttribute: XmlAttribute;
        MessageText: Text;
        CommentNode: XmlNode;
        HeaderNode: XmlNode;
    begin
        ITIXMLDOMManagement.FindNode(RootNode, 'Header', HeaderNode);
        if ITIXMLDOMManagement.FindNode(HeaderNode, 'Comment', CommentNode) then begin
            MessageText := CommentNode.AsXmlElement().InnerText;
            if MessageText <> '' then begin
                if ITIXMLDOMManagement.FindAttribute(CommentNode, ErrorAttribute, 'Error') then
                    if ErrorAttribute.Value = '1' then
                        MakeSound := true;

                MessageText := MessageText.Replace('_BELL_', '');
                if ITIXMLDOMManagement.FindAttribute(CommentNode, ErrorAttribute, 'Error') then begin
                    if ErrorAttribute.Value = '1' then begin
                        HTMLContent.AppendLine('<div class="ADCS-Error-Container">');
                        HTMLContent.AppendLine(Format('<span class="ADCS-Error-Text">' + MessageText + '</span>'));
                        HTMLContent.AppendLine('</div>');
                    end;
                end
                else begin
                    HTMLContent.AppendLine('<div class="ADCS-Comment-Container">');
                    HTMLContent.AppendLine(Format('<span class="ADCS-Comment-Text">' + MessageText + '</span>'));
                    HTMLContent.AppendLine('</div>');
                end;

            end;
        end;
    end;

    local procedure SetFunctions(HTMLContent: TextBuilder; RootNode: XmlNode)
    var
        ITIMiniformFunction: Record "ITI Miniform Function";
        FuncDesc: Text;
        FunctionNode: XmlNode;
        FunctionNodes: XmlNodeList;
        HeaderNode: XmlNode;
    begin
        ITIXMLDOMManagement.FindNode(RootNode, 'Header', HeaderNode);
        ITIXMLDOMManagement.FindNode(HeaderNode, 'Functions', FunctionNode);
        FunctionNodes := FunctionNode.AsXmlElement().GetChildElements();
        HTMLContent.AppendLine('<div id="ADCSFunctionKeys" style="display:none">' + GetFunctionsKey() + '</div>');

        ITIMiniformFunction.SetRange("Miniform Code", PageAttr.Get('UseCaseCode'));
        ITIMiniformFunction.SetRange(Promoted, true);
        if ITIMiniformFunction.FindSet() then
            repeat
                FuncDesc := ITIMiniformFunction."Function Caption";
                if FuncDesc = '' then
                    FuncDesc := ITIMiniformFunction."Function Code";
                HTMLContent.AppendLine(Format('            <a href="#" onclick="triggerFunction(''' + ITIMiniformFunction."Function Code" + ''')">' + FuncDesc + '</a>'));
            until ITIMiniformFunction.Next() = 0;
    end;

    local procedure GetDictionartValue(Dict: Dictionary of [Text, Text]; SearchKey: Text): Text
    begin
        if Dict.ContainsKey(SearchKey) then
            exit(Dict.Get(SearchKey))
        else
            exit('');
    end;

    local procedure SetInputType(): Text
    begin
        if HideInput then
            exit('type="password"')
        else
            exit('');
    end;

    local procedure SetInteger(TextInteger: Text): Integer
    var
        ReturnInt: Integer;
    begin
        Evaluate(ReturnInt, TextInteger);
        exit(ReturnInt);
    end;

    local procedure GetFunctionsKey(): Text
    var
        ITIMiniformFunction: Record "ITI Miniform Function";
        Result: Text;
    begin
        ITIMiniformFunction.SetRange("Miniform Code", PageAttr.Get('UseCaseCode'));
        if ITIMiniformFunction.FindSet() then
            repeat
                if ITIMiniformFunction."Keyboard Key" <> '' then
                    Result := Result + ITIMiniformFunction."Keyboard Key" + ',';
            until ITIMiniformFunction.Next() = 0;
        Result := DelChr(Result, '>', ',');
        exit(Result);
    end;

    var
        ITIXMLDOMManagement: Codeunit "ITI XML DOM Management";
        HideInput: Boolean;
        ADCSFormType: Enum "ITI ADCS Form Type";
        ActiveInputFieldDescription: Text;
        ActiveInputFieldID: Text;
        ActiveInputRecordID: Text;
        AttrHtmlMapping: Dictionary of [Text, Text];
        InputId: Text;
        PageAttr: Dictionary of [Text, Text];
        NextLbl: label 'Next';
        NoLbl: label '#';
        PageTypeErr: label 'Current page has no specified any page type.';
        SelectionLbl: label 'Select';
}