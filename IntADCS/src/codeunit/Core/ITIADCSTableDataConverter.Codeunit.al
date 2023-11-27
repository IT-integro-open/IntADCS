codeunit 69145 "ITIADCSTableDataConverter"
{
    Access = Public;

    var
        ITI25TableDataConverterImpl: Codeunit ITIADCSTableDataConverterImpl;

    /// <summary>
    /// Exports table data to a zip file and downloads it. Each file in the archive is a JSON with table data.
    /// </summary>
    /// <param name="TableMetadata">The list of tables whose data will be exported.</param>
    procedure ExportToZip(var TableMetadata: Record "Table Metadata")
    begin
        ITI25TableDataConverterImpl.ExportToZip(TableMetadata);
    end;

    /// <summary>
    /// Imports table data from a zip file represented by the <paramref name="ZipInStream"/> variable.  Each file in the archive should be a JSON file with table data.
    /// </summary>
    /// <param name="ZipInStream">The input stream containing the zip file data.</param>
    procedure ImportFromZip(ZipInStream: InStream)
    begin
        ITI25TableDataConverterImpl.ImportFromZip(ZipInStream);
    end;

    /// <summary>
    /// Converts a <paramref name="RecordRefToConvert"/> with assigned filters to JSON format.
    /// </summary>
    /// <param name="RecordRefToConvert">The RecordRef with assigned filters to convert to JSON.</param>
    /// <returns>The converted JSON object.</returns>
    procedure ConvertToJSON(var RecordRefToConvert: RecordRef): JsonObject
    begin
        exit(ITI25TableDataConverterImpl.ConvertToJSON(RecordRefToConvert));
    end;

    /// <summary>
    /// Converts a <paramref name="RecordRefToConvert"/> with assigned filters to JSON format. Only the fields filtered in <paramref name="Field"/> and primary key fields will be included.
    /// </summary>
    /// <param name="RecordRefToConvert">The RecordRef to convert to JSON.</param>
    /// <param name="Field">The Record Field with filtered fields to be converted.</param>
    /// <returns>The converted table data as a JSON object.</returns>
    procedure ConvertToJSON(var RecordRefToConvert: RecordRef; var Field: Record Field): JsonObject
    begin
        exit(ITI25TableDataConverterImpl.ConvertToJSON(RecordRefToConvert, Field));
    end;

    /// <summary>
    /// Imports table data based on the specified <paramref name="TableJsonObject"/>. The JsonObject must be created in a specific format. If the <paramref name="TableJsonObject"/> is not defined properly, an error occurs.
    /// </summary>
    /// <remarks> If the record already exists in the database, it will not be overwritten, and an error will occur if an insertion is attempted.</remarks>
    /// <param name="TableJsonObject">The JSON object containing the table data.</param>
    procedure ImportFromJSON(TableJsonObject: JsonObject)
    begin
        ITI25TableDataConverterImpl.ImportFromJSON(TableJsonObject);
    end;

    /// <summary>
    /// Imports table data based on the specified <paramref name="TableJsonObject"/>, with an option to modify existing records. The JsonObject must be created in a specific format. If the <paramref name="TableJsonObject"/> is not defined properly, an error occurs.
    /// </summary>
    /// <remarks>If the record already exists in the database and <paramref name="ModifyExistingRecords"/> is set to false, an error will occur if an insertion is attempted.</remarks>
    /// <param name="TableJsonObject">The JSON object containing the table data.</param>
    /// <param name="ModifyExistingRecords">True to modify existing records, false otherwise.</param>
    procedure ImportFromJSON(TableJsonObject: JsonObject; ModifyExistingRecords: Boolean)
    begin
        ITI25TableDataConverterImpl.ImportFromJSON(TableJsonObject, ModifyExistingRecords);
    end;

    /// <summary>
    /// Imports table data based on the specified <paramref name="TableJsonObject"/>, with an option to modify existing records. The JsonObject must be created in a specific format. If the <paramref name="TableJsonObject"/> is not defined properly, an error occurs. The imported records will be stored in the <paramref name="ImportTableRecordRef"/> reference after the process.
    /// </summary>
    /// <remarks>If the record already exists in the database and <paramref name="ModifyExistingRecords"/> is set to false, an error will occur if an insertion is attempted.</remarks>
    /// <param name="ImportTableRecordRef">Reference to a RecordRef that will store the imported records.</param>
    /// <param name="IsTemporary">Specifies if the <paramref name="ImportTableRecordRef"/> is a temporary record.</param>
    /// <param name="TableColumns">Reference to the list of columns defined id <paramref name="TableJsonObject"/>.</param>
    /// <param name="TableJsonObject">The JSON object containing the table data.</param>
    /// <param name="ModifyExistingRecords">True to modify existing records, false otherwise.</param>
    procedure ImportFromJSON(var ImportTableRecordRef: RecordRef; IsTemporary: Boolean; TableColumns: List of [Text]; TableJsonObject: JsonObject; ModifyExistingRecords: Boolean)
    begin
        ITI25TableDataConverterImpl.ImportFromJSON(ImportTableRecordRef, IsTemporary, TableColumns, TableJsonObject, ModifyExistingRecords);
    end;
}