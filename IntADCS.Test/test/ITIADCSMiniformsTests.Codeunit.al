codeunit 90000 "ITI ADCS Miniforms Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure LoginMiniformTest()
    var
        ITIADCSSetup: Codeunit "ITI ADCS Assisted Setup";
        ITIADCSController: Codeunit "ITI ADCS Controller";
    begin
        //[Scenario] User wants to login to ADCS with proper username and password
        //[Given] User Setup, Warehouse Employee, ADCS Setup, FunMapping, Miniforms
        ITIADCSSetup.GenerateData();
        ITIADCSTestLibrary.Initialize();
        Commit();

        //[THEN] Start ADCS 
        ITIADCSController.StartADCS();

        //[AND] Propeper user login was given to input.
        ITIADCSController.NextADCSPage('admin');

        //[AND] Propeper user password was given to input.
        ITIADCSController.NextADCSPage('admin');

        // [Then] Mainmenu should appear 
        ITIADCSController.CheckCurrPage('MAINMENU');
    end;


    var
        ITIADCSTestLibrary: Codeunit "ITI ADCS Test Library";
}