page 69091 "ITI ADCS Data Wizard"
{
    PageType = NavigatePage;
    Caption = 'Generate ADCS Data Package';
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(FinishedBanner)
            {
                ShowCaption = false;
                Editable = false;
                Visible = (CurrentStep = 1);
                field(MediaResourcesDone; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Step1)
            {
                Visible = (CurrentStep = 1);
                group(WelcomeTo)
                {
                    Caption = 'Welcome to ADCS Data Package generator.';
                    group(WelcomeToSubGroup)
                    {
                        ShowCaption = false;
                        InstructionalText = 'During this wizard, you will generate ADCS Data Package. ';
                    }
                }
                group(FinishPrompt)
                {
                    ShowCaption = false;
                    group(GoFinish)
                    {
                        Visible = true;
                        Caption = 'Choose Finish';
                        InstructionalText = 'Choose Finish to generate ADCS Data.';
                    }

                }
            }
        }
    }
    actions
    {
        area(processing)
        {
            action(ActionFinish)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finish';
                Enabled = (CurrentStep = 1);
                Image = NextRecord;
                InFooterBar = true;
                trigger OnAction();
                begin
                    Finish();
                end;
            }
        }

    }

    trigger OnInit();
    begin
        LoadBanners();
    end;

    trigger OnOpenPage();
    begin
        CurrentStep := 1;
    end;

    var
        MediaResourcesDone: Record "Media Resources";
        CurrentStep: Integer;

    local procedure LoadBanners()
    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
    begin
        if not (MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(CurrentClientType())) and MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(CurrentClientType()))) then
            exit;

        if MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref") then;
    end;

    local procedure Finish()
    begin
        GenerateDemonstrationalConfiguration();
        CurrPage.Close();
    end;

    local procedure GenerateDemonstrationalConfiguration()
    var
        ITIADCSAssistedSetup: Codeunit "ITI ADCS Assisted Setup";
        ConfirmDemoConfLbl: Label 'Do you want to import ADCS data.';
    begin
        if Dialog.Confirm(ConfirmDemoConfLbl) then begin
            ITIADCSAssistedSetup.GenerateData();
            Message('ADCS data generated.');
        end;
    end;

}