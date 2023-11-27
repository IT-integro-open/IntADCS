codeunit 69118 "ITI ADCS Assisted Setup"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterAssistedSetup', '', false, false)]
    local procedure OnRegisterAssistedSetup();
    var
        AssistedSetup: Codeunit "Guided Experience";
        GuidedExpirienceType: Enum "Guided Experience Type";
        AssistedSetupGroup: Enum "Assisted Setup Group";
    begin
        if not AssistedSetup.Exists(GuidedExpirienceType::"Assisted Setup", ObjectType::Page, Page::"ITI ADCS Data Wizard") then
            AssistedSetup.InsertAssistedSetup(
                'Generate Data Package',
                'Generate Data Pcg.',
                'Start using ADCS with default miniforms.',
                5,
                ObjectType::Page,
                Page::"ITI ADCS Data Wizard",
                AssistedSetupGroup::"ITI ADCS",
                '',
                "Video Category"::Uncategorized,
                ''
            );
    end;

    procedure GenerateData()
    var
        ITIADCSTableDataConverter: Codeunit "ITIADCSTableDataConverter";
        ITIADCSDemoData: Codeunit "ITI ADCS Data";
    begin
        ITIADCSTableDataConverter.ImportFromJSON(ITIADCSDemoData.GetConfigFieldMapAsJSON(), false);
        ITIADCSTableDataConverter.ImportFromJSON(ITIADCSDemoData.GetConfigLineAsJSON(), false);
        ITIADCSTableDataConverter.ImportFromJSON(ITIADCSDemoData.GetConfigPackageFilterAsJSON(), false);
        ITIADCSTableDataConverter.ImportFromJSON(ITIADCSDemoData.GetConfigQuestionAreaAsJSON(), false);
        ITIADCSTableDataConverter.ImportFromJSON(ITIADCSDemoData.GetConfigQuestionAsJSON(), false);
        ITIADCSTableDataConverter.ImportFromJSON(ITIADCSDemoData.GetConfigQuestionnaireAsJSON(), false);
        ITIADCSTableDataConverter.ImportFromJSON(ITIADCSDemoData.GetConfigTableProcessingRuleAsJSON(), false);
        ITIADCSTableDataConverter.ImportFromJSON(ITIADCSDemoData.GetConfigTemplateHeaderAsJSON(), false);
        ITIADCSTableDataConverter.ImportFromJSON(ITIADCSDemoData.GetMiniformFunctionGroupAsJSON(), false);
        ITIADCSTableDataConverter.ImportFromJSON(ITIADCSDemoData.GetConfigTemplateLineAsJSON(), false);
        ITIADCSTableDataConverter.ImportFromJSON(ITIADCSDemoData.GetConfigTmplSelectionRulesAsJSON(), false);
        ITIADCSTableDataConverter.ImportFromJSON(ITIADCSDemoData.GetMiniformFunctionAsJSON(), false);
        ITIADCSTableDataConverter.ImportFromJSON(ITIADCSDemoData.GetMiniformHeaderAsJSON(), false);
        ITIADCSTableDataConverter.ImportFromJSON(ITIADCSDemoData.GetMiniformLineAsJSON(), false);
    end;
}