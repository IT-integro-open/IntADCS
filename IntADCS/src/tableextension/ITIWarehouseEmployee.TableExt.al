tableextension 69050 "ITI Warehouse Employee" extends "Warehouse Employee"
{
    fields
    {
        field(50050; "ITI ADCS User"; Code[20])
        {
            Caption = 'ADCS User';
            DataClassification = CustomerContent;
            TableRelation = "ITI ADCS User";

        }
    }
}
