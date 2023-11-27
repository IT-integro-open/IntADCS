tableextension 69062 "ITI Warehouse Setup" extends "Warehouse Setup"
{
    fields
    {
        field(69050; "ITI Lot Nos."; Code[10])
        {
            Caption = 'Lot Nos.';

            TableRelation = "No. Series";
            DataClassification = CustomerContent;
        }
        field(69060; "ITI Whse. Ship. Lines to Pick"; Integer)
        {
            Caption = 'Whse. Shipment Lines to Pick';
            DataClassification = CustomerContent;

        }
        field(69070; "ITI Use Packaging"; Boolean)
        {
            Caption = 'Use Packaging';
            DataClassification = CustomerContent;

        }
        field(69080; "ITI Posting Date as Today"; Boolean)
        {
            Caption = 'Posting Date as Today';
            DataClassification = CustomerContent;

        }
    }
}
