codeunit 69091 "ITI Barcode Mgt"
{
    trigger OnRun()
    begin
    end;

    var
        bxtBarcodeBinary: BigText;
        txcErrorLengthErr: Label 'Value to encode should be %1 digits.', Comment = '%1 - expected length';
        txcErrorNumberErr: Label 'Only numbers allowed.';
        txcErrorSizeErr: Label 'Valid values for the barcode size are 1, 2, 3, 4 & 5';

    procedure EncodeEAN13(pcodBarcode: Code[250]; pintSize: Integer; pblnVertical: Boolean; var TenantMedia: Record "Tenant Media" temporary)
    var
        lcodBarInclCheckD: Code[13];
        lintBars: Integer;
        lintCheckDigit: Integer;
        lintCoding: Integer;
        lintCount: Integer;
        lintLines: Integer;
        lintNumber: Integer;
        loutBmpHeaderOutStream: OutStream;
        ltxtSentinel: Text[3];
        ltxtCenterGuard: Text[6];
        ltxtParEnc: array[10] of Text[6];
        ltxtSetEnc: array[10, 10] of Text[7];
        ltxtWeight: Text[12];
        ltxtBarcode: Text[30];
    begin
        Clear(bxtBarcodeBinary);
        Clear(TenantMedia);
        ltxtSentinel := '101';
        ltxtCenterGuard := '01010';
        ltxtWeight := '131313131313';

        if Strlen(pcodBarcode) <> 12 then
            Error(txcErrorLengthErr, 12);

        if not (pintSize IN [1, 2, 3, 4, 5]) then
            Error(txcErrorSizeErr);

        for lintCount := 1 to Strlen(pcodBarcode) do
            if not (pcodBarcode[lintCount] IN ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']) then
                Error(txcErrorNumberErr);

        InitEAN813(ltxtParEnc, ltxtSetEnc);

        //CALCULATE CHECKDIGIT
        lintCheckDigit := STRCHECKSUM(pcodBarcode, ltxtWeight, 10);

        //PAYLOAD to ENCODE
        lcodBarInclCheckD := COPYSTR(pcodBarcode, 2, Strlen(pcodBarcode)) + Format(lintCheckDigit);

        //EAN PARITY ENCODING TABLE
        Evaluate(lintCoding, Format(pcodBarcode[1]));
        lintCoding += 1;

        //ADD START SENTINEL
        bxtBarcodeBinary.Addtext(ltxtSentinel);

        for lintCount := 1 to Strlen(lcodBarInclCheckD) do begin

            //ADD CENTERGUARD
            if lintCount = 7 then
                bxtBarcodeBinary.Addtext(ltxtCenterGuard);

            Evaluate(lintNumber, Format(lcodBarInclCheckD[lintCount]));

            if lintCount <= 6 then begin
                ltxtBarcode := ltxtParEnc[lintCoding];
                CASE ltxtBarcode[lintCount] OF
                    'O':
                        bxtBarcodeBinary.Addtext(ltxtSetEnc[lintNumber + 1] [1]);
                    'E':
                        bxtBarcodeBinary.Addtext(ltxtSetEnc[lintNumber + 1] [2]);
                end;
            end else
                bxtBarcodeBinary.Addtext(ltxtSetEnc[lintNumber + 1] [3]);

        end;

        //ADD StoP SENTINEL
        bxtBarcodeBinary.Addtext(ltxtSentinel);

        lintBars := bxtBarcodeBinary.LENGTH;
        lintLines := Round(lintBars * 0.25, 1, '>');

        TenantMedia.Content.CREATEOUTSTREAM(loutBmpHeaderOutStream);

        //WRITING HEADER
        CreateBMPHeader(loutBmpHeaderOutStream, lintBars, lintLines, pintSize, pblnVertical);

        //Write BARCODE DETAIL
        CreateBarcodeDetail(lintLines, pintSize, pblnVertical, loutBmpHeaderOutStream);
    end;

    procedure EncodeCode128(pcodBarcode: Code[1024]; pintSize: Integer; pblnVertical: Boolean; var TenantMedia: Record "Tenant Media" temporary)
    var
        TempITICode128or39: Record "ITI Code 128 39" temporary;
        lblnnumber: Boolean;
        lcharCurrentCharSet: Char;
        lintBars: Integer;
        lintCheckDigit: Integer;
        lintConvInt: Integer;
        lintConvInt1: Integer;
        lintConvInt2: Integer;
        lintCount1: Integer;
        lintCount2: Integer;
        lintLines: Integer;
        lintWeightSum: Integer;
        loutBmpHeaderOutStream: OutStream;
        ltxtTerminationBar: Text[2];
    begin
        Clear(bxtBarcodeBinary);
        Clear(TenantMedia);
        Clear(TempITICode128or39);
        TempITICode128or39.DELETEALL();
        Clear(lcharCurrentCharSet);
        ltxtTerminationBar := '11';

        if not (pintSize IN [1, 2, 3, 4, 5]) then
            Error(txcErrorSizeErr);

        InitCode128(TempITICode128or39);

        for lintCount1 := 1 to Strlen(pcodBarcode) do begin
            lintCount2 += 1;
            lblnnumber := FALSE;
            TempITICode128or39.RESET();

            if Evaluate(lintConvInt1, Format(pcodBarcode[lintCount1])) then
                lblnnumber := Evaluate(lintConvInt2, Format(pcodBarcode[lintCount1 + 1]));

            //A '.' IS EvaluateD AS A 0, EXTRA CHECK NEEDED
            if Format(pcodBarcode[lintCount1]) = '.' then
                lblnnumber := FALSE;

            if Format(pcodBarcode[lintCount1 + 1]) = '.' then
                lblnnumber := FALSE;

            if lblnnumber AND (lintConvInt1 IN [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]) AND (lintConvInt2 IN [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]) then begin
                if (lcharCurrentCharSet <> 'C') then begin
                    if (lintCount1 = 1) then begin
                        TempITICode128or39.Get('STARTC');
                        Evaluate(lintConvInt, TempITICode128or39.Value);
                        lintWeightSum := lintConvInt;
                    end else begin
                        TempITICode128or39.Get('CODEC');
                        Evaluate(lintConvInt, TempITICode128or39.Value);
                        lintWeightSum += lintConvInt * lintCount2;
                        lintCount2 += 1;
                    end;

                    bxtBarcodeBinary.Addtext(Format(TempITICode128or39.Encoding));
                    lcharCurrentCharSet := 'C';
                end;
            end else
                if lcharCurrentCharSet <> 'A' then begin
                    if (lintCount1 = 1) then begin
                        TempITICode128or39.Get('STARTA');
                        Evaluate(lintConvInt, TempITICode128or39.Value);
                        lintWeightSum := lintConvInt;
                    end else begin
                        TempITICode128or39.Get('FNC4');
                        Evaluate(lintConvInt, TempITICode128or39.Value);
                        lintWeightSum += lintConvInt * lintCount2;
                        lintCount2 += 1;
                    end;

                    bxtBarcodeBinary.Addtext(Format(TempITICode128or39.Encoding));
                    lcharCurrentCharSet := 'A';
                end;

            CASE lcharCurrentCharSet OF
                'A':
                    begin
                        TempITICode128or39.Get(Format(pcodBarcode[lintCount1]));

                        Evaluate(lintConvInt, TempITICode128or39.Value);

                        lintWeightSum += lintConvInt * lintCount2;
                        bxtBarcodeBinary.Addtext(Format(TempITICode128or39.Encoding));
                    end;
                'C':
                    begin
                        TempITICode128or39.Reset();
                        TempITICode128or39.SetCurrentKey(Value);
                        TempITICode128or39.SetRange(Value, (Format(pcodBarcode[lintCount1]) + Format(pcodBarcode[lintCount1 + 1])));
                        TempITICode128or39.FindFirst();

                        Evaluate(lintConvInt, TempITICode128or39.Value);
                        lintWeightSum += lintConvInt * lintCount2;

                        bxtBarcodeBinary.Addtext(Format(TempITICode128or39.Encoding));
                        lintCount1 += 1;
                    end;
            end;
        end;

        lintCheckDigit := lintWeightSum MOD 103;

        //ADD CHECK DIGIT
        TempITICode128or39.RESET();
        TempITICode128or39.SetCurrentKey(Value);

        if lintCheckDigit <= 9 then
            TempITICode128or39.SetRange(Value, '0' + Format(lintCheckDigit))
        else
            TempITICode128or39.SetRange(Value, Format(lintCheckDigit));

        TempITICode128or39.FindFirst();
        bxtBarcodeBinary.Addtext(Format(TempITICode128or39.Encoding));

        //ADD StoP CHARACTER
        TempITICode128or39.Get('StoP');
        bxtBarcodeBinary.Addtext(Format(TempITICode128or39.Encoding));

        //ADD TERMINATION BAR
        bxtBarcodeBinary.Addtext(ltxtTerminationBar);

        lintBars := bxtBarcodeBinary.LENGTH;
        lintLines := Round(lintBars * 0.25, 1, '>');

        TenantMedia.Content.CREATEOUTSTREAM(loutBmpHeaderOutStream);

        //WRITING HEADER
        CreateBMPHeader(loutBmpHeaderOutStream, lintBars, lintLines, pintSize, pblnVertical);

        //Write BARCODE DETAIL
        CreateBarcodeDetail(lintLines, pintSize, pblnVertical, loutBmpHeaderOutStream);
    end;

    procedure EncodeCode39(pcodBarcode: Code[1024]; pintSize: Integer; pblnCheckDigit: Boolean; pblnVertical: Boolean; var TenantMedia: Record "Tenant Media" temporary)
    var
        TempITICode128or39: Record "ITI Code 128 39" temporary;
        lintBars: Integer;
        lintCheckDigit: Integer;
        lintConvInt: Integer;
        lintCount1: Integer;
        lintLines: Integer;
        lintSum: Integer;
        loutBmpHeaderOutStream: OutStream;
    begin
        Clear(bxtBarcodeBinary);
        Clear(TenantMedia);
        Clear(TempITICode128or39);
        TempITICode128or39.DELETEALL();
        lintSum := 0;

        if not (pintSize IN [1, 2, 3, 4, 5]) then
            Error(txcErrorSizeErr);

        InitCode39(TempITICode128or39);

        //CALCULATE CHECK DIGIT
        if pblnCheckDigit then begin
            for lintCount1 := 1 to Strlen(pcodBarcode) do begin
                TempITICode128or39.Get(Format(pcodBarcode[lintCount1]));
                Evaluate(lintConvInt, TempITICode128or39.Value);
                lintSum += lintConvInt;
            end;
            lintCheckDigit := lintSum MOD 43;
            pcodBarcode := pcodBarcode + Format(lintCheckDigit);
        end;

        //ADD START CHARACTER
        TempITICode128or39.Get('*');
        bxtBarcodeBinary.Addtext(Format(TempITICode128or39.Encoding));

        //ADD SEPERAtoR
        bxtBarcodeBinary.Addtext('0');

        for lintCount1 := 1 to Strlen(pcodBarcode) do begin
            //ADD SEPERAtoR
            bxtBarcodeBinary.Addtext('0');

            TempITICode128or39.Get(Format(pcodBarcode[lintCount1]));
            bxtBarcodeBinary.Addtext(Format(TempITICode128or39.Encoding));
        end;

        //ADD SEPERAtoR
        bxtBarcodeBinary.Addtext('0');

        //ADD StoP CHARACTER
        TempITICode128or39.Get('*');
        bxtBarcodeBinary.Addtext(Format(TempITICode128or39.Encoding));

        lintBars := bxtBarcodeBinary.LENGTH;
        lintLines := Round(lintBars * 0.25, 1, '>');

        TenantMedia.Content.CREATEOUTSTREAM(loutBmpHeaderOutStream);

        //WRITING HEADER
        CreateBMPHeader(loutBmpHeaderOutStream, lintBars, lintLines, pintSize, pblnVertical);

        //Write BARCODE DETAIL
        CreateBarcodeDetail(lintLines, pintSize, pblnVertical, loutBmpHeaderOutStream);
    end;

    procedure EncodeEAN8(pcodBarcode: Code[250]; pintSize: Integer; pblnVertical: Boolean; var TenantMedia: Record "Tenant Media" temporary)
    var
        lintBars: Integer;
        lintCheckDigit: Integer;
        lintCount: Integer;
        lintLines: Integer;
        lintNumber: Integer;
        loutBmpHeaderOutStream: OutStream;
        lcodBarInclCheckD: Text;
        ltxtSentinel: Text[3];
        ltxtCenterGuard: Text[6];
        ltxtParEnc: array[10] of Text[6];
        ltxtSetEnc: array[10, 10] of Text[7];
        ltxtWeight: Text[12];
    begin
        Clear(bxtBarcodeBinary);
        Clear(TenantMedia);
        ltxtSentinel := '101';
        ltxtCenterGuard := '01010';
        ltxtWeight := '3131313';

        if Strlen(pcodBarcode) <> 7 then
            Error(txcErrorLengthErr, 7);

        if not (pintSize IN [1, 2, 3, 4, 5]) then
            Error(txcErrorSizeErr);

        for lintCount := 1 to Strlen(pcodBarcode) do
            if not (pcodBarcode[lintCount] IN ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']) then
                Error(txcErrorNumberErr);

        InitEAN813(ltxtParEnc, ltxtSetEnc);

        //CALCULATE CHECKDIGIT
        lintCheckDigit := STRCHECKSUM(pcodBarcode, ltxtWeight, 10);

        //PAYLOAD to ENCODE
        lcodBarInclCheckD := pcodBarcode + Format(lintCheckDigit);

        //ADD START SENTINEL
        bxtBarcodeBinary.Addtext(ltxtSentinel);

        for lintCount := 1 to Strlen(lcodBarInclCheckD) do begin
            //ADD CENTERGUARD
            if lintCount = 5 then
                bxtBarcodeBinary.Addtext(ltxtCenterGuard);

            Evaluate(lintNumber, Format(lcodBarInclCheckD[lintCount]));

            if lintCount <= 4 then
                bxtBarcodeBinary.Addtext(ltxtSetEnc[lintNumber + 1] [1])
            else
                bxtBarcodeBinary.Addtext(ltxtSetEnc[lintNumber + 1] [3]);

        end;

        //ADD StoP SENTINEL
        bxtBarcodeBinary.Addtext(ltxtSentinel);

        lintBars := bxtBarcodeBinary.LENGTH;
        lintLines := Round(lintBars * 0.25, 1, '>');

        TenantMedia.Content.CREATEOUTSTREAM(loutBmpHeaderOutStream);

        //WRITING HEADER
        CreateBMPHeader(loutBmpHeaderOutStream, lintBars, lintLines, pintSize, pblnVertical);

        //Write BARCODE DETAIL
        CreateBarcodeDetail(lintLines, pintSize, pblnVertical, loutBmpHeaderOutStream);
    end;

    local procedure CreateBMPHeader(var poutBmpHeaderOutStream: OutStream; pintCols: Integer; pintRows: Integer; pintSize: Integer; pblnVertical: Boolean)
    var
        charInf: Char;
        lintHeight: Integer;
        lintResolution: Integer;
        lintWidth: Integer;
    begin

        lintResolution := Round(3835 / pintSize, 1, '=');

        if pblnVertical then begin
            lintWidth := pintRows * pintSize;
            lintHeight := pintCols;
        end else begin
            lintWidth := pintCols * pintSize;
            lintHeight := pintRows * pintSize;
        end;

        charInf := 'B';
        poutBmpHeaderOutStream.Write(charInf, 1);
        charInf := 'M';
        poutBmpHeaderOutStream.Write(charInf, 1);
        poutBmpHeaderOutStream.Write(54 + pintRows * pintCols * 3, 4); //SIZE BMP
        poutBmpHeaderOutStream.Write(0, 4); //APPLICATION SPECifIC
        poutBmpHeaderOutStream.Write(54, 4); //OFFSET DATA PIXELS
        poutBmpHeaderOutStream.Write(40, 4); //NUMBER OF BYTES IN HEADER FROM THIS POINT
        poutBmpHeaderOutStream.Write(lintWidth, 4); //WIDTH PIXEL
        poutBmpHeaderOutStream.Write(lintHeight, 4); //HEIGHT PIXEL
        poutBmpHeaderOutStream.Write(65536 * 24 + 1, 4); //COLOR DEPTH
        poutBmpHeaderOutStream.Write(0, 4); //NO. OF COLOR PANES & BITS PER PIXEL
        poutBmpHeaderOutStream.Write(0, 4); //SIZE BMP DATA
        poutBmpHeaderOutStream.Write(lintResolution, 4); //HORIZONTAL RESOLUTION
        poutBmpHeaderOutStream.Write(lintResolution, 4); //VERTICAL RESOLUTION
        poutBmpHeaderOutStream.Write(0, 4); //NO. OF COLORS IN PALETTE
        poutBmpHeaderOutStream.Write(0, 4); //IMPORTANT COLORS
    end;

    local procedure CreateBarcodeDetail(pintLines: Integer; pintSize: Integer; pblnVertical: Boolean; var poutBmpHeaderOutStream: OutStream)
    var
        lbyte: Byte;
        lintBarLoop: Integer;
        lintChainFiller: Integer;
        lintLineLoop: Integer;
        lintSize: Integer;
        ltxtByte: Text;
    begin
        if pblnVertical then
            for lintBarLoop := 1 to (bxtBarcodeBinary.LENGTH) do begin

                for lintLineLoop := 1 to (pintLines * pintSize) do begin
                    bxtBarcodeBinary.GetSUBTEXT(ltxtByte, lintBarLoop, 1);

                    if ltxtByte = '1' then
                        lbyte := 0
                    else
                        lbyte := 255;

                    poutBmpHeaderOutStream.Write(lbyte, 1);
                    poutBmpHeaderOutStream.Write(lbyte, 1);
                    poutBmpHeaderOutStream.Write(lbyte, 1);
                end;

                for lintChainFiller := 1 to (lintLineLoop MOD 4) do
                    poutBmpHeaderOutStream.Write(lbyte, 1);
            end
        else
            for lintLineLoop := 1 to pintLines * pintSize do begin
                for lintBarLoop := 1 to bxtBarcodeBinary.LENGTH do begin
                    bxtBarcodeBinary.GetSUBTEXT(ltxtByte, lintBarLoop, 1);

                    if ltxtByte = '1' then
                        lbyte := 0
                    else
                        lbyte := 255;

                    for lintSize := 1 to pintSize do begin
                        //Putting Pixel: Black or White
                        poutBmpHeaderOutStream.Write(lbyte, 1);
                        poutBmpHeaderOutStream.Write(lbyte, 1);
                        poutBmpHeaderOutStream.Write(lbyte, 1);
                    end
                end;

                for lintChainFiller := 1 to ((lintBarLoop * pintSize) MOD 4) do begin
                    //Adding 0 bytes if needed - line end
                    lbyte := 0;
                    poutBmpHeaderOutStream.Write(lbyte, 1);
                end;
            end;

    end;

    local procedure InitEAN813(var ptxtParEnc: array[10] of Text[6]; var ptxtSetEnc: array[10, 10] of Text[7])
    begin

        //Init() CONSTANTS
        //0
        ptxtParEnc[1] := 'OOOOOO';
        //1
        ptxtParEnc[2] := 'OOEOEE';
        //2
        ptxtParEnc[3] := 'OOEEOE';
        //3
        ptxtParEnc[4] := 'OOEEEO';
        //4
        ptxtParEnc[5] := 'OEOOEE';
        //5
        ptxtParEnc[6] := 'OEEOOE';
        //6
        ptxtParEnc[7] := 'OEEEOO';
        //7
        ptxtParEnc[8] := 'OEOEOE';
        //8
        ptxtParEnc[9] := 'OEOEEO';
        //9
        ptxtParEnc[10] := 'OEEOEO';

        //0
        ptxtSetEnc[1] [1] := '0001101';
        ptxtSetEnc[1] [2] := '0100111';
        ptxtSetEnc[1] [3] := '1110010';
        //1
        ptxtSetEnc[2] [1] := '0011001';
        ptxtSetEnc[2] [2] := '0110011';
        ptxtSetEnc[2] [3] := '1100110';
        //2
        ptxtSetEnc[3] [1] := '0010011';
        ptxtSetEnc[3] [2] := '0011011';
        ptxtSetEnc[3] [3] := '1101100';
        //3
        ptxtSetEnc[4] [1] := '0111101';
        ptxtSetEnc[4] [2] := '0100001';
        ptxtSetEnc[4] [3] := '1000010';
        //4
        ptxtSetEnc[5] [1] := '0100011';
        ptxtSetEnc[5] [2] := '0011101';
        ptxtSetEnc[5] [3] := '1011100';
        //5
        ptxtSetEnc[6] [1] := '0110001';
        ptxtSetEnc[6] [2] := '0111001';
        ptxtSetEnc[6] [3] := '1001110';
        //6
        ptxtSetEnc[7] [1] := '0101111';
        ptxtSetEnc[7] [2] := '0000101';
        ptxtSetEnc[7] [3] := '1010000';
        //7
        ptxtSetEnc[8] [1] := '0111011';
        ptxtSetEnc[8] [2] := '0010001';
        ptxtSetEnc[8] [3] := '1000100';
        //8
        ptxtSetEnc[9] [1] := '0110111';
        ptxtSetEnc[9] [2] := '0001001';
        ptxtSetEnc[9] [3] := '1001000';
        //9
        ptxtSetEnc[10] [1] := '0001011';
        ptxtSetEnc[10] [2] := '0010111';
        ptxtSetEnc[10] [3] := '1110100';
    end;

    local procedure InitCode128(var TempITICode128or39: Record "ITI Code 128 39" temporary)
    begin
        TempITICode128or39.Init();
        TempITICode128or39."CharA" := ' ';
        TempITICode128or39.CharB := ' ';
        TempITICode128or39.CharC := ' ';
        TempITICode128or39.Value := '00';
        TempITICode128or39.Encoding := '11011001100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '!';
        TempITICode128or39.CharB := '!';
        TempITICode128or39.CharC := '01';
        TempITICode128or39.Value := '01';
        TempITICode128or39.Encoding := '11001101100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '"';
        TempITICode128or39.CharB := '"';
        TempITICode128or39.CharC := '02';
        TempITICode128or39.Value := '02';
        TempITICode128or39.Encoding := '11001100110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '#';
        TempITICode128or39.CharB := '#';
        TempITICode128or39.CharC := '03';
        TempITICode128or39.Value := '03';
        TempITICode128or39.Encoding := '10010011000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '$';
        TempITICode128or39.CharB := '$';
        TempITICode128or39.CharC := '04';
        TempITICode128or39.Value := '04';
        TempITICode128or39.Encoding := '10010001100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '%';
        TempITICode128or39.CharB := '%';
        TempITICode128or39.CharC := '05';
        TempITICode128or39.Value := '05';
        TempITICode128or39.Encoding := '10001001100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '&';
        TempITICode128or39.CharB := '&';
        TempITICode128or39.CharC := '06';
        TempITICode128or39.Value := '06';
        TempITICode128or39.Encoding := '10011001000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '''';
        TempITICode128or39.CharB := '''';
        TempITICode128or39.CharC := '07';
        TempITICode128or39.Value := '07';
        TempITICode128or39.Encoding := '10011000100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '(';
        TempITICode128or39.CharB := '(';
        TempITICode128or39.CharC := '08';
        TempITICode128or39.Value := '08';
        TempITICode128or39.Encoding := '10001100100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := ')';
        TempITICode128or39.CharB := ')';
        TempITICode128or39.CharC := '09';
        TempITICode128or39.Value := '09';
        TempITICode128or39.Encoding := '11001001000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '*';
        TempITICode128or39.CharB := '*';
        TempITICode128or39.CharC := '10';
        TempITICode128or39.Value := '10';
        TempITICode128or39.Encoding := '11001000100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '+';
        TempITICode128or39.CharB := '+';
        TempITICode128or39.CharC := '11';
        TempITICode128or39.Value := '11';
        TempITICode128or39.Encoding := '11000100100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := ',';
        TempITICode128or39.CharB := ',';
        TempITICode128or39.CharC := '12';
        TempITICode128or39.Value := '12';
        TempITICode128or39.Encoding := '10110011100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '-';
        TempITICode128or39.CharB := '-';
        TempITICode128or39.CharC := '13';
        TempITICode128or39.Value := '13';
        TempITICode128or39.Encoding := '10011011100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '.';
        TempITICode128or39.CharB := '.';
        TempITICode128or39.CharC := '14';
        TempITICode128or39.Value := '14';
        TempITICode128or39.Encoding := '10011001110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '/';
        TempITICode128or39.CharB := '/';
        TempITICode128or39.CharC := '15';
        TempITICode128or39.Value := '15';
        TempITICode128or39.Encoding := '10111001100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '0';
        TempITICode128or39.CharB := '0';
        TempITICode128or39.CharC := '16';
        TempITICode128or39.Value := '16';
        TempITICode128or39.Encoding := '10011101100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '1';
        TempITICode128or39.CharB := '1';
        TempITICode128or39.CharC := '17';
        TempITICode128or39.Value := '17';
        TempITICode128or39.Encoding := '10011100110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '2';
        TempITICode128or39.CharB := '2';
        TempITICode128or39.CharC := '18';
        TempITICode128or39.Value := '18';
        TempITICode128or39.Encoding := '11001110010';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '3';
        TempITICode128or39.CharB := '3';
        TempITICode128or39.CharC := '19';
        TempITICode128or39.Value := '19';
        TempITICode128or39.Encoding := '11001011100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '4';
        TempITICode128or39.CharB := '4';
        TempITICode128or39.CharC := '20';
        TempITICode128or39.Value := '20';
        TempITICode128or39.Encoding := '11001001110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '5';
        TempITICode128or39.CharB := '5';
        TempITICode128or39.CharC := '21';
        TempITICode128or39.Value := '21';
        TempITICode128or39.Encoding := '11011100100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '6';
        TempITICode128or39.CharB := '6';
        TempITICode128or39.CharC := '22';
        TempITICode128or39.Value := '22';
        TempITICode128or39.Encoding := '11001110100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '7';
        TempITICode128or39.CharB := '7';
        TempITICode128or39.CharC := '23';
        TempITICode128or39.Value := '23';
        TempITICode128or39.Encoding := '11101101110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '8';
        TempITICode128or39.CharB := '8';
        TempITICode128or39.CharC := '24';
        TempITICode128or39.Value := '24';
        TempITICode128or39.Encoding := '11101001100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '9';
        TempITICode128or39.CharB := '9';
        TempITICode128or39.CharC := '25';
        TempITICode128or39.Value := '25';
        TempITICode128or39.Encoding := '11100101100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := ':';
        TempITICode128or39.CharB := ':';
        TempITICode128or39.CharC := '26';
        TempITICode128or39.Value := '26';
        TempITICode128or39.Encoding := '11100100110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := ';';
        TempITICode128or39.CharB := ';';
        TempITICode128or39.CharC := '27';
        TempITICode128or39.Value := '27';
        TempITICode128or39.Encoding := '11101100100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '<';
        TempITICode128or39.CharB := '<';
        TempITICode128or39.CharC := '28';
        TempITICode128or39.Value := '28';
        TempITICode128or39.Encoding := '11100110100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '=';
        TempITICode128or39.CharB := '=';
        TempITICode128or39.CharC := '29';
        TempITICode128or39.Value := '29';
        TempITICode128or39.Encoding := '11100110010';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '>';
        TempITICode128or39.CharB := '>';
        TempITICode128or39.CharC := '30';
        TempITICode128or39.Value := '30';
        TempITICode128or39.Encoding := '11011011000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '?';
        TempITICode128or39.CharB := '?';
        TempITICode128or39.CharC := '31';
        TempITICode128or39.Value := '31';
        TempITICode128or39.Encoding := '11011000110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '@';
        TempITICode128or39.CharB := '@';
        TempITICode128or39.CharC := '32';
        TempITICode128or39.Value := '32';
        TempITICode128or39.Encoding := '11000110110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'A';
        TempITICode128or39.CharB := 'A';
        TempITICode128or39.CharC := '33';
        TempITICode128or39.Value := '33';
        TempITICode128or39.Encoding := '10100011000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'B';
        TempITICode128or39.CharB := 'B';
        TempITICode128or39.CharC := '34';
        TempITICode128or39.Value := '34';
        TempITICode128or39.Encoding := '10001011000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'C';
        TempITICode128or39.CharB := 'C';
        TempITICode128or39.CharC := '35';
        TempITICode128or39.Value := '35';
        TempITICode128or39.Encoding := '10001000110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'D';
        TempITICode128or39.CharB := 'D';
        TempITICode128or39.CharC := '36';
        TempITICode128or39.Value := '36';
        TempITICode128or39.Encoding := '10110001000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'E';
        TempITICode128or39.CharB := 'E';
        TempITICode128or39.CharC := '37';
        TempITICode128or39.Value := '37';
        TempITICode128or39.Encoding := '10001101000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'F';
        TempITICode128or39.CharB := 'F';
        TempITICode128or39.CharC := '38';
        TempITICode128or39.Value := '38';
        TempITICode128or39.Encoding := '10001100010';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'G';
        TempITICode128or39.CharB := 'G';
        TempITICode128or39.CharC := '39';
        TempITICode128or39.Value := '39';
        TempITICode128or39.Encoding := '11010001000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'H';
        TempITICode128or39.CharB := 'H';
        TempITICode128or39.CharC := '40';
        TempITICode128or39.Value := '40';
        TempITICode128or39.Encoding := '11000101000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'I';
        TempITICode128or39.CharB := 'I';
        TempITICode128or39.CharC := '41';
        TempITICode128or39.Value := '41';
        TempITICode128or39.Encoding := '11000100010';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'J';
        TempITICode128or39.CharB := 'J';
        TempITICode128or39.CharC := '42';
        TempITICode128or39.Value := '42';
        TempITICode128or39.Encoding := '10110111000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'K';
        TempITICode128or39.CharB := 'K';
        TempITICode128or39.CharC := '43';
        TempITICode128or39.Value := '43';
        TempITICode128or39.Encoding := '10110001110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'L';
        TempITICode128or39.CharB := 'L';
        TempITICode128or39.CharC := '44';
        TempITICode128or39.Value := '44';
        TempITICode128or39.Encoding := '10001101110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'M';
        TempITICode128or39.CharB := 'M';
        TempITICode128or39.CharC := '45';
        TempITICode128or39.Value := '45';
        TempITICode128or39.Encoding := '10111011000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'N';
        TempITICode128or39.CharB := 'N';
        TempITICode128or39.CharC := '46';
        TempITICode128or39.Value := '46';
        TempITICode128or39.Encoding := '10111000110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'O';
        TempITICode128or39.CharB := 'O';
        TempITICode128or39.CharC := '47';
        TempITICode128or39.Value := '47';
        TempITICode128or39.Encoding := '10001110110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'P';
        TempITICode128or39.CharB := 'P';
        TempITICode128or39.CharC := '48';
        TempITICode128or39.Value := '48';
        TempITICode128or39.Encoding := '11101110110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'Q';
        TempITICode128or39.CharB := 'Q';
        TempITICode128or39.CharC := '49';
        TempITICode128or39.Value := '49';
        TempITICode128or39.Encoding := '11010001110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'R';
        TempITICode128or39.CharB := 'R';
        TempITICode128or39.CharC := '50';
        TempITICode128or39.Value := '50';
        TempITICode128or39.Encoding := '11000101110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'S';
        TempITICode128or39.CharB := 'S';
        TempITICode128or39.CharC := '51';
        TempITICode128or39.Value := '51';
        TempITICode128or39.Encoding := '11011101000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'T';
        TempITICode128or39.CharB := 'T';
        TempITICode128or39.CharC := '52';
        TempITICode128or39.Value := '52';
        TempITICode128or39.Encoding := '11011100010';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'U';
        TempITICode128or39.CharB := 'U';
        TempITICode128or39.CharC := '53';
        TempITICode128or39.Value := '53';
        TempITICode128or39.Encoding := '11011101110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'V';
        TempITICode128or39.CharB := 'V';
        TempITICode128or39.CharC := '54';
        TempITICode128or39.Value := '54';
        TempITICode128or39.Encoding := '11101011000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'W';
        TempITICode128or39.CharB := 'W';
        TempITICode128or39.CharC := '55';
        TempITICode128or39.Value := '55';
        TempITICode128or39.Encoding := '11101000110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'X';
        TempITICode128or39.CharB := 'X';
        TempITICode128or39.CharC := '56';
        TempITICode128or39.Value := '56';
        TempITICode128or39.Encoding := '11100010110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'Y';
        TempITICode128or39.CharB := 'Y';
        TempITICode128or39.CharC := '57';
        TempITICode128or39.Value := '57';
        TempITICode128or39.Encoding := '11101101000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'Z';
        TempITICode128or39.CharB := 'Z';
        TempITICode128or39.CharC := '58';
        TempITICode128or39.Value := '58';
        TempITICode128or39.Encoding := '11101100010';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '[';
        TempITICode128or39.CharB := '[';
        TempITICode128or39.CharC := '59';
        TempITICode128or39.Value := '59';
        TempITICode128or39.Encoding := '11100011010';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '\';
        TempITICode128or39.CharB := '\';
        TempITICode128or39.CharC := '60';
        TempITICode128or39.Value := '60';
        TempITICode128or39.Encoding := '11101111010';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := ']';
        TempITICode128or39.CharB := ']';
        TempITICode128or39.CharC := '61';
        TempITICode128or39.Value := '61';
        TempITICode128or39.Encoding := '11001000010';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '^';
        TempITICode128or39.CharB := '^';
        TempITICode128or39.CharC := '62';
        TempITICode128or39.Value := '62';
        TempITICode128or39.Encoding := '11110001010';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '_';
        TempITICode128or39.CharB := '_';
        TempITICode128or39.CharC := '63';
        TempITICode128or39.Value := '63';
        TempITICode128or39.Encoding := '10100110000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'NUL';
        TempITICode128or39.CharB := '`';
        TempITICode128or39.CharC := '64';
        TempITICode128or39.Value := '64';
        TempITICode128or39.Encoding := '10100001100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'SOH';
        TempITICode128or39.CharB := 'a';
        TempITICode128or39.CharC := '65';
        TempITICode128or39.Value := '65';
        TempITICode128or39.Encoding := '10010110000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'STX';
        TempITICode128or39.CharB := 'b';
        TempITICode128or39.CharC := '66';
        TempITICode128or39.Value := '66';
        TempITICode128or39.Encoding := '10010000110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'ETX';
        TempITICode128or39.CharB := 'c';
        TempITICode128or39.CharC := '67';
        TempITICode128or39.Value := '67';
        TempITICode128or39.Encoding := '10000101100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'EOT';
        TempITICode128or39.CharB := 'd';
        TempITICode128or39.CharC := '68';
        TempITICode128or39.Value := '68';
        TempITICode128or39.Encoding := '10000100110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'ENQ';
        TempITICode128or39.CharB := 'e';
        TempITICode128or39.CharC := '69';
        TempITICode128or39.Value := '69';
        TempITICode128or39.Encoding := '10110010000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'ACK';
        TempITICode128or39.CharB := 'f';
        TempITICode128or39.CharC := '70';
        TempITICode128or39.Value := '70';
        TempITICode128or39.Encoding := '10110000100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'BEL';
        TempITICode128or39.CharB := 'g';
        TempITICode128or39.CharC := '71';
        TempITICode128or39.Value := '71';
        TempITICode128or39.Encoding := '10011010000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'BS';
        TempITICode128or39.CharB := 'h';
        TempITICode128or39.CharC := '72';
        TempITICode128or39.Value := '72';
        TempITICode128or39.Encoding := '10011000010';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'HT';
        TempITICode128or39.CharB := 'i';
        TempITICode128or39.CharC := '73';
        TempITICode128or39.Value := '73';
        TempITICode128or39.Encoding := '10000110100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'LF';
        TempITICode128or39.CharB := 'j';
        TempITICode128or39.CharC := '74';
        TempITICode128or39.Value := '74';
        TempITICode128or39.Encoding := '10000110010';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'VT';
        TempITICode128or39.CharB := 'k';
        TempITICode128or39.CharC := '75';
        TempITICode128or39.Value := '75';
        TempITICode128or39.Encoding := '11000010010';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'FF';
        TempITICode128or39.CharB := 'l';
        TempITICode128or39.CharC := '76';
        TempITICode128or39.Value := '76';
        TempITICode128or39.Encoding := '11001010000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'CR';
        TempITICode128or39.CharB := 'm';
        TempITICode128or39.CharC := '77';
        TempITICode128or39.Value := '77';
        TempITICode128or39.Encoding := '11110111010';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'SO';
        TempITICode128or39.CharB := 'n';
        TempITICode128or39.CharC := '78';
        TempITICode128or39.Value := '78';
        TempITICode128or39.Encoding := '11000010100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'SI';
        TempITICode128or39.CharB := 'o';
        TempITICode128or39.CharC := '79';
        TempITICode128or39.Value := '79';
        TempITICode128or39.Encoding := '10001111010';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'DLE';
        TempITICode128or39.CharB := 'p';
        TempITICode128or39.CharC := '80';
        TempITICode128or39.Value := '80';
        TempITICode128or39.Encoding := '10100111100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'DC1';
        TempITICode128or39.CharB := 'q';
        TempITICode128or39.CharC := '81';
        TempITICode128or39.Value := '81';
        TempITICode128or39.Encoding := '10010111100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'DC2';
        TempITICode128or39.CharB := 'r';
        TempITICode128or39.CharC := '82';
        TempITICode128or39.Value := '82';
        TempITICode128or39.Encoding := '10010011110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'DC3';
        TempITICode128or39.CharB := 's';
        TempITICode128or39.CharC := '83';
        TempITICode128or39.Value := '83';
        TempITICode128or39.Encoding := '10111100100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'DC4';
        TempITICode128or39.CharB := 't';
        TempITICode128or39.CharC := '84';
        TempITICode128or39.Value := '84';
        TempITICode128or39.Encoding := '10011110100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'NAK';
        TempITICode128or39.CharB := 'u';
        TempITICode128or39.CharC := '85';
        TempITICode128or39.Value := '85';
        TempITICode128or39.Encoding := '10011110010';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'SYN';
        TempITICode128or39.CharB := 'v';
        TempITICode128or39.CharC := '86';
        TempITICode128or39.Value := '86';
        TempITICode128or39.Encoding := '11110100100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'ETB';
        TempITICode128or39.CharB := 'w';
        TempITICode128or39.CharC := '87';
        TempITICode128or39.Value := '87';
        TempITICode128or39.Encoding := '11110010100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'CAN';
        TempITICode128or39.CharB := 'x';
        TempITICode128or39.CharC := '88';
        TempITICode128or39.Value := '88';
        TempITICode128or39.Encoding := '11110010010';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'EM';
        TempITICode128or39.CharB := 'y';
        TempITICode128or39.CharC := '89';
        TempITICode128or39.Value := '89';
        TempITICode128or39.Encoding := '11011011110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'SUB';
        TempITICode128or39.CharB := 'z';
        TempITICode128or39.CharC := '90';
        TempITICode128or39.Value := '90';
        TempITICode128or39.Encoding := '11011110110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'ESC';
        TempITICode128or39.CharB := '{';
        TempITICode128or39.CharC := '91';
        TempITICode128or39.Value := '91';
        TempITICode128or39.Encoding := '11110110110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'FS';
        TempITICode128or39.CharB := '|';
        TempITICode128or39.CharC := '92';
        TempITICode128or39.Value := '92';
        TempITICode128or39.Encoding := '10101111000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'GS';
        TempITICode128or39.CharB := '}';
        TempITICode128or39.CharC := '93';
        TempITICode128or39.Value := '93';
        TempITICode128or39.Encoding := '10100011110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'RS';
        TempITICode128or39.CharB := '~';
        TempITICode128or39.CharC := '94';
        TempITICode128or39.Value := '94';
        TempITICode128or39.Encoding := '10001011110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'US';
        TempITICode128or39.CharB := 'DEL';
        TempITICode128or39.CharC := '95';
        TempITICode128or39.Value := '95';
        TempITICode128or39.Encoding := '10111101000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'FNC3';
        TempITICode128or39.CharB := 'FNC3';
        TempITICode128or39.CharC := '96';
        TempITICode128or39.Value := '96';
        TempITICode128or39.Encoding := '10111100010';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'FNC2';
        TempITICode128or39.CharB := 'FNC2';
        TempITICode128or39.CharC := '97';
        TempITICode128or39.Value := '97';
        TempITICode128or39.Encoding := '11110101000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'SHifT';
        TempITICode128or39.CharB := 'SHifT';
        TempITICode128or39.CharC := '98';
        TempITICode128or39.Value := '98';
        TempITICode128or39.Encoding := '11110100010';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'CODEC';
        TempITICode128or39.CharB := 'CODEC';
        TempITICode128or39.CharC := '99';
        TempITICode128or39.Value := '99';
        TempITICode128or39.Encoding := '10111011110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'CODEB';
        TempITICode128or39.CharB := 'FNC4';
        TempITICode128or39.CharC := 'CODEB';
        TempITICode128or39.Value := '100';
        TempITICode128or39.Encoding := '10111101110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'FNC4';
        TempITICode128or39.CharB := 'CODEA';
        TempITICode128or39.CharC := 'CODEA';
        TempITICode128or39.Value := '101';
        TempITICode128or39.Encoding := '11101011110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'FNC1';
        TempITICode128or39.CharB := 'FNC1';
        TempITICode128or39.CharC := 'FNC1';
        TempITICode128or39.Value := '102';
        TempITICode128or39.Encoding := '11110101110';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'STARTA';
        TempITICode128or39.CharB := 'STARTA';
        TempITICode128or39.CharC := 'STARTA';
        TempITICode128or39.Value := '103';
        TempITICode128or39.Encoding := '11010000100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'STARTB';
        TempITICode128or39.CharB := 'STARTB';
        TempITICode128or39.CharC := 'STARTB';
        TempITICode128or39.Value := '104';
        TempITICode128or39.Encoding := '11010010000';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'STARTC';
        TempITICode128or39.CharB := 'STARTC';
        TempITICode128or39.CharC := 'STARTC';
        TempITICode128or39.Value := '105';
        TempITICode128or39.Encoding := '11010011100';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'StoP';
        TempITICode128or39.CharB := 'StoP';
        TempITICode128or39.CharC := 'StoP';
        TempITICode128or39.Value := '';
        TempITICode128or39.Encoding := '11000111010';
        TempITICode128or39.Insert();
    end;

    local procedure InitCode39(var TempITICode128or39: Record "ITI Code 128 39" temporary)
    begin
        //THIS IS not THE EXTendED CODE 39 ENCODING TABLE!

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '0';
        TempITICode128or39.Value := '0';
        TempITICode128or39.Encoding := '101001101101';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '1';
        TempITICode128or39.Value := '1';
        TempITICode128or39.Encoding := '110100101011';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '2';
        TempITICode128or39.Value := '2';
        TempITICode128or39.Encoding := '101100101011';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '3';
        TempITICode128or39.Value := '3';
        TempITICode128or39.Encoding := '110110010101';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '4';
        TempITICode128or39.Value := '4';
        TempITICode128or39.Encoding := '101001101011';
        TempITICode128or39.Insert();
        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '5';
        TempITICode128or39.Value := '5';
        TempITICode128or39.Encoding := '110100110101';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '6';
        TempITICode128or39.Value := '6';
        TempITICode128or39.Encoding := '101100110101';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '7';
        TempITICode128or39.Value := '7';
        TempITICode128or39.Encoding := '101001011011';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '8';
        TempITICode128or39.Value := '8';
        TempITICode128or39.Encoding := '110100101101';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '9';
        TempITICode128or39.Value := '9';
        TempITICode128or39.Encoding := '101100101101';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'A';
        TempITICode128or39.Value := '10';
        TempITICode128or39.Encoding := '110101001011';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'B';
        TempITICode128or39.Value := '11';
        TempITICode128or39.Encoding := '101101001011';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'C';
        TempITICode128or39.Value := '12';
        TempITICode128or39.Encoding := '110110100101';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'D';
        TempITICode128or39.Value := '13';
        TempITICode128or39.Encoding := '101011001011';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'E';
        TempITICode128or39.Value := '14';
        TempITICode128or39.Encoding := '110101100101';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'F';
        TempITICode128or39.Value := '15';
        TempITICode128or39.Encoding := '101101100101';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'G';
        TempITICode128or39.Value := '16';
        TempITICode128or39.Encoding := '101010011011';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'H';
        TempITICode128or39.Value := '17';
        TempITICode128or39.Encoding := '110101001101';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'I';
        TempITICode128or39.Value := '18';
        TempITICode128or39.Encoding := '101101001101';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'J';
        TempITICode128or39.Value := '19';
        TempITICode128or39.Encoding := '101011001101';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'K';
        TempITICode128or39.Value := '20';
        TempITICode128or39.Encoding := '110101010011';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'L';
        TempITICode128or39.Value := '21';
        TempITICode128or39.Encoding := '101101010011';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'M';
        TempITICode128or39.Value := '22';
        TempITICode128or39.Encoding := '110110101001';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'N';
        TempITICode128or39.Value := '23';
        TempITICode128or39.Encoding := '101011010011';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'O';
        TempITICode128or39.Value := '24';
        TempITICode128or39.Encoding := '110101101001';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'P';
        TempITICode128or39.Value := '25';
        TempITICode128or39.Encoding := '101101101001';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'Q';
        TempITICode128or39.Value := '26';
        TempITICode128or39.Encoding := '101010110011';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'R';
        TempITICode128or39.Value := '27';
        TempITICode128or39.Encoding := '110101011001';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'S';
        TempITICode128or39.Value := '28';
        TempITICode128or39.Encoding := '101101011001';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'T';
        TempITICode128or39.Value := '29';
        TempITICode128or39.Encoding := '101011011001';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'U';
        TempITICode128or39.Value := '30';
        TempITICode128or39.Encoding := '110010101011';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'V';
        TempITICode128or39.Value := '31';
        TempITICode128or39.Encoding := '100110101011';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'W';
        TempITICode128or39.Value := '32';
        TempITICode128or39.Encoding := '110011010101';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'X';
        TempITICode128or39.Value := '33';
        TempITICode128or39.Encoding := '100101101011';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'Y';
        TempITICode128or39.Value := '34';
        TempITICode128or39.Encoding := '110010110101';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := 'Z';
        TempITICode128or39.Value := '35';
        TempITICode128or39.Encoding := '100110110101';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '-';
        TempITICode128or39.Value := '36';
        TempITICode128or39.Encoding := '100101011011';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '.';
        TempITICode128or39.Value := '37';
        TempITICode128or39.Encoding := '110010101101';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := ' ';
        TempITICode128or39.Value := '38';
        TempITICode128or39.Encoding := '100110101101';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '$';
        TempITICode128or39.Value := '39';
        TempITICode128or39.Encoding := '100100100101';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '/';
        TempITICode128or39.Value := '40';
        TempITICode128or39.Encoding := '100100101001';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '+';
        TempITICode128or39.Value := '41';
        TempITICode128or39.Encoding := '100101001001';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '%';
        TempITICode128or39.Value := '42';
        TempITICode128or39.Encoding := '101001001001';
        TempITICode128or39.Insert();

        TempITICode128or39.Init();
        TempITICode128or39."CharA" := '*';
        TempITICode128or39.Value := '';
        TempITICode128or39.Encoding := '100101101101';
        TempITICode128or39.Insert();
    end;
}

