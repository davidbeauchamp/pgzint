CREATE EXTENSION pgzint;

SELECT bc_pdf417('test');
SELECT bc_qrcode('test');
SELECT bc_code128('test');

SELECT getzintsymbolid('BARCODE_PDF417');
SELECT getzintsymbolconstant(55);
