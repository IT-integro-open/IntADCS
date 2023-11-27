/// <summary>
/// Codeunit ITI ADCS WS (ID 50054).
/// </summary>
codeunit 69053 "ITI ADCS WS"
{

    /// <summary>
    /// ProcessDocument.
    /// </summary>
    /// <param name="Document">VAR Text.</param>
    procedure ProcessDocument(var Document: Text)
    var
        ITIADCSManagement: Codeunit "ITI ADCS Management";
        MyOutStream: OutStream;
        InputXmlDocument: XmlDocument;
        OutputXmlDocument: XmlDocument;
    begin
        XmlDocument.ReadFrom(Document, InputXmlDocument);
        ITIADCSManagement.ProcessDocument(InputXmlDocument);
        ITIADCSManagement.GetOutboundDocument(OutputXmlDocument);
        OutputXmlDocument.WriteTo(Document);
    end;
}
