codeunit 69147 "ITIADCSTableDataConverterImpl"
{
    Access = Internal;

    var
        ITI26DataConverterConstant: Codeunit "ITIADCSDataConverterConstant";
        ParseJSONErr: Label 'Test Data is incorrectly defined. The correct format is defined by the JSON schema: {"type": "object","properties": {"Table ID": {"type": "integer"},"Table Columns": {"type": "array"},"Table Data": {"type": "array","items": [{"type": "object"}]},"required": ["Table ID","Table Columns","Table Data"]}', Locked = true;

    procedure ExportToZip(var TableMetadata: Record "Table Metadata")
    var
        DataCompression: Codeunit "Data Compression";
        ITI26Dialog: Dialog;
        DialogTxt: Label 'Exporting #1#######', Comment = '%1 = Table Caption';
    begin
        if not TableMetadata.FindSet() then
            exit;

        ITI26Dialog.Open(DialogTxt);
        DataCompression.CreateZipArchive();
        repeat
            ITI26Dialog.Update(1, TableMetadata.Caption);
            AddTableDataToZipArchive(TableMetadata, DataCompression);
        until TableMetadata.Next() = 0;

        ITI26Dialog.Close();
        DownloadZipArchive(DataCompression);
    end;

    procedure ImportFromZip(ZipInStream: InStream)
    var
        DataCompression: Codeunit "Data Compression";
        ITI26Dialog: Dialog;
        EntryList: List of [Text];
        DialogTxt: Label 'Importing #1#######', Comment = '%1 = File Name';
        EntryName: Text;
    begin
        DataCompression.OpenZipArchive(ZipInStream, false);
        DataCompression.GetEntryList(EntryList);
        ITI26Dialog.Open(DialogTxt);
        foreach EntryName in EntryList do begin
            ITI26Dialog.Update(1, EntryName);
            ImportTableDataFromZipEntry(DataCompression, EntryName);
        end;
        ITI26Dialog.Close();
    end;

    procedure ConvertToJSON(var RecordRefToConvert: RecordRef): JsonObject
    var
        Field: Record Field;
    begin
        FilterFields(Field, RecordRefToConvert.Number());
        exit(ConvertToJSON(RecordRefToConvert, Field));
    end;

    procedure ConvertToJSON(var RecordRefToConvert: RecordRef; var Field: Record Field) TableJsonObject: JsonObject
    begin
        ErrIfNotInitialized(RecordRefToConvert);
        AddTableID(TableJsonObject, RecordRefToConvert);
        FilterAndAddTableColumns(TableJsonObject, RecordRefToConvert, Field);
        AddTableData(TableJsonObject, RecordRefToConvert, Field);
    end;

    procedure ImportFromJSON(TableJsonObject: JsonObject)
    begin
        ImportFromJSON(TableJsonObject, false);
    end;

    procedure ImportFromJSON(TableJsonObject: JsonObject; ModifyExistingRecords: Boolean)
    var
        ImportTableRecordRef: RecordRef;
        TableColumns: List of [Text];
    begin
        ImportFromJSON(ImportTableRecordRef, false, TableColumns, TableJsonObject, ModifyExistingRecords);
    end;

    procedure ImportFromJSON(var ImportTableRecordRef: RecordRef; IsTemporary: Boolean; var TableColumns: List of [Text]; TableJsonObject: JsonObject; ModifyExistingRecords: Boolean)
    var
        TableID: Integer;
        TableData: JsonArray;
    begin
        if not ParseTableJSON(TableJsonObject, TableID, TableColumns, TableData) then
            Error(ParseJSONErr);

        ImportTableRecordRef.Open(TableID, IsTemporary);
        ImportTableData(ImportTableRecordRef, TableColumns, TableData, ModifyExistingRecords);
    end;

    local procedure AddTableDataToZipArchive(TableMetadata: Record "Table Metadata"; var DataCompression: Codeunit "Data Compression")
    var
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
        TableOutStream: OutStream;
        TableInStream: InStream;
        FileName: Text;
    begin
        RecordRef.Open(TableMetadata.ID);
        TempBlob.CreateOutStream(TableOutStream, GetTextEncoding());
        TableOutStream.Write(Format(ConvertToJSON(RecordRef)));
        TempBlob.CreateInStream(TableInStream, GetTextEncoding());
        FileName := Format(TableMetadata.Name) + '.json';
        DataCompression.AddEntry(TableInStream, FileName);
        RecordRef.Close();
    end;

    local procedure DownloadZipArchive(DataCompression: Codeunit "Data Compression")
    var
        TempBlob: Codeunit "Temp Blob";
        ZipOutStream: OutStream;
        ZipInStream: InStream;
        ZipFileName: Text;
    begin
        ZipFileName := 'Data_' + Format(CurrentDateTime) + '.zip';
        TempBlob.CreateOutStream(ZipOutStream);
        DataCompression.SaveZipArchive(ZipOutStream);
        TempBlob.CreateInStream(ZipInStream);
        DownloadFromStream(ZipInStream, '', '', '', ZipFileName);
    end;

    local procedure ImportTableDataFromZipEntry(DataCompression: Codeunit "Data Compression"; EntryName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        TableOutStream: OutStream;
        TableInStream: InStream;
        Text: Text;
        JsonObject: JsonObject;
        EntryLength: Integer;
    begin
        TempBlob.CreateOutStream(TableOutStream, GetTextEncoding());
        DataCompression.ExtractEntry(EntryName, TableOutStream, EntryLength);
        TempBlob.CreateInStream(TableInStream, GetTextEncoding());
        TableInStream.ReadText(Text);
        JsonObject.ReadFrom(Text);
        ImportFromJSON(JsonObject, true);
    end;

    local procedure GetTextEncoding(): TextEncoding
    begin
        exit(TextEncoding::UTF8);
    end;

    local procedure ErrIfNotInitialized(var RecordRefToConvert: RecordRef)
    var
        RecRefNotInitializedErr: Label 'Record Ref has not been initialized.';
    begin
        if RecordRefToConvert.Number() = 0 then
            Error(RecRefNotInitializedErr);
    end;

    local procedure AddTableID(var TableJsonObject: JsonObject; RecordRefToConvert: RecordRef)
    begin
        TableJsonObject.Add(ITI26DataConverterConstant.TableID(), RecordRefToConvert.Number());
    end;

    local procedure FilterAndAddTableColumns(var TableJsonObject: JsonObject; var RecordRefToConvert: RecordRef; var Field: Record Field)
    var
        TableColumns: JsonArray;
    begin
        FilterTableFieldsAndIncludePrimaryKeys(Field, RecordRefToConvert.Number());
        if Field.FindSet() then
            repeat
                TableColumns.Add(Field.FieldName);
            until Field.Next() = 0;

        TableJsonObject.Add(ITI26DataConverterConstant.TableColumns(), TableColumns);
    end;

    local procedure AddTableData(var TableJsonObject: JsonObject; var RecordRefToConvert: RecordRef; var Field: Record Field)
    var
        TableData: JsonArray;
    begin
        if RecordRefToConvert.FindSet() then
            repeat
                AddTableRow(TableData, RecordRefToConvert, Field)
            until RecordRefToConvert.Next() = 0;
        TableJsonObject.Add(ITI26DataConverterConstant.TableData(), TableData)
    end;

    local procedure AddTableRow(var TableData: JsonArray; var RecordRefToConvert: RecordRef; var Field: Record Field)
    var
        FieldRefToConvert: FieldRef;
        TableRow: JsonObject;
    begin
        if Field.FindSet() then
            repeat
                FieldRefToConvert := RecordRefToConvert.Field(Field."No.");
                if Field.IsPartOfPrimaryKey or HasValue(FieldRefToConvert) then
                    TableRow.Add(Field.FieldName, FormatField(FieldRefToConvert));
            until Field.Next() = 0;
        TableData.Add(TableRow);
    end;

    [TryFunction]
    local procedure ParseTableJSON(TableJsonObject: JsonObject; var TableID: Integer; var TableColumns: List of [Text]; var TableData: JsonArray)
    begin
        ParseTableID(TableJsonObject, TableID);
        ParseTableColumns(TableJsonObject, TableColumns);
        ParseTableData(TableJsonObject, TableData);
    end;

    local procedure ParseTableID(TableJsonObject: JsonObject; var TableID: Integer)
    var
        JSONToken: JsonToken;
    begin
        TableJsonObject.Get(ITI26DataConverterConstant.TableID(), JSONToken);
        TableID := JSONToken.AsValue().AsInteger();
    end;

    local procedure ParseTableColumns(TableJsonObject: JsonObject; var TableColumns: List of [Text])
    var
        JSONToken: JsonToken;
        ColumnToken: JsonToken;
    begin
        TableJsonObject.Get(ITI26DataConverterConstant.TableColumns(), JSONToken);
        foreach ColumnToken in JSONToken.AsArray() do
            TableColumns.Add(ColumnToken.AsValue().AsText());
    end;

    local procedure ParseTableData(TableJsonObject: JsonObject; var TableData: JsonArray)
    var
        JSONToken: JsonToken;
    begin
        TableJsonObject.Get(ITI26DataConverterConstant.TableData(), JSONToken);
        TableData := JSONToken.AsArray();
    end;

    local procedure ImportTableData(var ImportTableRecordRef: RecordRef; TableColumns: List of [Text]; TableData: JsonArray; ModifyExistingRecords: Boolean)
    var
        Field: Record Field;
        TableRecord: JsonToken;
    begin
        if TableData.Count() = 0 then
            exit;

        FilterFields(Field, ImportTableRecordRef.Number(), TableColumns);

        foreach TableRecord in TableData do
            ImportRecord(TableRecord, ImportTableRecordRef, Field, ModifyExistingRecords);
    end;

    local procedure ImportRecord(TableRecord: JsonToken; var ImportTableRecordRef: RecordRef; var Field: Record Field; ModifyExistingRecords: Boolean)
    var
        ImportTableFieldRef: FieldRef;
        FieldValueText: Text;
    begin
        if not Field.FindSet() then
            exit;

        ImportTableRecordRef.Init();
        repeat
            FieldValueText := GetValueAsText(TableRecord.AsObject(), Field.FieldName);
            if (FieldValueText <> '') or (Field.IsPartOfPrimaryKey) then begin
                ImportTableFieldRef := ImportTableRecordRef.Field(Field."No.");
                ParseTextValueToFieldRef(ImportTableFieldRef, FieldValueText);
            end;
        until Field.Next() = 0;

        InsertOrModifyRecord(ImportTableRecordRef, ModifyExistingRecords)
    end;

    local procedure GetValueAsText(JsonObject: JsonObject; "Key": Text) Value: Text
    var
        JsonToken: JsonToken;
    begin
        if not JsonObject.Get("Key", JsonToken) then
            exit;

        Value := JsonToken.AsValue().AsText();
    end;

    local procedure InsertOrModifyRecord(var ImportTableRecordRef: RecordRef; ModifyExistingRecords: Boolean)
    begin
        if ModifyExistingRecords then begin
            if not ImportTableRecordRef.Insert() then
                ImportTableRecordRef.Modify();
        end else
            if ImportTableRecordRef.Insert() then;
    end;


    procedure FilterFields(var Field: Record Field; TableID: Integer)
    begin
        Clear(Field);
        FilterNormalActiveNotSystemFields(Field, TableID);
    end;

    procedure FilterFields(var Field: Record Field; TableID: Integer; TableColumns: List of [Text])
    begin
        Clear(Field);
        FilterTableAndFields(Field, TableID, GetFieldsFilter(TableID, TableColumns));
    end;

    procedure FilterTableFieldsAndIncludePrimaryKeys(var Field: Record Field; TableID: Integer)
    var
        NonPrimaryKeyFilter: Text;
        FilterText: Text;
    begin
        FilterNormalActiveNotSystemFields(Field, TableID);

        FilterText := GetPrimaryKeyFieldsFilter(TableID);

        Field.SetRange(IsPartOfPrimaryKey, false);
        NonPrimaryKeyFilter := GetFieldsFilter(Field);
        if NonPrimaryKeyFilter <> '' then
            FilterText += '|' + NonPrimaryKeyFilter;

        Clear(Field);
        FilterTableAndFields(Field, TableID, FilterText);
    end;

    procedure GetListOfPKFields(TableID: Integer) ListOfPKFields: List of [Text]
    var
        Field: Record Field;
    begin
        FilterTableAndFields(Field, TableID, GetPrimaryKeyFieldsFilter(TableID));
        if Field.FindSet() then
            repeat
                ListOfPKFields.Add(Field.FieldName);
            until Field.Next() = 0;
    end;

    local procedure FilterTableAndFields(var Field: Record Field; TableID: Integer; FieldsFilter: Text)
    begin
        Field.SetRange(TableNo, TableID);
        Field.SetFilter("No.", FieldsFilter);
    end;

    local procedure FilterNormalActiveNotSystemFields(var Field: Record Field; TableID: Integer)
    begin
        Field.SetRange(TableNo, TableID);
        Field.SetRange(Class, Field.Class::Normal);
        Field.SetRange(ObsoleteState, Field.ObsoleteState::No);
        // Skip system fields
        if Field.GetFilter("No.") <> '' then
            Field.SetFilter("No.", Field.GetFilter("No.") + '&<2000000000')
        else
            Field.SetFilter("No.", '<2000000000');
    end;

    local procedure GetPrimaryKeyFieldsFilter(TableID: Integer): Text
    var
        Field: Record Field;
    begin
        Field.SetRange(TableNo, TableID);
        Field.SetRange(IsPartOfPrimaryKey, true);
        exit(GetFieldsFilter(Field));
    end;

    local procedure GetFieldsFilter(var Field: Record Field) FieldsFilter: Text
    begin
        if not Field.FindSet() then
            exit;

        repeat
            FieldsFilter += Format(Field."No.") + '|';
        until Field.Next() = 0;

        FieldsFilter := FieldsFilter.Substring(1, StrLen(FieldsFilter) - 1);
    end;

    local procedure GetFieldsFilter(TableID: Integer; TableColumns: List of [Text]) FieldsFilter: Text
    var
        Field: Record Field;
    begin
        Field.SetRange(TableNo, TableID);
        if not Field.FindSet() then
            exit;

        repeat
            if TableColumns.Contains(Field.FieldName) then
                FieldsFilter += Format(Field."No.") + '|';
        until Field.Next() = 0;

        if FieldsFilter = '' then
            exit;
        FieldsFilter := FieldsFilter.Substring(1, StrLen(FieldsFilter) - 1);
    end;

    procedure HasValue(FieldRef: FieldRef): Boolean
    var
        BigInt: BigInteger;
        BooleanHasValue: Boolean;
        Int: Integer;
        Dec: Decimal;
        D: Date;
        T: Time;
    begin
        case FieldRef.Type() of
            FieldType::BigInteger:
                begin
                    BigInt := FieldRef.Value();
                    BooleanHasValue := BigInt <> 0;
                end;
            FieldType::Boolean:
                BooleanHasValue := FieldRef.Value();
            FieldType::Date:
                begin
                    D := FieldRef.Value();
                    BooleanHasValue := D <> 0D;
                end;
            FieldType::Decimal:
                begin
                    Dec := FieldRef.Value();
                    BooleanHasValue := Dec <> 0;
                end;
            FieldType::Integer:
                begin
                    Int := FieldRef.Value();
                    BooleanHasValue := Int <> 0;
                end;
            FieldType::Time:
                begin
                    T := FieldRef.Value();
                    BooleanHasValue := T <> 0T;
                end;
            FieldType::BLOB, FieldType::Media, FieldType::MediaSet, FieldType::Option:
                BooleanHasValue := true;
            else
                //code, text etc.
                BooleanHasValue := Format(FieldRef.Value()) <> '';
        end;
        exit(BooleanHasValue);
    end;

    procedure ParseTextValueToFieldRef(var FieldRef: FieldRef; FieldValueText: Text)
    var
        ConfigMediaBuffer: Record "Config. Media Buffer";
        TempBlob: Codeunit "Temp Blob";
        DateFormulaValue: DateFormula;
        RecordIdValue: RecordId;
        BigIntegerValue: BigInteger;
        DecimalValue: Decimal;
        GuidValue: Guid;
        DateValue: Date;
        DateTimeValue: DateTime;
        TimeValue: Time;
        OptionValue: Option;
        BooleanValue: Boolean;
        IntegerValue: Integer;
        DurationValue: Duration;
    begin
        case FieldRef.Type() of
            FieldType::BigInteger:
                begin
                    Evaluate(BigIntegerValue, FieldValueText, 9);
                    FieldRef.Value := BigIntegerValue;
                end;
            FieldType::Blob:
                begin
                    BlobFromBase64(TempBlob, FieldValueText);
                    TempBlob.ToFieldRef(FieldRef);
                end;
            FieldType::Boolean:
                begin
                    Evaluate(BooleanValue, FieldValueText, 9);
                    FieldRef.Value := BooleanValue;
                end;
            FieldType::Decimal:
                begin
                    Evaluate(DecimalValue, FieldValueText, 9);
                    FieldRef.Value := DecimalValue;
                end;
            FieldType::Date:
                begin
                    Evaluate(DateValue, FieldValueText, 9);
                    FieldRef.Value := DateValue;
                end;
            FieldType::DateFormula:
                begin
                    Evaluate(DateFormulaValue, FieldValueText, 9);
                    FieldRef.Value := DateFormulaValue;
                end;
            FieldType::DateTime:
                begin
                    Evaluate(DatetimeValue, FieldValueText, 9);
                    FieldRef.Value := DatetimeValue;
                end;
            FieldType::Duration:
                begin
                    Evaluate(DurationValue, FieldValueText, 9);
                    FieldRef.Value := DurationValue;
                end;
            FieldType::Guid:
                begin
                    Evaluate(GuidValue, FieldValueText, 9);
                    FieldRef.Value := GuidValue;
                end;
            FieldType::Integer:
                begin
                    Evaluate(IntegerValue, FieldValueText, 9);
                    FieldRef.Value := IntegerValue;
                end;
            FieldType::Media:
                begin
                    MediaFromBase64(ConfigMediaBuffer, FieldValueText);
                    FieldRef.Value := Format(ConfigMediaBuffer.Media);
                end;
            FieldType::MediaSet:
                begin
                    MediaSetFromBase64(ConfigMediaBuffer, FieldValueText);
                    FieldRef.Value := Format(ConfigMediaBuffer."Media Set");
                end;
            FieldType::RecordId:
                begin
                    Evaluate(RecordIdValue, FieldValueText, 9);
                    FieldRef.Value := RecordIdValue;
                end;
            FieldType::Time:
                begin
                    Evaluate(TimeValue, FieldValueText, 9);
                    FieldRef.Value := TimeValue;
                end;
            FieldType::Option:
                begin
                    Evaluate(OptionValue, FieldValueText, 9);
                    FieldRef.Value := OptionValue;
                end;
            FieldType::Code, FieldType::TableFilter, FieldType::Text:
                FieldRef.Value := FieldValueText;
        end;
    end;

    procedure FormatField(FieldRef: FieldRef): Text
    begin
        if not (FieldRef.Type() in [FieldRef.Type::Blob, FieldRef.Type::Media, FieldRef.Type::MediaSet]) then
            exit(Format(FieldRef.Value(), 0, 9));

        exit(ToBase64(FieldRef))
    end;

    local procedure ToBase64(var FieldRef: FieldRef): Text
    begin
        case FieldRef.Type() of
            FieldType::Blob:
                exit(BlobToBase64(FieldRef));
            FieldType::Media:
                exit(MediaToBase64(FieldRef));
            FieldType::MediaSet:
                exit(MediaSetToBase64(FieldRef));
        end;
    end;

    local procedure BlobToBase64(var FieldRef: FieldRef): Text
    var
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        InStream: InStream;
    begin
        TempBlob.FromFieldRef(FieldRef);
        if not TempBlob.HasValue() then
            exit;

        TempBlob.CreateInStream(InStream);
        exit(Base64Convert.ToBase64(InStream));
    end;

    local procedure MediaToBase64(var FieldRef: FieldRef): Text
    var
        TempConfigMediaBuffer: Record "Config. Media Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        MediaOutStream: OutStream;
        InStream: InStream;
    begin
        TempConfigMediaBuffer.Init();
        TempConfigMediaBuffer.Media := FieldRef.Value();
        TempConfigMediaBuffer.Insert();

        TempBlob.CreateOutStream(MediaOutStream);
        if TempConfigMediaBuffer.Media.ExportStream(MediaOutStream) then begin
            TempBlob.CreateInStream(InStream);
            exit(Base64Convert.ToBase64(InStream));
        end;
    end;

    local procedure MediaSetToBase64(var FieldRef: FieldRef): Text
    var
        TempConfigMediaBuffer: Record "Config. Media Buffer" temporary;
        TenantMedia: Record "Tenant Media";
        ListOfMedia: List of [Text];
        NoOfFiles: Integer;
        i: Integer;
    begin
        TempConfigMediaBuffer.Init();
        TempConfigMediaBuffer."Media Set" := FieldRef.Value();
        TempConfigMediaBuffer.Insert();
        NoOfFiles := TempConfigMediaBuffer."Media Set".Count();
        if NoOfFiles > 0 then
            for i := 1 to NoOfFiles do begin
                TenantMedia.Get(TempConfigMediaBuffer."Media Set".Item(i));
                ListOfMedia.Add(BlobToBase64(TenantMedia));
            end;
        exit(ListOfTextToString(ListOfMedia));
    end;

    local procedure BlobToBase64(var TenantMedia: Record "Tenant Media"): Text
    var
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        InStream: InStream;
    begin
        TempBlob.FromRecord(TenantMedia, TenantMedia.FieldNo(Content));

        if TempBlob.HasValue() then begin
            TempBlob.CreateInStream(InStream);
            exit(Base64Convert.ToBase64(InStream));
        end;
    end;

    local procedure ListOfTextToString(List: List of [Text]) ListAsText: Text
    var
        Text: Text;
    begin
        if List.Count() = 0 then
            exit;

        foreach Text in List do
            ListAsText += Text + ',';

        ListAsText := ListAsText.Substring(1, StrLen(ListAsText) - 1);
    end;

    local procedure BlobFromBase64(var TempBlob: Codeunit "Temp Blob"; BlobValue: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(BlobValue, OutStream);
    end;

    local procedure MediaFromBase64(var ConfigMediaBuffer: Record "Config. Media Buffer"; MediaValue: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        MediaInStream: InStream;
        MediaOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(MediaOutStream);
        Base64Convert.FromBase64(MediaValue, MediaOutStream);

        if not TempBlob.HasValue() then
            exit;

        TempBlob.CreateInStream(MediaInStream);
        ConfigMediaBuffer.Init();
        ConfigMediaBuffer.Media.ImportStream(MediaInStream, '');
    end;

    local procedure MediaSetFromBase64(var ConfigMediaBuffer: Record "Config. Media Buffer"; MediaSetValue: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        ListOfMedia: List Of [Text];
        MediaSetInStream: InStream;
        MediaSetOutStream: OutStream;
        i: Integer;
    begin
        ListOfMedia := MediaSetValue.Split(',');
        if ListOfMedia.Count() = 0 then
            exit;

        ConfigMediaBuffer.Init();
        for i := 1 to ListOfMedia.Count() do begin
            TempBlob.CreateOutStream(MediaSetOutStream);
            Base64Convert.FromBase64(ListOfMedia.Get(i), MediaSetOutStream);
            if TempBlob.HasValue() then begin
                TempBlob.CreateInStream(MediaSetInStream);
                ConfigMediaBuffer."Media Set".ImportStream(MediaSetInStream, '');
            end;
        end;
    end;
}