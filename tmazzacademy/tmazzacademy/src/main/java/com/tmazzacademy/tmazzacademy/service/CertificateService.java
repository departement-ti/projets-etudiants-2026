package com.tmazzacademy.tmazzacademy.service;

import com.itextpdf.text.*;
import com.itextpdf.text.pdf.*;
import com.tmazzacademy.tmazzacademy.model.Certificate;
import com.tmazzacademy.tmazzacademy.model.Student;
import com.tmazzacademy.tmazzacademy.repository.CertificateRepository;
import com.tmazzacademy.tmazzacademy.repository.StudentRepository;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
public class CertificateService {

    private final CertificateRepository certificateRepository;
    private final StudentRepository studentRepository;

    public CertificateService(
            CertificateRepository certificateRepository,
            StudentRepository studentRepository
    ) {
        this.certificateRepository = certificateRepository;
        this.studentRepository = studentRepository;
    }

    public List<Certificate> getCertificatesByStudent(Long studentId) {
        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("Student not found"));

        return certificateRepository.findByStudent(student);
    }

    public byte[] generateCertificatePdf(Long certificateId) {
        Certificate certificate = certificateRepository.findById(certificateId)
                .orElseThrow(() -> new RuntimeException("Certificate not found"));

        try {
            ByteArrayOutputStream out = new ByteArrayOutputStream();

            Document document = new Document(PageSize.A4.rotate(), 0, 0, 0, 0);
            PdfWriter writer = PdfWriter.getInstance(document, out);

            document.open();

            PdfContentByte cb = writer.getDirectContent();
            Rectangle page = document.getPageSize();

            float w = page.getWidth();
            float h = page.getHeight();

            BaseColor blue = new BaseColor(37, 99, 235);
            BaseColor darkBlue = new BaseColor(30, 64, 175);
            BaseColor dark = new BaseColor(15, 23, 42);
            BaseColor gray = new BaseColor(71, 85, 105);

            Font logoFont = new Font(Font.FontFamily.HELVETICA, 28, Font.BOLD, BaseColor.WHITE);
            Font academyFont = new Font(Font.FontFamily.HELVETICA, 24, Font.BOLD, dark);
            Font smallGray = new Font(Font.FontFamily.HELVETICA, 13, Font.NORMAL, gray);

            Font certFont = new Font(Font.FontFamily.TIMES_ROMAN, 54, Font.BOLD, darkBlue);
            Font achievementFont = new Font(Font.FontFamily.HELVETICA, 19, Font.BOLD, dark);

            Font normalFont = new Font(Font.FontFamily.HELVETICA, 17, Font.NORMAL, gray);
            Font nameFont = new Font(Font.FontFamily.TIMES_ROMAN, 40, Font.BOLDITALIC, darkBlue);
            Font courseFont = new Font(Font.FontFamily.HELVETICA, 20, Font.BOLD, blue);
            Font scoreFont = new Font(Font.FontFamily.HELVETICA, 18, Font.BOLD, dark);
            Font signFont = new Font(Font.FontFamily.TIMES_ROMAN, 26, Font.ITALIC, dark);
            Font boldSmall = new Font(Font.FontFamily.HELVETICA, 13, Font.BOLD, darkBlue);

            // Background
            cb.setColorFill(BaseColor.WHITE);
            cb.rectangle(0, 0, w, h);
            cb.fill();

            // Light wave lines
            cb.setColorStroke(new BaseColor(226, 232, 240));
            cb.setLineWidth(0.4f);

            for (int i = 0; i < 16; i++) {
                float y = 150 + i * 20;
                cb.moveTo(95, y);
                cb.curveTo(w / 3, y + 14, w * 2 / 3, y - 14, w - 95, y);
                cb.stroke();
            }

            // Borders
            cb.setColorStroke(blue);
            cb.setLineWidth(5f);
            cb.rectangle(35, 35, w - 70, h - 70);
            cb.stroke();

            cb.setColorStroke(darkBlue);
            cb.setLineWidth(1.5f);
            cb.rectangle(50, 50, w - 100, h - 100);
            cb.stroke();

            cb.setColorStroke(blue);
            cb.setLineWidth(2f);
            cb.rectangle(65, 65, w - 130, h - 130);
            cb.stroke();

            drawCorner(cb, 35, 35, blue, false, false);
            drawCorner(cb, w - 35, 35, blue, true, false);
            drawCorner(cb, 35, h - 35, blue, false, true);
            drawCorner(cb, w - 35, h - 35, blue, true, true);

            // Logo
            cb.setColorFill(blue);
            cb.roundRectangle(w / 2 - 28, h - 105, 56, 56, 12);
            cb.fill();

            addText(cb, "M", logoFont, w / 2, h - 88, Element.ALIGN_CENTER);

            addText(cb, "TMazz Academy", academyFont, w / 2, h - 135, Element.ALIGN_CENTER);
            addText(cb, "Empowering minds, building futures.", smallGray, w / 2, h - 157, Element.ALIGN_CENTER);

            // Main title
            addText(cb, "CERTIFICATE", certFont, w / 2, h - 230, Element.ALIGN_CENTER);

            cb.setColorStroke(blue);
            cb.setLineWidth(2f);
            cb.moveTo(w / 2 - 175, h - 255);
            cb.lineTo(w / 2 + 175, h - 255);
            cb.stroke();

            addText(cb, "OF ACHIEVEMENT", achievementFont, w / 2, h - 263, Element.ALIGN_CENTER);

            // Student section
            addText(cb, "This is to certify that", normalFont, w / 2, h - 303, Element.ALIGN_CENTER);

            addText(
                    cb,
                    capitalize(certificate.getStudentName()),
                    nameFont,
                    w / 2,
                    h - 350,
                    Element.ALIGN_CENTER
            );

            cb.setColorStroke(blue);
            cb.setLineWidth(1.2f);
            cb.moveTo(w / 2 - 210, h - 365);
            cb.lineTo(w / 2 + 210, h - 365);
            cb.stroke();

            addText(
                    cb,
                    "has successfully completed the course",
                    normalFont,
                    w / 2,
                    h - 402,
                    Element.ALIGN_CENTER
            );

            // Course title - max 2 lines
            addCenteredMultilineText(
                    cb,
                    certificate.getCourseTitle(),
                    courseFont,
                    120,
                    w - 120,
                    h - 438,
                    24,
                    2
            );

            // Score واضح وما فوقوش badge
            addText(
                    cb,
                    "Score: " + certificate.getScore() + "/20",
                    scoreFont,
                    w / 2,
                    h - 485,
                    Element.ALIGN_CENTER
            );

            String date = LocalDate.now().format(DateTimeFormatter.ofPattern("MMMM dd, yyyy"));

            // Signature left
            addText(cb, "TMazz", signFont, 190, 130, Element.ALIGN_CENTER);

            cb.setColorStroke(gray);
            cb.setLineWidth(1f);
            cb.moveTo(100, 113);
            cb.lineTo(280, 113);
            cb.stroke();

            addText(cb, "TMazz Academy", boldSmall, 190, 92, Element.ALIGN_CENTER);
            addText(cb, "Authorized Signature", smallGray, 190, 74, Element.ALIGN_CENTER);

            // Date right
            addText(cb, date, scoreFont, w - 190, 130, Element.ALIGN_CENTER);

            cb.setColorStroke(gray);
            cb.setLineWidth(1f);
            cb.moveTo(w - 280, 113);
            cb.lineTo(w - 100, 113);
            cb.stroke();

            addText(cb, "Date of Completion", smallGray, w - 190, 92, Element.ALIGN_CENTER);

            // Certificate ID
            addText(
                    cb,
                    "CERTIFICATE ID: #" + certificate.getId(),
                    boldSmall,
                    w / 2,
                    70,
                    Element.ALIGN_CENTER
            );

            document.close();

            return out.toByteArray();

        } catch (Exception e) {
            e.printStackTrace();
            throw new RuntimeException("Error generating PDF");
        }
    }

    private void addText(
            PdfContentByte cb,
            String text,
            Font font,
            float x,
            float y,
            int align
    ) {
        ColumnText.showTextAligned(
                cb,
                align,
                new Phrase(text == null ? "" : text, font),
                x,
                y,
                0
        );
    }

    private void addCenteredMultilineText(
            PdfContentByte cb,
            String text,
            Font font,
            float left,
            float right,
            float topY,
            float lineHeight,
            int maxLines
    ) throws Exception {

        if (text == null || text.trim().isEmpty()) {
            return;
        }

        BaseFont bf = BaseFont.createFont(
                BaseFont.HELVETICA,
                BaseFont.CP1252,
                BaseFont.NOT_EMBEDDED
        );

        String[] words = text.trim().split("\\s+");
        StringBuilder line = new StringBuilder();

        int linesPrinted = 0;
        float y = topY;

        for (String word : words) {

            String testLine =
                    line.length() == 0
                            ? word
                            : line + " " + word;

            float width = bf.getWidthPoint(testLine, font.getSize());

            if (width > (right - left) && line.length() > 0) {

                linesPrinted++;

                if (linesPrinted > maxLines) {
                    return;
                }

                addText(
                        cb,
                        line.toString(),
                        font,
                        (left + right) / 2,
                        y,
                        Element.ALIGN_CENTER
                );

                y -= lineHeight;
                line = new StringBuilder(word);

            } else {
                line = new StringBuilder(testLine);
            }
        }

        if (line.length() > 0 && linesPrinted < maxLines) {
            addText(
                    cb,
                    line.toString(),
                    font,
                    (left + right) / 2,
                    y,
                    Element.ALIGN_CENTER
            );
        }
    }

    private String capitalize(String text) {
        if (text == null || text.trim().isEmpty()) {
            return "";
        }

        String[] words = text.trim().split("\\s+");
        StringBuilder result = new StringBuilder();

        for (String word : words) {
            if (!word.isEmpty()) {
                result.append(word.substring(0, 1).toUpperCase())
                        .append(word.substring(1).toLowerCase())
                        .append(" ");
            }
        }

        return result.toString().trim();
    }

    private void drawCorner(
            PdfContentByte cb,
            float x,
            float y,
            BaseColor color,
            boolean right,
            boolean top
    ) {
        cb.setColorStroke(color);
        cb.setLineWidth(3f);

        float sx = right ? -1 : 1;
        float sy = top ? -1 : 1;

        cb.moveTo(x, y + sy * 35);
        cb.curveTo(
                x + sx * 12,
                y + sy * 12,
                x + sx * 12,
                y + sy * 12,
                x + sx * 35,
                y
        );
        cb.stroke();

        cb.setLineWidth(1.2f);

        cb.moveTo(x + sx * 15, y + sy * 55);
        cb.curveTo(
                x + sx * 25,
                y + sy * 25,
                x + sx * 25,
                y + sy * 25,
                x + sx * 55,
                y + sy * 15
        );
        cb.stroke();
    }
}