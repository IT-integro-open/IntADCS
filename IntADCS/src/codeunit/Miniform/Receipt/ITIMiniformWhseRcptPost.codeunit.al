codeunit 69106 "ITI Miniform Whse. Rcpt Post"
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
            ProcessInput;

        CLEAR(DOMxmlin);
    end;

    var
        MiniformHeader: Record "ITI Miniform Header";
        XMLDOMMgt: Codeunit "ITI XML DOM Management";
        ADCSCommunication: Codeunit "ITI ADCS Communication";
        ADCSMgt: Codeunit "ITI ADCS Management";
        RecRef: RecordRef;
        DOMxmlin: XmlDocument;
        ReturnedNode: XmlNode;
        RootNode: XmlNode;
        ADCSUserId: Text[250];
        Remark: Text[250];
        WhseEmpId: Text[250];
        LocationFilter: Text[250];
        CurrentCode: Text[250];
        StackCode: Text[250];
        ActiveInputField: Integer;
        Text006: Label 'No input Node found.';
        Text007: Label 'Record not found';
        Text012: Label 'No Lines available_BELL__BELL_';

    local procedure ProcessInput()
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
        Location: Record Location;
        TableNo: Integer;
        RecordId: RecordID;
        FldNo: Integer;
        TextValue: Text[250];
    begin
        IF XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode) THEN
            TextValue := ReturnedNode.AsXmlElement().InnerText
        ELSE
            ERROR(Text006);

        EVALUATE(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.OPEN(TableNo);
        EVALUATE(RecordId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        IF RecRef.GET(RecordId) THEN BEGIN
            RecRef.SETTABLE(WhseRcptLine);
            WhseRcptLine.SETRANGE("No.", WhseRcptLine."No.");
            IF UPPERCASE(TextValue) = 'TAK' THEN BEGIN
                RunMainMenuMiniform(DOMxmlin);
                Post(WhseRcptLine);
            END ELSE
                ADCSCommunication.RunPreviousMiniform(DOMxmlin);
        END ELSE BEGIN
            ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            EXIT;
        END;
    end;

    local procedure PrepareData()
    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        TableNo: Integer;
        RecordId: RecordID;
    begin
        XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode);

        EVALUATE(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.OPEN(TableNo);
        EVALUATE(RecordId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        IF RecRef.GET(RecordId) THEN BEGIN
            RecRef.SETTABLE(WhseRcptHeader);
            WhseRcptLine.SETRANGE("No.", WhseRcptHeader."No.");
            IF NOT WhseRcptLine.FINDFIRST THEN BEGIN
                ADCSMgt.SendError(Text012);
                EXIT;
            END ELSE BEGIN
                WhseRcptLine.MODIFYALL("ITI User ID", WhseEmpId);
                COMMIT;
            END;

            RecRef.GETTABLE(WhseRcptLine);
            ADCSCommunication.SetRecRef(RecRef);
            ActiveInputField := 1;
            SendForm(ActiveInputField);
        END ELSE
            ERROR(Text007);
    end;


    procedure Post(WhseRcptLine2: Record "Warehouse Receipt Line")
    var
        WhseActHeader: Record "Warehouse Activity Header";
        WhseActLine: Record "Warehouse Activity Line";
        WhseRcptLine: Record "Warehouse Receipt Line";
        ADCSSetup: Record "ITI ADCS Setup";
        WhsePostReceipt: Codeunit "Whse.-Post Receipt";
    begin
        IF NOT WhseRcptLine.GET(WhseRcptLine2."No.", WhseRcptLine2."Line No.") THEN
            ERROR(Text007);

        CLEAR(WhsePostReceipt);
        WhsePostReceipt.SetHideValidationDialog(TRUE);
        WhsePostReceipt.RUN(WhseRcptLine);

        ADCSSetup.GET;
        IF ADCSSetup."Assign Whse. Empl. to Put-Away" THEN BEGIN
            WhseActLine.SETCURRENTKEY("Source Type", "Source Subtype", "Source No.");
            WhseActLine.SETRANGE("Source Type", WhseRcptLine."Source Type");
            WhseActLine.SETRANGE("Source Subtype", WhseRcptLine."Source Subtype");
            WhseActLine.SETRANGE("Source No.", WhseRcptLine."Source No.");
            IF WhseActLine.FINDFIRST THEN BEGIN
                WhseActHeader.GET(WhseActLine."Activity Type", WhseActLine."No.");
                WhseActHeader.VALIDATE("Assigned User ID", WhseEmpId);
                WhseActHeader.MODIFY;
            END;
        END;
    end;

    local procedure SendForm(InputField: Integer)
    begin
        ADCSCommunication.EncodeMiniForm(MiniformHeader, StackCode, DOMxmlin, InputField, Remark, ADCSUserId);
        ADCSCommunication.GetReturnXML(DOMxmlin);
        ADCSMgt.SendXMLReply(DOMxmlin);
    end;


    procedure RunMainMenuMiniform(var DOMxmlin: XmlDocument)
    var
        MiniformHeader2: Record "ITI Miniform Header";
        PreviousCode: Text[20];
    begin
        ADCSCommunication.DecreaseStack(DOMxmlin, PreviousCode);
        ADCSCommunication.DecreaseStack(DOMxmlin, PreviousCode);
        MiniformHeader2.GET(PreviousCode);
        MiniformHeader2.SaveXMLinExt(DOMxmlin);
        CODEUNIT.RUN(MiniformHeader2."Handling Codeunit", MiniformHeader2);
    end;

}