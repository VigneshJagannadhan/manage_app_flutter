import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The fonts a user can pick from on the "Customise the App" screen.
enum AppFontOption {
  bitcount,
  roboto,
  poppins,
  inter,
  lato;

  static const AppFontOption defaultOption = AppFontOption.bitcount;

  String get label => switch (this) {
    AppFontOption.bitcount => 'Bitcount',
    AppFontOption.roboto => 'Roboto',
    AppFontOption.poppins => 'Poppins',
    AppFontOption.inter => 'Inter',
    AppFontOption.lato => 'Lato',
  };

  TextStyle textStyle({required double fontSize, required FontWeight fontWeight, required Color color}) => switch (this) {
    AppFontOption.bitcount => GoogleFonts.bitcountPropSingle(fontSize: fontSize, fontWeight: fontWeight, color: color),
    AppFontOption.roboto => GoogleFonts.roboto(fontSize: fontSize, fontWeight: fontWeight, color: color),
    AppFontOption.poppins => GoogleFonts.poppins(fontSize: fontSize, fontWeight: fontWeight, color: color),
    AppFontOption.inter => GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: color),
    AppFontOption.lato => GoogleFonts.lato(fontSize: fontSize, fontWeight: fontWeight, color: color),
  };

  static AppFontOption fromName(String? name) => AppFontOption.values.firstWhere((option) => option.name == name, orElse: () => defaultOption);
}
