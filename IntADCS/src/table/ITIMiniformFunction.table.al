table 69054 "ITI Miniform Function"
{
    Caption = 'Miniform Function';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Miniform Code"; Code[20])
        {
            Caption = 'Miniform Code';
            DataClassification = CustomerContent;
            TableRelation = "ITI Miniform Header".Code;
        }
        field(2; "Function Code"; Code[20])
        {
            Caption = 'Function Code';
            DataClassification = CustomerContent;
            TableRelation = "ITI Miniform Function Group".Code;
        }
        field(4; "Next Miniform"; Code[20])
        {
            Caption = 'Next Miniform';
            DataClassification = CustomerContent;
            TableRelation = "ITI Miniform header";
        }
        field(10; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Report));

            trigger OnValidate()
            begin
                CalcFields("Report Caption");

            end;
        }
        field(11; "Report Caption"; Text[250])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Report),
                                                                           "Object ID" = FIELD("Report ID")));
            Caption = 'Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Function Caption"; Text[20])
        {
            Caption = 'Function Caption';
            DataClassification = CustomerContent;
        }
        field(30; "Keyboard Key"; Text[20])
        {
            Caption = 'Keyboard Key';
            DataClassification = CustomerContent;
        }
        field(40; Promoted; Boolean)
        {
            Caption = 'Promoted';
            DataClassification = CustomerContent;
            trigger OnValidate()
            var
                ITIKeyDef: Enum "ITI KeyDef";
            begin
                if Rec."Function Code" = Format(ITIKeyDef::Input).ToUpper() then
                    Error(InputErrLbl);
            end;
        }
    }

    keys
    {
        key(Key1; "Miniform Code", "Function Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
    var
        InputErrLbl: Label 'Input can not be set as promoted.';
}

