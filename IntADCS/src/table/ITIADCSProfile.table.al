table 69050 "ITI ADCS Profile"
{
    Caption = 'ADCS Profile';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Profile ID"; Code[30])
        {
            Caption = 'Profile ID';
            DataClassification = SystemMetadata;
        }
        field(2; Miniform; Code[20])
        {
            Caption = 'Miniform';
            DataClassification = SystemMetadata;
            TableRelation = "ITI Miniform Header" where("Main Menu" = const(true));
        }
    }
    keys
    {
        key(PK; "Profile ID")
        {
            Clustered = true;
        }
    }
}
