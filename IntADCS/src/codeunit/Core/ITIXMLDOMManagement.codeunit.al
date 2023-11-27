codeunit 69055 "ITI XML DOM Management"
{
    procedure AddElement(var pXMLNode: XmlNode; pNodeName: Text; pNodeText: Text; pNameSpace: Text; var pCreatedNode: XmlNode): Boolean
    var
        lNewChildNode: XmlNode;
    begin
        if pNodeText <> '' then
            lNewChildNode := XmlElement.Create(pNodeName, pNameSpace, pNodeText).AsXmlNode()
        else
            lNewChildNode := XmlElement.Create(pNodeName, pNameSpace).AsXmlNode();
        if pXMLNode.AsXmlElement().Add(lNewChildNode) then begin
            pCreatedNode := lNewChildNode;
            exit(true);
        end;
    end;

    procedure AddRootElement(var pXMLDocument: XmlDocument; pNodeName: Text; var pCreatedNode: XmlNode): Boolean
    begin
        pCreatedNode := XmlElement.Create(pNodeName).AsXmlNode();
        exit(pXMLDocument.Add(pCreatedNode));
    end;

    procedure AddRootElementWithPrefix(var pXMLDocument: XmlDocument; pNodeName: Text; pPrefix: Text; pNameSpace: text; var pCreatedNode: XmlNode): Boolean
    begin
        pCreatedNode := XmlElement.Create(pNodeName, pNameSpace).AsXmlNode();
        pCreatedNode.AsXmlElement().Add(XmlAttribute.CreateNamespaceDeclaration(pPrefix, pNameSpace));
        exit(pXMLDocument.Add(pCreatedNode));
    end;

    procedure AddElementWithPrefix(var pXMLNode: XmlNode; pNodeName: Text; pNodeText: Text; pPrefix: Text; pNameSpace: text; var pCreatedNode: XmlNode): Boolean
    var
        lNewChildNode: XmlNode;
    begin
        if pNodeText <> '' then
            lNewChildNode := XmlElement.Create(pNodeName, pNameSpace, pNodeText).AsXmlNode()
        else
            lNewChildNode := XmlElement.Create(pNodeName, pNameSpace).AsXmlNode();
        lNewChildNode.AsXmlElement().Add(XmlAttribute.CreateNamespaceDeclaration(pPrefix, pNameSpace));
        if pXMLNode.AsXmlElement().Add(lNewChildNode) then begin
            pCreatedNode := lNewChildNode;
            exit(true);
        end;
    end;

    procedure AddPrefix(var pXMLNode: XmlNode; pPrefix: Text; pNameSpace: text): Boolean
    begin
        pXMLNode.AsXmlElement().Add(XmlAttribute.CreateNamespaceDeclaration(pPrefix, pNameSpace));
        exit(true);
    end;

    procedure AddAttribute(var pXMLNode: XmlNode; pName: Text; pValue: Text): Boolean
    begin
        pXMLNode.AsXmlElement().SetAttribute(pName, pValue);
        exit(true);
    end;

    procedure AddAttributeWithNamespace(var pXMLNode: XmlNode; pName: Text; pNameSpace: text; pValue: Text): Boolean
    begin
        pXMLNode.AsXmlElement().SetAttribute(pName, pNameSpace, pValue);
        exit(true);
    end;

    procedure FindNode(pXMLRootNode: XmlNode; pNodePath: Text; var pFoundXMLNode: XmlNode): Boolean
    begin
        IF pXMLRootNode.AsXmlElement().IsEmpty then
            exit(false);
        IF pXMLRootNode.SelectSingleNode(pNodePath, pFoundXMLNode) then
            exit(true);
    end;

    procedure FindNodeWithNameSpace(pXMLRootNode: XmlNode; pNodePath: Text; pPrefix: Text; pNamespace: Text; var pFoundXMLNode: XmlNode): Boolean
    var
        lXmlNsMgr: XmlNamespaceManager;
    begin
        IF pXMLRootNode.AsXmlElement().IsEmpty then
            exit(false);
        lXmlNsMgr.NameTable(pXMLRootNode.AsXmlDocument().NameTable);
        lXMLNsMgr.AddNamespace(pPrefix, pNamespace);

        IF pXMLRootNode.SelectSingleNode(pNodePath, lXmlNsMgr, pFoundXMLNode) then
            Exit(true);
    end;

    procedure FindNodesWithNameSpace(pXMLRootNode: XmlNode; pXPath: Text; pPrefix: Text; pNamespace: Text; var pFoundXmlNodeList: XmlNodeList): Boolean
    var
        lXmlNsMgr: XmlNamespaceManager;
    begin
        IF pXMLRootNode.AsXmlElement().IsEmpty then
            exit(false);
        lXmlNsMgr.NameTable(pXMLRootNode.AsXmlDocument().NameTable);
        lXMLNsMgr.AddNamespace(pPrefix, pNamespace);
        exit(FindNodesWithNamespaceManager(pXMLRootNode, pXPath, lXmlNsMgr, pFoundXmlNodeList));
    end;

    procedure FindNodesWithNamespaceManager(pXMLRootNode: XmlNode; pXPath: Text; pXmlNsMgr: XmlNamespaceManager; var pFoundXmlNodeList: XmlNodeList): Boolean
    var
    begin
        IF pXMLRootNode.AsXmlElement().IsEmpty then
            exit(false);
        IF not pXMLRootNode.SelectNodes(pXPath, pXmlNsMgr, pFoundXmlNodeList) then
            exit(false);

        IF pFoundXmlNodeList.Count = 0 then
            exit(false);
        exit(true);
    end;

    procedure FindNodeXML(pXMLRootNode: XmlNode; pNodePath: Text): Text
    var
        lXmlNode: XmlNode;
    begin
        IF pXMLRootNode.AsXmlElement().IsEmpty then
            exit('');
        IF pXMLRootNode.SelectSingleNode(pNodePath, lXmlNode) then
            Exit(lXmlNode.AsXmlElement().InnerXml);
    end;

    procedure FindNodeText(pXMLRootNode: XmlNode; pNodePath: Text): Text
    var
        lXmlNode: XmlNode;
    begin
        IF pXMLRootNode.AsXmlElement().IsEmpty then
            exit('');
        IF pXMLRootNode.SelectSingleNode(pNodePath, lXmlNode) then
            Exit(lXmlNode.AsXmlElement().InnerText);
    end;

    procedure FindNodeTextWithNameSpace(pXMLRootNode: XmlNode; pNodePath: Text; pPrefix: Text; pNamespace: Text): Text
    var
        lXmlNsMgr: XmlNamespaceManager;
        lXmlNode: XmlNode;
    begin
        IF pXMLRootNode.AsXmlElement().IsEmpty then
            exit('');
        lXmlNsMgr.NameTable(pXMLRootNode.AsXmlDocument().NameTable);
        lXMLNsMgr.AddNamespace(pPrefix, pNamespace);

        IF pXMLRootNode.SelectSingleNode(pNodePath, lXmlNsMgr, lXmlNode) then
            Exit(lXmlNode.AsXmlElement().InnerText);
    end;

    procedure FindNodeTextNs(pXMLRootNode: XmlNode; pNodePath: Text; pXmlNsMgr: XmlNamespaceManager): Text
    var
        lFoundXMLNode: XmlNode;
    begin
        if pXMLRootNode.SelectSingleNode(pNodePath, pXmlNsMgr, lFoundXMLNode) then
            exit(lFoundXMLNode.AsXmlElement().InnerText());
    end;

    procedure FindNodes(pXMLRootNode: XmlNode; pNodePath: Text; var pFoundXMLNodeList: XmlNodeList): Boolean
    begin
        if not pXMLRootNode.SelectNodes(pNodePath, pFoundXmlNodeList) then
            exit(false);
        if pFoundXmlNodeList.Count() = 0 then
            exit(false);
        exit(true);
    end;

    procedure LoadXMLDocumentFromText(pXMLText: Text; var pXMLDocument: XmlDocument)
    begin
        IF pXMLText = '' then
            exit;
        XmlDocument.ReadFrom(pXMLText, pXMLDocument);
    end;

    procedure FindAttribute(pXMLNode: XmlNode; var pXmlAttribute: XmlAttribute; pAttributeName: Text): Boolean
    begin
        exit(pXMLNode.AsXmlElement().Attributes().Get(pAttributeName, pXmlAttribute));
    end;

    procedure GetAttributeValue(pXMLNode: XmlNode; pAttributeName: Text): Text
    var
        lXmlAttribute: XmlAttribute;
    begin
        if pXMLNode.AsXmlElement().Attributes().Get(pAttributeName, lXmlAttribute) then
            exit(lXmlAttribute.Value());
    end;

    procedure AddDeclaration(var pXMLDocument: XmlDocument; pVersion: Text; pEncoding: Text; pStandalone: Text)
    var
        lXmlDeclaration: XmlDeclaration;
    begin
        lXmlDeclaration := XmlDeclaration.Create(pVersion, pEncoding, pStandalone);
        pXMLDocument.SetDeclaration(lXmlDeclaration);
    end;

    procedure AddGroupNode(var pXMLNode: XmlNode; pNodeName: Text)
    var
        lXMLNewChild: XmlNode;
    begin
        AddElement(pXMLNode, pNodeName, '', '', lXMLNewChild);
        pXMLNode := lXMLNewChild;
    end;

    procedure AddNode(var pXMLNode: XmlNode; pNodeName: Text; pNodeText: Text)
    var
        lXMLNewChild: XmlNode;
    begin
        AddElement(pXMLNode, pNodeName, pNodeText, '', lXMLNewChild);
    end;

    procedure AddLastNode(var pXMLNode: XmlNode; pNodeName: Text; pNodeText: Text)
    var
        lXMLElement: XmlElement;
        lXMLNewChild: XmlNode;
    begin
        AddElement(pXMLNode, pNodeName, pNodeText, '', lXMLNewChild);
        if pXMLNode.GetParent(lXMLElement) then
            pXMLNode := lXMLElement.AsXmlNode();
    end;

    procedure GetXmlNSMgr(pXMLRootNode: XmlNode; pPrefix: Text; pNamespace: Text; var pXmlNsMgr: XmlNamespaceManager): Text
    var
        lXMLDocument: XmlDocument;
    begin

        if pXMLRootNode.IsXmlDocument() then
            pXmlNsMgr.NameTable(pXMLRootNode.AsXmlDocument().NameTable())
        else begin
            pXMLRootNode.GetDocument(lXMLDocument);
            pXmlNsMgr.NameTable(lXMLDocument.NameTable());
        end;
        pXmlNsMgr.AddNamespace(pPrefix, pNamespace);
    end;

    procedure AddNameSpace(var pXmlNsMgr: XmlNamespaceManager; pPrefix: text; pNamespace: text);
    begin
        pXmlNsMgr.AddNamespace(pPrefix, pNamespace);
    end;

    procedure AddNamespaces(var pXmlNsMgr: XmlNamespaceManager; pXMLDocument: XmlDocument)
    var
        lXmlAttribute: XmlAttribute;
        lXmlAttributeCollection: XmlAttributeCollection;
        lXMLElement: XmlElement;
    begin
        pXmlNsMgr.NameTable(pXMLDocument.NameTable());
        pXMLDocument.GetRoot(lXMLElement);
        lXmlAttributeCollection := lXMLElement.Attributes();
        if lXMLElement.NamespaceUri() <> '' then
            pXmlNsMgr.AddNamespace('', lXMLElement.NamespaceUri());
        Foreach lXmlAttribute in lXmlAttributeCollection do
            if StrPos(lXmlAttribute.Name(), 'xmlns:') = 1 then
                pXmlNsMgr.AddNamespace(DELSTR(lXmlAttribute.Name(), 1, 6), lXmlAttribute.Value());
    end;

    procedure XMLEscape(pXMLText: Text): Text
    var
        lNewXmlNode: XmlNode;
    begin
        lNewXmlNode := XmlElement.Create('XMLEscape', '', pXMLText).AsXmlNode();
        exit(lNewXmlNode.AsXmlElement().InnerXml());
    end;

    procedure LoadXMLNodeFromText(pXMLText: Text; var pXMLRootNode: XmlNode)
    var
        lXmlDocument: XmlDocument;
    begin
        LoadXMLDocumentFromText(pXMLText, lXmlDocument);
        pXMLRootNode := lXmlDocument.AsXmlNode();
    end;

    procedure GetRootNode2(pXMLDocument: XmlDocument; var pXMLRootNode: XmlNode)
    Var
        NodeList: XmlNodeList;
    Begin
        NodeList := pXMLDocument.GetChildNodes();
        NodeList.get(1, pXMLRootNode);
    End;

    procedure GetRootNode(pXMLDocument: XmlDocument; var pFoundXMLNode: XmlNode): Boolean
    var
        lXmlElement: XmlElement;
    begin
        pXMLDocument.GetRoot(lXmlElement);
        pFoundXMLNode := lXmlElement.AsXmlNode();
    end;
}