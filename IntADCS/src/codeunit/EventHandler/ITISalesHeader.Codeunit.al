codeunit 69081 "ITI Sales Header"
{
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnBeforeUpdateSalesLines, '', false, false)]
    local procedure OnBeforeUpdateSalesLines(ChangedFieldName: Text[100]; var AskQuestion: Boolean; var SalesHeader: Record "Sales Header")
    begin
        AskQuestion := NOT SalesHeader.GetHideValidationDialog();
    end;
}
