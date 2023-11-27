page 69120 ITIADCSItemSearchTemplate
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = ITIADCSItemSearchTemplate;
    AutoSplitKey = true;
    Caption = 'ADCS Item Search Template';
    DelayedInsert = true;
    LinksAllowed = false;
    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Line No. field.';
                    Editable = true;
                    Visible = false;
                }
                field("Item No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Item No. field.';
                    Editable = true;
                }
                field("Item No. by Vendor"; Rec."Vendor Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Item No. by Vendor field.';
                    Editable = true;
                }
                field("Item Identifier No."; Rec."Identifier No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Item Identifier No. field.';
                    Editable = true;
                }
                field("Item Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Item Serial No. field.';
                    Editable = true;
                }
                field("Item Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Item Lot No. field.';
                    Editable = true;
                }
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Package No. field.';
                    Editable = true;
                }
                field("Reference No."; Rec."Reference No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Reference No. field.';
                    Editable = true;
                    trigger OnValidate()
                    begin
                        if Rec."Reference No." then
                            AllowEditReferenceType()
                        else
                            Rec."Reference Type" := Rec."Reference Type"::" ";
                    end;
                }
                field("Reference Type"; Rec."Reference Type")
                {
                    ApplicationArea = All;
                    Editable = ReferenceTypeEditable;
                    ToolTip = 'Specifies the value of the Reference Type field.';
                    trigger OnValidate()
                    begin
                        if not Rec."Reference No." then
                            Rec."Reference Type" := Rec."Reference Type"::" ";
                    end;
                }
            }
        }
    }
    trigger OnModifyRecord(): Boolean
    begin
        if Rec."Reference No." then
            AllowEditReferenceType()
        else
            Rec."Reference Type" := Rec."Reference Type"::" ";
    end;

    trigger OnOpenPage()
    begin
        AllowEditReferenceType();
    end;
    
    local procedure AllowEditReferenceType()
    begin
        ReferenceTypeEditable := true
    end;
    
    var 
        ReferenceTypeEditable: Boolean;
}