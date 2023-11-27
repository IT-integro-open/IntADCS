pageextension 69068 "ITI ADCS Warehouse Shipment" extends "Warehouse Shipment"
{
    layout
    {
        addafter("Location Code")
        {
            field(ITIDestinationType; Rec."ITI Destination Type")
            {
                ApplicationArea = All;
            }
            field(ITIDestinationNo; Rec."ITI Destination No.")
            {
                ApplicationArea = All;
            }
            field(ITIDestinationName; Rec."ITI Destination Name")
            {
                ApplicationArea = All;
            }
            field(ITIDestinationName2; Rec."ITI Destination Name 2")
            {
                ApplicationArea = All;
            }
            field(ITIPackageStatus; Rec."ITI Package Status")
            {
                ApplicationArea = All;
            }
            field(ITIPackageTrackingNo; Rec."ITI Package Tracking No.")
            {
                ApplicationArea = All;
            }
        }
    }
}
