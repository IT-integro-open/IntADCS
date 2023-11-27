codeunit 69058 "ITI Miniform Mainmenu"
{
    TableNo = "ITI Miniform Header";

    trigger OnRun()
    var
        MiniformMgt: Codeunit "ITI Miniform Management";
        ADCSSetup: Record "ITI ADCS Setup";
    begin
        ADCSSetup.get();
        //GlobalLanguage(ADCSSetup.GetLanguageID);
        MiniformMgt.Initialize(
          MiniformHeader, Rec, DOMxmlin, ReturnedNode,
          RootNode, XMLDOMMgt, ADCSCommunication, ADCSUserId,
          CurrentCode, StackCode, WhseEmpId, LocationFilter);

        IF Rec.Code <> CurrentCode THEN
            SendForm(1)
        ELSE
            Process();

        CLEAR(DOMxmlin);
    end;

    var
        MiniformHeader: Record "ITI Miniform Header";
        MiniformHeader2: Record "ITI Miniform Header";
        ADCSCommunication: Codeunit "ITI ADCS Communication";
        ADCSMgt: Codeunit "ITI ADCS Management";
        XMLDOMMgt: Codeunit "ITI XML DOM Management";
        NodeNotFoundErr: Label 'No input Node found.';
        ADCSUserId: Text;
        CurrentCode: Text;
        LocationFilter: Text;
        StackCode: Text;
        TextValue: Text;
        WhseEmpId: Text;
        DOMxmlin: XmlDocument;
        ReturnedNode: XmlNode;
        RootNode: XmlNode;

    local procedure Process()
    var 
        FuncGroup: Record "ITI Miniform Function Group";
    begin
        IF XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode) THEN
            TextValue := ReturnedNode.AsXmlElement().InnerText
        ELSE
            ERROR(NodeNotFoundErr);
        
        ADCSCommunication.GetCallMiniForm(MiniformHeader.Code, MiniformHeader2, TextValue);
        ADCSCommunication.IncreaseStack(DOMxmlin, MiniformHeader.Code);
        MiniformHeader2.SaveXMLinExt(DOMxmlin);
        CODEUNIT.RUN(MiniformHeader2."Handling Codeunit", MiniformHeader2);



    end;

    local procedure SendForm(ActiveInputField: Integer)
    begin
        ADCSCommunication.EncodeMiniForm(MiniformHeader, '', DOMxmlin, ActiveInputField, STRSUBSTNO(LoggedMsg, ADCSUserId), ADCSUserId);
        ADCSCommunication.GetReturnXML(DOMxmlin);
        ADCSMgt.SendXMLReply(DOMxmlin);
    end;

    var
        LoggedMsg: Label 'Logged in: %1';
}

