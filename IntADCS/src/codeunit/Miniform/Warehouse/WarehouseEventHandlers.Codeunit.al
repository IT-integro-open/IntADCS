codeunit 69130 "Warehouse Event Handlers"
{
 
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ITIADCSItemNoSearch, 'OnBeforeShowMoreThatOneOutputFoundErrByLotNoEvent', '', false, false)]
    local procedure OnBeforeShowMoreThatOneOutputFoundErrByLotNoEvent(var LotNoInformation: Record "Lot No. Information"; var IsHandled: Boolean);
    begin
        LotNoInformation.FindFirst();
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ITIADCSItemNoSearch, 'OnBeforeShowMoreThatOneOutputFoundErrByPackageNoEvent', '', false, false)]
    local procedure OnBeforeShowMoreThatOneOutputFoundErrByPackageNoEvent(var PackageNoInformation: Record "Package No. Information"; var IsHandled: Boolean);
    begin
        PackageNoInformation.FindLast();
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ITIADCSItemNoSearch, 'OnBeforeShowMoreThatOneOutputFoundErrBySerialNoEvent', '', false, false)]
    local procedure OnBeforeShowMoreThatOneOutputFoundErrBySerialNoEvent(var SerialNoInformation: Record "Serial No. Information"; var IsHandled: Boolean);
    begin
        SerialNoInformation.FindFirst();
        IsHandled := true;
    end;

}