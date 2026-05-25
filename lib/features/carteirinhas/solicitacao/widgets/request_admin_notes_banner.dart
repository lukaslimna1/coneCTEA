import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RequestAdminNotesBanner extends StatelessWidget {
  final String adminNotes;

  const RequestAdminNotesBanner({super.key, required this.adminNotes});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIconsRegular.warningCircle,
                color: Colors.orange[800],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ajustes solicitados',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    color: Colors.orange[900],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            adminNotes,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.orange[900],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
