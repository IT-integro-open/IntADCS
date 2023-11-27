codeunit 69109 "ITI ADCS Item Management"
{
    procedure GetItemNo(SourceItemNo: Code[20]; var InputValue: Text[250]; var ItemNo: Code[20])
    var
        Item: Record Item;
        ItemIdent: Record "Item Identifier";
        IsHandled: Boolean;
    begin
        OnBeforeGetItemNo(SourceItemNo, InputValue, ItemIdent, ItemNo, IsHandled);
        if IsHandled then
            exit;

        if InputValue = '' then
            ItemNo := SourceItemNo
        else
            if ItemIdent.Get(InputValue) then
                ItemNo := ItemIdent."Item No."
            else begin
                Item.Get(InputValue);
                ItemNo := Item."No.";
            end;

        OnAfterGetItemNo(SourceItemNo, InputValue, ItemIdent, ItemNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItemNo(var SourceItemNo: Code[20]; var InputValue: Text[250]; var ItemIdent: Record "Item Identifier"; var ItemNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItemNo(var SourceItemNo: Code[20]; var InputValue: Text[250]; var ItemIdent: Record "Item Identifier"; var ItemNo: Code[20])
    begin
    end;
}
