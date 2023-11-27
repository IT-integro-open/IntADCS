codeunit 69072 "ITI Bin Code Event Handler"
{
    [EventSubscriber(ObjectType::Table, Database::Bin, 'OnBeforeValidateEvent', 'Code', true, true)]
    local procedure OnAfterValidateEvent(var Rec: Record Bin; var xRec: Record Bin)
    var
        ResultString: Code[20];
        ReturnFromFunction: Text[1];
        CurrentCharacter: Text[1];
        Iteration: Integer;
    begin
        for Iteration := 1 to StrLen(Rec.Code) do begin
            CurrentCharacter := LowerCase(CopyStr(Rec.Code, Iteration, 1));
            ReturnNewCharacter(CurrentCharacter);
            ResultString += CurrentCharacter;
        end;
        Rec.Code := ResultString;
    end;

    local procedure ReturnNewCharacter(var CurrentCharacter: Text[1]): Text[1]
    var
        PolishLbl1: Label 'ą';
        PolishLbl2: Label 'ć';
        PolishLbl3: Label 'ę';
        PolishLbl4: Label 'ł';
        PolishLbl5: Label 'ń';
        PolishLbl6: Label 'ó';
        PolishLbl7: Label 'ź';
        PolishLbl8: Label 'ż';
        albl: Label 'a';
        clbl: Label 'c';
        elbl: Label 'e';
        llbl: Label 'l';
        nlbl: Label 'n';
        olbl: Label 'o';
        zlbl: Label 'z';
    begin
        case CurrentCharacter of
            PolishLbl1:
                CurrentCharacter := albl;
            PolishLbl2:
                CurrentCharacter := clbl;
            PolishLbl3:
                CurrentCharacter := elbl;
            PolishLbl4:
                CurrentCharacter := llbl;
            PolishLbl5:
                CurrentCharacter := nlbl;
            PolishLbl6:
                CurrentCharacter := olbl;
            PolishLbl7:
                CurrentCharacter := zlbl;
            PolishLbl8:
                CurrentCharacter := zlbl;
        end;
    end;
}