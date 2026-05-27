import 'package:flutter/material.dart';

const kMessageError =
    'Có lỗi xảy ra trong quá trình xử lý, vui lòng thử lại sau';
const kRememberLogin = 'kRememberLogin';

// ── Floating Glass NavBar ──
/// Chiều cao bar nổi (78) + khoảng trống dưới (16) + thêm margin an toàn (16)
const double kFloatingNavBarHeight = 78.0 + 16.0 + 16.0;

/// Tính bottom padding an toàn, tránh bị che bởi:
///   • Floating navigation bar
///   • Gesture bar / home indicator
///   • Tai thỏ (notch)
///   • Keyboard
double floatingNavBottomPadding(BuildContext context) {
  return MediaQuery.of(context).padding.bottom + kFloatingNavBarHeight;
}

const userAgentIOS =
    "Mozilla/5.0 (iPhone; CPU iPhone OS 15_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.3 Mobile/15E148 Safari/605.1 NAVER(inapp; search; 1010; 11.11.6; 11PRO)";
const userAgentAndroid =
    "Mozilla/5.0 (Linux; arm_64; Android 12; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 YaApp_Android/22.50.1 YaSearchBrowser/22.50.1 BroPP/1.0 SA/3 Mobile Safari/537.36";

const kLogPass = "Onevnu@123";

const String PNG = 'PNG';
const String JPG = 'JPG';
const String JPEG = 'JPEG';
const String GIF = 'GIF';
const String XLS = 'XLS';
const String XLSX = 'XLSX';
const String PDF = 'PDF';
const String DOC = 'DOC';
const String DOCX = 'DOCX';
const String PPT = 'PPT';
const String PPTX = 'PPTX';
const String TXT = 'TXT';
const String RAR = 'RAR';
const String ZIP = 'ZIP';

const String roleXLC = 'mainProcess';
const String rolePH = 'process';
const String roleDXL = 'coProcess';
const String roleXEM = 'watching';

const String kNOLOG = 'NOLOG';
const String kFINISH = 'FINISH';
const String ALL = 'ALL';
const String UNREAD = 'UNREAD';
const String READED = 'READED';
const String PKI = 'PKI';
const String SMART = 'SMART';

//Config key
const String CONFIG_NHAP_LYDO_KETTHUC_VB = 'CONFIG_NHAP_LYDO_KETTHUC_VB';
const String CONFIG_SIGNATURE_NHIEULAN = 'CONFIG_SIGNATURE_NHIEULAN';
const String CONFIG_SIGNATURE_EXCEL = 'CONFIG_SIGNATURE_EXCEL';

//Document
const btn_tranfer_process = 'btn_tranfer_process';
const btn_process_outgoing = 'btn_process_outgoing';
const btn_process_incomming = 'btn_process_incomming';
const btn_luu_hscv = 'btn_luu_hscv';
const btn_danhdau = 'btn_danhdau';
const btn_bo_danhdau = 'btn_bo_danhdau';
const btn_activity = 'btn_activity';
const btn_finish = 'btn_finish';
const btn_send_comment = 'btn_send_comment';
const btn_give_back = 'btn_give_back';
const btn_recover = "btn_recover";
const btn_tranfer_view = "btn_tranfer_view";

/// Thông tin id action cho chuyển văn bản trong luồng
const int FA_NO_ACTION = -1;
const int FA_CHUYEN_TRONG_LUONG = 1;
const int FA_CHUYEN_NGOAI_LUONG = 2;
const int FA_ISSUE = 6;
const int FA_UPDATE_ISSUE = 20;
const int FA_XINYKIEN = 7;
const int FA_CHOYKIEN = 8;
const int FA_GIAOVIEC = 9;
const int FA_FINISH = 10;
const int FA_REFUSE = 11;
const int FA_TRANSFERVIEW = 12;
const int FA_GIVEBACK = 13;
const int FA_ANSWER = 14;
