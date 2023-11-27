tableextension 69065 "ITI Warehouse Activity Header" extends "Warehouse Activity Header"
{
    fields
    {
        field(69050; "ITI Pick No. to Whse. Shipment"; Integer)
        {
            Caption = 'Pick No. to Whse. Shipment';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(69051; "ITI No of Picks from Shpt"; Integer)
        {
            Caption = 'No. of Picks from Whse. Shpt.';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(69052; "ITI Whse. Document Type"; Enum "Warehouse Activity Document Type")
        {
            Caption = 'Whse. Document Type';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(69053; "ITI Whse. Document No."; Code[20])
        {
            Caption = 'Whse. Document No.';
            Editable = false;
            TableRelation = IF ("ITI Whse. Document Type" = CONST(Receipt)) "Posted Whse. Receipt Header"."No." WHERE("No." = FIELD("ITI Whse. Document No."))
            ELSE
            IF ("ITI Whse. Document Type" = CONST(Shipment)) "Warehouse Shipment Header"."No." WHERE("No." = FIELD("ITI Whse. Document No."))
            ELSE
            IF ("ITI Whse. Document Type" = CONST("Internal Put-away")) "Whse. Internal Put-away Header"."No." WHERE("No." = FIELD("ITI Whse. Document No."))
            ELSE
            IF ("ITI Whse. Document Type" = CONST("Internal Pick")) "Whse. Internal Pick Header"."No." WHERE("No." = FIELD("ITI Whse. Document No."))
            ELSE
            IF ("ITI Whse. Document Type" = CONST(Production)) "Production Order"."No." WHERE("No." = FIELD("ITI Whse. Document No."))
            ELSE
            IF ("ITI Whse. Document Type" = CONST("Assembly")) "Assembly Header"."No." WHERE("Document Type" = CONST(Order), "No." = FIELD("ITI Whse. Document No."));
            DataClassification = CustomerContent;
        }
    }
}
