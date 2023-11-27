table 69056 "ITI Miniform Header"
{
    Caption = 'Miniform Header';
    DataClassification = CustomerContent;
    DrillDownPageId = "ITI Miniform";
    LookupPageID = "ITI Miniform";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(11; Description; Text[30])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(12; "No. of Records in List"; Integer)
        {
            Caption = 'No. of Records in List';
            DataClassification = CustomerContent;
        }
        field(13; "Form Type"; enum "ITI ADCS Form Type")
        {
            Caption = 'Form Type';
            DataClassification = CustomerContent;
        }
        field(15; "Start Miniform"; Boolean)
        {
            Caption = 'Start Miniform';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                MiniformHeader: Record "ITI Miniform Header";
            begin
                MiniformHeader.SETFILTER(Code, '<>%1', Code);
                MiniformHeader.SETRANGE("Start Miniform", TRUE);
                IF NOT MiniformHeader.IsEmpty() THEN
                    ERROR(OneLoginErr);
            end;
        }
        field(20; "Handling Codeunit"; Integer)
        {
            Caption = 'Handling Codeunit';
            DataClassification = CustomerContent;
            TableRelation = "AllObjWithCaption"."Object ID" WHERE("Object Type" = CONST(Codeunit), "Object Name" = filter('ITI Miniform*'));
        }
        field(21; "Next Miniform"; Code[20])
        {
            Caption = 'Next Miniform';
            DataClassification = CustomerContent;
            TableRelation = "ITI Miniform Header";

            trigger OnValidate()
            begin
                IF "Next Miniform" = Code THEN
                    ERROR(RecursionErr);
                /*
                                IF "Form Type" IN ["Form Type"::"Selection List", "Form Type"::"Data List Input"] THEN
                                    ERROR(NotBeErr, FIELDCAPTION("Form Type"), "Form Type");
                                    */

            end;
        }
        field(25; XMLin; BLOB)
        {
            Caption = 'XMLin';
            DataClassification = CustomerContent;
        }
        field(30; "Hide Blank Lines"; Boolean)
        {
            Caption = 'Hide Blank Lines';
            DataClassification = CustomerContent;
        }
        field(40; "Check Permissions"; Boolean)
        {
            Caption = 'Check Permissions';
            DataClassification = CustomerContent;
        }
        field(50; "Main Menu"; Boolean)
        {
            Caption = 'Main Menu';
            DataClassification = CustomerContent;
        }
        field(100; "No. of Used Miniform"; integer)
        {
            Caption = 'No. of Used Miniform';
            FieldClass = FlowField;
            CalcFormula = count("ITI miniform header" WHERE("Next Miniform" = FIELD(Code)));
        }
        field(101; "No. of Used Next Miniform"; integer)
        {
            Caption = 'No. of Used Next Miniform';
            FieldClass = FlowField;
            CalcFormula = count("ITI miniform line" WHERE("Call Miniform" = FIELD(Code)));
        }
        field(102; "No. of Used Function"; integer)
        {
            Caption = 'No. of Used Function';
            FieldClass = FlowField;
            CalcFormula = count("ITI miniform Function" WHERE("Next Miniform" = FIELD(Code)));
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ITIMiniformFunction: Record "ITI Miniform Function";
        ITIMiniformLine: Record "ITI Miniform Line";
    begin
        ITIMiniformLine.RESET();
        ITIMiniformLine.SETRANGE("Miniform Code", Code);
        ITIMiniformLine.DELETEALL();

        ITIMiniformFunction.RESET();
        ITIMiniformFunction.SETRANGE("Miniform Code", Code);
        ITIMiniformFunction.DELETEALL();
    end;

    var
        OneLoginErr: Label 'There can only be one login form.';
        RecursionErr: Label 'Recursion is not allowed.';



    /// <summary>
    /// SaveXMLinExt.
    /// </summary>
    /// <param name="DOMxmlin">XmlDocument.</param>
    procedure SaveXMLinExt(DOMxmlin: XmlDocument)
    var
        OutStrm: OutStream;
    begin
        XMLin.CREATEOUTSTREAM(OutStrm);
        DOMxmlin.WriteTo(OutStrm);

    end;

    /// <summary>
    /// LoadXMLinExt.
    /// </summary>
    /// <param name="DOMxmlin">VAR XmlDocument.</param>
    procedure LoadXMLinExt(var DOMxmlin: XmlDocument)
    var
        FirstLine: boolean;
        InStrm: InStream;
        ReadLine: text;
        ReadText: text;
    begin
        FirstLine := true;
        XMLin.CreateInStream(InStrm, TextEncoding::UTF8);
        Repeat
            InStrm.ReadText(ReadLine);
            IF not FirstLine then
                ReadText += ReadLine;
            FirstLine := false;
        Until InStrm.EOS;
        XmlDocument.ReadFrom(ReadText, DOMxmlin);
    end;
}

