codeunit 69050 "ITI ADCS Communication"
{

    trigger OnRun()
    begin
    end;

    var
        ITIADCSUser: Record "ITI ADCS User";
        ITIXMLDOMManagement: Codeunit "ITI XML DOM Management";
        RecRef, RecRefHeader, RecRefLines : RecordRef;
        RecRefPosition: Integer;
        InputIsHidden: Boolean;
        RecRefRunning, RecRefHeaderRunning, RecRefLinesRunning : Boolean;
        ActiveInput: Integer;
        InputCounter: Integer;
        AddAttributeErr: Label 'Failed to add the attribute: %1.', Comment = '%1 - attribute';
        AddElementErr: Label 'Failed to add the element: %1.', Comment = '%1 - element';
        AddNodeErr: Label 'Failed to add a node.';
        FieldContainErr: Label 'The field %2 in the record %1 can only contain %3 characters. (%4).', Comment = 'The field %2 - [Field Caption] in the record %1 - [Record Caption] [Field Caption] can only contain %3 - [Field Length] characters. ( %4 [Attempted value to set]).';
        MiniformNotFoundErr: Label 'Miniform %1 not found.', Comment = '%1 - Miniform';
        NotUsedErr: Label '<%1> not used.', Comment = '%1 - Function key';
        NotValidErr: Label '%1 is not a valid value for the %2 field.', Comment = '%1 - value, %2 - field';
        OneMiniFormErr: Label 'There must be one miniform that is set to %1.', Comment = '%1 - start miniform';
        Comment: Text;
        RecID: Text;
        TableNo: Text;
        XMLDOM: XmlDocument;
        GlobalVariables: Dictionary of [Text, Text];

    /// <summary>
    /// EncodeMiniForm.
    /// </summary>
    /// <param name="ITIMiniFormHeader">Record "ITI Miniform Header".</param>
    /// <param name="StackCode">text.</param>
    /// <param name="XMLDOMin">VAR XmlDocument.</param>
    /// <param name="ActiveInputField">Integer.</param>
    /// <param name="cMessage">Text.</param>
    /// <param name="ADCSUserId">Text.</param>
    procedure EncodeMiniForm(ITIMiniFormHeader: Record "ITI Miniform Header"; StackCode: Text; var XMLDOMin: XmlDocument; ActiveInputField: Integer; cMessage: Text; ADCSUserId: Text)
    var
        iAttributeCounter: Integer;
        iCounter: Integer;
        LookupItem: Text;
        DictKey: text;

        AttributeNode: XmlAttribute;
        oAttributes: XmlAttributeCollection;
        CurrNode: XmlNode;
        FunctionNode: XmlNode;
        NewChild: XmlNode;
        ReturnedNode: XmlNode;
        RootNode: XmlNode;
    begin

        XMLDOM := XMLDOMin;
        ActiveInput := ActiveInputField;
        InputCounter := 0;
        Comment := cMessage;
        ITIXMLDOMManagement.GetRootNode(XMLDOM, RootNode);
        // get the incoming header before we create the empty Container..
        ITIXMLDOMManagement.FindNode(RootNode, 'Header', ReturnedNode);

        // Now create an empty root node... this must always be done before we use this object!!
        ITIXMLDOMManagement.LoadXMLDocumentFromText('<ADCS/>', XMLDOM);

        // Set the current node to the root node
        //CurrNode := XMLDOM.DocumentElement;
        ITIXMLDOMManagement.GetRootNode(XMLDOM, CurrNode);
        // add a header node to the ADCS node

        if not ITIXMLDOMManagement.AddElement(CurrNode, 'Header', '', '', NewChild) then
            Error(AddNodeErr);

        // Add all the header fields from the incoming XMLDOM  
        oAttributes := ReturnedNode.AsXmlElement().Attributes();
        iAttributeCounter := oAttributes.Count;
        iCounter := 0;
        while iCounter < iAttributeCounter do begin
            //AttributeNode := oAttributes.Item(iCounter);
            oAttributes.Get(iCounter + 1, AttributeNode);
            AddAttribute(NewChild, AttributeNode.Name, AttributeNode.Value);
            iCounter := iCounter + 1;
        end;

        VerifyCorrectFieldValue(ReturnedNode, 'LookupItem', UpperCase(Format(true)), NewChild);


        // Now add the UserId to the Header
        if ADCSUserId <> '' then begin
            AddAttribute(NewChild, 'LoginID', ADCSUserId);
            SetUserNo(ADCSUserId);
        end else
            Clear(ITIADCSUser);

        // now add the input to the Header
        AddAttribute(NewChild, 'UseCaseCode', ITIMiniFormHeader.Code);
        AddAttribute(NewChild, 'StackCode', StackCode);
        AddAttribute(NewChild, 'RunReturn', '0');
        AddAttribute(NewChild, 'FormTypeOpt', Format(ITIMiniFormHeader."Form Type"));
        AddAttribute(NewChild, 'NoOfLines', Format(ITIMiniFormHeader."No. of Records in List"));
        AddAttribute(NewChild, 'InputIsHidden', '0');
        if GlobalVariables.Count > 0 then
            foreach DictKey in GlobalVariables.Keys() do
                AddAttribute(NewChild, DictKey, GlobalVariables.Get(DictKey));

        InputIsHidden := false;

        ITIXMLDOMManagement.AddElement(NewChild, 'Comment', Comment, '', FunctionNode);

        // add the Function List to the Mini Form
        if ITIXMLDOMManagement.AddElement(NewChild, 'Functions', '', '', FunctionNode) then
            EncodeFunctions(ITIMiniFormHeader, FunctionNode);

        EncodeLines(ITIMiniFormHeader, CurrNode);

        if InputIsHidden then begin
            ITIXMLDOMManagement.FindNode(CurrNode, 'Header', ReturnedNode);
            SetNodeAttribute(ReturnedNode, 'InputIsHidden', '1');
        end;

        XMLDOMin := XMLDOM;
    end;

    local procedure VerifyCorrectFieldValue(ReturnedNode: XmlNode; TargetFieldName: Text; TargetFieldValue: Text; var NewChild: XmlNode)
    var
        AttributeFieldName: XmlAttribute;
        AttributeFieldValue: XmlAttribute;
        XMLAttributeCollection: XmlAttributeCollection;
        LookupNode: XmlNode;
    begin
        if ITIXMLDOMManagement.FindNode(ReturnedNode, 'Input', LookupNode) then begin
            XMLAttributeCollection := LookupNode.AsXmlElement().Attributes();
            if XMLAttributeCollection.Get('FieldName', AttributeFieldName) then
                if UpperCase(AttributeFieldName.Value) = UpperCase(TargetFieldName) then
                    if XMLAttributeCollection.Get('FieldValue', AttributeFieldValue) then
                        if UpperCase(AttributeFieldValue.Value) = UpperCase(TargetFieldValue) then begin
                            AddAttribute(NewChild, 'FieldName', TargetFieldName);
                            AddAttribute(NewChild, 'FieldValue', TargetFieldValue);
                        end;
        end;
    end;

    local procedure EncodeFunctions(MiniFormHdr: Record "ITI Miniform Header"; var CurrNode: XmlNode)
    var
        ITIFunctionLine: Record "ITI Miniform Function";
        NewChild: XmlNode;
    begin
        // Add the Function List to the XML Document
        ITIFunctionLine.Reset();
        ITIFunctionLine.SetRange("Miniform Code", MiniFormHdr.Code);

        if ITIFunctionLine.FindSet() then
            repeat
                ITIXMLDOMManagement.AddElement(CurrNode, 'Function', Format(ITIFunctionLine."Function Code"), '', NewChild);
            until ITIFunctionLine.Next() = 0
    end;

    local procedure EncodeLines(ITIMiniFormHeader: Record "ITI Miniform Header"; var CurrNode: XmlNode)
    var
        ITIMiniformLine: Record "ITI Miniform Line";
        ITIMiniformLine2: Record "ITI Miniform Line";
        CurrArea: Enum "ITI ADCS Area";
        PermissionGranted, StopRec, LinesMoved : Boolean;
        CurrentOption, LineMove : Integer;
        LineCounter: Integer;
        AreaNode: XmlNode;
        DataLineNode: XmlNode;
        LinesNode: XmlNode;
    begin
        // add a lines node to the ADCS node
        if not ITIXMLDOMManagement.AddElement(CurrNode, 'Lines', '', '', LinesNode) then
            Error(AddNodeErr);

        CurrentOption := -1;
        LineCounter := 0;
        StopRec := false;
        LinesMoved := false;

        if RecRefRunning and RecRefLinesRunning then
            CheckRecRefLinePosition();

        ITIMiniformLine.Reset();
        ITIMiniformLine.SetCurrentKey(Area);
        ITIMiniformLine.SetRange("Miniform Code", ITIMiniFormHeader.Code);
        if ITIMiniformLine.FindSet() then
            repeat
                if CurrArea <> ITIMiniformLine."Area" then begin
                    CurrArea := ITIMiniformLine."Area";
                    StopRec := false;
                end;
                PermissionGranted := IsPermissionGranted(ITIMiniFormHeader, ITIMiniformLine);
                if PermissionGranted then begin
                    if CurrentOption <> ITIMiniformLine.Area.AsInteger() then begin
                        CurrentOption := ITIMiniformLine.Area.AsInteger();
                        if not ITIXMLDOMManagement.AddElement(LinesNode, Format(ITIMiniformLine.Area), '', '', AreaNode) then
                            Error(AddNodeErr);
                    end;
                    case ITIMiniformLine.Area of
                        ITIMiniformLine.Area::Body:
                            case ITIMiniFormHeader."Form Type" of
                                ITIMiniFormHeader."Form Type"::Card:
                                    SendComposition(ITIMiniformLine, AreaNode);
                                ITIMiniFormHeader."Form Type"::Document:
                                    SendCompositionForDocument(ITIMiniformLine, AreaNode, true);
                                ITIMiniFormHeader."Form Type"::"Data List", ITIMiniFormHeader."Form Type"::"Data List Input", ITIMiniFormHeader."Form Type"::"Selection List":
                                    while ITIMiniFormHeader."No. of Records in List" > LineCounter do begin
                                        if ((ITIMiniFormHeader."Form Type" = ITIMiniFormHeader."Form Type"::"Data List") or
                                            (ITIMiniFormHeader."Form Type" = ITIMiniFormHeader."Form Type"::"Data List Input"))
                                        then begin
                                            ITIMiniformLine2.SetCurrentKey(Area);
                                            ITIMiniformLine2.SetRange("Miniform Code", ITIMiniformLine."Miniform Code");
                                            ITIMiniformLine2.SetRange(Area, ITIMiniformLine.Area);
                                            if ITIMiniformLine2.Find('-') then begin
                                                SendLineNo(ITIMiniformLine2, AreaNode, DataLineNode, LineCounter);
                                                repeat
                                                    SendComposition(ITIMiniformLine2, DataLineNode);
                                                until ITIMiniformLine2.Next() = 0;
                                                if GetNextRecord() = 0 then
                                                    LineCounter := ITIMiniFormHeader."No. of Records in List";
                                            end;
                                        end else begin
                                            if PermissionGranted then begin
                                                SendLineNo(ITIMiniformLine, AreaNode, DataLineNode, LineCounter);
                                                SendComposition(ITIMiniformLine, DataLineNode);
                                            end;

                                            if ITIMiniformLine.Next() = 0 then
                                                LineCounter := ITIMiniFormHeader."No. of Records in List"
                                            else
                                                if ITIMiniformLine.Area <> ITIMiniformLine.Area::Body then begin
                                                    ITIMiniformLine.Find('<');
                                                    LineCounter := ITIMiniFormHeader."No. of Records in List";
                                                end;
                                        end;
                                        if PermissionGranted then
                                            LineCounter := LineCounter + 1;
                                    end;
                            end;
                        ITIMiniformLine.Area::Footer, ITIMiniformLine.Area::Header:
                            SendComposition(ITIMiniformLine, AreaNode);
                        ITIMiniformLine."Area"::Repeater:
                            if not StopRec then begin
                                if (ITIMiniFormHeader."No. of Records in List" < RecRefLines.Count) and (not LinesMoved) then begin
                                    LineMove := ITIMiniFormHeader."No. of Records in List" - RecRefPosition;
                                    if LineMove < 0 then begin
                                        repeat
                                            RecRefLines.Next();
                                            LineMove += 1;
                                        until LineMove = 0;
                                        LinesMoved := true;
                                    end;
                                end;
                                ITIMiniformLine2.SetCurrentKey(Area);
                                ITIMiniformLine2.SetRange("Miniform Code", ITIMiniformLine."Miniform Code");
                                ITIMiniformLine2.SetRange(Area, ITIMiniformLine.Area);
                                if ITIMiniformLine2.Find('-') then begin
                                    SendLineNoForDocument(ITIMiniformLine2, AreaNode, DataLineNode, LineCounter);
                                    repeat
                                        SendCompositionForDocument(ITIMiniformLine2, DataLineNode, false);
                                    until ITIMiniformLine2.Next() = 0;
                                    if (RecRefLines.Next() <> 0) and (LineCounter + 1 < ITIMiniFormHeader."No. of Records in List") then
                                        LineCounter += 1
                                    else
                                        StopRec := true;
                                end;
                            end;

                    end;
                end;
            until ITIMiniformLine.Next() = 0;
    end;

    local procedure SendComposition(ITIMiniformLine: Record "ITI Miniform Line"; var CurrNode: XmlNode)
    var
        MiniformHeader: Record "ITI Miniform Header";
        NewChild: XmlNode;
    begin
        // add a data node to the area node

        AddElement(CurrNode, 'Field', GetFieldValue(ITIMiniformLine), '', NewChild);

        // add the field name as an attribute..
        if ITIMiniformLine."Field Type" <> ITIMiniformLine."Field Type"::Text then
            AddAttribute(NewChild, 'FieldID', Format(ITIMiniformLine."Field No."));

        MiniformHeader.Get(ITIMiniformLine."Miniform Code");
        if RecRefRunning and (MiniformHeader."Form Type" = MiniformHeader."Form Type"::Card)
        and (not MiniformHeader."Start Miniform") then begin
            AddAttribute(NewChild, 'TableNo', Format(RecRef.Number));
            AddAttribute(NewChild, 'RecordID', Format(RecRef.RecordId));
        end;

        // What type of field is this ?
        if ITIMiniformLine."Field Type" in [ITIMiniformLine."Field Type"::Input, ITIMiniformLine."Field Type"::Asterisk] then begin
            InputCounter := InputCounter + 1;
            if InputCounter = ActiveInput then begin
                AddAttribute(NewChild, 'Type', 'Input');
                InputIsHidden := ITIMiniformLine."Field Type" = ITIMiniformLine."Field Type"::Asterisk;
            end else
                AddAttribute(NewChild, 'Type', 'OutPut');
        end else
            AddAttribute(NewChild, 'Type', Format(ITIMiniformLine."Field Type"));

        if ITIMiniformLine."Field Type" = ITIMiniformLine."Field Type"::Text then
            ITIMiniformLine."Field Length" := StrLen(ITIMiniformLine.Text);
        AddAttribute(NewChild, 'MaxLen', Format(ITIMiniformLine."Field Length"));

        // The Data Description
        if ITIMiniformLine."Field Type" <> ITIMiniformLine."Field Type"::Text then
            AddAttribute(NewChild, 'Descrip', ITIMiniformLine.Text);
    end;

    local procedure SendCompositionForDocument(ITIMiniformLine: Record "ITI Miniform Line"; var CurrNode: XmlNode; Isheader: Boolean)
    var
        MiniformHeader: Record "ITI Miniform Header";
        NewChild: XmlNode;
    begin
        // add a data node to the area node
        ResetInputCounter(ITIMiniformLine."Miniform Code", Isheader);
        AddElement(CurrNode, 'Field', GetFieldValueForDocument(ITIMiniformLine, Isheader), '', NewChild);

        // add the field name as an attribute..
        if ITIMiniformLine."Field Type" <> ITIMiniformLine."Field Type"::Text then
            AddAttribute(NewChild, 'FieldID', Format(ITIMiniformLine."Field No."));

        MiniformHeader.Get(ITIMiniformLine."Miniform Code");

        if Isheader then begin
            if RecRefHeaderRunning then begin
                AddAttribute(NewChild, 'TableNo', Format(RecRefHeader.Number));
                AddAttribute(NewChild, 'RecordID', Format(RecRefHeader.RecordId));
            end;
        end
        else
            if RecRefLinesRunning then begin
                AddAttribute(NewChild, 'TableNo', Format(RecRefLines.Number));
                AddAttribute(NewChild, 'RecordID', Format(RecRefLines.RecordId));
            end;

        // What type of field is this ?
        if ITIMiniformLine."Field Type" in [ITIMiniformLine."Field Type"::Input, ITIMiniformLine."Field Type"::Asterisk] then begin
            InputCounter := InputCounter + 1;
            if (InputCounter = ActiveInput) and (RecRef.RecordId = RecRefLines.RecordId) then begin
                AddAttribute(NewChild, 'Type', 'Input');
                InputIsHidden := ITIMiniformLine."Field Type" = ITIMiniformLine."Field Type"::Asterisk;
            end else
                AddAttribute(NewChild, 'Type', 'OutPut');
        end else
            AddAttribute(NewChild, 'Type', Format(ITIMiniformLine."Field Type"));

        if ITIMiniformLine."Field Type" = ITIMiniformLine."Field Type"::Text then
            ITIMiniformLine."Field Length" := StrLen(ITIMiniformLine.Text);
        AddAttribute(NewChild, 'MaxLen', Format(ITIMiniformLine."Field Length"));

        // The Data Description
        if ITIMiniformLine."Field Type" <> ITIMiniformLine."Field Type"::Text then
            AddAttribute(NewChild, 'Descrip', ITIMiniformLine.Text);
    end;

    local procedure ResetInputCounter(MiniformCode: Code[20]; isHeader: Boolean)
    var
        ITIMiniformLine: Record "ITI Miniform Line";
    begin
        ITIMiniformLine.SetRange("Miniform Code", MiniformCode);
        if isHeader then
            ITIMiniformLine.SetRange("Area", ITIMiniformLine."Area"::Body)
        else
            ITIMiniformLine.SetRange("Area", ITIMiniformLine."Area"::Repeater);
        ITIMiniformLine.SetFilter("Field Type", '%1|%2', ITIMiniformLine."Field Type"::Input, ITIMiniformLine."Field Type"::Asterisk);
        if ITIMiniformLine.Count <= InputCounter then
            InputCounter := 0;
    end;

    local procedure SendLineNo(ITIMiniformLine: Record "ITI Miniform Line"; var CurrNode: XmlNode; var RetNode: XmlNode; LineNo: Integer)
    var
        NewChild: XmlNode;
    begin
        GlobalLanguage(1033);
        if (ITIMiniformLine.Area = ITIMiniformLine.Area::Body) or (ITIMiniformLine.Area = ITIMiniformLine.Area::Repeater) then
            AddElement(CurrNode, 'Line', '', '', NewChild)
        else
            NewChild := CurrNode;

        if RecRefRunning then begin
            TableNo := Format(RecRef.Number);
            RecID := Format(RecRef.RecordId);
        end;
        AddAttribute(NewChild, 'No', Format(LineNo));
        AddAttribute(NewChild, 'TableNo', TableNo);
        AddAttribute(NewChild, 'RecordID', RecID);

        RetNode := NewChild;
    end;

    local procedure SendLineNoForDocument(ITIMiniformLine: Record "ITI Miniform Line"; var CurrNode: XmlNode; var RetNode: XmlNode; LineNo: Integer)
    var
        NewChild: XmlNode;
    begin
        GlobalLanguage(1033);
        if ITIMiniformLine.Area = ITIMiniformLine.Area::Repeater then
            AddElement(CurrNode, 'Line', '', '', NewChild)
        else
            NewChild := CurrNode;

        if RecRefLinesRunning then begin
            TableNo := Format(RecRefLines.Number);
            RecID := Format(RecRefLines.RecordId);
        end;
        AddAttribute(NewChild, 'No', Format(LineNo));
        AddAttribute(NewChild, 'TableNo', TableNo);
        AddAttribute(NewChild, 'RecordID', RecID);

        RetNode := NewChild;
    end;

    local procedure AddElement(var CurrNode: XmlNode; ElemName: Text; ElemValue: Text; NameSpace: Text; var NewChild: XmlNode)
    begin
        if not ITIXMLDOMManagement.AddElement(CurrNode, ElemName, ElemValue, NameSpace, NewChild) then
            Error(AddElementErr, ElemName);
    end;

    local procedure AddAttribute(var NewChild: XmlNode; AttribName: Text; AttribValue: Text)
    begin

        if not ITIXMLDOMManagement.AddAttribute(NewChild, AttribName, AttribValue) then
            Error(AddAttributeErr, AttribName);
    end;

    procedure SetRecRef(var NewRecRef: RecordRef)
    begin
        RecRef := NewRecRef.Duplicate();
        RecRefRunning := true;
    end;

    local procedure GetNextRecord(): Integer
    begin
        exit(RecRef.Next());
    end;

    procedure FindRecRef(SelectOption: Integer; NoOfLines: Integer): Boolean
    var
        i: Integer;
    begin

        case SelectOption of
            0:
                exit(RecRef.Find('-'));
            1:
                exit(RecRef.Find('>'));
            2:
                exit(RecRef.Find('<'));
            3:
                exit(RecRef.Find('+'));
            4:
                begin
                    for i := 0 to NoOfLines - 1 do
                        if not RecRef.Find('>') then
                            exit(false);
                    exit(true);
                end;
            5:
                begin
                    for i := 0 to NoOfLines - 1 do
                        if not RecRef.Find('<') then
                            exit(false);
                    exit(true);
                end;
            6:
                exit(RecRef.Find('='));
            else
                exit(false);
        end;
    end;

    local procedure GetFieldValue(ITIMiniformLine: Record "ITI Miniform Line"): Text
    var
        "Field": Record "Field";
        FldRef: FieldRef;
    begin
        if (ITIMiniformLine."Table No." = 0) or (ITIMiniformLine."Field No." = 0) then
            exit(ITIMiniformLine.Text);

        Field.Get(ITIMiniformLine."Table No.", ITIMiniformLine."Field No.");

        if RecRefRunning then begin
            FldRef := RecRef.Field(ITIMiniformLine."Field No.");
            if Field.Class = Field.Class::FlowField then
                FldRef.CalcField();

            exit(Format(FldRef));
        end;
        exit('');
    end;

    local procedure GetFieldValueForDocument(ITIMiniformLine: Record "ITI Miniform Line"; isHeader: Boolean): Text
    var
        "Field": Record "Field";
        FldRef: FieldRef;
    begin
        if (ITIMiniformLine."Table No." = 0) or (ITIMiniformLine."Field No." = 0) then
            exit(ITIMiniformLine.Text);

        Field.Get(ITIMiniformLine."Table No.", ITIMiniformLine."Field No.");

        if ((RecRefLinesRunning) and (not isHeader)) or ((RecRefHeaderRunning) and isHeader) then begin
            if isHeader then
                FldRef := RecRefHeader.Field(ITIMiniformLine."Field No.")
            else
                FldRef := RecRefLines.Field(ITIMiniformLine."Field No.");
            if Field.Class = Field.Class::FlowField then
                FldRef.CalcField();

            exit(Format(FldRef));
        end;
        exit('');
    end;

    procedure FieldSetvalue(var NewRecRef: RecordRef; FldNo: Integer; Text: Text): Boolean
    var
        FldRef: FieldRef;
    begin
        FldRef := NewRecRef.Field(FldNo);

        if not FieldHandleEvaluate(FldRef, Text) then
            Error(NotValidErr, Text, FldRef.Caption);

        FldRef.Validate();
        exit(true);
    end;

    local procedure FieldHandleEvaluate(var FldRef: FieldRef; Text: Text): Boolean
    var
        FieldRecord: Record "Field";
        DateFormula: DateFormula;
        RecordRef: RecordRef;
        BigInteger: BigInteger;
        Boolean: Boolean;
        "Code": Code[250];
        Date: Date;
        DateTime: DateTime;
        Decimal: Decimal;
        Duration: Duration;
        "Integer": Integer;
        OptionNo: Option;
        CurrOptionString: Text;
        OptionString: Text;
    begin
        Evaluate(FieldRecord.Type, Format(FldRef.Type));

        if Text = '' then
            exit(true);

        case FieldRecord.Type of
            FieldRecord.Type::Option:
                begin
                    if Text = '' then begin
                        FldRef.Value := 0;
                        exit(true);
                    end;
                    OptionString := FldRef.OptionCaption;
                    while OptionString <> '' do begin
                        if StrPos(OptionString, ',') = 0 then begin
                            CurrOptionString := OptionString;
                            OptionString := '';
                        end else begin
                            CurrOptionString := CopyStr(OptionString, 1, StrPos(OptionString, ',') - 1);
                            OptionString := CopyStr(OptionString, StrPos(OptionString, ',') + 1);
                        end;
                        if Text = CurrOptionString then begin
                            FldRef.Value := OptionNo;
                            exit(true);
                        end;
                        OptionNo := OptionNo + 1;
                    end;
                end;
            FieldRecord.Type::Text:
                begin
                    RecordRef := FldRef.Record();
                    FieldRecord.Get(RecordRef.Number, FldRef.Number);
                    if StrLen(Text) > FieldRecord.Len then
                        Error(FieldContainErr, FldRef.Record().Caption, FldRef.Caption, FieldRecord.Len, Text);
                    FldRef.Value := Text;
                    exit(true);
                end;
            FieldRecord.Type::Code:
                begin
                    Code := CopyStr(Text, 1, MaxStrLen(Code));
                    RecordRef := FldRef.Record();
                    FieldRecord.Get(RecordRef.Number, FldRef.Number);
                    if StrLen(Code) > FieldRecord.Len then
                        Error(FieldContainErr, FldRef.Record().Caption, FldRef.Caption, FieldRecord.Len, Code);
                    FldRef.Value := Code;
                    exit(true);
                end;
            FieldRecord.Type::Date:
                begin
                    if Text <> '' then begin
                        Evaluate(Date, Text);
                        FldRef.Value := Date;
                    end;
                    exit(true);
                end;
            FieldRecord.Type::DateTime:
                begin
                    Evaluate(DateTime, Text);
                    FldRef.Value := DateTime;
                    exit(true);
                end;
            FieldRecord.Type::Integer:
                begin
                    Evaluate(Integer, Text);
                    FldRef.Value := Integer;
                    exit(true);
                end;
            FieldRecord.Type::BigInteger:
                begin
                    Evaluate(BigInteger, Text);
                    FldRef.Value := BigInteger;
                    exit(true);
                end;
            FieldRecord.Type::Duration:
                begin
                    Evaluate(Duration, Text);
                    FldRef.Value := Duration;
                    exit(true);
                end;
            FieldRecord.Type::Decimal:
                begin
                    Evaluate(Decimal, Text);
                    FldRef.Value := Decimal;
                    exit(true);
                end;
            FieldRecord.Type::DateFormula:
                begin
                    Evaluate(DateFormula, Text);
                    FldRef.Value := DateFormula;
                    exit(true);
                end;
            FieldRecord.Type::Boolean:
                begin
                    Evaluate(Boolean, Text);
                    FldRef.Value := Boolean;
                    exit(true);
                end;
            FieldRecord.Type::BLOB, FieldRecord.Type::Binary:
                begin
                    FieldRecord.Get(FldRef.Record().Number, FldRef.Number);
                    FieldRecord.FieldError(Type);
                end;
            else begin
                FieldRecord.Get(FldRef.Record().Number, FldRef.Number);
                FieldRecord.FieldError(Type);
            end;
        end;
    end;

    procedure SetXMLDOMS(var oXMLDOM: XmlDocument)
    begin
        XMLDOM := oXMLDOM;
    end;


    procedure GetReturnXML(var xmlout: XmlDocument)
    begin
        xmlout := XMLDOM;
    end;

    procedure GetNodeAttribute(CurrNode: XmlNode; AttributeName: Text) AttribValue: Text
    var
        oTempNode: XmlAttribute;
    begin
        if ITIXMLDOMManagement.FindAttribute(CurrNode, oTempNode, AttributeName) then
            AttribValue := oTempNode.Value
        else
            AttribValue := '';
    end;

    procedure SetNodeAttribute(CurrNode: XmlNode; AttributeName: Text; AttribValue: Text)
    var
        oTempNode: XmlAttribute;
        NodeAttributes: XmlAttributeCollection;
    begin
        NodeAttributes := CurrNode.AsXmlElement().Attributes();
        NodeAttributes.Get(AttributeName, oTempNode);
        oTempNode.Value := AttribValue;
    end;

    procedure SetUserNo(uNo: Text)
    begin
        ITIADCSUser.Get(uNo)
    end;

    procedure GetWhseEmployee(ADCSLoginId: Text; var WhseEmpId: Text; var LocationFilter: Text): Boolean
    var
        ADCSUserRec: Record "ITI ADCS User";
        WhseEmployee: Record "Warehouse Employee";
    begin
        if ADCSLoginId <> '' then begin
            WhseEmpId := '';
            LocationFilter := '';

            if not ADCSUserRec.Get(ADCSLoginId) then
                exit(false);

            WhseEmployee.SetRange("ITI ADCS User", ADCSUserRec.Name);
            if not WhseEmployee.FindSet() then
                exit(false);

            WhseEmpId := WhseEmployee."User ID";
            repeat
                LocationFilter := LocationFilter + WhseEmployee."Location Code" + '|';
            until WhseEmployee.Next() = 0;
            LocationFilter := CopyStr(LocationFilter, 1, (StrLen(LocationFilter) - 1));
            exit(true);
        end;
        exit(false);
    end;

    procedure GetNextMiniForm(ActualMiniFormHeader: Record "ITI Miniform Header"; var MiniformHeader2: Record "ITI Miniform Header"; ADCSUser: Code[50])
    var
        ITIADCSUser: record "ITI ADCS User";
        ITIADCSProfile: record "ITI ADCS Profile";
    begin
        if not MiniformHeader2.Get(ActualMiniFormHeader."Next Miniform") then
            Error(MiniformNotFoundErr, ActualMiniFormHeader.Code)
        else
            IF MiniformHeader2."Main Menu" then begin
                ITIADCSUser.get(ADCSUser);
                IF ITIADCSUser."Profile Id" <> '' then begin
                    ITIADCSProfile.get(ITIADCSUser."Profile Id");
                    if not MiniformHeader2.Get(ITIADCSProfile."Miniform") then
                        Error(MiniformNotFoundErr, ActualMiniFormHeader.Code);
                end;
            end;
    end;

    procedure GetCallMiniForm(MiniFormCode: Code[20]; var MiniformHeader2: Record "ITI Miniform Header"; ReturnTextValue: Text)
    var
        ITIMiniformLine: Record "ITI Miniform Line";
    begin
        ITIMiniformLine.Reset();
        ITIMiniformLine.SetRange("Miniform Code", MiniFormCode);
        ITIMiniformLine.SetRange(Text, ReturnTextValue);
        ITIMiniformLine.FindFirst();
        ITIMiniformLine.TestField("Call Miniform");
        MiniformHeader2.Get(ITIMiniformLine."Call Miniform");
    end;


    procedure RunPreviousMiniform(var DOMxmlin: XmlDocument)
    var
        MiniformHeader2: Record "ITI Miniform Header";
        PreviousCode: Text;
    begin
        DecreaseStack(DOMxmlin, PreviousCode);
        MiniformHeader2.Get(PreviousCode);
        MiniformHeader2.SaveXMLinExt(DOMxmlin);
        Codeunit.Run(MiniformHeader2."Handling Codeunit", MiniformHeader2);
    end;


    procedure IncreaseStack(var DOMxmlin: XmlDocument; NextElement: Text)
    var
        StackCode: Text;
        ReturnedNode: XmlNode;
        RootNode: XmlNode;
    begin
        ITIXMLDOMManagement.GetRootNode(DOMxmlin, RootNode);
        ITIXMLDOMManagement.FindNode(RootNode, 'Header', ReturnedNode);
        StackCode := GetNodeAttribute(ReturnedNode, 'StackCode');

        if StackCode = '' then
            StackCode := NextElement
        else
            StackCode := StrSubstNo(Substr2Lbl, StackCode, NextElement);

        SetNodeAttribute(ReturnedNode, 'StackCode', StackCode);
        SetNodeAttribute(ReturnedNode, 'RunReturn', '0');
    end;


    procedure DecreaseStack(var DOMxmlin: XmlDocument; var PreviousElement: Text)
    var
        p: Integer;
        pos: Integer;
        StackCode: Text;
        ReturnedNode: XmlNode;
        RootNode: XmlNode;
    begin
        ITIXMLDOMManagement.GetRootNode(DOMxmlin, RootNode);
        ITIXMLDOMManagement.FindNode(RootNode, 'Header', ReturnedNode);
        StackCode := GetNodeAttribute(ReturnedNode, 'StackCode');

        if StackCode = '' then begin
            PreviousElement := GetNodeAttribute(ReturnedNode, 'UseCaseCode');
            exit;
        end;

        for p := StrLen(StackCode) downto 1 do
            if StackCode[p] = '|' then begin
                pos := p;
                p := 1;
            end;

        if pos > 1 then begin
            PreviousElement := CopyStr(StackCode, pos + 1, StrLen(StackCode) - pos);
            StackCode := CopyStr(StackCode, 1, pos - 1);
        end else begin
            PreviousElement := StackCode;
            StackCode := '';
        end;

        SetNodeAttribute(ReturnedNode, 'StackCode', StackCode);
        SetNodeAttribute(ReturnedNode, 'RunReturn', '1');
    end;

    procedure GetFunctionKey(MiniformCode: Code[20]; InputValue: Text): Integer
    var
        ITIMiniformFunction: Record "ITI Miniform Function";
        ITIMiniformFunctionGroup: Record "ITI Miniform Function Group";
    begin
        if StrLen(InputValue) > MaxStrLen(ITIMiniformFunctionGroup.Code) then
            exit(0);
        if ITIMiniformFunctionGroup.Get(InputValue) then begin
            if not ITIMiniformFunction.Get(MiniformCode, InputValue) then
                Error(NotUsedErr, InputValue);

            exit(ITIMiniformFunctionGroup.KeyDef.AsInteger());
        end;
        exit(0);
    end;

    procedure GetActiveInputNo(MiniformCode: Code[20]; FieldID: Integer): Integer
    var
        ITIMiniformLine: Record "ITI Miniform Line";
        CurrField: Integer;
    begin
        if FieldID = 0 then
            exit(1);

        ITIMiniformLine.SetRange("Miniform Code", MiniformCode);
        ITIMiniformLine.SetRange("Field Type", ITIMiniformLine."Field Type"::Input);
        if ITIMiniformLine.FindSet() then
            repeat
                CurrField += 1;
                if ITIMiniformLine."Field No." = FieldID then
                    exit(CurrField);
            until ITIMiniformLine.Next() = 0;

        exit(1);
    end;

    procedure LastEntryField(MiniformCode: Code[20]; FieldID: Integer): Boolean
    var
        ITIMiniformLine: Record "ITI Miniform Line";
    begin
        if FieldID = 0 then
            exit(false);

        ITIMiniformLine.SetRange("Miniform Code", MiniformCode);
        ITIMiniformLine.SetFilter("Field Type", Substr2Lbl, ITIMiniformLine."Field Type"::Input, ITIMiniformLine."Field Type"::Asterisk);
        if ITIMiniformLine.FindLast() and (ITIMiniformLine."Field No." = FieldID) then
            exit(true);

        exit(false);
    end;

    procedure GetLoginFormCode(): Code[20]
    var
        ITIMiniformHeader: Record "ITI Miniform Header";
    begin
        ITIMiniformHeader.SetRange("Start Miniform", true);
        if ITIMiniformHeader.FindFirst() then
            exit(ITIMiniformHeader.Code);
        Error(OneMiniFormErr, ITIMiniformHeader.FieldCaption("Start Miniform"));
    end;

    procedure GetFunctionKeyNextMiniform(FunctionGroup: Code[20]; MiniformCode: Code[20]): Code[20]
    var
        MiniformFunction: Record "ITI Miniform Function";
    begin
        if MiniformFunction.Get(MiniformCode, FunctionGroup) then
            exit(MiniformFunction."Next Miniform");
        exit('');
    end;

    procedure IsPermissionGranted(MiniFormHdr: Record "ITI Miniform Header"; MiniFormLine: Record "ITI Miniform Line") PermissionGranted: Boolean
    begin
        /*PermissionGranted:=FALSE;
        IF MiniFormHdr."Check Permissions" AND (MiniFormLine.Area = MiniFormLine.Area::Body) THEN BEGIN
        MiniformPermissions.SETRANGE("Miniform Code",MiniFormLine."Miniform Code");
        MiniformPermissions.SETRANGE("Line No.",MiniFormLine."Line No.");
        MiniformPermissions.SETRANGE("ADCS Name",ADCSUser.Name);
        PermissionGranted := NOT MiniformPermissions.ISEMPTY;
        END ELSE*/
        PermissionGranted := true;
        //   end;
    end;

    procedure SetGlobalValues(VariableName: Text; VariableValue: Text)
    begin
        GlobalVariables.Add(VariableName, VariableValue);
    end;

    procedure SetDocumentHeader(var DocHeader: RecordRef)
    begin
        RecRefHeader := DocHeader.Duplicate();
        RecRefHeaderRunning := true;
    end;

    procedure SetDocumenLines(var DocLines: RecordRef)
    begin
        RecRefLines := DocLines.Duplicate();
        RecRefLinesRunning := true;
    end;

    local procedure CheckRecRefLinePosition()
    var
        IterRecRef: RecordRef;
        Iter: Integer;
    begin
        IterRecRef := RecRefLines.Duplicate();

        While IterRecRef.RecordId <> RecRef.RecordId do begin
            IterRecRef.Next();
            Iter += 1;
        end;
        RecRefPosition := Iter + 1;
    end;

    var
        Substr2Lbl: Label '%1|%2', Locked = true, Comment = '%1 - first %2 - second';
}

