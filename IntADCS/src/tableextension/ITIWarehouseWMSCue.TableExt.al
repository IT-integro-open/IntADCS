tableextension 69063 "ITI Warehouse WMS Cue" extends "Warehouse WMS Cue"
{
    fields
    {
        field(69050; "Packed Shipments - Today"; Integer)
        {
            CalcFormula = Count("Warehouse Shipment Header" WHERE("Shipment Date" = FIELD("Date Filter"),
                                                                   "Location Code" = FIELD("Location Filter"),
                                                                   "Document Status" = FILTER("Partially Picked" | "Completely Picked"),
                                                                   "ITI Package Status" = FILTER("Partially Packed" | "Completely Packed")));
            Caption = 'Packed Shipments - Today';
            Editable = false;
            FieldClass = FlowField;
        }
    }
}
