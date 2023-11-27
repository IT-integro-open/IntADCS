codeunit 69105 "ITI Miniform WhseRcptList Post"
{
    TableNo = "ITI Miniform Header";

    trigger OnRun()
    var
        MiniformMgmt: Codeunit "ITI Miniform Management";
    begin
        MiniformMgmt.Initialize(
          MiniformHeader, Rec, DOMxmlin, ReturnedNode,
          RootNode, XMLDOMMgt, ADCSCommunication, ADCSUserId,
          CurrentCode, StackCode, WhseEmpId, LocationFilter);

        IF Rec.Code <> CurrentCode THEN
            PrepareData
        ELSE
            ProcessSelection;

        CLEAR(DOMxmlin);
    end;

    var
        MiniformHeader: Record "ITI Miniform Header";
        MiniformHeader2: Record "ITI Miniform Header";
        XMLDOMMgt: Codeunit "ITI XML DOM Management";
        ADCSCommunication: Codeunit "ITI ADCS Communication";
        ADCSMgt: Codeunit "ITI ADCS Management";
        ReturnedNode: XmlNode;
        DOMxmlin: XmlDocument;
        RootNode: XmlNode;
        Text000: Label 'Function not Found.';
        Text006: Label 'No input Node found.';
        TextValue: Text[250];
        ADCSUserId: Text[250];
        WhseEmpId: Text[250];
        LocationFilter: Text[250];
        CurrentCode: Text[250];
        PreviousCode: Text[250];
        StackCode: Text[250];
        Remark: Text[250];
        ActiveInputField: Integer;
        Text009: Label 'No Documents found.';
        RecRef: RecordRef;

    local procedure ProcessSelection()
    var
        RecordId: RecordID;
        WhseRcptHeader: Record "Warehouse Receipt Header";
        FuncGroup: Record "ITI Miniform Function Group";
        TableNo: Integer;
    begin
        IF XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode) THEN
            TextValue := ReturnedNode.AsXmlElement().InnerText
        ELSE
            ERROR(Text006);

        EVALUATE(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.OPEN(TableNo);
        EVALUATE(RecordId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        IF RecRef.GET(RecordId) THEN BEGIN
            RecRef.SETTABLE(WhseRcptHeader);
            WhseRcptHeader.SETCURRENTKEY("No.");
            WhseRcptHeader.SETFILTER("Location Code", LocationFilter);
            WhseRcptHeader.SETRANGE("ITI Partially Posted", FALSE);
            WhseRcptHeader.SETRANGE("Assigned User ID", WhseEmpId);
            RecRef.GETTABLE(WhseRcptHeader);
            ADCSCommunication.SetRecRef(RecRef);
        END ELSE BEGIN
            ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            EXIT;
        END;

             FuncGroup.KeyDef := Enum::"ITI KeyDef".FromInteger(ADCSCommunication.GetFunctionKey(MiniformHeader.Code, TextValue));
        ActiveInputField := 1;

        CASE FuncGroup.KeyDef OF
            FuncGroup.KeyDef::Esc:
                ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            FuncGroup.KeyDef::First:
                ADCSCommunication.FindRecRef(0, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::LnDn:
                IF NOT ADCSCommunication.FindRecRef(1, MiniformHeader."No. of Records in List") THEN
                    Remark := Text009;
            FuncGroup.KeyDef::LnUp:
                ADCSCommunication.FindRecRef(2, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::Last:
                ADCSCommunication.FindRecRef(3, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::PgDn:
                IF NOT ADCSCommunication.FindRecRef(4, MiniformHeader."No. of Records in List") THEN
                    Remark := Text009;
            FuncGroup.KeyDef::PgUp:
                ADCSCommunication.FindRecRef(5, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::Input:
                BEGIN
                    ADCSCommunication.IncreaseStack(DOMxmlin, MiniformHeader.Code);
                    ADCSCommunication.GetNextMiniForm(MiniformHeader, MiniformHeader2,ADCSUserId);
                    MiniformHeader2.SaveXMLinExt(DOMxmlin);
                    CODEUNIT.RUN(MiniformHeader2."Handling Codeunit", MiniformHeader2);
                END;
            ELSE
                ERROR(Text000);
        END;

        IF NOT (FuncGroup.KeyDef IN [FuncGroup.KeyDef::Esc, FuncGroup.KeyDef::Input]) THEN
            SendForm(ActiveInputField);
    end;

    local procedure PrepareData()
    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
    begin
        WhseRcptHeader.RESET;
        IF WhseEmpId <> '' THEN BEGIN
            WhseRcptHeader.SETFILTER("Location Code", LocationFilter);
            WhseRcptHeader.SETRANGE("Assigned User ID", WhseEmpId);
        END;
        WhseRcptHeader.SETRANGE("ITI Partially Posted", FALSE);
        IF NOT WhseRcptHeader.FINDFIRST THEN BEGIN
            IF ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RunReturn') = '0' THEN BEGIN
                ADCSMgt.SendError(Text009);
                EXIT;
            END;
            ADCSCommunication.DecreaseStack(DOMxmlin, PreviousCode);
            MiniformHeader2.GET(PreviousCode);
            MiniformHeader2.SaveXMLinExt(DOMxmlin);
            CODEUNIT.RUN(MiniformHeader2."Handling Codeunit", MiniformHeader2);
        END ELSE BEGIN
            RecRef.GETTABLE(WhseRcptHeader);
            ADCSCommunication.SetRecRef(RecRef);
            ActiveInputField := 1;
            SendForm(ActiveInputField);
        END;
    end;

    local procedure SendForm(InputField: Integer)
    begin
        ADCSCommunication.EncodeMiniForm(MiniformHeader, StackCode, DOMxmlin, InputField, Remark, ADCSUserId);
        ADCSCommunication.GetReturnXML(DOMxmlin);
        ADCSMgt.SendXMLReply(DOMxmlin);
    end;
}

