tableextension 69066 "ITI Warehouse Journal Line" extends "Warehouse Journal Line"
{
    fields
    {
        field(69050; "ITI EAN"; Code[20])
        {
            CalcFormula = Lookup(Item."ITI EAN" WHERE ("No."=FIELD("Item No.")));
            Caption = 'EAN Code';
            Editable = false;
            FieldClass = FlowField;
        }
    }
}
