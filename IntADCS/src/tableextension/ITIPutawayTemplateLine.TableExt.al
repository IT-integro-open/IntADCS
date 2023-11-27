tableextension 69053 "ITI Put-away Template Line" extends "Put-away Template Line"
{
    fields
    {
        field(69050; "ITI Find Default Bin"; Boolean)
        {
            Caption = 'Find Default Bin';
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                IF "ITI Find Default Bin" THEN
                    "ITI Find Additional Bin" := FALSE;
            end;
        }
        field(69051; "ITI Find Additional Bin"; Boolean)
        {
            Caption = 'Find Additional Bin';
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                IF "ITI Find Additional Bin" THEN
                    "ITI Find Default Bin" := FALSE;
            end;
        }
    }
}
