codeunit 69115 "ITI ADCS Fun. Mapping"
{
    procedure CreateHtmlPage(MiniformCode: Text; FunctionCode: Text): Text
    var
        Content: TextBuilder;
    begin
        Content.AppendLine('<div class="ADCS-Container">');
        Content.AppendLine(StrSubstNo(PageHeaderLbl, StrSubstNo(PageHeaderContentLbl, FunctionCode, MiniformCode)));
        Content.AppendLine('<br>');
        Content.AppendLine('<input class="ADCS-Input" id = "ADCSKeyInput" placeholder="Key" value="' + GetCurrentFunKey(MiniformCode, FunctionCode) + '" onfocus="setFunKey()"/>');
        Content.AppendLine('<button id="ADCSButton" onclick="SaveMapping()" class="ADCS-NextButton" type="button">' + SaveLbl + '</button>');
        Content.AppendLine('</div>');
        exit(Format(Content))
    end;

    procedure SaveKeyMapping(MiniformCode: Text; FunctionCode: Text; KeyValue: Text)
    var
        ITIMiniformFunction: Record "ITI Miniform Function";
    begin
        ITIMiniformFunction.SetRange("Miniform Code", MiniformCode);
        ITIMiniformFunction.SetRange("Keyboard Key", KeyValue);
        if (not ITIMiniformFunction.IsEmpty()) and (KeyValue <> '') then
            Error(KeyIsInUseErrorLbl, KeyValue);
        ITIMiniformFunction.Get(MiniformCode, FunctionCode);
        ITIMiniformFunction."Keyboard Key" := KeyValue;
        ITIMiniformFunction.Modify();
    end;

    local procedure GetCurrentFunKey(MiniformCode: Text; FunctionCode: Text): Text
    var
        ITIMiniformFunction: Record "ITI Miniform Function";
    begin
        ITIMiniformFunction.Get(MiniformCode, FunctionCode);
        exit(ITIMiniformFunction."Keyboard Key");
    end;


    var
        PageHeaderLbl: Label '<span class="ADCS-FormHeader-Text">%1</span><br>', Locked = true;
        SaveLbl: Label 'Save';
        PageHeaderContentLbl: Label 'Assign key for function <strong>%1</strong> on <strong>%2</strong> page.', Comment = '%1=function Name; %2=Miniform Name';
        KeyIsInUseErrorLbl: Label 'Key %1 is in used by other function on this miniform. Use other keyboard key.', Comment = '%1=Selected key';
}