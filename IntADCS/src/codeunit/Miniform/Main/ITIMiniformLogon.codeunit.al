codeunit 69057 "ITI Miniform Logon"
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

        IF ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RunReturn') = '0' THEN BEGIN
            IF Rec.Code <> CurrentCode THEN
                PrepareData()
            ELSE
                ProcessInput();
        END ELSE
            PrepareData();

        CLEAR(DOMxmlin);
    end;


    local procedure ProcessInput()
    var
        FuncGroup: Record "ITI Miniform Function Group";
        RecId: RecordID;
        FldNo: Integer;
        TableNo: Integer;
        TextValue: Text;
    begin
        IF XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode) THEN
            TextValue := ReturnedNode.AsXmlElement().InnerText
        ELSE
            ERROR(NoInputNodeErr);

        IF EVALUATE(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo')) THEN BEGIN
            RecRef.OPEN(TableNo);
            EVALUATE(RecId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
            IF RecRef.GET(RecId) THEN BEGIN
                RecRef.SETTABLE(ADCSUser);
                ADCSCommunication.SetRecRef(RecRef);
            END ELSE
                ERROR(RecordNotFoundErr);
        END;
        FuncGroup.KeyDef := Enum::"ITI KeyDef".FromInteger(ADCSCommunication.GetFunctionKey(MiniformHeader.Code, TextValue));

        CASE FuncGroup.KeyDef OF
            FuncGroup.KeyDef::Esc:
                PrepareData();
            FuncGroup.KeyDef::Input:
                BEGIN
                    EVALUATE(FldNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'FieldID'));
                    CASE FldNo OF
                        ADCSUser.FIELDNO(Name):
                            IF NOT GetUser(UPPERCASE(TextValue)) THEN
                                EXIT;
                        ADCSUser.FIELDNO(Password):
                            IF NOT CheckPassword(TextValue) THEN
                                EXIT;
                        ELSE BEGIN
                            ADCSCommunication.FieldSetvalue(RecRef, FldNo, TextValue);
                            RecRef.SETTABLE(ADCSUser);
                        END;
                    END;

                    ActiveInputField := ADCSCommunication.GetActiveInputNo(CurrentCode, FldNo);
                    IF ADCSCommunication.LastEntryField(CurrentCode, FldNo) THEN BEGIN
                        ADCSCommunication.GetNextMiniForm(MiniformHeader, MiniformHeader2,ADCSUserId);
                        MiniformHeader2.SaveXMLinExt(DOMxmlin);
                        CODEUNIT.RUN(MiniformHeader2."Handling Codeunit", MiniformHeader2);
                    END ELSE
                        ActiveInputField += 1;

                    RecRef.GETTABLE(ADCSUser);
                    ADCSCommunication.SetRecRef(RecRef);
                END;
            else
                Error('Unknown action');
        END;

        IF NOT (FuncGroup.KeyDef IN [FuncGroup.KeyDef::Esc]) AND
           NOT ADCSCommunication.LastEntryField(CurrentCode, FldNo)
        THEN
            SendForm(ActiveInputField);
    end;

    local procedure GetUser(TextValue: Text) ReturnValue: Boolean
    begin
        IF ADCSUser.GET(TextValue) THEN BEGIN
            ADCSUserId := ADCSUser.Name;
            ADCSUser.Password := '';
            IF NOT ADCSCommunication.GetWhseEmployee(ADCSUserId, WhseEmpId, LocationFilter) THEN BEGIN
                ADCSMgt.SendError(InvalidUserIdErr + ' ' + TextValue);
                ReturnValue := FALSE;
                EXIT;
            END;
        END ELSE BEGIN
            ADCSMgt.SendError(InvalidUserIdErr + ' ' + TextValue);
            ReturnValue := FALSE;
            EXIT;
        END;
        ReturnValue := TRUE;
    end;

    local procedure CheckPassword(TextValue: Text) ReturnValue: Boolean
    begin
        ADCSUser.GET(ADCSUserId);
        IF ADCSUser.Password <> ADCSUser.CalculatePassword(COPYSTR(TextValue, 1, 30)) THEN BEGIN
            ADCSMgt.SendError(InvalidPasswordErr + ' ' + TextValue);
            ReturnValue := FALSE;
            EXIT;
        END;
        ReturnValue := TRUE;
        ADCSUser."Last Login Date" := Today();
        ADCSUser."Last Login Time" := Time();
        ADCSUser.Modify();
    end;

    local procedure PrepareData()
    begin
        ActiveInputField := 1;
        SendForm(ActiveInputField);
    end;

    local procedure SendForm(InputField: Integer)
    begin
        ADCSCommunication.EncodeMiniForm(MiniformHeader, StackCode, DOMxmlin, InputField, '', ADCSUserId);
        ADCSCommunication.GetReturnXML(DOMxmlin);
        ADCSMgt.SendXMLReply(DOMxmlin);
    end;

    local procedure MyProcedure(ActualMiniFormHeader: Record "ITI Miniform Header"; var MiniformHeader2: Record "ITI Miniform Header")
    var
        ITIADCSProfile: Record "ITI ADCS Profile";
        ITIADCSUser: Record "ITI ADCS User";
    begin
        ITIADCSUser.get(ADCSUserId);
        IF ITIADCSUser."Profile Id" <> '' then begin
            ITIADCSProfile.get(ITIADCSUser."Profile Id");
            IF NOT MiniformHeader2.GET(ITIADCSProfile.Miniform) THEN
                ERROR(MiniformNotFoundErr, ActualMiniFormHeader.Code);
        end else
            ADCSCommunication.GetNextMiniForm(MiniformHeader, MiniformHeader2,ADCSUserId);
    end;

    var
        ADCSUser: Record "ITI ADCS User";
        MiniformHeader: Record "ITI Miniform Header";
        MiniformHeader2: Record "ITI Miniform Header";
        ADCSCommunication: Codeunit "ITI ADCS Communication";
        ADCSMgt: Codeunit "ITI ADCS Management";
        XMLDOMMgt: Codeunit "ITI XML DOM Management";
        RecRef: RecordRef;
        ActiveInputField: Integer;
        InvalidUserIdErr: Label 'Invalid User ID.';
        InvalidPasswordErr: Label 'Invalid Password.';
        NoInputNodeErr: Label 'No input Node found.';
        RecordNotFoundErr: Label 'Record not found.';
        MiniformNotFoundErr: Label 'Miniform %1 not found.';
        ADCSUserId: Text;
        CurrentCode: Text;
        LocationFilter: Text;
        StackCode: Text;
        WhseEmpId: Text;
        DOMxmlin: XmlDocument;
        ReturnedNode: XmlNode;
        RootNode: XmlNode;
}

