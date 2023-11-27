codeunit 90001 "ITI ADCS Test Library"
{
    procedure Initialize()
    begin
        CreateADCSSetup();
        CreateWarehouseEmplyee();
    end;

    procedure CreateADCSSetup()
    var
        ITIADCSSetup: Record "ITI ADCS Setup";
    begin
        ITIADCSSetup.Init();
        ITIADCSSetup.Insert(true);
    end;

    procedure CreateLocation(): Text
    var
        Location: Record Location;
    begin
        Location.Init();
        Location.Code := 'TEST';
        Location.Insert();
        exit('TEST');
    end;

    local procedure CreateADCSUser(): Text
    var
        ADCSUser: Record "ITI ADCS User";
    begin
        ADCSUser.Init();
        ADCSUser.Name := 'ADMIN';
        ADCSUser.Password := ADCSUser.CalculatePassword('admin');
        ADCSUser.Insert();
        exit('ADMIN');
    end;

    procedure CreateWarehouseEmplyee()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.Init();
        WarehouseEmployee."User ID" := UserId;
        WarehouseEmployee."Location Code" := CreateLocation();
        WarehouseEmployee."ITI ADCS User" := CreateADCSUser();
        WarehouseEmployee.Insert();
    end;
}