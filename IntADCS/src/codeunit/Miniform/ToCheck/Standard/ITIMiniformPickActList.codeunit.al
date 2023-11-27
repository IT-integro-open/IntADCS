codeunit 69073 "ITI Miniform Pick Act. List"
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
            PrepareData()
        ELSE
            ProcessSelection();

        CLEAR(DOMxmlin);
    end;

    var
        MiniformHeader: Record "ITI Miniform Header";
        MiniformHeader2: Record "ITI Miniform Header";
        ADCSCommunication: Codeunit "ITI ADCS Communication";
        ADCSMgt: Codeunit "ITI ADCS Management";
        XMLDOMMgt: Codeunit "ITI XML DOM Management";
        RecRef: RecordRef;
        ActiveInputField: Integer;
        Text000: Label 'Function not Found.';
        Text006: Label 'No input Node found.';
        Text009: Label 'No Documents found.';
        ADCSUserId: Text;
        CurrentCode: Text;
        LocationFilter: Text;
        PreviousCode: Text;
        Remark: Text;
        StackCode: Text;
        TextValue: Text;
        WhseEmpId: Text;
        DOMxmlin: XmlDocument;
        ReturnedNode: XmlNode;
        RootNode: XmlNode;

    local procedure ProcessSelection()
    var
        WhseActivityHeader: Record 5766;
        FuncGroup: Record 7702;
        RecId: RecordID;
        TableNo: Integer;
    begin
        IF XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode) THEN
            TextValue := ReturnedNode.AsXmlElement().InnerText
        ELSE
            ERROR(Text006);

        EVALUATE(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.OPEN(TableNo);
        EVALUATE(RecId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        IF RecRef.GET(RecId) THEN BEGIN
            RecRef.SETTABLE(WhseActivityHeader);
            WhseActivityHeader.SETCURRENTKEY(Type, "No.");
            WhseActivityHeader.SETRANGE(Type, WhseActivityHeader.Type);
            WhseActivityHeader.SETRANGE("Assigned User ID", WhseEmpId);
            WhseActivityHeader.SETFILTER("Location Code", LocationFilter);
            RecRef.GETTABLE(WhseActivityHeader);
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
        WhseActivityHeader: Record 5766;
    begin
        WhseActivityHeader.RESET();
        WhseActivityHeader.SETRANGE(Type, WhseActivityHeader.Type::Pick);
        IF WhseEmpId <> '' THEN BEGIN
            WhseActivityHeader.SETRANGE("Assigned User ID", WhseEmpId);
            WhseActivityHeader.SETFILTER("Location Code", LocationFilter);
        END;
        IF NOT WhseActivityHeader.FINDFIRST() THEN BEGIN
            IF ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RunReturn') = '0' THEN BEGIN
                ADCSMgt.SendError(Text009);
                EXIT;
            END;
            ADCSCommunication.DecreaseStack(DOMxmlin, PreviousCode);
            MiniformHeader2.GET(PreviousCode);
            MiniformHeader2.SaveXMLinExt(DOMxmlin);
            CODEUNIT.RUN(MiniformHeader2."Handling Codeunit", MiniformHeader2);
        END ELSE BEGIN
            RecRef.GETTABLE(WhseActivityHeader);
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

