codeunit 69116 OnRunEvent
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Conf./Personalization Mgt.", 'OnRoleCenterOpen', '', false, false)]
    local procedure OnRoleCenterOpen();
    begin
        Page.Run(page::ITIADCS);
    end;


    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterInitialization', '', false, false)]
    // local procedure OnAfterInitialization()
    // begin
    //     OpenADCSPage();
    // end;

    [EventSubscriber(ObjectType::Page, Page::"ITI ADCS User RC", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPageEvent()
    begin
        Page.Run(page::ITIADCS);
    end;

}