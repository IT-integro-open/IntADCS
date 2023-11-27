
/// <summary>
/// Codeunit ITI ADCS Management (ID 69050).
/// </summary>
codeunit 69052 "ITI ADCS Management"
{
    SingleInstance = true;

    var
        LineFromLbl: Label 'Line %1 from %2.';
        AutomaticJournalErr: Label 'Automatically %1 journal not set.';
        TextDefault: Label 'DEFAULT';
        InboundDocument: XmlDocument;
        OutboundDocument: XmlDocument;

    /// <summary>
    /// SendXMLReply.
    /// </summary>
    /// <param name="xmlout">XmlDocument.</param>
    procedure SendXMLReply(xmlout: XmlDocument)
    begin
        OutboundDocument := xmlout;
    end;

    /// <summary>
    /// SendError.
    /// </summary>
    /// <param name="ErrorString">Text[250].</param>
    procedure SendError(ErrorString: Text)
    var
        ITIXMLDOMManagement: Codeunit "ITI XML DOM Management";
        Child: XmlNode;
        ReturnedNode: XmlNode;
        RootNode: XmlNode;
        NodeList: XmlNodeList;
    begin
        OutboundDocument := InboundDocument;
        CLEAR(ITIXMLDOMManagement);
        NodeList := OutboundDocument.GetChildElements();
        NodeList.get(1, RootNode);
        IF ITIXMLDOMManagement.FindNode(RootNode, 'Header', ReturnedNode) THEN BEGIN
            IF ITIXMLDOMManagement.FindNode(RootNode, 'Header/Input', Child) THEN
                Child.Remove();
            IF ITIXMLDOMManagement.FindNode(RootNode, 'Header/Comment', Child) THEN
                Child.Remove();
            ITIXMLDOMManagement.AddElement(ReturnedNode, 'Comment', ErrorString, '', ReturnedNode);
            ITIXMLDOMManagement.AddAttribute(ReturnedNode, 'Error', '1');
        END;
        CLEAR(RootNode);
        CLEAR(Child);
    end;

    procedure SendMessage(ErrorString: Text)
    var
        ITIXMLDOMManagement: Codeunit "ITI XML DOM Management";
        Child: XmlNode;
        ReturnedNode: XmlNode;
        RootNode: XmlNode;
        NodeList: XmlNodeList;
    begin
        OutboundDocument := InboundDocument;
        CLEAR(ITIXMLDOMManagement);
        NodeList := OutboundDocument.GetChildNodes();
        NodeList.get(1, RootNode);
        IF ITIXMLDOMManagement.FindNode(RootNode, 'Header', ReturnedNode) THEN BEGIN
            IF ITIXMLDOMManagement.FindNode(RootNode, 'Header/Comment', Child) THEN
                Child.Remove();
            ITIXMLDOMManagement.AddElement(ReturnedNode, 'Comment', ErrorString, '', ReturnedNode);
        END;
        CLEAR(RootNode);
        CLEAR(Child);
    end;

    /// <summary>
    /// ProcessDocument.
    /// </summary>
    /// <param name="Document">XmlDocument.</param>
    procedure ProcessDocument(Document: XmlDocument)
    var
        ITIMiniformManagement: Codeunit "ITI Miniform Management";
    begin
        InboundDocument := Document;
        ITIMiniformManagement.ReceiveXML(InboundDocument);
    end;

    /// <summary>
    /// GetOutboundDocument.
    /// </summary>
    /// <param name="Document">VAR XmlDocument.</param>
    procedure GetOutboundDocument(var Document: XmlDocument)
    begin
        Document := OutboundDocument;
    end;

    /*procedure FillBufferLines(var BinContentBuff: Record "Bin Content Buffer"; ItemFilter: Code[20]; LotFilter: Code[20]; SerialFilter: Code[20]; LocationFilter: Code[10]; BinFilter: Code[20]; WhseEmpId: Text[250])
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        ItemLedgEntry: Record "Item Ledger Entry";
        Location: Record Location;
        LotNoInfo: Record "Lot No. Information";
        AcctualRecord: Integer;
        NoOfRecords: Integer;
    begin
        // GLOBALLANGUAGE(1045);
        BinContentBuff.SETRANGE("ITI User ID", WhseEmpId);
        BinContentBuff.DELETEALL;

        IF BinFilter <> '' THEN BEGIN
            IF LocationFilter <> '' THEN
                BinContent.SETRANGE("Location Code", LocationFilter);
            IF BinFilter <> '' THEN
                BinContent.SETRANGE("Bin Code", BinFilter);
            IF ItemFilter <> '' THEN
                BinContent.SETRANGE("Item No.", ItemFilter);
            IF LotFilter <> '' THEN
                BinContent.SETRANGE("Lot No. Filter", LotFilter);
            BinContent.SETFILTER("Quantity (Base)", '<>0');
            IF BinContent.FINDSET THEN
                REPEAT
                    ItemFilter := BinContent."Item No.";
                    UpdateBufferLines(BinContentBuff, ItemFilter, LotFilter, SerialFilter, LocationFilter, BinFilter, WhseEmpId);
                UNTIL BinContent.NEXT = 0;
        END ELSE BEGIN
            UpdateBufferLines(BinContentBuff, ItemFilter, LotFilter, SerialFilter, LocationFilter, BinFilter, WhseEmpId);
        END;

        BinContentBuff.SETRANGE("ITI User ID", WhseEmpId);
        NoOfRecords := BinContentBuff.COUNT;
        AcctualRecord := 1;
        IF BinContentBuff.FINDSET THEN
            REPEAT
                BinContentBuff."ITI No. of Lines" := STRSUBSTNO(LineFromLbl, FORMAT(AcctualRecord), FORMAT(NoOfRecords));
                BinContentBuff.MODIFY;
                AcctualRecord += 1;
            UNTIL BinContentBuff.NEXT = 0;


    end;

    local procedure UpdateBufferLines(var BinContentBuff: Record "Bin Content Buffer"; ItemFilter: Code[20]; LotFilter: Code[20]; SerialFilter: Code[20]; LocationFilter: Code[10]; BinFilter: Code[20]; WhseEmpId: Text[250])
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        ItemLedgEntry: Record "Item Ledger Entry";
        Location: Record Location;
        LotNoInfo: Record "Lot No. Information";
    begin

        ItemLedgEntry.RESET;
        ItemLedgEntry.SETCURRENTKEY("Item No.", Open, "Variant Code",
          Positive, "Location Code", "Posting Date", "Expiration Date", "Lot No.", "Serial No.");
        IF ItemFilter <> '' THEN
            ItemLedgEntry.SETRANGE("Item No.", ItemFilter);
        ItemLedgEntry.SETRANGE(Open, TRUE);
        IF LocationFilter <> '' THEN
            ItemLedgEntry.SETRANGE("Location Code", LocationFilter);
        IF LotFilter <> '' THEN
            ItemLedgEntry.SETRANGE("Lot No.", LotFilter);
        IF SerialFilter <> '' THEN
            ItemLedgEntry.SETRANGE("Serial No.", SerialFilter);
        IF ItemLedgEntry.FINDSET THEN
            REPEAT
                IF Location.GET(ItemLedgEntry."Location Code") THEN BEGIN
                    IF NOT Location."Bin Mandatory" THEN BEGIN
                        IF NOT BinContentBuff.GET(
                          ItemLedgEntry."Location Code", '', ItemLedgEntry."Item No.", ItemLedgEntry."Variant Code",
                          ItemLedgEntry."Unit of Measure Code", ItemLedgEntry."Lot No.", SerialFilter)
                        THEN BEGIN
                            BinContentBuff.INIT;
                            BinContentBuff."Location Code" := ItemLedgEntry."Location Code";
                            BinContentBuff."Bin Code" := '';
                            BinContentBuff."Item No." := ItemLedgEntry."Item No.";
                            IF Item.GET(ItemLedgEntry."Item No.") THEN
                                BinContentBuff."ITI Description" := Item.Description;
                            BinContentBuff."Variant Code" := ItemLedgEntry."Variant Code";
                            BinContentBuff."Unit of Measure Code" := ItemLedgEntry."Unit of Measure Code";
                            BinContentBuff."Lot No." := ItemLedgEntry."Lot No.";
                            BinContentBuff."Serial No." := ItemLedgEntry."Serial No.";
                            BinContentBuff."Qty. to Handle (Base)" := ItemLedgEntry."Remaining Quantity";
                            BinContentBuff."ITI User ID" := WhseEmpId;
                            BinContentBuff.INSERT;
                        END ELSE BEGIN
                            BinContentBuff."Qty. to Handle (Base)" += ItemLedgEntry."Remaining Quantity";
                            BinContentBuff.MODIFY;
                        END;
                    END ELSE BEGIN
                        ItemFilter := ItemLedgEntry."Item No.";
                        LocationFilter := ItemLedgEntry."Location Code";
                        LotFilter := ItemLedgEntry."Lot No.";
                        SerialFilter := ItemLedgEntry."Serial No.";

                        IF LocationFilter <> '' THEN
                            BinContent.SETRANGE("Location Code", LocationFilter);
                        IF BinFilter <> '' THEN
                            BinContent.SETRANGE("Bin Code", BinFilter);
                        IF ItemFilter <> '' THEN
                            BinContent.SETRANGE("Item No.", ItemFilter);
                        IF LotFilter <> '' THEN
                            BinContent.SETRANGE("Lot No. Filter", LotFilter);
                        IF SerialFilter <> '' THEN
                            BinContent.SETRANGE("Serial No. Filter", SerialFilter);
                        BinContent.SETFILTER("Quantity (Base)", '<>0');
                        IF BinContent.FINDSET THEN
                            REPEAT
                                IF NOT BinContentBuff.GET(
                                  BinContent."Location Code", BinContent."Bin Code", BinContent."Item No.", BinContent."Variant Code",
                                  BinContent."Unit of Measure Code", LotFilter, SerialFilter)
                                THEN BEGIN
                                    BinContentBuff.INIT;
                                    BinContentBuff."Location Code" := BinContent."Location Code";
                                    BinContentBuff."Bin Code" := BinContent."Bin Code";
                                    BinContentBuff."Item No." := BinContent."Item No.";
                                    IF Item.GET(BinContent."Item No.") THEN
                                        BinContentBuff."ITI Description" := Item.Description;
                                    IF Bin.GET(BinContent."Location Code", BinContent."Bin Code") THEN
                                        BinContentBuff."ITI Description 2" := Bin.Description;
                                    BinContentBuff."Variant Code" := BinContent."Variant Code";
                                    BinContentBuff."Unit of Measure Code" := BinContent."Unit of Measure Code";
                                    BinContentBuff."Lot No." := LotFilter;
                                    BinContentBuff."Serial No." := SerialFilter;
                                    BinContentBuff."Zone Code" := BinContent."Zone Code";
                                    BinContent.CALCFIELDS(Quantity);
                                    BinContentBuff."Qty. to Handle (Base)" := BinContent.Quantity;
                                    BinContentBuff."ITI User ID" := WhseEmpId;
                                    BinContentBuff.INSERT;
                                END ELSE BEGIN
                                    BinContentBuff."Qty. to Handle (Base)" += BinContent."Quantity (Base)";
                                    BinContentBuff.MODIFY;
                                END;
                            UNTIL BinContent.NEXT = 0;
                    END;
                END;
            UNTIL ItemLedgEntry.NEXT = 0;
    end;
*/
    procedure GetWarehouseJournal(Type: Option Item,"Physical Inventory",Reclassification; var WarehouseJournalBatch: Record "Warehouse Journal Batch"; WhseUserID: Text[250]): Text[250]
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        WarehouseJournalTemplate.RESET;
        //WarehouseJournalTemplate.SETRANGE("ITI Automatic Journal", TRUE);
        WarehouseJournalTemplate.SETRANGE(Type, Type);
        IF NOT WarehouseJournalTemplate.FINDFIRST THEN
            EXIT(STRSUBSTNO(AutomaticJournalErr, TranslateWhseJournal(Type)))
        ELSE BEGIN
            WarehouseJournalBatch.SETRANGE("Journal Template Name", WarehouseJournalTemplate.Name);
            WarehouseJournalBatch.SETRANGE("Assigned User ID", WhseUserID);
            IF NOT WarehouseJournalBatch.FINDFIRST THEN
                AddWarehouseJournalBatch(WarehouseJournalTemplate, WarehouseJournalBatch, WhseUserID);
        END;
        EXIT('');
    end;

    local procedure AddWarehouseJournalBatch(WarehouseJournalTemplate: Record "Warehouse Journal Template"; var WarehouseJournalBatch: Record "Warehouse Journal Batch"; WhseUserID: Text[250])
    var
        OldWarehouseJournalBatch: Record "Warehouse Journal Batch";
    begin
        OldWarehouseJournalBatch.SETRANGE("Journal Template Name", WarehouseJournalTemplate.Name);
        OldWarehouseJournalBatch.SETRANGE(Name, TextDefault);
        IF OldWarehouseJournalBatch.FINDFIRST THEN BEGIN
            CLEAR(WarehouseJournalBatch);
            WarehouseJournalBatch := OldWarehouseJournalBatch;
            WarehouseJournalBatch.Name := GetUserID(WhseUserID);
            WarehouseJournalBatch.Description := WhseUserID;
            WarehouseJournalBatch."Assigned User ID" := WhseUserID;
            WarehouseJournalBatch.INSERT;
        END;
    end;

    local procedure GetUserID(UID: Text[250]): Code[10]
    begin
        EXIT(COPYSTR(DELCHR(COPYSTR(UID, STRPOS(UID, '\') + 1, STRLEN(UID)), '=', '.'), 1, 10));
    end;

    local procedure TranslateWhseJournal(Mess: Integer): Text[100]
    var
        ItemCapt: Label 'Item';
        PhysInvCapt: Label 'Physical Inventory';
        ReclassCapt: Label 'Reclassification';
    begin
        CASE Mess OF
            0:
                EXIT(ItemCapt);
            1:
                EXIT(PhysInvCapt);
            2:
                EXIT(ReclassCapt);
        END;
    end;

    procedure ChangePLtoENG(var InputText: Text): Text
    begin
        EXIT(CONVERTSTR(InputText, 'óęłśąńćźżÓĘŁŚĄŃĆŹŻ', 'oelsanczzOELSANCZZ'));
    end;
}

